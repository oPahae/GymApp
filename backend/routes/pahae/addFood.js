import express from "express";
import pool from "../../config/db.js";

const router = express.Router();

const mapIngredient = (row) => ({
  id: String(row.id),
  name: row.name ?? "",
  imageUrl: row.image ?? "",
  calories: row.calories ?? 0,
  type: row.type ?? "solid",
});

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

router.get("/recipes/:clientID", async (req, res) => {
  const { clientID } = req.params;

  if (!clientID || isNaN(clientID)) {
    return res.status(400).json({
      success: false,
      message: "Invalid clientID",
    });
  }

  try {
    const [recipes] = await pool.query(
      `SELECT id, name, image, calories
       FROM Recipes
       WHERE clientID = ?
       ORDER BY name ASC`,
      [clientID]
    );

    if (recipes.length === 0) {
      return res.json({
        success: true,
        data: [],
      });
    }

    const recipeIds = recipes.map(r => r.id);
    const placeholders = recipeIds.map(() => "?").join(",");

    const [ingredientRows] = await pool.query(
      `SELECT
          ir.recipeID,
          ir.quantity,
          i.id,
          i.name,
          i.image,
          i.calories,
          i.type
       FROM IngredientRecipes ir
       JOIN Ingredients i
         ON i.id = ir.ingredientID
       WHERE ir.recipeID IN (${placeholders})`,
      recipeIds
    );

    const ingredientsByRecipe = {};

    for (const row of ingredientRows) {
      if (!ingredientsByRecipe[row.recipeID]) {
        ingredientsByRecipe[row.recipeID] = [];
      }

      ingredientsByRecipe[row.recipeID].push({
        ...mapIngredient(row),
        quantity: row.quantity,
      });
    }

    const result = recipes.map(recipe => ({
      id: String(recipe.id),
      name: recipe.name ?? "",
      imageUrl: recipe.image ?? "",
      calories: recipe.calories ?? 0,
      ingredients: ingredientsByRecipe[recipe.id] ?? [],
    }));

    res.json({
      success: true,
      data: result,
    });
  } catch (err) {
    console.error("GET /recipes/:clientID:", err);
    res.status(500).json({
      success: false,
      message: "Failed to fetch recipes",
    });
  }
});

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
      await connection.query(
        "INSERT INTO Days (logDate, calories, clientID) VALUES (?, 0, ?)",
        [today, clientID]
      );

      dayID = insertResult.insertId;
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

    await connection.query(
      "INSERT INTO Recipes (name, image, calories, clientID) VALUES (?,?,?,?,?)",
      [name.trim(), image ?? "", Math.round(calories), clientID]
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