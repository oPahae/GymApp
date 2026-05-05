

import express from "express";
import pool from "../../config/db.js";

const router = express.Router();

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Calcule l'IMC et son label (en français, identique à Flutter). */
function computeBmi(weight, height) {
  const h = height / 100;
  const bmi = weight / (h * h);
  let label, color;
  if (bmi < 18.5) { label = "INSUFFISANT"; color = "#5BC4F5"; }
  else if (bmi < 25) { label = "NORMAL";      color = "#C8FF00"; }
  else if (bmi < 30) { label = "SURPOIDS";    color = "#FFA940"; }
  else               { label = "OBÉSITÉ";     color = "#FF6B6B"; }
  return { value: parseFloat(bmi.toFixed(1)), label, color };
}

/** Ratio de progression [0-1] vers l'objectif de poids. */
function computeProgressRatio(startWeight, currentWeight, goalWeight) {
  const total = Math.abs(startWeight - goalWeight);
  if (total === 0) return 1;
  return Math.min(1, Math.abs(startWeight - currentWeight) / total);
}

/** ETA en mois (entiers) basé sur un taux mensuel moyen. */
function computeEtaMonths(history, currentWeight, goalWeight) {
  if (history.length < 2) return null;
  const remaining = Math.abs(currentWeight - goalWeight);
  if (remaining < 0.5) return 0;                  // objectif atteint
  const months  = history.length - 1;
  const delta   = history[history.length - 1].weight - history[0].weight;
  if (months === 0 || Math.abs(delta) < 0.1) return null;
  const rate    = delta / months;
  if (Math.abs(rate) < 0.05) return null;
  const needed  = (currentWeight - goalWeight) / rate;
  return needed <= 0 ? 0 : Math.round(needed);
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/stat/:clientID
// Payload principal de StatScreen :
//   • profil client
//   • stats calculées (IMC, ratio, ETA, changement total)
//   • calories des 30 derniers jours (table Days)
// ─────────────────────────────────────────────────────────────────────────────
router.get("/:clientID", async (req, res) => {
  const { clientID } = req.params;
  if (!clientID || isNaN(clientID)) {
    return res.status(400).json({ success: false, message: "Invalid clientID" });
  }

  try {
    // 1. Profil client
    const [clients] = await pool.query(
      `SELECT id, name, image, birth, weight, height,
              frequency, goal, weightGoal, createdAt
       FROM Clients WHERE id = ?`,
      [clientID]
    );
    if (clients.length === 0) {
      return res.status(404).json({ success: false, message: "Client not found" });
    }
    const c = clients[0];

    // 2. Historique de poids mensuel (pour le ratio / ETA)
    const [weightRows] = await pool.query(
      `SELECT
         DATE_FORMAT(logDate, '%Y-%m-01') AS monthStart,
         ROUND(AVG(weight), 1)            AS weight
       FROM WeightHistory
       WHERE clientID = ?
       GROUP BY monthStart
       ORDER BY monthStart ASC`,
      [clientID]
    ).catch(() => [[]]);           // table peut ne pas exister encore → tableau vide

    const weightHistory = weightRows.map((r) => ({
      date:   r.monthStart,
      weight: parseFloat(r.weight),
    }));

    // Poids de départ = première entrée connue, sinon poids actuel
    const startWeight = weightHistory.length > 0
      ? weightHistory[0].weight
      : c.weight;

    // 3. Stats calculées
    const bmi          = computeBmi(c.weight, c.height);
    const ratio        = computeProgressRatio(startWeight, c.weight, c.weightGoal);
    const change       = parseFloat((c.weight - startWeight).toFixed(1));
    const remaining    = parseFloat(Math.abs(c.weight - c.weightGoal).toFixed(1));
    const etaMonths    = computeEtaMonths(weightHistory, c.weight, c.weightGoal);

    // 4. Calories des 30 derniers jours (table Days)
    const [calorieRows] = await pool.query(
      `SELECT logDate, calories
       FROM Days
       WHERE clientID = ?
         AND logDate >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
       ORDER BY logDate ASC`,
      [clientID]
    );

    const avgCalories = calorieRows.length > 0
      ? Math.round(
          calorieRows.reduce((s, r) => s + (r.calories ?? 0), 0) / calorieRows.length
        )
      : 0;

    // 5. Réponse
    res.json({
      success: true,
      data: {
        // ── Profil ──────────────────────────────────────────────────────────
        id:         String(c.id),
        name:       c.name        ?? "",
        imageUrl:   c.image       ?? "",
        birth:      c.birth,
        weight:     c.weight,
        height:     c.height,
        frequency:  c.frequency,
        goal:       c.goal        ?? "",
        weightGoal: c.weightGoal,
        createdAt:  c.createdAt,

        // ── Statistiques calculées ──────────────────────────────────────────
        startWeight,
        change,
        remaining,
        progressRatio: parseFloat(ratio.toFixed(3)),  // [0.0 – 1.0]
        etaMonths,                                    // null = pas calculable

        bmi: {
          value: bmi.value,
          label: bmi.label,
          color: bmi.color,
        },

        // ── Nutrition ───────────────────────────────────────────────────────
        calorieLogs: calorieRows.map((r) => ({
          date:     r.logDate,
          calories: r.calories ?? 0,
        })),
        avgCalories30d: avgCalories,
      },
    });
  } catch (err) {
    console.error("GET /stat/:clientID:", err.message);
    res.status(500).json({ success: false, message: "Failed to fetch stats" });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/stat/:clientID/weight-history
// Historique de poids mensuel – remplace _buildHistory() côté Flutter.
// ─────────────────────────────────────────────────────────────────────────────
router.get("/:clientID/weight-history", async (req, res) => {
  const { clientID } = req.params;
  if (!clientID || isNaN(clientID)) {
    return res.status(400).json({ success: false, message: "Invalid clientID" });
  }

  try {
    // Vérifie que le client existe
    const [clients] = await pool.query(
      "SELECT id FROM Clients WHERE id = ?",
      [clientID]
    );
    if (clients.length === 0) {
      return res.status(404).json({ success: false, message: "Client not found" });
    }

    // Agrégation mensuelle : moyenne du mois
    const [rows] = await pool.query(
      `SELECT
         DATE_FORMAT(logDate, '%Y-%m-01') AS date,
         ROUND(AVG(weight), 1)            AS weight
       FROM WeightHistory
       WHERE clientID = ?
       GROUP BY date
       ORDER BY date ASC`,
      [clientID]
    );

    res.json({
      success: true,
      data: rows.map((r) => ({
        date:   r.date,
        weight: parseFloat(r.weight),
      })),
    });
  } catch (err) {
    console.error("GET /stat/:clientID/weight-history:", err.message);
    res.status(500).json({ success: false, message: "Failed to fetch weight history" });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/stat/:clientID/weight-history
// Enregistre (ou met à jour) le poids du client pour aujourd'hui.
// Body: { weight: 82.5 }
// ─────────────────────────────────────────────────────────────────────────────
router.post("/:clientID/weight-history", async (req, res) => {
  const { clientID } = req.params;
  const { weight } = req.body;

  if (!clientID || isNaN(clientID)) {
    return res.status(400).json({ success: false, message: "Invalid clientID" });
  }
  if (weight == null || isNaN(weight) || weight <= 0) {
    return res.status(400).json({ success: false, message: "Valid weight required (kg)" });
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    // Vérifie que le client existe
    const [clients] = await connection.query(
      "SELECT id FROM Clients WHERE id = ?",
      [clientID]
    );
    if (clients.length === 0) {
      await connection.rollback();
      connection.release();
      return res.status(404).json({ success: false, message: "Client not found" });
    }

    const today = new Date().toISOString().split("T")[0];
    const rounded = parseFloat(Number(weight).toFixed(1));

    // INSERT ou UPDATE si une entrée existe déjà aujourd'hui
    await connection.query(
      `INSERT INTO WeightHistory (weight, logDate, clientID)
       VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE weight = VALUES(weight)`,
      [rounded, today, clientID]
    );

    // Met aussi à jour le poids courant dans Clients
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
    console.error("POST /stat/:clientID/weight-history:", err.message);
    res.status(500).json({ success: false, message: "Failed to log weight" });
  }
});

export default router;