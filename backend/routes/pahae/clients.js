import express from "express";
import pool from "../../config/db.js";

const router = express.Router();

// ─────────────────────────────────────────────
// GET /api/pahae/clients/coach/:coachID
// Returns all clients assigned to a coach
// ─────────────────────────────────────────────
router.get("/coach/:coachID", async (req, res) => {
  const { coachID } = req.params;

  if (!coachID || isNaN(coachID)) {
    return res.status(400).json({ error: "Invalid coachID" });
  }

  try {
    const [rows] = await pool.query(
      `SELECT 
         c.id,
         c.name,
         c.image,
         c.birth,
         c.gender,
         c.email,
         c.weight,
         c.height,
         c.frequency,
         c.goal,
         c.weightGoal,
         c.createdAt,
         c.coachID
       FROM Clients c
       WHERE c.coachID = ?
       ORDER BY c.name ASC`,
      [coachID]
    );

    return res.status(200).json({ clients: rows });
  } catch (err) {
    console.error("GET /coach/:coachID error:", err.message);
    return res.status(500).json({ error: "Internal server error" });
  }
});

// ─────────────────────────────────────────────
// DELETE /api/pahae/clients/:clientID/coach/:coachID
// Removes the coach from a client (sets coachID to NULL)
// Does NOT delete the client account
// ─────────────────────────────────────────────
router.delete("/:clientID/coach/:coachID", async (req, res) => {
  const { clientID, coachID } = req.params;

  if (!clientID || isNaN(clientID) || !coachID || isNaN(coachID)) {
    return res.status(400).json({ error: "Invalid clientID or coachID" });
  }

  try {
    // Verify the client actually belongs to this coach before removing
    const [check] = await pool.query(
      `SELECT id FROM Clients WHERE id = ? AND coachID = ?`,
      [clientID, coachID]
    );

    if (check.length === 0) {
      return res.status(404).json({ error: "Client not found for this coach" });
    }

    await pool.query(
      `UPDATE Clients SET coachID = NULL WHERE id = ? AND coachID = ?`,
      [clientID, coachID]
    );

    return res.status(200).json({ message: "Client removed successfully" });
  } catch (err) {
    console.error("DELETE /:clientID/coach/:coachID error:", err.message);
    return res.status(500).json({ error: "Internal server error" });
  }
});

export default router;
