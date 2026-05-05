import express from "express";
import pool from "../../config/db.js";

const router = express.Router();

// ─────────────────────────────────────────────────────────────────
// GET /api/pahae/addRecipe/ingredients
// Returns all available ingredients from the catalogue
// ─────────────────────────────────────────────────────────────────
router.get("/ingredients", async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT id, name, image, calories, type FROM Ingredients ORDER BY name ASC"
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    console.error("GET /ingredients error:", error.message);
    res.status(500).json({ success: false, message: "Failed to fetch ingredients." });
  }
});

// ─────────────────────────────────────────────────────────────────
// POST /api/pahae/addRecipe/save
// Creates a new recipe and links its ingredients
//
// Body:
// {
//   clientID: 1,          ← example value
//   name: "My Recipe",
//   image: "https://...", ← optional URL string (from picked image or first ingredient)
//   calories: 532,        ← total computed on client
//   ingredients: [
//     { ingredientID: 1, quantity: 100 },
//     { ingredientID: 3, quantity: 200 },
//     ...
//   ]
// }
//
// Note: RecipeIngredients (the join table linking a recipe to its
// specific ingredients + quantities) is not part of the current
// schema, so we insert into NutritionIngredients with mealtime
// set to "recipe" as a convention, and we store the recipe row
// in Recipes. Extend the schema later if a dedicated
// RecipeIngredients table is added.
// ─────────────────────────────────────────────────────────────────
router.post("/save", async (req, res) => {
  const {
    clientID = 1,       // example default
    name,
    image = null,
    calories,
    ingredients = [],   // [{ ingredientID, quantity }]
  } = req.body;

  // ── Basic validation ──────────────────────────────────────────
  if (!name || typeof name !== "string" || name.trim() === "") {
    return res.status(400).json({ success: false, message: "Recipe name is required." });
  }
  if (!Array.isArray(ingredients) || ingredients.length === 0) {
    return res.status(400).json({ success: false, message: "At least one ingredient is required." });
  }
  for (const ing of ingredients) {
    if (!ing.ingredientID || ing.quantity == null || ing.quantity <= 0) {
      return res.status(400).json({
        success: false,
        message: `Invalid ingredient entry: ${JSON.stringify(ing)}`,
      });
    }
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    // 1. Insert the recipe row
    const recipeId = Date.now(); // simple numeric ID; replace with AUTO_INCREMENT if schema allows
    await connection.query(
      "INSERT INTO Recipes (id, name, image, calories, clientID) VALUES (?, ?, ?, ?, ?)",
      [recipeId, name.trim(), image, Math.round(calories ?? 0), clientID]
    );

    // 2. Link each ingredient via NutritionIngredients
    //    mealtime = 'recipe' is a conventional marker so these rows are
    //    distinguishable from real meal-plan rows.
    for (const ing of ingredients) {
      // Upsert: if the same ingredient already exists for this client/mealtime,
      // update quantity rather than crash on duplicate primary key.
      await connection.query(
        `INSERT INTO NutritionIngredients (ingredientID, clientID, mealtime, quantity)
         VALUES (?, ?, 'recipe', ?)
         ON DUPLICATE KEY UPDATE quantity = VALUES(quantity)`,
        [ing.ingredientID, clientID, Math.round(ing.quantity)]
      );
    }

    await connection.commit();
    res.status(201).json({ success: true, data: { recipeID: recipeId } });
  } catch (error) {
    await connection.rollback();
    console.error("POST /save error:", error.message);
    res.status(500).json({ success: false, message: "Failed to save recipe." });
  } finally {
    connection.release();
  }
});

// ─────────────────────────────────────────────────────────────────
// GET /api/pahae/addRecipe/recipes/:clientID
// Returns all recipes belonging to a client (for later use / validation)
// ─────────────────────────────────────────────────────────────────
router.get("/recipes/:clientID", async (req, res) => {
  const { clientID } = req.params;
  if (!clientID || isNaN(Number(clientID))) {
    return res.status(400).json({ success: false, message: "Invalid clientID." });
  }
  try {
    const [rows] = await pool.query(
      "SELECT id, name, image, calories FROM Recipes WHERE clientID = ? ORDER BY id DESC",
      [clientID]
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    console.error("GET /recipes/:clientID error:", error.message);
    res.status(500).json({ success: false, message: "Failed to fetch recipes." });
  }
});

export default router;