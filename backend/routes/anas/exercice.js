import express from "express";
import pool from "../../config/db.js";

const router = express.Router();

// ─── Mappers ─────────────────────────────────────────────────────────────────

const mapNote = (row) => ({
  id: String(row.id),
  text: row.text ?? "",
  imageUrl: row.image ?? "",        // Notes table has no image col in BDD,
});                                 // kept for forward-compat / Flutter model

const mapExercise = (row, notes = []) => ({
  id: String(row.id),
  name: row.name ?? "",
  imageUrl: row.image ?? "",
  muscle: row.muscle ?? "",         // used as typeLabel in Flutter
  video: row.video ?? "",
  description: row.description ?? "",
  bodyPartID: String(row.bodyPartID),
  notes,
});

const mapBodyPart = (row, exercises = []) => ({
  id: String(row.id),
  name: row.name ?? "",
  imageUrl: row.image ?? "",
  exercises,
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/exercises/bodyparts
// Returns every body part (no exercises embedded – for a list/picker screen).
// ─────────────────────────────────────────────────────────────────────────────
router.get("/bodyparts", async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT id, name, image FROM BodyParts ORDER BY name ASC"
    );
    res.json({ success: true, data: rows.map((r) => mapBodyPart(r)) });
  } catch (err) {
    console.error("GET /bodyparts:", err.message);
    res.status(500).json({ success: false, message: "Failed to fetch body parts" });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/exercises/bodyparts/:bodyPartID
// Returns one body part WITH its full exercise list (each exercise includes notes).
// Used by ExercicesScreen.
// ─────────────────────────────────────────────────────────────────────────────
router.get("/bodyparts/:bodyPartID", async (req, res) => {
  const { bodyPartID } = req.params;

  if (!bodyPartID || isNaN(bodyPartID)) {
    return res.status(400).json({ success: false, message: "Invalid bodyPartID" });
  }

  try {
    // 1. Fetch the body part
    const [bpRows] = await pool.query(
      "SELECT id, name, image FROM BodyParts WHERE id = ?",
      [bodyPartID]
    );
    if (bpRows.length === 0) {
      return res.status(404).json({ success: false, message: "Body part not found" });
    }

    // 2. Fetch all exercises for this body part
    const [exRows] = await pool.query(
      `SELECT id, name, image, muscle, video, description, bodyPartID
       FROM Exercises
       WHERE bodyPartID = ?
       ORDER BY name ASC`,
      [bodyPartID]
    );

    if (exRows.length === 0) {
      return res.json({
        success: true,
        data: mapBodyPart(bpRows[0], []),
      });
    }

    // 3. Fetch all notes for those exercises in one query
    const exerciseIDs = exRows.map((e) => e.id);
    const placeholders = exerciseIDs.map(() => "?").join(",");

    const [noteRows] = await pool.query(
      `SELECT id, text, exerciseID FROM Notes WHERE exerciseID IN (${placeholders}) ORDER BY id ASC`,
      exerciseIDs
    );

    // 4. Group notes by exerciseID
    const notesByExercise = {};
    for (const note of noteRows) {
      if (!notesByExercise[note.exerciseID]) notesByExercise[note.exerciseID] = [];
      notesByExercise[note.exerciseID].push(mapNote(note));
    }

    // 5. Assemble
    const exercises = exRows.map((ex) =>
      mapExercise(ex, notesByExercise[ex.id] ?? [])
    );

    res.json({
      success: true,
      data: mapBodyPart(bpRows[0], exercises),
    });
  } catch (err) {
    console.error("GET /bodyparts/:bodyPartID:", err.message);
    res.status(500).json({ success: false, message: "Failed to fetch exercises" });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/exercises/:exerciseID
// Returns a single exercise with its notes + parent body part.
// Used by ExerciceScreen and TutorialScreen.
// ─────────────────────────────────────────────────────────────────────────────
router.get("/:exerciseID", async (req, res) => {
  const { exerciseID } = req.params;

  if (!exerciseID || isNaN(exerciseID)) {
    return res.status(400).json({ success: false, message: "Invalid exerciseID" });
  }

  try {
    // 1. Exercise row
    const [exRows] = await pool.query(
      `SELECT e.id, e.name, e.image, e.muscle, e.video, e.description, e.bodyPartID,
              bp.name AS bpName, bp.image AS bpImage
       FROM Exercises e
       JOIN BodyParts bp ON bp.id = e.bodyPartID
       WHERE e.id = ?`,
      [exerciseID]
    );

    if (exRows.length === 0) {
      return res.status(404).json({ success: false, message: "Exercise not found" });
    }

    const ex = exRows[0];

    // 2. Notes for this exercise
    const [noteRows] = await pool.query(
      "SELECT id, text FROM Notes WHERE exerciseID = ? ORDER BY id ASC",
      [exerciseID]
    );

    // 3. Assemble (embed parent body part for Flutter's exercice.part.name)
    const data = {
      ...mapExercise(ex, noteRows.map(mapNote)),
      part: {
        id: String(ex.bodyPartID),
        name: ex.bpName ?? "",
        imageUrl: ex.bpImage ?? "",
      },
    };

    res.json({ success: true, data });
  } catch (err) {
    console.error("GET /:exerciseID:", err.message);
    res.status(500).json({ success: false, message: "Failed to fetch exercise" });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/exercises
// Returns ALL exercises (flat list, no notes) – useful for search / coach views.
// ─────────────────────────────────────────────────────────────────────────────
router.get("/", async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT id, name, image, muscle, video, description, bodyPartID
       FROM Exercises
       ORDER BY name ASC`
    );
    res.json({ success: true, data: rows.map((r) => mapExercise(r)) });
  } catch (err) {
    console.error("GET /exercises:", err.message);
    res.status(500).json({ success: false, message: "Failed to fetch exercises" });
  }
});

export default router;