import express from 'express';
import db from '../../config/db.js'; 
import authMiddleware from './auth.js';

const router = express.Router();

// Toutes les routes clients nécessitent un JWT valide
router.use(authMiddleware);

// ─────────────────────────────────────────────
// GET /api/clients  – liste tous les clients
// ─────────────────────────────────────────────
router.get('/', async (req, res) => {
  try {
    const [clients] = await db.query(
      `SELECT c.id, c.name, c.email, c.image, c.birth, c.weight, c.height,
              c.frequency, c.goal, c.weightGoal, c.createdAt, c.gender, c.coachID,
              co.name AS coachName, co.image AS coachImage, co.specialty
       FROM Clients c
       LEFT JOIN Coaches co ON c.coachID = co.id
       ORDER BY c.createdAt DESC`
    );
    res.json({ success: true, clients });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// ─────────────────────────────────────────────
// GET /api/clients/:id
// ─────────────────────────────────────────────
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT
        c.id, c.name, c.email, c.image, c.birth, c.weight, c.height,
        c.frequency, c.goal, c.weightGoal, c.createdAt, c.gender, c.coachID,
        co.id AS coach_id, co.name AS coach_name, co.image AS coach_image,
        co.specialty, co.bio
       FROM Clients c
       LEFT JOIN Coaches co ON c.coachID = co.id
       WHERE c.id = ?`,
      [req.params.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Client introuvable.' });
    }

    const row = rows[0];
    const client = {
      id: row.id,
      name: row.name,
      email: row.email,
      image: row.image,
      birth: row.birth,
      weight: row.weight,
      height: row.height,
      frequency: row.frequency,
      goal: row.goal,
      weightGoal: row.weightGoal,
      createdAt: row.createdAt,
      gender: row.gender,
      coachID: row.coachID,
      coach: row.coach_id ? { // Vérifie si coach_id existe
        id: row.coach_id,
        name: row.coach_name,
        image: row.coach_image,
        specialty: row.specialty,
        bio: row.bio
      } : null,
    };

    res.json({ success: true, client });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// ─────────────────────────────────────────────
// PUT /api/clients/:id  – mise à jour profil
// ─────────────────────────────────────────────
router.put('/:id', async (req, res) => {
  if (parseInt(req.params.id) !== req.user.id) {
    return res.status(403).json({ success: false, message: 'Accès interdit.' });
  }

  const { name, image, birth, weight, height, frequency, goal, weightGoal, gender, coachID } = req.body;

  try {
    await db.query(
      `UPDATE Clients
       SET name = COALESCE(?, name),
           image = COALESCE(?, image),
           birth = COALESCE(?, birth),
           weight = COALESCE(?, weight),
           height = COALESCE(?, height),
           frequency = COALESCE(?, frequency),
           goal = COALESCE(?, goal),
           weightGoal = COALESCE(?, weightGoal),
           gender = COALESCE(?, gender),
           coachID = COALESCE(?, coachID)
       WHERE id = ?`,
      [name, image, birth, weight, height, frequency, goal, weightGoal, gender, coachID, req.params.id]
    );

    const [updated] = await db.query(
      `SELECT id, name, email, image, birth, weight, height, frequency, goal, weightGoal, createdAt, gender, coachID
       FROM Clients WHERE id = ?`,
      [req.params.id]
    );

    res.json({ success: true, message: 'Profil mis à jour.', client: updated[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// ─────────────────────────────────────────────
// DELETE /api/clients/:id
// ─────────────────────────────────────────────
router.delete('/:id', async (req, res) => {
  if (parseInt(req.params.id) !== req.user.id) {
    return res.status(403).json({ success: false, message: 'Accès interdit.' });
  }

  try {
    await db.query('DELETE FROM Clients WHERE id = ?', [req.params.id]);
    res.json({ success: true, message: 'Compte supprimé.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

export default router; 