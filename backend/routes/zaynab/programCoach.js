import express from "express";
import pool from "../../config/db.js";

const router = express.Router();

const DAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

// ─── GET /api/znp/program-coach?clientId=1 ───────────────────────────────────
router.get("/", async (req, res) => {
  const { clientId } = req.query;
  if (!clientId) {
    return res.status(400).json({ success: false, message: "clientId is required" });
  }

  try {
    const [workouts] = await pool.query(
      `SELECT w.weekDay, w.exerciseID, e.name, e.image, e.video, e.muscle,
              e.description, e.bodyPartID, bp.name as bodyPartName
       FROM Workouts w
       LEFT JOIN Exercises e ON w.exerciseID = e.id
       LEFT JOIN BodyParts bp ON e.bodyPartID = bp.id
       WHERE w.clientID = ?`,
      [clientId]
    );

    const [ingredients] = await pool.query(
      `SELECT ni.ingredientID, ni.mealtime, ni.quantity, ni.weekDay,
              i.id, i.name, i.image, i.calories, i.type
       FROM NutritionIngredients ni
       JOIN Ingredients i ON ni.ingredientID = i.id
       WHERE ni.clientID = ?`,
      [clientId]
    );

    const [recipes] = await pool.query(
      `SELECT nr.recipeID, nr.mealtime, nr.quantity, nr.weekDay,
              r.id, r.name, r.image, r.calories
       FROM NutritionRecipes nr
       JOIN Recipes r ON nr.recipeID = r.id
       WHERE nr.clientID = ?`,
      [clientId]
    );

    const week = DAYS.map((d) => ({
      day: d,
      breakfastFoods: [],
      lunchFoods: [],
      dinnerFoods: [],
      exercises: [],
    }));

    for (const w of workouts) {
      const idx = DAYS.indexOf(w.weekDay);
      if (idx === -1) continue;
      week[idx].exercises.push({
        id: String(w.exerciseID),
        name: w.name ?? "",
        description: w.description ?? "",
        image: w.image ?? "",
        video: w.video ?? "",
        muscle: w.muscle ?? "",
        type: (w.muscle ?? "").toLowerCase().includes("cardio") ? "cardio"
            : (w.muscle ?? "").toLowerCase().includes("flex") ? "flexibility"
            : "strength",
        part: {
          id: String(w.bodyPartID ?? ""),
          name: w.bodyPartName ?? "",
          imageUrl: "",
        },
      });
    }

    const mapFood = (item) => ({
      id: String(item.id),
      name: item.name ?? "",
      imageUrl: item.image ?? "",
      calories: (item.calories ?? 0) * (item.quantity ?? 1),
      type: item.type ?? "solid",
    });

    for (const item of [...ingredients, ...recipes]) {
      const idx = DAYS.indexOf(item.weekDay);
      if (idx === -1) continue;
      const food = mapFood(item);
      if (item.mealtime === "breakfast") week[idx].breakfastFoods.push(food);
      else if (item.mealtime === "lunch") week[idx].lunchFoods.push(food);
      else if (item.mealtime === "dinner") week[idx].dinnerFoods.push(food);
    }

    res.json({ success: true, data: { week } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// ─── GET /api/znp/program-coach/foods ────────────────────────────────────────
router.get("/foods", async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT id, name, image, calories, type FROM Ingredients ORDER BY name ASC"
    );
    const data = rows.map((r) => ({
      id: String(r.id),
      name: r.name ?? "",
      imageUrl: r.image ?? "",
      calories: r.calories ?? 0,
      type: r.type ?? "solid",
    }));
    res.json({ success: true, data: { foods: data } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// ─── GET /api/znp/program-coach/exercises ────────────────────────────────────
router.get("/exercises", async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT e.id, e.name, e.image, e.video, e.muscle, e.description,
              e.bodyPartID, bp.name as bodyPartName, bp.image as bodyPartImage
       FROM Exercises e
       LEFT JOIN BodyParts bp ON e.bodyPartID = bp.id
       ORDER BY e.name ASC`
    );
    const data = rows.map((e) => ({
      id: String(e.id),
      name: e.name ?? "",
      description: e.description ?? "",
      image: e.image ?? "",
      video: e.video ?? "",
      muscle: e.muscle ?? "",
      type: (e.muscle ?? "").toLowerCase().includes("cardio") ? "cardio"
          : (e.muscle ?? "").toLowerCase().includes("flex") ? "flexibility"
          : "strength",
      part: {
        id: String(e.bodyPartID ?? ""),
        name: e.bodyPartName ?? "",
        imageUrl: e.bodyPartImage ?? "",
      },
    }));
    res.json({ success: true, data: { exercises: data } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// ─── POST /api/znp/program-coach ─────────────────────────────────────────────
// Body: { clientId, week: [ { day, breakfastFoods, lunchFoods, dinnerFoods, exercises } ] }
router.post("/", async (req, res) => {
  const { clientId, week } = req.body;
  if (!clientId || !Array.isArray(week)) {
    return res.status(400).json({ success: false, message: "clientId and week are required." });
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    // Supprimer l'ancien programme
    await conn.query("DELETE FROM Workouts WHERE clientID = ?", [clientId]);
    await conn.query("DELETE FROM NutritionIngredients WHERE clientID = ?", [clientId]);
    await conn.query("DELETE FROM NutritionRecipes WHERE clientID = ?", [clientId]);

    // Générer un id de départ pour Workouts (pas AUTO_INCREMENT)
    const [maxW] = await conn.query("SELECT COALESCE(MAX(id), 0) + 1 AS next FROM Workouts");
    let workoutId = maxW[0].next;

    for (const day of week) {
      // Exercises → Workouts
      for (const ex of day.exercises ?? []) {
        await conn.query(
          "INSERT INTO Workouts (id, weekDay, exerciseID, clientID) VALUES (?, ?, ?, ?)",
          [workoutId++, day.day, ex.id, clientId]
        );
      }

      // Foods → NutritionIngredients (par mealtime)
      const insertFoods = async (foods, mealtime) => {
        for (const f of foods ?? []) {
          await conn.query(
            `INSERT INTO NutritionIngredients (ingredientID, clientID, mealtime, weekDay, quantity)
             VALUES (?, ?, ?, ?, 1)
             ON DUPLICATE KEY UPDATE quantity = 1`,
            [f.id, clientId, mealtime, day.day]
          );
        }
      };

      await insertFoods(day.breakfastFoods, "breakfast");
      await insertFoods(day.lunchFoods,     "lunch");
      await insertFoods(day.dinnerFoods,    "dinner");
    }

    await conn.commit();
    conn.release();
    res.json({ success: true, message: "Program saved." });

  } catch (err) {
    await conn.rollback();
    conn.release();
    console.error(err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

export default router;