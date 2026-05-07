import express from 'express';
import db from '../../config/db.js';
import { authMiddleware } from './auth.js';

const router = express.Router();

// Toutes les routes nécessitent un JWT valide
router.use(authMiddleware);

// ─────────────────────────────────────────────────────────────────
// RÈGLES MÉTIER :
//   - Un CLIENT ne peut communiquer qu'avec son propre coach
//   - Un COACH peut communiquer avec tous ses clients
// ─────────────────────────────────────────────────────────────────

/**
 * Vérifie que l'appelant a le droit d'accéder à la conversation
 * entre coachID et clientID.
 */
async function assertAccess(req, res, coachId, clientId) {
  const { id: callerId, role } = req.user;

  if (role === 'client') {
    if (callerId !== clientId) {
      res.status(403).json({ success: false, message: 'Accès interdit.' });
      return false;
    }
    const [rows] = await db.query(
      'SELECT id FROM Clients WHERE id = ? AND coachID = ?',
      [clientId, coachId]
    );
    if (rows.length === 0) {
      res.status(403).json({ success: false, message: 'Ce coach n\'est pas le vôtre.' });
      return false;
    }
  } else {
    if (callerId !== coachId) {
      res.status(403).json({ success: false, message: 'Accès interdit.' });
      return false;
    }
    const [rows] = await db.query(
      'SELECT id FROM Clients WHERE id = ? AND coachID = ?',
      [clientId, coachId]
    );
    if (rows.length === 0) {
      res.status(403).json({ success: false, message: 'Ce client ne vous appartient pas.' });
      return false;
    }
  }
  return true;
}

// ─────────────────────────────────────────────
// GET /api/jihane/chat/conversations
// ─────────────────────────────────────────────
router.get('/conversations', async (req, res) => {
  const { id: callerId, role } = req.user;

  try {
    if (role === 'client') {
      const [rows] = await db.query(
        `SELECT
           c.coachID,
           co.name      AS coachName,
           co.image     AS coachImage,
           co.specialty AS coachSpecialty,
           (
             SELECT m.text FROM Messages m
             WHERE m.coachID = c.coachID AND m.clientID = c.id
             ORDER BY m.time DESC LIMIT 1
           ) AS lastMessage,
           (
             SELECT m.time FROM Messages m
             WHERE m.coachID = c.coachID AND m.clientID = c.id
             ORDER BY m.time DESC LIMIT 1
           ) AS lastMessageTime,
           (
             SELECT COUNT(*) FROM Messages m
             WHERE m.coachID = c.coachID AND m.clientID = c.id
               AND m.isUser = 0 AND m.status != 'read'
           ) AS unreadCount
         FROM Clients c
         LEFT JOIN Coaches co ON co.id = c.coachID
         WHERE c.id = ?`,
        [callerId]
      );
      return res.json({ success: true, conversations: rows });
    }

    const [rows] = await db.query(
      `SELECT
         cl.id        AS clientID,
         cl.name      AS clientName,
         cl.image     AS clientImage,
         cl.gender    AS clientGender,
         (
           SELECT m.text FROM Messages m
           WHERE m.coachID = ? AND m.clientID = cl.id
           ORDER BY m.time DESC LIMIT 1
         ) AS lastMessage,
         (
           SELECT m.time FROM Messages m
           WHERE m.coachID = ? AND m.clientID = cl.id
           ORDER BY m.time DESC LIMIT 1
         ) AS lastMessageTime,
         (
           SELECT COUNT(*) FROM Messages m
           WHERE m.coachID = ? AND m.clientID = cl.id
             AND m.isUser = 1 AND m.status != 'read'
         ) AS unreadCount
       FROM Clients cl
       WHERE cl.coachID = ?
       ORDER BY lastMessageTime DESC`,
      [callerId, callerId, callerId, callerId]
    );
    return res.json({ success: true, conversations: rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// ─────────────────────────────────────────────
// GET /api/jihane/chat/messages/:coachId/:clientId
// ─────────────────────────────────────────────
router.get('/messages/:coachId/:clientId', async (req, res) => {
  const coachId  = parseInt(req.params.coachId);
  const clientId = parseInt(req.params.clientId);
  const limit    = Math.min(parseInt(req.query.limit) || 50, 100);
  const before   = req.query.before ? parseInt(req.query.before) : null;

  const ok = await assertAccess(req, res, coachId, clientId);
  if (!ok) return;

  try {
    let query;
    let params;

    if (before) {
      query = `SELECT id, text, time, isUser, status
               FROM Messages
               WHERE coachID = ? AND clientID = ? AND id < ?
               ORDER BY time DESC
               LIMIT ?`;
      params = [coachId, clientId, before, limit];
    } else {
      query = `SELECT id, text, time, isUser, status
               FROM Messages
               WHERE coachID = ? AND clientID = ?
               ORDER BY time DESC
               LIMIT ?`;
      params = [coachId, clientId, limit];
    }

    const [messages] = await db.query(query, params);

    // Marquer comme lus les messages reçus par l'appelant
    const isUser = req.user.role === 'client' ? 0 : 1;
    await db.query(
      `UPDATE Messages
       SET status = 'read'
       WHERE coachID = ? AND clientID = ? AND isUser = ? AND status != 'read'`,
      [coachId, clientId, isUser]
    );

    res.json({
      success: true,
      messages: messages.reverse(),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// ─────────────────────────────────────────────
// POST /api/jihane/chat/messages
// Envoyer un message texte
// ─────────────────────────────────────────────
router.post('/messages', async (req, res) => {
  const { coachId, clientId, text } = req.body;

  if (!coachId || !clientId) {
    return res.status(400).json({ success: false, message: 'coachId et clientId requis.' });
  }

  if (!text || !text.trim()) {
    return res.status(400).json({ success: false, message: 'Le texte du message est requis.' });
  }

  const coachIdInt  = parseInt(coachId);
  const clientIdInt = parseInt(clientId);

  const ok = await assertAccess(req, res, coachIdInt, clientIdInt);
  if (!ok) return;

  const isUser = req.user.role === 'client' ? 1 : 0;

  try {
    const [result] = await db.query(
      `INSERT INTO Messages (text, time, isUser, type, status, coachID, clientID)
       VALUES (?, NOW(), ?, 'text', 'sent', ?, ?)`,
      [text.trim(), isUser, coachIdInt, clientIdInt]
    );

    const [rows] = await db.query(
      'SELECT id, text, time, isUser, status FROM Messages WHERE id = ?',
      [result.insertId]
    );

    res.status(201).json({ success: true, message: rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// ─────────────────────────────────────────────
// PATCH /api/jihane/chat/messages/:id/status
// ─────────────────────────────────────────────
router.patch('/messages/:id/status', async (req, res) => {
  const { status } = req.body;
  const validStatuses = ['sending', 'sent', 'delivered', 'read'];

  if (!status || !validStatuses.includes(status)) {
    return res.status(400).json({ success: false, message: 'Statut invalide.' });
  }

  try {
    const [rows] = await db.query(
      'SELECT id, coachID, clientID, isUser FROM Messages WHERE id = ?',
      [req.params.id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Message introuvable.' });
    }

    const msg = rows[0];
    const ok  = await assertAccess(req, res, msg.coachID, msg.clientID);
    if (!ok) return;

    await db.query('UPDATE Messages SET status = ? WHERE id = ?', [status, req.params.id]);
    res.json({ success: true, message: 'Statut mis à jour.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// ─────────────────────────────────────────────
// DELETE /api/jihane/chat/messages/:id
// ─────────────────────────────────────────────
router.delete('/messages/:id', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT id, coachID, clientID, isUser FROM Messages WHERE id = ?',
      [req.params.id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Message introuvable.' });
    }

    const msg      = rows[0];
    const { id: callerId, role } = req.user;

    const senderIsUser = msg.isUser === 1;
    if (role === 'client' && (!senderIsUser || callerId !== msg.clientID)) {
      return res.status(403).json({ success: false, message: 'Vous ne pouvez supprimer que vos propres messages.' });
    }
    if (role === 'coach' && (senderIsUser || callerId !== msg.coachID)) {
      return res.status(403).json({ success: false, message: 'Vous ne pouvez supprimer que vos propres messages.' });
    }

    await db.query('DELETE FROM Messages WHERE id = ?', [req.params.id]);
    res.json({ success: true, message: 'Message supprimé.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// ═══════════════════════════════════════════════════════
//  APPELS (CALLS)
// ═══════════════════════════════════════════════════════

// ─────────────────────────────────────────────
// POST /api/jihane/chat/calls
// ─────────────────────────────────────────────
router.post('/calls', async (req, res) => {
  const { coachId, clientId, callType } = req.body;

  if (!coachId || !clientId) {
    return res.status(400).json({ success: false, message: 'coachId et clientId requis.' });
  }
  if (!['voice', 'video'].includes(callType)) {
    return res.status(400).json({ success: false, message: 'callType doit être "voice" ou "video".' });
  }

  const coachIdInt  = parseInt(coachId);
  const clientIdInt = parseInt(clientId);

  const ok = await assertAccess(req, res, coachIdInt, clientIdInt);
  if (!ok) return;

  try {
    const [result] = await db.query(
      `INSERT INTO Calls (coachID, clientID, callType, status, startedAt)
       VALUES (?, ?, ?, 'initiated', NOW())`,
      [coachIdInt, clientIdInt, callType]
    );

    const [rows] = await db.query(
      'SELECT id, coachID, clientID, callType, status, startedAt FROM Calls WHERE id = ?',
      [result.insertId]
    );

    res.status(201).json({ success: true, call: rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// ─────────────────────────────────────────────
// PATCH /api/jihane/chat/calls/:id
// ─────────────────────────────────────────────
router.patch('/calls/:id', async (req, res) => {
  const { status } = req.body;
  const validStatuses = ['initiated', 'accepted', 'rejected', 'ended', 'missed'];

  if (!status || !validStatuses.includes(status)) {
    return res.status(400).json({ success: false, message: 'Statut invalide.' });
  }

  try {
    const [rows] = await db.query(
      'SELECT id, coachID, clientID, callType, status, startedAt FROM Calls WHERE id = ?',
      [req.params.id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Appel introuvable.' });
    }

    const call = rows[0];
    const ok   = await assertAccess(req, res, call.coachID, call.clientID);
    if (!ok) return;

    const updates = { status };

    if (status === 'ended' || status === 'rejected' || status === 'missed') {
      updates.endedAt = new Date();
      if (call.status === 'accepted' && call.startedAt) {
        const durationSeconds = Math.floor((Date.now() - new Date(call.startedAt).getTime()) / 1000);
        updates.duration = durationSeconds;
      }
    }

    await db.query(
      `UPDATE Calls
       SET status   = ?,
           endedAt  = COALESCE(?, endedAt),
           duration = COALESCE(?, duration)
       WHERE id = ?`,
      [updates.status, updates.endedAt || null, updates.duration || null, req.params.id]
    );

    const [updated] = await db.query(
      'SELECT id, coachID, clientID, callType, status, startedAt, endedAt, duration FROM Calls WHERE id = ?',
      [req.params.id]
    );

    res.json({ success: true, call: updated[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// ─────────────────────────────────────────────
// GET /api/jihane/chat/calls/:coachId/:clientId
// ─────────────────────────────────────────────
router.get('/calls/:coachId/:clientId', async (req, res) => {
  const coachIdInt  = parseInt(req.params.coachId);
  const clientIdInt = parseInt(req.params.clientId);

  const ok = await assertAccess(req, res, coachIdInt, clientIdInt);
  if (!ok) return;

  try {
    const [calls] = await db.query(
      `SELECT id, callType, status, startedAt, endedAt, duration
       FROM Calls
       WHERE coachID = ? AND clientID = ?
       ORDER BY startedAt DESC
       LIMIT 50`,
      [coachIdInt, clientIdInt]
    );
    res.json({ success: true, calls });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// ─────────────────────────────────────────────
// GET /api/jihane/chat/calls/active/:coachId/:clientId
// ─────────────────────────────────────────────
router.get('/calls/active/:coachId/:clientId', async (req, res) => {
  const coachIdInt  = parseInt(req.params.coachId);
  const clientIdInt = parseInt(req.params.clientId);

  const ok = await assertAccess(req, res, coachIdInt, clientIdInt);
  if (!ok) return;

  try {
    const [rows] = await db.query(
      `SELECT id, callType, status, startedAt
       FROM Calls
       WHERE coachID = ? AND clientID = ?
         AND status IN ('initiated', 'accepted')
       ORDER BY startedAt DESC
       LIMIT 1`,
      [coachIdInt, clientIdInt]
    );
    res.json({ success: true, activeCall: rows[0] || null });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

export default router;