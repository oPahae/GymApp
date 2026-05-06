import express from 'express';
import pool from "../../config/db.js";

const router = express.Router();

// GET /api/coaches — liste de tous les coaches
router.get('/', async (req, res) => {
  try {
    const [coaches] = await pool.query(`
      SELECT c.id, c.name, c.image, c.createdAt
      FROM Coaches c
      ORDER BY c.createdAt DESC
    `);
    res.json(coaches);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/coaches/:id — un coach avec ses clients
router.get('/:id', async (req, res) => {
  try {
    const [[coach]] = await pool.query(
      `SELECT id, name, image, createdAt FROM Coaches WHERE id = ?`,
      [req.params.id]
    );
    if (!coach) return res.status(404).json({ error: 'Coach not found' });

    const [clients] = await pool.query(
      `SELECT id, name, image, birth, weight, height, frequency, goal, weightGoal, createdAt, coachID, gender
       FROM Clients WHERE coachID = ?`,
      [req.params.id]
    );
    res.json({ ...coach, clients });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/coaches — créer un coach
router.post('/', async (req, res) => {
  const { id, name, image, createdAt } = req.body;
  try {
    await pool.query(
      `INSERT INTO Coaches (id, name, image, createdAt) VALUES (?, ?, ?, ?)`,
      [id, name, image ?? '', createdAt ?? new Date()]
    );
    res.status(201).json({ message: 'Coach created', id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/coaches/:id — mettre à jour un coach
router.put('/:id', async (req, res) => {
  const { name, image } = req.body;
  try {
    await pool.query(
      `UPDATE Coaches SET name = COALESCE(?, name), image = COALESCE(?, image) WHERE id = ?`,
      [name, image, req.params.id]
    );
    res.json({ message: 'Coach updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/coaches/:id — supprimer un coach
router.delete('/:id', async (req, res) => {
  try {
    await pool.query(`DELETE FROM Coaches WHERE id = ?`, [req.params.id]);
    res.json({ message: 'Coach deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;