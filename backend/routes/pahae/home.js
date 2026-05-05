import express from "express";
import pool from "../../config/db.js";

const router = express.Router();

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: get or create today's Day record for a client
// ─────────────────────────────────────────────────────────────────────────────
async function getOrCreateDay(clientID, conn) {
  const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD

  const [rows] = await conn.execute(
    "SELECT id, calories FROM Days WHERE clientID = ? AND logDate = ?",
    [clientID, today]
  );

  if (rows.length > 0) return rows[0];

  // Create a new day with 0 calories consumed initially
  const [result] = await conn.execute(
    "INSERT INTO Days (logDate, calories, clientID) VALUES (?, 0, ?)",
    [today, clientID]
  );
  return { id: result.insertId, calories: 0 };
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /summary/:clientID
// Returns today's full calorie summary: consumed (by mealtime), burned, remaining
// ─────────────────────────────────────────────────────────────────────────────
router.get("/summary/:clientID", async (req, res) => {
  const { clientID } = req.params;
  const conn = await pool.getConnection();

  try {
    const today = new Date().toISOString().slice(0, 10);

    // Ensure day exists
    const day = await getOrCreateDay(clientID, conn);
    const dayID = day.id;

    // Base metabolic rate (static for now — can be computed from client profile)
    const BASE_BURNED = 2200;
    const CALORIE_GOAL = 2300;

    // ── Calories burned from activities today ──
    const [actRows] = await conn.execute(
      "SELECT COALESCE(SUM(calories), 0) AS activityCalories FROM Activities WHERE dayID = ?",
      [dayID]
    );
    const activityCalories = actRows[0].activityCalories ?? 0;
    const totalBurned = BASE_BURNED + activityCalories;

    // ── Calories consumed from ingredients today ──
    const [ingCalRows] = await conn.execute(
      `SELECT COALESCE(SUM(i.calories * id2.quantity), 0) AS total
       FROM IngredientsDay id2
       JOIN Ingredients i ON i.id = id2.ingredientID
       WHERE id2.dayID = ?`,
      [dayID]
    );
    const ingredientCalories = ingCalRows[0].total ?? 0;

    // ── Calories consumed from recipes today ──
    const [recCalRows] = await conn.execute(
      `SELECT COALESCE(SUM(r.calories * rd.quantity), 0) AS total
       FROM RecipesDay rd
       JOIN Recipes r ON r.id = rd.recipeID
       WHERE rd.dayID = ?`,
      [dayID]
    );
    const recipeCalories = recCalRows[0].total ?? 0;

    const totalConsumed = ingredientCalories + recipeCalories;
    const remaining = Math.max(0, CALORIE_GOAL - totalConsumed);

    res.json({
      success: true,
      data: {
        dayID,
        calorieGoal: CALORIE_GOAL,
        baseBurned: BASE_BURNED,
        activityCalories,
        totalBurned,
        totalConsumed,
        remaining,
      },
    });
  } catch (err) {
    console.error("GET /summary error:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  } finally {
    conn.release();
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /meals/:clientID
// Returns today's meals grouped by mealtime (breakfast / lunch / dinner)
// Each item can be an ingredient or a recipe
// ─────────────────────────────────────────────────────────────────────────────
router.get("/meals/:clientID", async (req, res) => {
  const { clientID } = req.params;
  const conn = await pool.getConnection();

  try {
    const day = await getOrCreateDay(clientID, conn);
    const dayID = day.id;

    // ── Ingredients entries for today ──
    const [ingredients] = await conn.execute(
      `SELECT
         id2.mealtime,
         i.id,
         i.name,
         i.image,
         i.calories AS caloriesPerUnit,
         id2.quantity,
         (i.calories * id2.quantity) AS totalCalories,
         'ingredient' AS itemType
       FROM IngredientsDay id2
       JOIN Ingredients i ON i.id = id2.ingredientID
       WHERE id2.dayID = ?
       ORDER BY FIELD(id2.mealtime, 'breakfast', 'lunch', 'dinner', 'snack'), i.name`,
      [dayID]
    );

    // ── Recipe entries for today ──
    const [recipes] = await conn.execute(
      `SELECT
         rd.mealtime,
         r.id,
         r.name,
         r.image,
         r.calories AS caloriesPerUnit,
         rd.quantity,
         (r.calories * rd.quantity) AS totalCalories,
         'recipe' AS itemType
       FROM RecipesDay rd
       JOIN Recipes r ON r.id = rd.recipeID
       WHERE rd.dayID = ?
       ORDER BY FIELD(rd.mealtime, 'breakfast', 'lunch', 'dinner', 'snack'), r.name`,
      [dayID]
    );

    // ── Group by mealtime ──
    const mealtimes = ["breakfast", "lunch", "dinner", "snack"];
    const allItems = [...ingredients, ...recipes];

    const grouped = {};
    for (const mt of mealtimes) {
      const items = allItems.filter((i) => i.mealtime === mt);
      const totalKcal = items.reduce((sum, i) => sum + (i.totalCalories ?? 0), 0);
      grouped[mt] = { mealtime: mt, totalKcal, items };
    }

    res.json({ success: true, data: grouped });
  } catch (err) {
    console.error("GET /meals error:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  } finally {
    conn.release();
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /activities/:clientID
// Returns today's activity list
// ─────────────────────────────────────────────────────────────────────────────
router.get("/activities/:clientID", async (req, res) => {
  const { clientID } = req.params;
  const conn = await pool.getConnection();

  try {
    const day = await getOrCreateDay(clientID, conn);
    const dayID = day.id;

    const [activities] = await conn.execute(
      "SELECT id, name, calories FROM Activities WHERE dayID = ? ORDER BY id",
      [dayID]
    );

    res.json({ success: true, data: activities });
  } catch (err) {
    console.error("GET /activities error:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  } finally {
    conn.release();
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /activities/:clientID
// Body: { name: string, calories: int }
// Adds a new activity to today's day
// ─────────────────────────────────────────────────────────────────────────────
router.post("/activities/:clientID", async (req, res) => {
  const { clientID } = req.params;
  const { name, calories } = req.body;

  if (!name || typeof name !== "string" || name.trim() === "") {
    return res.status(400).json({ success: false, message: "Invalid activity name" });
  }
  const cal = parseInt(calories, 10);
  if (isNaN(cal) || cal <= 0) {
    return res.status(400).json({ success: false, message: "Invalid calories value" });
  }

  const conn = await pool.getConnection();
  try {
    const day = await getOrCreateDay(clientID, conn);
    const dayID = day.id;

    const [result] = await conn.execute(
      "INSERT INTO Activities (name, calories, dayID) VALUES (?, ?, ?)",
      [name.trim(), cal, dayID]
    );

    res.status(201).json({
      success: true,
      data: { id: result.insertId, name: name.trim(), calories: cal },
    });
  } catch (err) {
    console.error("POST /activities error:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  } finally {
    conn.release();
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// DELETE /activities/:clientID/:activityID
// Deletes an activity from today's day (safety check: activity must belong to client's day)
// ─────────────────────────────────────────────────────────────────────────────
router.delete("/activities/:clientID/:activityID", async (req, res) => {
  const { clientID, activityID } = req.params;
  const conn = await pool.getConnection();

  try {
    const day = await getOrCreateDay(clientID, conn);
    const dayID = day.id;

    // Safety: verify activity belongs to this client's day
    const [check] = await conn.execute(
      "SELECT id FROM Activities WHERE id = ? AND dayID = ?",
      [activityID, dayID]
    );
    if (check.length === 0) {
      return res.status(404).json({ success: false, message: "Activity not found" });
    }

    await conn.execute("DELETE FROM Activities WHERE id = ?", [activityID]);

    res.json({ success: true, message: "Activity deleted" });
  } catch (err) {
    console.error("DELETE /activities error:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  } finally {
    conn.release();
  }
});

export default router;