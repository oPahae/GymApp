import express from 'express';
import db from '../../config/db.js';
import { authMiddleware } from './auth.js';

const router = express.Router();

// Toutes les routes clients nécessitent un JWT valide
router.use(authMiddleware);

// ─────────────────────────────────────────────
// GET /api/jihane/clients
// Liste tous les clients (coach uniquement)
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
// GET /api/jihane/clients/:id
// Retourne un client avec son coach imbriqué
// ─────────────────────────────────────────────
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT
         c.id, c.name, c.email, c.image, c.birth, c.gender,
         c.weight, c.height, c.frequency, c.goal, c.weightGoal,
         c.createdAt, c.coachID,
         co.id        AS coach_id,
         co.name      AS coach_name,
         co.image     AS coach_image,
         co.createdAt AS coach_createdAt,
         co.specialty AS coach_specialty,
         co.bio       AS coach_bio
       FROM Clients c
       LEFT JOIN Coaches co ON co.id = c.coachID
       WHERE c.id = ?`,
      [req.params.id]
    );

    if (rows.length === 0)
      return res.status(404).json({ success: false, message: 'Client introuvable.' });

    res.json({ success: true, client: _formatClient(rows[0]) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// ─────────────────────────────────────────────
// PUT /api/jihane/clients/:id
// Mise à jour du profil — client lui-même OU son coach
// ─────────────────────────────────────────────
router.put('/:id', async (req, res) => {
  const targetId = parseInt(req.params.id);
  const { role, id: callerId } = req.user;

  // Autorisation : le client modifie son propre profil, ou le coach modifie l'un de ses clients
  if (role === 'client' && callerId !== targetId)
    return res.status(403).json({ success: false, message: 'Accès interdit.' });

  if (role === 'coach') {
    // Vérifier que ce client appartient bien à ce coach
    const [check] = await db.query(
      'SELECT id FROM Clients WHERE id = ? AND coachID = ?',
      [targetId, callerId]
    );
    if (check.length === 0)
      return res.status(403).json({ success: false, message: 'Ce client ne vous appartient pas.' });
  }

  const { name, image, birth, weight, height, frequency, goal, weightGoal, gender, coachID } = req.body;

  try {
    await db.query(
      `UPDATE Clients
       SET name       = COALESCE(?, name),
           image      = COALESCE(?, image),
           birth      = COALESCE(?, birth),
           weight     = COALESCE(?, weight),
           height     = COALESCE(?, height),
           frequency  = COALESCE(?, frequency),
           goal       = COALESCE(?, goal),
           weightGoal = COALESCE(?, weightGoal),
           gender     = COALESCE(?, gender),
           coachID    = COALESCE(?, coachID)
       WHERE id = ?`,
      [name ?? null, image ?? null, birth ?? null,
       weight ?? null, height ?? null, frequency ?? null,
       goal ?? null, weightGoal ?? null, gender ?? null,
       coachID ?? null, targetId]
    );

    // Retourner le client mis à jour avec son coach imbriqué
    const [rows] = await db.query(
      `SELECT
         c.id, c.name, c.email, c.image, c.birth, c.gender,
         c.weight, c.height, c.frequency, c.goal, c.weightGoal,
         c.createdAt, c.coachID,
         co.id        AS coach_id,
         co.name      AS coach_name,
         co.image     AS coach_image,
         co.createdAt AS coach_createdAt,
         co.specialty AS coach_specialty,
         co.bio       AS coach_bio
       FROM Clients c
       LEFT JOIN Coaches co ON co.id = c.coachID
       WHERE c.id = ?`,
      [targetId]
    );

    res.json({ success: true, message: 'Profil mis à jour.', client: _formatClient(rows[0]) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// ─────────────────────────────────────────────
// DELETE /api/jihane/clients/:id
// ─────────────────────────────────────────────
router.delete('/:id', async (req, res) => {
  if (parseInt(req.params.id) !== req.user.id)
    return res.status(403).json({ success: false, message: 'Accès interdit.' });

  try {
    await db.query('DELETE FROM Clients WHERE id = ?', [req.params.id]);
    res.json({ success: true, message: 'Compte supprimé.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// ─────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────
function _formatClient(row) {
  return {
    id: row.id,
    name: row.name,
    email: row.email,
    image: row.image ?? '',
    birth: row.birth,
    gender: row.gender,
    weight: row.weight,
    height: row.height,
    frequency: row.frequency,
    goal: row.goal,
    weightGoal: row.weightGoal,
    createdAt: row.createdAt,
    coachID: row.coachID ?? null,
    coach: row.coach_id ? {
      id: row.coach_id,
      name: row.coach_name,
      image: row.coach_image ?? '',
      createdAt: row.coach_createdAt,
      specialty: row.coach_specialty ?? '',
      bio: row.coach_bio ?? '',
    } : null,
  };
}

export default router;