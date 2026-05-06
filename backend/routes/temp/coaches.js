import express from "express";
import pool from "../../config/db.js";

const router = express.Router();

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/temp/coaches
// Récupère la liste de tous les coaches (avec leurs images si disponibles)
// ─────────────────────────────────────────────────────────────────────────────
router.get("/", async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT id, name, image, createdAt FROM Coaches ORDER BY name ASC"
    );
    res.json({
      success: true,
      data: rows.map((coach) => ({
        id: coach.id,
        name: coach.name,
        image: coach.image || null, // Si image est vide, on renvoie null
        createdAt: coach.createdAt,
      })),
    });
  } catch (err) {
    console.error("GET /api/temp/coaches:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to fetch coaches",
    });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/temp/coaches/invited/:clientID
// Vérifie si un client a déjà invité un coach (et lequel)
// ─────────────────────────────────────────────────────────────────────────────
router.get("/invited/:clientID", async (req, res) => {
  const { clientID } = req.params;
  if (!clientID || isNaN(clientID)) {
    return res.status(400).json({
      success: false,
      message: "Invalid clientID",
    });
  }

  try {
    const [rows] = await pool.query(
      `SELECT c.id, c.name, c.image
       FROM Invites i
       JOIN Coaches c ON i.coachID = c.id
       WHERE i.clientID = ?`,
      [clientID]
    );

    if (rows.length === 0) {
      return res.json({
        success: true,
        data: null, // Aucun coach invité
      });
    }

    // Un client ne peut avoir qu'une seule invitation (selon votre règle)
    const invitedCoach = rows[0];
    res.json({
      success: true,
      data: {
        id: invitedCoach.id,
        name: invitedCoach.name,
        image: invitedCoach.image || null,
      },
    });
  } catch (err) {
    console.error("GET /api/temp/coaches/invited/:clientID:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to check invited coach",
    });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/temp/coaches/invite
// Envoie une invitation à un coach (body: { clientID, coachID })
// ─────────────────────────────────────────────────────────────────────────────
router.post("/invite", async (req, res) => {
  const { clientID, coachID } = req.body;

  if (!clientID || isNaN(clientID) || !coachID || isNaN(coachID)) {
    return res.status(400).json({
      success: false,
      message: "clientID and coachID are required and must be valid numbers",
    });
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    // Vérifier si le client existe
    const [clientRows] = await connection.query(
      "SELECT id FROM Clients WHERE id = ?",
      [clientID]
    );
    if (clientRows.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        success: false,
        message: "Client not found",
      });
    }

    // Vérifier si le coach existe
    const [coachRows] = await connection.query(
      "SELECT id FROM Coaches WHERE id = ?",
      [coachID]
    );
    if (coachRows.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        success: false,
        message: "Coach not found",
      });
    }

    // Vérifier si le client a déjà invité un coach
    const [existingInvites] = await connection.query(
      "SELECT coachID FROM Invites WHERE clientID = ?",
      [clientID]
    );
    if (existingInvites.length > 0) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: `Client has already invited coach ${existingInvites[0].coachID}`,
        alreadyInvitedCoachID: existingInvites[0].coachID,
      });
    }

    // Créer l'invitation
    await connection.query(
      "INSERT INTO Invites (coachID, clientID) VALUES (?, ?)",
      [coachID, clientID]
    );

    await connection.commit();
    res.json({
      success: true,
      message: `Invitation sent to coach ${coachID}`,
    });
  } catch (err) {
    await connection.rollback();
    console.error("POST /api/temp/coaches/invite:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to send invitation",
    });
  } finally {
    connection.release();
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// DELETE /api/temp/coaches/cancel-invite
// Annule une invitation existante (body: { clientID })
// ─────────────────────────────────────────────────────────────────────────────
router.delete("/cancel-invite", async (req, res) => {
  const { clientID } = req.body;

  if (!clientID || isNaN(clientID)) {
    return res.status(400).json({
      success: false,
      message: "clientID is required and must be a valid number",
    });
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    // Vérifier si le client a une invitation existante
    const [existingInvites] = await connection.query(
      "SELECT coachID FROM Invites WHERE clientID = ?",
      [clientID]
    );
    if (existingInvites.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        success: false,
        message: "No invitation found for this client",
      });
    }

    // Supprimer l'invitation
    await connection.query(
      "DELETE FROM Invites WHERE clientID = ?",
      [clientID]
    );

    await connection.commit();
    res.json({
      success: true,
      message: "Invitation cancelled",
    });
  } catch (err) {
    await connection.rollback();
    console.error("DELETE /api/temp/coaches/cancel-invite:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to cancel invitation",
    });
  } finally {
    connection.release();
  }
});

export default router;