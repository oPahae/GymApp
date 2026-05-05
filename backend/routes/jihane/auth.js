import express from 'express';
import db from '../../config/db.js';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';

const router = express.Router();

// Clé secrète JWT (remplace process.env.JWT_SECRET)
const JWT_SECRET = 'secret'; // À remplacer par une clé sécurisée en production

// Route pour le login
router.post('/login', async (req, res) => {
  const { identifier, password } = req.body;

  if (!identifier || !password) {
    return res.status(400).json({ success: false, message: 'Email/Username and password are required.' });
  }

  try {
    // Vérifie si l'utilisateur existe (par email ou nom)
    const [users] = await db.query(
      'SELECT id, name, email, password FROM Clients WHERE email = ? OR name = ?',
      [identifier, identifier]
    );

    if (users.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid credentials.' });
    }

    const user = users[0];
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      return res.status(401).json({ success: false, message: 'Invalid credentials.' });
    }

    // Génère un token JWT
    const token = jwt.sign(
      { id: user.id, name: user.name, email: user.email },
      JWT_SECRET,
      { expiresIn: '1d' }
    );

    res.json({
      success: true,
      token,
      client: { id: user.id, name: user.name, email: user.email },
      message: 'Login successful.'
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// Route pour le register (déjà existante, mais adaptée)
router.post('/register', async (req, res) => {
  const {
    name,
    email,
    password,
    image,
    birth,
    weight,
    height,
    frequency,
    goal,
    weightGoal,
    gender,
    coachID, // Peut être null ou undefined
  } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({ success: false, message: 'Name, email, and password are required.' });
  }

  try {
    // Vérifie si l'email existe déjà
    const [existingUsers] = await db.query('SELECT id FROM Clients WHERE email = ?', [email]);
    if (existingUsers.length > 0) {
      return res.status(400).json({ success: false, message: 'Email already exists.' });
    }

    // Hash le mot de passe
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insère le nouveau client (coachID peut être null)
    const [result] = await db.query(
      `INSERT INTO Clients
       (name, email, password, image, birth, weight, height, frequency, goal, weightGoal, gender, coachID, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
      [
        name,
        email,
        hashedPassword,
        image || null, // Si image est undefined, on envoie null
        birth || null,
        weight || null,
        height || null,
        frequency || null,
        goal || null,
        weightGoal || null,
        gender || 'Male', // Valeur par défaut
        coachID || null, // coachID peut être null
      ],
    );

    // Génère un token JWT
    const token = jwt.sign(
      { id: result.insertId, name, email },
      JWT_SECRET,
      { expiresIn: '1d' },
    );

    // Récupère le client créé
    const [newClient] = await db.query('SELECT id, name, email, image FROM Clients WHERE id = ?', [result.insertId]);

    res.status(201).json({
      success: true,
      token,
      client: newClient[0],
      message: 'Registration successful.',
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error.' });
  }
});

export default router;