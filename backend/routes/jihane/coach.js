import express from 'express';
import db from '../../config/db.js';
import authMiddleware from './auth.js';

const router = express.Router();

router.use(authMiddleware);

// GET /api/coaches
router.get('/', async (req, res) => {
  try {
    const [coaches] = await db.query(
      `SELECT co.id, co.name, co.image, co.createdAt, co.specialty, co.bio,
              COUNT(c.id) AS clientCount
       FROM Coaches co
       LEFT JOIN Clients c ON c.coachID = co.id
       GROUP BY co.id
       ORDER BY co.name`
    );
    res.json({ success: true, coaches });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// GET /api/coaches/:id (avec ses clients)
router.get('/:id', async (req, res) => {
  try {
    const [coaches] = await db.query(
      'SELECT id, name, image, createdAt, specialty, bio FROM Coaches WHERE id = ?',
      [req.params.id]
    );
    if (coaches.length === 0) {
      return res.status(404).json({ success: false, message: 'Coach introuvable.' });
    }

    const [clients] = await db.query(
      `SELECT id, name, image, birth, weight, height, frequency, goal, weightGoal, createdAt, gender
       FROM Clients WHERE coachID = ?`,
      [req.params.id]
    );

    res.json({
      success: true,
      coach: {
        ...coaches[0],
        clients: clients || [] // Retourne une liste vide si aucun client
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// POST /api/coaches
router.post('/', async (req, res) => {
  const { name, image = '', specialty, bio } = req.body;
  if (!name) return res.status(422).json({ success: false, message: 'Le nom est obligatoire.' });

  try {
    const [result] = await db.query(
      'INSERT INTO Coaches (name, image, createdAt, specialty, bio) VALUES (?, ?, NOW(), ?, ?)',
      [name, image, specialty, bio]
    );
    const [coaches] = await db.query('SELECT * FROM Coaches WHERE id = ?', [result.insertId]);
    res.status(201).json({ success: true, coach: coaches[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// PUT /api/coaches/:id
router.put('/:id', async (req, res) => {
  const { name, image, specialty, bio } = req.body;
  try {
    await db.query(
      `UPDATE Coaches
       SET name = COALESCE(?, name),
           image = COALESCE(?, image),
           specialty = COALESCE(?, specialty),
           bio = COALESCE(?, bio)
       WHERE id = ?`,
      [name, image, specialty, bio, req.params.id]
    );
    const [coaches] = await db.query(
      'SELECT id, name, image, createdAt, specialty, bio FROM Coaches WHERE id = ?',
      [req.params.id]
    );
    res.json({ success: true, coach: coaches[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

export default router; 