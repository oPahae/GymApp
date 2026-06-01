import express from 'express';
import db from '../../config/db.js';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';
import { sendPasswordResetEmail, htmlError, htmlResetForm } from './emailService.js';
import { authMiddleware } from './auth.js';

const router = express.Router();
const JWT_SECRET = 'secret';
const BASE_URL = process.env.SERVER;

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

    const [clients] = await db.query(
      `SELECT id, name, image, birth, gender, weight, height,
              frequency, goal, weightGoal, createdAt, coachID
       FROM Clients WHERE coachID = ?`,
      [coachId]
    );

    res.json({ success: true, coach: { ...rows[0], clients } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

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

    await sendPasswordResetEmail(coach.email, coach.name, 'coach');

    res.json({ success: true, message: 'Email de réinitialisation envoyé.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

router.get('/reset-password', async (req, res) => {
  const { email } = req.query;
  console.log('Email to work on : ' + email);
  if (!email)
    return res.send(htmlError('Email manquant', 'Lien invalide.'));

  try {
    const [coaches] = await db.query(
      'SELECT id FROM Coaches WHERE email = ?', [email]
    );
    if (coaches.length === 0)
      return res.send(htmlError('Email introuvable', 'Aucun compte associé à cet email.'));

    console.log('reseting ...');
    res.send(htmlResetForm(email, `${BASE_URL}/api/jihane/coaches/update-password`));
  } catch (err) {
    console.error(err);
    res.status(500).send('Erreur serveur.');
  }
});

router.post('/update-password', async (req, res) => {
  const { email, newPassword } = req.body;
  console.log('Updating...');
  if (!email || !newPassword)
    return res.status(400).json({ success: false, message: 'Email et mot de passe requis.' });
  if (newPassword.length < 6)
    return res.status(400).json({ success: false, message: 'Au moins 6 caractères.' });

  try {
    const [coaches] = await db.query(
      'SELECT id FROM Coaches WHERE email = ?', [email]
    );
    if (coaches.length === 0)
      return res.status(400).json({ success: false, message: 'Email introuvable.' });

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await db.query(
      'UPDATE Coaches SET password = ? WHERE email = ?',
      [hashedPassword, email]
    );

    res.json({ success: true, message: 'Mot de passe réinitialisé avec succès.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

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

router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT id, name, email, image, specialty, bio, createdAt FROM Coaches WHERE id = ?',
      [req.params.id]
    );
    if (rows.length === 0)
      return res.status(404).json({ success: false, message: 'Coach introuvable.' });

    const [clients] = await db.query(
      `SELECT id, name, image, birth, gender, weight, height,
              frequency, goal, weightGoal, createdAt, coachID
       FROM Clients WHERE coachID = ?`,
      [rows[0].id]
    );

    res.json({ success: true, coach: { ...rows[0], clients } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

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

export default router;