import express from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';
import db from '../../config/db.js';
import { sendPasswordResetEmail, htmlError, htmlResetForm } from './emailService.js';

// --- Constants ---
const JWT_SECRET = 'secret';
const BASE_URL = process.env.BASE_URL || 'http://localhost:5000';
const router = express.Router();

// --- Middleware ---
const authMiddleware = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  console.log("authHeader");
  console.log(authHeader);
  if (!authHeader)
    return res.status(401).json({ success: false, message: 'Token manquant.' });

  const token = authHeader.startsWith('Bearer ')
    ? authHeader.slice(7)
    : authHeader;

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded; // { id, name, email, role }
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Token invalide ou expiré.' });
  }
};

// --- Routes ---

// POST /api/jihane/auth/login
router.post('/login', async (req, res) => {
  const { identifier, password } = req.body;
  if (!identifier || !password)
    return res.status(400).json({ success: false, message: 'Email/Username and password are required.' });

  try {
    const [users] = await db.query(
      'SELECT id, name, email, password FROM Clients WHERE email = ? OR name = ?',
      [identifier, identifier]
    );
    const [coaches] = await db.query(
      'SELECT id, name, email, password, image, specialty, bio FROM Coaches WHERE email = ? OR name = ?',
      [identifier, identifier]
    );

    let user = null;
    let role = null;

    if (users.length > 0) {
      user = users[0];
      role = 'client';
    } else if (coaches.length > 0) {
      user = coaches[0];
      role = 'coach';
    } else {
      return res.status(401).json({ success: false, message: 'Invalid credentials.' });
    }

    if (!await bcrypt.compare(password, user.password))
      return res.status(401).json({ success: false, message: 'Invalid credentials.' });

    const token = jwt.sign(
      { id: user.id, name: user.name, email: user.email, role },
      JWT_SECRET, { expiresIn: '1d' }
    );

    if (role === 'client') {
      return res.json({
        success: true, token, role: 'client',
        client: { id: user.id, name: user.name, email: user.email },
        message: 'Login successful.'
      });
    } else {
      return res.json({
        success: true, token, role: 'coach',
        coach: { id: user.id, name: user.name, email: user.email, image: user.image, specialty: user.specialty, bio: user.bio },
        message: 'Login successful.'
      });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// POST /api/jihane/auth/register
router.post('/register', async (req, res) => {
  const { name, email, password, image, birth, weight, height, frequency, goal, weightGoal, gender, coachID } = req.body;
  if (!name || !email || !password)
    return res.status(400).json({ success: false, message: 'Name, email, and password are required.' });

  try {
    const [existing] = await db.query('SELECT id FROM Clients WHERE email = ?', [email]);
    if (existing.length > 0)
      return res.status(400).json({ success: false, message: 'Email already exists.' });

    const hashedPassword = await bcrypt.hash(password, 10);
    const [result] = await db.query(
      `INSERT INTO Clients (name, email, password, image, birth, weight, height, frequency, goal, weightGoal, gender, coachID, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
      [name, email, hashedPassword, image || null, birth || null, weight || null,
        height || null, frequency || null, goal || null, weightGoal || null,
        gender || 'Male', coachID || null]
    );

    const token = jwt.sign(
      { id: result.insertId, name, email, role: 'client' },
      JWT_SECRET, { expiresIn: '1d' }
    );

    const [newClient] = await db.query(
      'SELECT id, name, email, image FROM Clients WHERE id = ?', [result.insertId]
    );

    res.status(201).json({ success: true, token, role: 'client', client: newClient[0], message: 'Registration successful.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// GET /api/jihane/auth/me
router.get('/me', authMiddleware, async (req, res) => {
  const { id, role } = req.user;

  try {
    if (role === 'coach') {
      const [rows] = await db.query(
        `SELECT id, name, email, image, specialty, bio, createdAt FROM Coaches WHERE id = ?`, [id]
      );
      if (rows.length === 0)
        return res.status(404).json({ success: false, message: 'Coach introuvable.' });

      const [clients] = await db.query(
        `SELECT id, name, image, birth, gender, weight, height,
                frequency, goal, weightGoal, createdAt, coachID
         FROM Clients WHERE coachID = ?`, [id]
      );

      return res.json({ success: true, role: 'coach', coach: { ...rows[0], clients } });
    }

    // role === 'client'
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
       WHERE c.id = ?`, [id]
    );
    if (rows.length === 0)
      return res.status(404).json({ success: false, message: 'Client introuvable.' });

    return res.json({ success: true, role: 'client', user: _formatClient(rows[0]) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// POST /api/jihane/auth/forgot-password
// Reçoit l'email, envoie un lien contenant l'email (pas de token stocké)
router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  if (!email)
    return res.status(400).json({ success: false, message: 'Email requis.' });

  try {
    const [users] = await db.query(
      'SELECT id, name, email FROM Clients WHERE email = ?', [email]
    );

    // Réponse identique que l'email existe ou non (sécurité)
    if (users.length === 0)
      return res.json({ success: true, message: 'Si cet email existe, un lien a été envoyé.' });

    const user = users[0];
    await sendPasswordResetEmail(user.email, user.name, 'client');

    res.json({ success: true, message: 'Email de réinitialisation envoyé.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// GET /api/jihane/auth/reset-password?email=xxx
// Affiche le formulaire de reset
router.get('/reset-password', async (req, res) => {
  const { email } = req.query;
  if (!email)
    return res.send(htmlError('Email manquant', 'Lien invalide.'));

  try {
    const [users] = await db.query(
      'SELECT id FROM Clients WHERE email = ?', [email]
    );
    if (users.length === 0)
      return res.send(htmlError('Email introuvable', 'Aucun compte associé à cet email.'));

    res.send(htmlResetForm(email, `${BASE_URL}/api/jihane/auth/reset-password`));
  } catch (err) {
    console.error(err);
    res.status(500).send('Erreur serveur.');
  }
});

// POST /api/jihane/auth/reset-password
// Reçoit { email, newPassword } et met à jour le mot de passe
router.post('/reset-password', async (req, res) => {
  const { email, newPassword } = req.body;
  if (!email || !newPassword)
    return res.status(400).json({ success: false, message: 'Email et mot de passe requis.' });
  if (newPassword.length < 6)
    return res.status(400).json({ success: false, message: 'Au moins 6 caractères.' });

  try {
    const [users] = await db.query(
      'SELECT id FROM Clients WHERE email = ?', [email]
    );
    if (users.length === 0)
      return res.status(400).json({ success: false, message: 'Email introuvable.' });

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await db.query(
      'UPDATE Clients SET password = ? WHERE email = ?',
      [hashedPassword, email]
    );

    res.json({ success: true, message: 'Mot de passe réinitialisé avec succès.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// POST /api/jihane/auth/create-coach
router.post('/create-coach', async (req, res) => {
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

    res.status(201).json({
      success: true,
      coach: { id: result.insertId, name, email },
      message: 'Coach created successfully.'
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// --- Helpers ---
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

export { router as default, authMiddleware };