import express from "express";
import pool from "../../config/db.js";

const router = express.Router();

// DB column is "image", Flutter model expects "imageUrl"
const mapIngredient = (row) => ({
  id: String(row.id),
  name: row.name ?? "",
  imageUrl: row.image ?? "",
  calories: row.calories ?? 0,
  type: row.type ?? "solid",
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/pahae/addFood/ingredients
// ─────────────────────────────────────────────────────────────────────────────
router.get("/ingredients", async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT id, name, image, calories, type FROM Ingredients ORDER BY name ASC"
    );
    res.json({ success: true, data: rows.map(mapIngredient) });
  } catch (err) {
    console.error("GET /ingredients:", err.message);
    res.status(500).json({ success: false, message: "Failed to fetch ingredients" });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/pahae/addFood/recent/:clientID
// ─────────────────────────────────────────────────────────────────────────────
router.get("/recent/:clientID", async (req, res) => {
  const { clientID } = req.params;
  if (!clientID || isNaN(clientID)) {
    return res.status(400).json({ success: false, message: "Invalid clientID" });
  }
  try {
    const [days] = await pool.query(
      "SELECT id FROM Days WHERE clientID = ? ORDER BY logDate DESC LIMIT 1",
      [clientID]
    );
    if (days.length === 0) {
      return res.json({ success: true, data: [] });
    }
    const dayID = days[0].id;
    const [rows] = await pool.query(
      `SELECT i.id, i.name, i.image, i.calories, i.type
       FROM IngredientsDay id2
       JOIN Ingredients i ON i.id = id2.ingredientID
       WHERE id2.dayID = ?
       GROUP BY i.id
       LIMIT 6`,
      [dayID]
    );
    res.json({ success: true, data: rows.map(mapIngredient) });
  } catch (err) {
    console.error("GET /recent/:clientID:", err.message);
    res.status(500).json({ success: false, message: "Failed to fetch recent foods" });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/pahae/addFood/recipes/:clientID
// ─────────────────────────────────────────────────────────────────────────────
router.get("/recipes/:clientID", async (req, res) => {
  const { clientID } = req.params;
  if (!clientID || isNaN(clientID)) {
    return res.status(400).json({ success: false, message: "Invalid clientID" });
  }
  try {
    const [recipes] = await pool.query(
      "SELECT id, name, image, calories FROM Recipes WHERE clientID = ? ORDER BY name ASC",
      [clientID]
    );
    if (recipes.length === 0) {
      return res.json({ success: true, data: [] });
    }

    const mealtimeKeys = recipes.map((r) => `recipe_${r.id}`);
    const mtPlaceholders = mealtimeKeys.map(() => "?").join(",");

    const [ingredientRows] = await pool.query(
      `SELECT ni.mealtime, i.id, i.name, i.image, i.calories, i.type
       FROM NutritionIngredients ni
       JOIN Ingredients i ON i.id = ni.ingredientID
       WHERE ni.clientID = ? AND ni.mealtime IN (${mtPlaceholders})`,
      [clientID, ...mealtimeKeys]
    );

    const ingredientsByRecipe = {};
    for (const row of ingredientRows) {
      const recipeID = parseInt(row.mealtime.replace("recipe_", ""), 10);
      if (!ingredientsByRecipe[recipeID]) ingredientsByRecipe[recipeID] = [];
      ingredientsByRecipe[recipeID].push(mapIngredient(row));
    }

    const result = recipes.map((r) => ({
      id: String(r.id),
      name: r.name ?? "",
      imageUrl: r.image ?? "",
      calories: r.calories ?? 0,
      ingredients: ingredientsByRecipe[r.id] ?? [],
    }));

    res.json({ success: true, data: result });
  } catch (err) {
    console.error("GET /recipes/:clientID:", err.message);
    res.status(500).json({ success: false, message: "Failed to fetch recipes" });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/pahae/addFood/log
// Body: { clientID, mealtime, items: [{ type, id, quantity }] }
// ─────────────────────────────────────────────────────────────────────────────
router.post("/log", async (req, res) => {
  const { clientID, mealtime, items } = req.body;

  if (!clientID || isNaN(clientID)) {
    return res.status(400).json({ success: false, message: "Invalid clientID" });
  }
  const validMealtimes = ["breakfast", "lunch", "dinner", "snacks"];
  if (!mealtime || !validMealtimes.includes(mealtime)) {
    return res.status(400).json({
      success: false,
      message: `Invalid mealtime. Must be one of: ${validMealtimes.join(", ")}`,
    });
  }
  if (!items || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ success: false, message: "items must be a non-empty array" });
  }
  for (const item of items) {
    if (!["ingredient", "recipe"].includes(item.type)) {
      return res.status(400).json({ success: false, message: `Invalid item type: "${item.type}"` });
    }
    if (!item.id || isNaN(item.id)) {
      return res.status(400).json({ success: false, message: "Each item needs a valid id" });
    }
    if (!item.quantity || isNaN(item.quantity) || item.quantity < 1) {
      return res.status(400).json({ success: false, message: "Each item needs quantity >= 1" });
    }
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const today = new Date().toISOString().split("T")[0];
    let [days] = await connection.query(
      "SELECT id FROM Days WHERE clientID = ? AND logDate = ?",
      [clientID, today]
    );

    let dayID;
    if (days.length === 0) {
      const [clientRows] = await connection.query(
        "SELECT id FROM Clients WHERE id = ?",
        [clientID]
      );
      if (clientRows.length === 0) {
        await connection.rollback();
        connection.release();
        return res.status(404).json({ success: false, message: "Client not found" });
      }
      const [maxId] = await connection.query(
        "SELECT COALESCE(MAX(id), 0) + 1 AS nextID FROM Days"
      );
      dayID = maxId[0].nextID;
      await connection.query(
        "INSERT INTO Days (id, logDate, calories, clientID) VALUES (?, ?, 0, ?)",
        [dayID, today, clientID]
      );
    } else {
      dayID = days[0].id;
    }

    let totalCaloriesAdded = 0;

    for (const item of items) {
      const id = Number(item.id);
      const qty = Number(item.quantity);

      if (item.type === "ingredient") {
        const [ingRows] = await connection.query(
          "SELECT id, calories FROM Ingredients WHERE id = ?",
          [id]
        );
        if (ingRows.length === 0) {
          await connection.rollback();
          connection.release();
          return res.status(404).json({ success: false, message: `Ingredient ${id} not found` });
        }
        totalCaloriesAdded += (ingRows[0].calories ?? 0) * qty;

        const [existing] = await connection.query(
          "SELECT quantity FROM IngredientsDay WHERE ingredientID=? AND dayID=? AND mealtime=?",
          [id, dayID, mealtime]
        );
        if (existing.length > 0) {
          await connection.query(
            "UPDATE IngredientsDay SET quantity=quantity+? WHERE ingredientID=? AND dayID=? AND mealtime=?",
            [qty, id, dayID, mealtime]
          );
        } else {
          await connection.query(
            "INSERT INTO IngredientsDay (ingredientID, dayID, mealtime, quantity) VALUES (?,?,?,?)",
            [id, dayID, mealtime, qty]
          );
        }
      } else {
        const [recRows] = await connection.query(
          "SELECT id, calories FROM Recipes WHERE id=? AND clientID=?",
          [id, clientID]
        );
        if (recRows.length === 0) {
          await connection.rollback();
          connection.release();
          return res.status(404).json({ success: false, message: `Recipe ${id} not found` });
        }
        totalCaloriesAdded += (recRows[0].calories ?? 0) * qty;

        const [existing] = await connection.query(
          "SELECT quantity FROM RecipesDay WHERE recipeID=? AND dayID=? AND mealtime=?",
          [id, dayID, mealtime]
        );
        if (existing.length > 0) {
          await connection.query(
            "UPDATE RecipesDay SET quantity=quantity+? WHERE recipeID=? AND dayID=? AND mealtime=?",
            [qty, id, dayID, mealtime]
          );
        } else {
          await connection.query(
            "INSERT INTO RecipesDay (recipeID, dayID, mealtime, quantity) VALUES (?,?,?,?)",
            [id, dayID, mealtime, qty]
          );
        }
      }
    }

    if (totalCaloriesAdded > 0) {
      await connection.query(
        "UPDATE Days SET calories=calories+? WHERE id=?",
        [totalCaloriesAdded, dayID]
      );
    }

    await connection.commit();
    connection.release();

    res.json({
      success: true,
      message: `${items.length} item(s) logged to ${mealtime}`,
      dayID,
      totalCaloriesAdded,
    });
  } catch (err) {
    await connection.rollback();
    connection.release();
    console.error("POST /log:", err.message);
    res.status(500).json({ success: false, message: "Failed to log items" });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/pahae/addFood/recipes
// Body: { clientID, name, image, calories, ingredientIDs: [1,2,3] }
// ─────────────────────────────────────────────────────────────────────────────
router.post("/recipes", async (req, res) => {
  const { clientID, name, image, calories, ingredientIDs } = req.body;

  if (!clientID || isNaN(clientID)) {
    return res.status(400).json({ success: false, message: "Invalid clientID" });
  }
  if (!name || typeof name !== "string" || name.trim() === "") {
    return res.status(400).json({ success: false, message: "Recipe name is required" });
  }
  if (calories == null || isNaN(calories) || calories < 0) {
    return res.status(400).json({ success: false, message: "Valid calories required" });
  }
  if (!ingredientIDs || !Array.isArray(ingredientIDs) || ingredientIDs.length === 0) {
    return res.status(400).json({ success: false, message: "ingredientIDs must be non-empty" });
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const [clientRows] = await connection.query(
      "SELECT id FROM Clients WHERE id=?",
      [clientID]
    );
    if (clientRows.length === 0) {
      await connection.rollback();
      connection.release();
      return res.status(404).json({ success: false, message: "Client not found" });
    }

    const [maxId] = await connection.query(
      "SELECT COALESCE(MAX(id),0)+1 AS nextID FROM Recipes"
    );
    const newRecipeID = maxId[0].nextID;

    await connection.query(
      "INSERT INTO Recipes (id, name, image, calories, clientID) VALUES (?,?,?,?,?)",
      [newRecipeID, name.trim(), image ?? "", Math.round(calories), clientID]
    );

    const mealtimeKey = `recipe_${newRecipeID}`;
    for (const ingID of ingredientIDs) {
      const [ingRows] = await connection.query(
        "SELECT id FROM Ingredients WHERE id=?",
        [ingID]
      );
      if (ingRows.length === 0) {
        await connection.rollback();
        connection.release();
        return res.status(404).json({ success: false, message: `Ingredient ${ingID} not found` });
      }
      const [existing] = await connection.query(
        "SELECT 1 FROM NutritionIngredients WHERE ingredientID=? AND clientID=? AND mealtime=?",
        [ingID, clientID, mealtimeKey]
      );
      if (existing.length === 0) {
        await connection.query(
          "INSERT INTO NutritionIngredients (ingredientID, clientID, mealtime, quantity) VALUES (?,?,?,1)",
          [ingID, clientID, mealtimeKey]
        );
      }
    }

    await connection.commit();
    connection.release();

    res.status(201).json({
      success: true,
      message: "Recipe created",
      recipeID: newRecipeID,
    });
  } catch (err) {
    await connection.rollback();
    connection.release();
    console.error("POST /recipes:", err.message);
    res.status(500).json({ success: false, message: "Failed to create recipe" });
  }
});

export default router;