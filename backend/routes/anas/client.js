

import express from "express";
import pool from "../../config/db.js";

const router = express.Router();

// ─── Mappers ──────────────────────────────────────────────────────────────────

const mapClient = (row) => ({
  id:         row.id,
  name:       row.name        ?? "",
  imageUrl:   row.image       ?? "",
  birth:      row.birth,
  weight:     row.weight,
  height:     row.height,
  frequency:  row.frequency,
  goal:       row.goal        ?? "",
  weightGoal: row.weightGoal,
  createdAt:  row.createdAt,
  coachID:    row.coachID,
});

const mapFood = (row) => ({
  id:       String(row.id),
  name:     row.name      ?? "",
  imageUrl: row.image     ?? "",
  calories: row.calories  ?? 0,
  type:     row.type      ?? "solid",   // "solid" | "liquid" | "grains" | "unit"
});

// Mealtimes réels uniquement (exclut les clés "recipe_X" créées par food.js)
const REAL_MEALTIMES = ["breakfast", "lunch", "dinner", "snacks"];

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/client/:clientID
// Profil complet du client pour la ClientScreen du coach.
// ─────────────────────────────────────────────────────────────────────────────
router.get("/:clientID", async (req, res) => {
  const { clientID } = req.params;
  if (!clientID || isNaN(clientID)) {
    return res.status(400).json({ success: false, message: "Invalid clientID" });
  }

  try {
    const [rows] = await pool.query(
      `SELECT id, name, image, birth, weight, height,
              frequency, goal, weightGoal, createdAt, coachID
       FROM Clients WHERE id = ?`,
      [clientID]
    );
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: "Client not found" });
    }

    res.json({ success: true, data: mapClient(rows[0]) });
  } catch (err) {
    console.error("GET /client/:clientID:", err.message);
    res.status(500).json({ success: false, message: "Failed to fetch client" });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/client/:clientID/weight-history
// Historique mensuel de poids pour _buildWeightChart() et _buildProgressCard().
// Retourne aussi le poids de départ (first entry) pour calculer la progression.
// ─────────────────────────────────────────────────────────────────────────────
router.get("/:clientID/weight-history", async (req, res) => {
  const { clientID } = req.params;
  if (!clientID || isNaN(clientID)) {
    return res.status(400).json({ success: false, message: "Invalid clientID" });
  }

  try {
    const [clientRows] = await pool.query(
      "SELECT id, weight FROM Clients WHERE id = ?",
      [clientID]
    );
    if (clientRows.length === 0) {
      return res.status(404).json({ success: false, message: "Client not found" });
    }

    // Agrégation mensuelle depuis WeightHistory
    const [rows] = await pool.query(
      `SELECT
         DATE_FORMAT(logDate, '%Y-%m-01') AS date,
         DATE_FORMAT(logDate, '%b')        AS month,
         ROUND(AVG(weight), 1)             AS weight
       FROM WeightHistory
       WHERE clientID = ?
       GROUP BY date, month
       ORDER BY date ASC`,
      [clientID]
    ).catch(() => [[]]); // si la table n'existe pas encore → tableau vide

    const history = rows.map((r) => ({
      date:   r.date,
      month:  r.month,           // 'Nov', 'Dec'… → utilisé tel quel par Flutter
      weight: parseFloat(r.weight),
    }));

    // Si pas d'historique : on renvoie un point unique avec le poids actuel
    const startWeight = history.length > 0
      ? history[0].weight
      : clientRows[0].weight;

    res.json({
      success: true,
      data: {
        history,
        startWeight,
        currentWeight: clientRows[0].weight,
      },
    });
  } catch (err) {
    console.error("GET /client/:clientID/weight-history:", err.message);
    res.status(500).json({ success: false, message: "Failed to fetch weight history" });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/client/:clientID/weight-history
// Enregistre (ou met à jour) le poids du jour et met à jour Clients.weight.
// Body: { weight: 82.5 }
// ─────────────────────────────────────────────────────────────────────────────
router.post("/:clientID/weight-history", async (req, res) => {
  const { clientID } = req.params;
  const { weight } = req.body;

  if (!clientID || isNaN(clientID)) {
    return res.status(400).json({ success: false, message: "Invalid clientID" });
  }
  if (weight == null || isNaN(weight) || Number(weight) <= 0) {
    return res.status(400).json({ success: false, message: "Valid weight required (kg)" });
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const [clientRows] = await connection.query(
      "SELECT id FROM Clients WHERE id = ?",
      [clientID]
    );
    if (clientRows.length === 0) {
      await connection.rollback();
      connection.release();
      return res.status(404).json({ success: false, message: "Client not found" });
    }

    const today   = new Date().toISOString().split("T")[0];
    const rounded = parseFloat(Number(weight).toFixed(1));

    await connection.query(
      `INSERT INTO WeightHistory (weight, logDate, clientID)
       VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE weight = VALUES(weight)`,
      [rounded, today, clientID]
    );

    // Synchronise le poids courant du client
    await connection.query(
      "UPDATE Clients SET weight = ? WHERE id = ?",
      [rounded, clientID]
    );

    await connection.commit();
    connection.release();

    res.json({
      success: true,
      message: "Weight logged",
      data: { date: today, weight: rounded },
    });
  } catch (err) {
    await connection.rollback();
    connection.release();
    console.error("POST /client/:clientID/weight-history:", err.message);
    res.status(500).json({ success: false, message: "Failed to log weight" });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/client/:clientID/foods
// Liste des aliments distincts enregistrés par le client dans NutritionIngredients
// (mealtimes réels seulement : breakfast / lunch / dinner / snacks).
// Utilisé par _buildFoodList() de la ClientScreen.
// ─────────────────────────────────────────────────────────────────────────────
router.get("/:clientID/foods", async (req, res) => {
  const { clientID } = req.params;
  if (!clientID || isNaN(clientID)) {
    return res.status(400).json({ success: false, message: "Invalid clientID" });
  }

  try {
    const [clientRows] = await pool.query(
      "SELECT id FROM Clients WHERE id = ?",
      [clientID]
    );
    if (clientRows.length === 0) {
      return res.status(404).json({ success: false, message: "Client not found" });
    }

    const placeholders = REAL_MEALTIMES.map(() => "?").join(",");

    const [rows] = await pool.query(
      `SELECT DISTINCT i.id, i.name, i.image, i.calories, i.type
       FROM NutritionIngredients ni
       JOIN Ingredients i ON i.id = ni.ingredientID
       WHERE ni.clientID = ?
         AND ni.mealtime IN (${placeholders})
       ORDER BY i.name ASC`,
      [clientID, ...REAL_MEALTIMES]
    );

    res.json({ success: true, data: rows.map(mapFood) });
  } catch (err) {
    console.error("GET /client/:clientID/foods:", err.message);
    res.status(500).json({ success: false, message: "Failed to fetch food list" });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/client/:clientID/program
// Récupère le programme coach pour ce client.
// Retourne { text: "", updatedAt: null } si aucun programme n'a encore été écrit.
// ─────────────────────────────────────────────────────────────────────────────
router.get("/:clientID/program", async (req, res) => {
  const { clientID } = req.params;
  if (!clientID || isNaN(clientID)) {
    return res.status(400).json({ success: false, message: "Invalid clientID" });
  }

  try {
    const [clientRows] = await pool.query(
      "SELECT id FROM Clients WHERE id = ?",
      [clientID]
    );
    if (clientRows.length === 0) {
      return res.status(404).json({ success: false, message: "Client not found" });
    }

    const [rows] = await pool.query(
      `SELECT cp.text, cp.updatedAt, c.name AS coachName
       FROM CoachPrograms cp
       JOIN Coaches c ON c.id = cp.coachID
       WHERE cp.clientID = ?`,
      [clientID]
    );

    if (rows.length === 0) {
      return res.json({
        success: true,
        data: { text: "", updatedAt: null, coachName: null },
      });
    }

    res.json({
      success: true,
      data: {
        text:      rows[0].text      ?? "",
        updatedAt: rows[0].updatedAt ?? null,
        coachName: rows[0].coachName ?? "",
      },
    });
  } catch (err) {
    console.error("GET /client/:clientID/program:", err.message);
    res.status(500).json({ success: false, message: "Failed to fetch program" });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// PUT /api/client/:clientID/program
// Le coach sauvegarde (ou met à jour) le programme du client.
// Body: { coachID: 3, text: "Day 1 : ..." }
// ─────────────────────────────────────────────────────────────────────────────
router.put("/:clientID/program", async (req, res) => {
  const { clientID } = req.params;
  const { coachID, text } = req.body;

  if (!clientID || isNaN(clientID)) {
    return res.status(400).json({ success: false, message: "Invalid clientID" });
  }
  if (!coachID || isNaN(coachID)) {
    return res.status(400).json({ success: false, message: "Invalid coachID" });
  }
  if (text == null || typeof text !== "string") {
    return res.status(400).json({ success: false, message: "text (string) is required" });
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    // Vérifie que le client existe et appartient bien à ce coach
    const [clientRows] = await connection.query(
      "SELECT id FROM Clients WHERE id = ? AND coachID = ?",
      [clientID, coachID]
    );
    if (clientRows.length === 0) {
      await connection.rollback();
      connection.release();
      return res.status(403).json({
        success: false,
        message: "Client not found or does not belong to this coach",
      });
    }

    // Upsert : crée si inexistant, met à jour sinon
    await connection.query(
      `INSERT INTO CoachPrograms (text, clientID, coachID)
       VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE
         text    = VALUES(text),
         coachID = VALUES(coachID)`,
      [text.trim(), clientID, coachID]
    );

    await connection.commit();
    connection.release();

    res.json({ success: true, message: "Program saved" });
  } catch (err) {
    await connection.rollback();
    connection.release();
    console.error("PUT /client/:clientID/program:", err.message);
    res.status(500).json({ success: false, message: "Failed to save program" });
  }
});

export default router;