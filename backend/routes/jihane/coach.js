import express from 'express';
import db from '../../config/db.js';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';
import crypto from 'crypto';
import { sendPasswordResetEmail } from './emailService.js';
import { authMiddleware } from './auth.js';

const router = express.Router();
const JWT_SECRET = 'secret';

// ─────────────────────────────────────────────
// POST /api/jihane/coaches/login
// ─────────────────────────────────────────────
router.post('/login', async (req, res) => {
  const { identifier, password } = req.body;
  if (!identifier || !password)
    return res.status(400).json({ success: false, message: 'Email/Username and password are required.' });

  try {
    const [coaches] = await db.query(
      'SELECT id, name, email, password, image, specialty, bio FROM Coaches WHERE email = ? OR name = ?',
      [identifier, identifier]
    );
    if (coaches.length === 0)
      return res.status(401).json({ success: false, message: 'Invalid credentials.' });

    const coach = coaches[0];
    if (!await bcrypt.compare(password, coach.password))
      return res.status(401).json({ success: false, message: 'Invalid credentials.' });

    const token = jwt.sign(
      { id: coach.id, name: coach.name, email: coach.email, role: 'coach' },
      JWT_SECRET, { expiresIn: '1d' }
    );

    res.json({
      success: true, token, role: 'coach',
      coach: { id: coach.id, name: coach.name, email: coach.email, image: coach.image, specialty: coach.specialty, bio: coach.bio },
      message: 'Login successful.'
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// ─────────────────────────────────────────────
// POST /api/jihane/coaches/register
// ─────────────────────────────────────────────
router.post('/register', async (req, res) => {
  const { name, email, password, image, specialty, bio } = req.body;
  if (!name || !email || !password)
    return res.status(400).json({ success: false, message: 'Name, email and password are required.' });

  try {
    const [existing] = await db.query('SELECT id FROM Coaches WHERE email = ?', [email]);
    if (existing.length > 0)
      return res.status(400).json({ success: false, message: 'Email already exists.' });

    const hashedPassword = await bcrypt.hash(password, 10);
    const [result] = await db.query(
      `INSERT INTO Coaches (name, email, password, image, specialty, bio, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, NOW())`,
      [name, email, hashedPassword, image || null, specialty || null, bio || null]
    );

    const token = jwt.sign(
      { id: result.insertId, name, email, role: 'coach' },
      JWT_SECRET, { expiresIn: '1d' }
    );

    const [newCoach] = await db.query(
      'SELECT id, name, email, image, specialty, bio FROM Coaches WHERE id = ?',
      [result.insertId]
    );

    res.status(201).json({ success: true, token, role: 'coach', coach: newCoach[0], message: 'Coach registered successfully.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// ─────────────────────────────────────────────
// GET /api/jihane/coaches/me/profile
// Profil du coach connecté + ses clients
// IMPORTANT : cette route doit être déclarée AVANT /:id
// ─────────────────────────────────────────────
router.get('/me/profile', authMiddleware, async (req, res) => {
  if (req.user.role !== 'coach')
    return res.status(403).json({ success: false, message: 'Accès réservé aux coaches.' });

  const coachId = req.user.id;

  try {
    const [rows] = await db.query(
      'SELECT id, name, email, image, specialty, bio, createdAt FROM Coaches WHERE id = ?',
      [coachId]
    );
    if (rows.length === 0)
      return res.status(404).json({ success: false, message: 'Coach introuvable.' });

    const coach = rows[0];

    const [clients] = await db.query(
      `SELECT id, name, image, birth, gender, weight, height,
              frequency, goal, weightGoal, createdAt, coachID
       FROM Clients WHERE coachID = ?`,
      [coachId]
    );

    res.json({
      success: true,
      coach: { ...coach, clients }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// ─────────────────────────────────────────────
// GET /api/jihane/coaches
// Liste tous les coaches
// ─────────────────────────────────────────────
router.get('/', async (req, res) => {
  try {
    const [coaches] = await db.query(
      'SELECT id, name, email, image, specialty, bio, createdAt FROM Coaches ORDER BY createdAt DESC'
    );
    res.json({ success: true, coaches });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// ─────────────────────────────────────────────
// GET /api/jihane/coaches/:id
// Profil d'un coach par ID + ses clients
// ─────────────────────────────────────────────
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT id, name, email, image, specialty, bio, createdAt FROM Coaches WHERE id = ?',
      [req.params.id]
    );
    if (rows.length === 0)
      return res.status(404).json({ success: false, message: 'Coach introuvable.' });

    const coach = rows[0];

    const [clients] = await db.query(
      `SELECT id, name, image, birth, gender, weight, height,
              frequency, goal, weightGoal, createdAt, coachID
       FROM Clients WHERE coachID = ?`,
      [coach.id]
    );

    res.json({ success: true, coach: { ...coach, clients } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// ─────────────────────────────────────────────
// PUT /api/jihane/coaches/:id
// Mise à jour du profil coach (lui-même uniquement)
// ─────────────────────────────────────────────
router.put('/:id', authMiddleware, async (req, res) => {
  const targetId = parseInt(req.params.id);

  if (req.user.role !== 'coach' || req.user.id !== targetId)
    return res.status(403).json({ success: false, message: 'Accès interdit.' });

  const { name, specialty, bio, image } = req.body;

  try {
    await db.query(
      `UPDATE Coaches
       SET name      = COALESCE(?, name),
           specialty = COALESCE(?, specialty),
           bio       = COALESCE(?, bio),
           image     = COALESCE(?, image)
       WHERE id = ?`,
      [name ?? null, specialty ?? null, bio ?? null, image ?? null, targetId]
    );

    const [rows] = await db.query(
      'SELECT id, name, email, image, specialty, bio, createdAt FROM Coaches WHERE id = ?',
      [targetId]
    );

    // Récupérer les clients aussi pour garder la cohérence avec profileCoach
    const [clients] = await db.query(
      `SELECT id, name, image, birth, gender, weight, height,
              frequency, goal, weightGoal, createdAt, coachID
       FROM Clients WHERE coachID = ?`,
      [targetId]
    );

    res.json({ success: true, coach: { ...rows[0], clients }, message: 'Profil mis à jour.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// ─────────────────────────────────────────────
// POST /api/jihane/coaches/forgot-password
// ─────────────────────────────────────────────
router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  if (!email)
    return res.status(400).json({ success: false, message: 'Email requis.' });

  try {
    const [coaches] = await db.query(
      'SELECT id, name, email FROM Coaches WHERE email = ?', [email]
    );
    if (coaches.length === 0)
      return res.json({ success: true, message: 'Si cet email existe, un lien a été envoyé.' });

    const coach = coaches[0];
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenExpiry = new Date(Date.now() + 3600000);

    await db.query(
      'UPDATE Coaches SET resetToken = ?, resetTokenExpiry = ? WHERE id = ?',
      [resetToken, resetTokenExpiry, coach.id]
    );
    await sendPasswordResetEmail(coach.email, resetToken, coach.name, 'coach');

    res.json({ success: true, message: 'Email de réinitialisation envoyé.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// ─────────────────────────────────────────────
// GET /api/jihane/coaches/reset-password?token=xxx
// ─────────────────────────────────────────────
router.get('/reset-password', async (req, res) => {
  const { token } = req.query;
  if (!token) return res.send(htmlError('Token manquant', 'Lien invalide.'));

  try {
    const [coaches] = await db.query(
      'SELECT id FROM Coaches WHERE resetToken = ? AND resetTokenExpiry > NOW()', [token]
    );
    if (coaches.length === 0)
      return res.send(htmlError('Lien expiré ou invalide', 'Demandez un nouveau lien.'));

    res.send(htmlResetForm(token, '/api/jihane/coaches/reset-password'));
  } catch (err) {
    console.error(err);
    res.status(500).send('Erreur serveur.');
  }
});

// ─────────────────────────────────────────────
// POST /api/jihane/coaches/reset-password
// ─────────────────────────────────────────────
router.post('/reset-password', async (req, res) => {
  const { token, newPassword } = req.body;
  if (!token || !newPassword)
    return res.status(400).json({ success: false, message: 'Token et mot de passe requis.' });
  if (newPassword.length < 6)
    return res.status(400).json({ success: false, message: 'Au moins 6 caractères.' });

  try {
    const [coaches] = await db.query(
      'SELECT id FROM Coaches WHERE resetToken = ? AND resetTokenExpiry > NOW()', [token]
    );
    if (coaches.length === 0)
      return res.status(400).json({ success: false, message: 'Token invalide ou expiré.' });

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await db.query(
      'UPDATE Coaches SET password = ?, resetToken = NULL, resetTokenExpiry = NULL WHERE id = ?',
      [hashedPassword, coaches[0].id]
    );
    res.json({ success: true, message: 'Mot de passe réinitialisé avec succès.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// --- HTML Helpers (Placeholders) ---
function htmlError(title, message) {
  return `<html><body><h1>${title}</h1><p>${message}</p></body></html>`;
}

function htmlResetForm(token, action) {
  return `
    <html>
      <body>
        <h1>Réinitialiser le mot de passe</h1>
        <form method="POST" action="${action}">
          <input type="hidden" name="token" value="${token}" />
          <label>Nouveau mot de passe: <input type="password" name="newPassword" required /></label>
          <button type="submit">Réinitialiser</button>
        </form>
      </body>
    </html>
  `;
}

export default router;