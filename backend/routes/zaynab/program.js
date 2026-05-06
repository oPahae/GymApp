import express from 'express';
import pool from "../../config/db.js";

const router = express.Router();

const handleSqlError = (res, error) => {
  console.error("SQL Error:", error);
  return res.status(500).json({ success: false, message: "Server error." });
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/program/week?clientId=1
// ─────────────────────────────────────────────────────────────────────────────
router.get('/week', async (req, res) => {
  const { clientId } = req.query;
  if (!clientId) {
    return res.status(400).json({ success: false, message: "clientId is required." });
  }

  const weekDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  const emptyWeek = weekDays.map(day => ({
    day, breakfastFoods: [], lunchFoods: [], dinnerFoods: [], exercises: []
  }));

  try {
    // 1. Ingredients par weekDay + mealtime
    const [ingredients] = await pool.query(`
      SELECT i.id, i.name, i.image, i.calories, i.type,
             ni.weekDay, ni.mealtime, ni.quantity
      FROM NutritionIngredients ni
      JOIN Ingredients i ON ni.ingredientID = i.id
      WHERE ni.clientID = ?
    `, [clientId]);

    // 2. Recipes par weekDay + mealtime
    const [recipes] = await pool.query(`
      SELECT r.id, r.name, r.image, r.calories,
             nr.weekDay, nr.mealtime, nr.quantity
      FROM NutritionRecipes nr
      JOIN Recipes r ON nr.recipeID = r.id
      WHERE nr.clientID = ?
    `, [clientId]);

    // 3. Exercises par weekDay (Workouts)
    const [exercises] = await pool.query(`
      SELECT w.weekDay, e.id, e.name, e.description, e.image, e.video, e.muscle,
             bp.name as bodyPartName
      FROM Workouts w
      JOIN Exercises e ON w.exerciseID = e.id
      LEFT JOIN BodyParts bp ON e.bodyPartID = bp.id
      WHERE w.clientID = ?
    `, [clientId]);

    // 4. Construire la map
    const dayMap = {};
    weekDays.forEach(d => {
      dayMap[d] = { day: d, breakfastFoods: [], lunchFoods: [], dinnerFoods: [], exercises: [] };
    });

    const mapFood = (item) => ({
      id: String(item.id),
      name: item.name ?? "",
      imageUrl: item.image ?? "",
      calories: (item.calories ?? 0) * (item.quantity ?? 1),
      type: item.type ?? "solid",
    });

    [...ingredients, ...recipes].forEach(item => {
      const day = item.weekDay;
      if (!dayMap[day]) return;
      const food = mapFood(item);
      if (item.mealtime === 'breakfast') dayMap[day].breakfastFoods.push(food);
      else if (item.mealtime === 'lunch') dayMap[day].lunchFoods.push(food);
      else if (item.mealtime === 'dinner') dayMap[day].dinnerFoods.push(food);
    });

    exercises.forEach(ex => {
      const day = ex.weekDay;
      if (!dayMap[day]) return;
      dayMap[day].exercises.push({
        id: String(ex.id),
        name: ex.name ?? "",
        description: ex.description ?? "",
        image: ex.image ?? "",
        video: ex.video ?? "",
        muscle: ex.muscle ?? "",
        bodyPart: ex.bodyPartName ?? "",
        type: ex.muscle ? "strength" : "cardio",
      });
    });

    res.json({ success: true, data: { week: weekDays.map(d => dayMap[d]) } });

  } catch (error) {
    handleSqlError(res, error);
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/znp/program/day?clientId=1&day=Monday
// ─────────────────────────────────────────────────────────────────────────────
router.get('/day', async (req, res) => {
  const { clientId, day } = req.query;
  if (!clientId || !day) {
    return res.status(400).json({ success: false, message: "clientId and day are required." });
  }

  try {
    const [ingredients] = await pool.query(`
      SELECT i.id, i.name, i.image, i.calories, i.type, ni.mealtime, ni.quantity
      FROM NutritionIngredients ni
      JOIN Ingredients i ON ni.ingredientID = i.id
      WHERE ni.clientID = ? AND ni.weekDay = ?
    `, [clientId, day]);

    const [recipes] = await pool.query(`
      SELECT r.id, r.name, r.image, r.calories, nr.mealtime, nr.quantity
      FROM NutritionRecipes nr
      JOIN Recipes r ON nr.recipeID = r.id
      WHERE nr.clientID = ? AND nr.weekDay = ?
    `, [clientId, day]);

    const [exercises] = await pool.query(`
      SELECT e.id, e.name, e.description, e.image, e.video, e.muscle,
             bp.name as bodyPartName
      FROM Workouts w
      JOIN Exercises e ON w.exerciseID = e.id
      LEFT JOIN BodyParts bp ON e.bodyPartID = bp.id
      WHERE w.clientID = ? AND w.weekDay = ?
    `, [clientId, day]);

    const mapFood = (item) => ({
      id: String(item.id),
      name: item.name ?? "",
      imageUrl: item.image ?? "",
      calories: (item.calories ?? 0) * (item.quantity ?? 1),
      type: item.type ?? "solid",
    });

    const allFoods = [...ingredients, ...recipes];

    res.json({
      success: true,
      data: {
        day,
        breakfastFoods: allFoods.filter(f => f.mealtime === 'breakfast').map(mapFood),
        lunchFoods:     allFoods.filter(f => f.mealtime === 'lunch').map(mapFood),
        dinnerFoods:    allFoods.filter(f => f.mealtime === 'dinner').map(mapFood),
        exercises: exercises.map(e => ({
          id: String(e.id),
          name: e.name ?? "",
          description: e.description ?? "",
          image: e.image ?? "",
          video: e.video ?? "",
          muscle: e.muscle ?? "",
          bodyPart: e.bodyPartName ?? "",
          type: e.muscle ? "strength" : "cardio",
        })),
      }
    });

  } catch (error) {
    handleSqlError(res, error);
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/znp/program/food
// Body: { clientId, day, mealtime, foodId, type ('ingredient'|'recipe'), quantity }
// ─────────────────────────────────────────────────────────────────────────────
router.post('/food', async (req, res) => {
  const { clientId, day, mealtime, foodId, type, quantity = 1 } = req.body;

  if (!clientId || !day || !mealtime || !foodId || !type) {
    return res.status(400).json({ success: false, message: "All fields are required." });
  }
  const validMealtimes = ['breakfast', 'lunch', 'dinner'];
  if (!validMealtimes.includes(mealtime)) {
    return res.status(400).json({ success: false, message: `mealtime must be one of: ${validMealtimes.join(', ')}` });
  }

  try {
    if (type === 'ingredient') {
      await pool.query(`
        INSERT INTO NutritionIngredients (ingredientID, clientID, mealtime, weekDay, quantity)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE quantity = quantity + ?
      `, [foodId, clientId, mealtime, day, quantity, quantity]);

    } else if (type === 'recipe') {
      await pool.query(`
        INSERT INTO NutritionRecipes (recipeID, clientID, mealtime, weekDay, quantity)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE quantity = quantity + ?
      `, [foodId, clientId, mealtime, day, quantity, quantity]);

    } else {
      return res.status(400).json({ success: false, message: "type must be 'ingredient' or 'recipe'." });
    }

    res.json({ success: true, message: "Food added successfully." });

  } catch (error) {
    handleSqlError(res, error);
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// DELETE /api/znp/program/food
// Body: { clientId, day, mealtime, foodId, type }
// ─────────────────────────────────────────────────────────────────────────────
router.delete('/food', async (req, res) => {
  const { clientId, day, mealtime, foodId, type } = req.body;

  if (!clientId || !day || !mealtime || !foodId || !type) {
    return res.status(400).json({ success: false, message: "All fields are required." });
  }

  try {
    if (type === 'ingredient') {
      await pool.query(`
        DELETE FROM NutritionIngredients
        WHERE ingredientID = ? AND clientID = ? AND mealtime = ? AND weekDay = ?
      `, [foodId, clientId, mealtime, day]);

    } else if (type === 'recipe') {
      await pool.query(`
        DELETE FROM NutritionRecipes
        WHERE recipeID = ? AND clientID = ? AND mealtime = ? AND weekDay = ?
      `, [foodId, clientId, mealtime, day]);

    } else {
      return res.status(400).json({ success: false, message: "type must be 'ingredient' or 'recipe'." });
    }

    res.json({ success: true, message: "Food removed successfully." });

  } catch (error) {
    handleSqlError(res, error);
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/znp/program/exercise
// Body: { clientId, day, exerciseId }
// ─────────────────────────────────────────────────────────────────────────────
router.post('/exercise', async (req, res) => {
  const { clientId, day, exerciseId } = req.body;

  if (!clientId || !day || !exerciseId) {
    return res.status(400).json({ success: false, message: "All fields are required." });
  }

  try {
    // Vérifier si déjà ajouté
    const [existing] = await pool.query(`
      SELECT id FROM Workouts WHERE clientID = ? AND weekDay = ? AND exerciseID = ?
    `, [clientId, day, exerciseId]);

    if (existing.length > 0) {
      return res.status(409).json({ success: false, message: "Exercise already added for this day." });
    }

    // Générer un id pour Workouts (pas AUTO_INCREMENT dans la BDD)
    const [maxId] = await pool.query(`SELECT COALESCE(MAX(id), 0) + 1 AS nextID FROM Workouts`);
    const newId = maxId[0].nextID;

    await pool.query(`
      INSERT INTO Workouts (id, weekDay, exerciseID, clientID)
      VALUES (?, ?, ?, ?)
    `, [newId, day, exerciseId, clientId]);

    res.json({ success: true, message: "Exercise added successfully." });

  } catch (error) {
    handleSqlError(res, error);
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// DELETE /api/znp/program/exercise
// Body: { clientId, day, exerciseId }
// ─────────────────────────────────────────────────────────────────────────────
router.delete('/exercise', async (req, res) => {
  const { clientId, day, exerciseId } = req.body;

  if (!clientId || !day || !exerciseId) {
    return res.status(400).json({ success: false, message: "All fields are required." });
  }

  try {
    await pool.query(`
      DELETE FROM Workouts
      WHERE clientID = ? AND weekDay = ? AND exerciseID = ?
    `, [clientId, day, exerciseId]);

    res.json({ success: true, message: "Exercise removed successfully." });

  } catch (error) {
    handleSqlError(res, error);
  }
});

export default router;