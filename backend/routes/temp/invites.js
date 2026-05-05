import express from "express";
import pool from "../../config/db.js";

const router = express.Router();

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/temp/invites/:coachID
// Récupère la liste des clients qui ont invité un coach (avec leurs infos)
// ─────────────────────────────────────────────────────────────────────────────
router.get("/:coachID", async (req, res) => {
  const { coachID } = req.params;
  if (!coachID || isNaN(coachID)) {
    return res.status(400).json({
      success: false,
      message: "Invalid coachID",
    });
  }

  try {
    const [rows] = await pool.query(
      `SELECT
        c.id, c.name, c.image, c.birth, c.gender, c.weight, c.height,
        c.frequency, c.goal, c.weightGoal, c.createdAt
       FROM Invites i
       JOIN Clients c ON i.clientID = c.id
       WHERE i.coachID = ?
       ORDER BY i.clientID DESC`,
      [coachID]
    );

    res.json({
      success: true,
      data: rows.map((client) => ({
        id: client.id,
        name: client.name,
        image: client.image || null,
        birth: client.birth,
        gender: client.gender,
        weight: client.weight,
        height: client.height,
        frequency: client.frequency,
        goal: client.goal,
        weightGoal: client.weightGoal,
        createdAt: client.createdAt,
      })),
    });
  } catch (err) {
    console.error("GET /api/temp/invites/:coachID:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to fetch invites",
    });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/temp/invites/:clientID/accept
// Accepte une invitation (met à jour le coachID du client et supprime l'invitation)
// Body: { coachID }
// ─────────────────────────────────────────────────────────────────────────────
router.post("/:clientID/accept", async (req, res) => {
  const { clientID } = req.params;
  const { coachID } = req.body;

  if (!clientID || isNaN(clientID) || !coachID || isNaN(coachID)) {
    return res.status(400).json({
      success: false,
      message: "clientID and coachID are required and must be valid numbers",
    });
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    // Vérifier si l'invitation existe
    const [inviteRows] = await connection.query(
      "SELECT 1 FROM Invites WHERE clientID = ? AND coachID = ?",
      [clientID, coachID]
    );
    if (inviteRows.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        success: false,
        message: "Invitation not found",
      });
    }

    // Mettre à jour le coachID du client
    await connection.query(
      "UPDATE Clients SET coachID = ? WHERE id = ?",
      [coachID, clientID]
    );

    // Supprimer l'invitation
    await connection.query(
      "DELETE FROM Invites WHERE clientID = ? AND coachID = ?",
      [clientID, coachID]
    );

    await connection.commit();
    res.json({
      success: true,
      message: `Invitation from client ${clientID} accepted`,
    });
  } catch (err) {
    await connection.rollback();
    console.error("POST /api/temp/invites/:clientID/accept:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to accept invitation",
    });
  } finally {
    connection.release();
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/temp/invites/:clientID/refuse
// Refuse une invitation (supprime l'invitation et stocke la raison)
// Body: { coachID, reason }
// ─────────────────────────────────────────────────────────────────────────────
router.post("/:clientID/refuse", async (req, res) => {
  const { clientID } = req.params;
  const { coachID, reason } = req.body;

  if (!clientID || isNaN(clientID) || !coachID || isNaN(coachID)) {
    return res.status(400).json({
      success: false,
      message: "clientID and coachID are required and must be valid numbers",
    });
  }

  if (!reason || typeof reason !== "string" || reason.trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Reason is required and must be a non-empty string",
    });
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    // Vérifier si l'invitation existe
    const [inviteRows] = await connection.query(
      "SELECT 1 FROM Invites WHERE clientID = ? AND coachID = ?",
      [clientID, coachID]
    );
    if (inviteRows.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        success: false,
        message: "Invitation not found",
      });
    }

    // Supprimer l'invitation
    await connection.query(
      "DELETE FROM Invites WHERE clientID = ? AND coachID = ?",
      [clientID, coachID]
    );

    // TODO: Stocker la raison dans une table dédiée (ex: InviteRefusals)
    // Exemple:
    // await connection.query(
    //   "INSERT INTO InviteRefusals (clientID, coachID, reason, refusedAt) VALUES (?, ?, ?, NOW())",
    //   [clientID, coachID, reason.trim()]
    // );

    await connection.commit();
    res.json({
      success: true,
      message: `Invitation from client ${clientID} refused`,
    });
  } catch (err) {
    await connection.rollback();
    console.error("POST /api/temp/invites/:clientID/refuse:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to refuse invitation",
    });
  } finally {
    connection.release();
  }
});

export default router;