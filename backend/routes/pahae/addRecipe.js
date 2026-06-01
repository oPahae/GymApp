import express from "express";
import pool from "../../config/db.js";

const router = express.Router();

// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────

router.post("/save", async (req, res) => {
  const {
    clientID = 1,
    name,
    image = null,
    calories,
    ingredients = [],
  } = req.body;

  if (!name || typeof name !== "string" || !name.trim()) {
    return res.status(400).json({
      success: false,
      message: "Recipe name is required.",
    });
  }

  if (!Array.isArray(ingredients) || ingredients.length === 0) {
    return res.status(400).json({
      success: false,
      message: "At least one ingredient is required.",
    });
  }

  for (const ing of ingredients) {
    if (!ing.ingredientID || !ing.quantity || ing.quantity <= 0) {
      return res.status(400).json({
        success: false,
        message: `Invalid ingredient entry: ${JSON.stringify(ing)}`,
      });
    }
  }

  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const [recipeResult] = await connection.query(
      `INSERT INTO Recipes (name, image, calories, clientID)
       VALUES (?, ?, ?, ?)`,
      [
        name.trim(),
        image,
        Math.round(calories ?? 0),
        clientID,
      ]
    );

    const recipeID = recipeResult.insertId;

    for (const ing of ingredients) {
      await connection.query(
        `INSERT INTO IngredientRecipes
         (recipeID, ingredientID, clientID, quantity)
         VALUES (?, ?, ?, ?)`,
        [
          recipeID,
          ing.ingredientID,
          clientID,
          Math.round(ing.quantity),
        ]
      );
    }

    await connection.commit();

    res.status(201).json({
      success: true,
      recipeID,
    });
  } catch (error) {
    await connection.rollback();

    console.error("POST /save error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to save recipe.",
    });
  } finally {
    connection.release();
  }
});

// ─────────────────────────────────────────────────────────────────────────────

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