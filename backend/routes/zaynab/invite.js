import express from 'express';
import pool from "../../config/db.js";

const router = express.Router();

// POST /api/invites — envoyer une invitation (client → coach)
router.post('/', async (req, res) => {
  const { coachID, clientID } = req.body;
  if (!coachID || !clientID)
    return res.status(400).json({ error: 'coachID and clientID are required' });
  try {
    await pool.query(
      `INSERT IGNORE INTO Invites (coachID, clientID) VALUES (?, ?)`,
      [coachID, clientID]
    );
    res.status(201).json({ message: 'Invitation sent' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/invites/coach/:coachID — clients qui ont invité ce coach
router.get('/coach/:coachID', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT c.id, c.name, c.image, c.birth, c.weight, c.height,
              c.frequency, c.goal, c.weightGoal, c.createdAt, c.coachID, c.gender
       FROM Invites i
       JOIN Clients c ON c.id = i.clientID
       WHERE i.coachID = ?`,
      [req.params.coachID]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/invites/client/:clientID — coaches invités par un client
router.get('/client/:clientID', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT co.id, co.name, co.image, co.createdAt
       FROM Invites i
       JOIN Coaches co ON co.id = i.coachID
       WHERE i.clientID = ?`,
      [req.params.clientID]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/invites/accept — coach accepte un client
// body: { coachID, clientID }
router.post('/accept', async (req, res) => {
  const { coachID, clientID } = req.body;
  if (!coachID || !clientID)
    return res.status(400).json({ error: 'coachID and clientID are required' });

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    // Lier le client à ce coach
    await conn.query(`UPDATE Clients SET coachID = ? WHERE id = ?`, [coachID, clientID]);
    // Supprimer l'invitation
    await conn.query(`DELETE FROM Invites WHERE coachID = ? AND clientID = ?`, [coachID, clientID]);
    await conn.commit();
    res.json({ message: 'Invitation accepted' });
  } catch (err) {
    await conn.rollback();
    res.status(500).json({ error: err.message });
  } finally {
    conn.release();
  }
});

// POST /api/invites/refuse — coach refuse un client
// body: { coachID, clientID, reason? }
router.post('/refuse', async (req, res) => {
  const { coachID, clientID } = req.body;
  if (!coachID || !clientID)
    return res.status(400).json({ error: 'coachID and clientID are required' });
  try {
    await pool.query(
      `DELETE FROM Invites WHERE coachID = ? AND clientID = ?`,
      [coachID, clientID]
    );
    res.json({ message: 'Invitation refused' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/invites — annuler une invitation (côté client)
router.delete('/', async (req, res) => {
  const { coachID, clientID } = req.body;
  try {
    await pool.query(`DELETE FROM Invites WHERE coachID = ? AND clientID = ?`, [coachID, clientID]);
    res.json({ message: 'Invitation cancelled' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;