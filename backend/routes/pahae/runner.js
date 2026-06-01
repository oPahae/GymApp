import express from "express";
import pool from "../../config/db.js";

const router = express.Router();

router.get("/run", async (req, res) => {
  pool.execute('SELECT * FROM Clients LIMIT 1');
  res.send("the app is up :D");
});

router.get("/init", async (req, res) => {
  const conn = await pool.getConnection();

  try {
    await conn.beginTransaction();

    await conn.query(`SET FOREIGN_KEY_CHECKS = 0`);

    const [tables] = await conn.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = DATABASE()
    `);

    for (const table of tables) {
      await conn.query(`DROP TABLE IF EXISTS \`${table.TABLE_NAME}\``);
    }

    await conn.query(`SET FOREIGN_KEY_CHECKS = 1`);

    await conn.query(`
      CREATE TABLE BodyParts (
        id INT PRIMARY KEY AUTO_INCREMENT,
        name VARCHAR(255),
        image VARCHAR(255)
      )
    `);

    await conn.query(`
      CREATE TABLE Coaches (
        id INT PRIMARY KEY AUTO_INCREMENT,
        name VARCHAR(255),
        image VARCHAR(255),
        createdAt DATE,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        specialty VARCHAR(255),
        bio TEXT,
        resetToken VARCHAR(255),
        resetTokenExpiry DATETIME
      )
    `);

    await conn.query(`
      CREATE TABLE Clients (
        id INT PRIMARY KEY AUTO_INCREMENT,
        name VARCHAR(255),
        image VARCHAR(255),
        birth DATE,
        gender VARCHAR(10) NOT NULL DEFAULT 'Male',
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        weight DOUBLE,
        height DOUBLE,
        frequency INT,
        goal VARCHAR(255),
        weightGoal DOUBLE,
        createdAt DATE,
        coachID INT,
        passwordHash VARCHAR(255) NOT NULL DEFAULT '',
        FOREIGN KEY (coachID) REFERENCES Coaches(id)
      )
    `);

    await conn.query(`
      CREATE TABLE Exercises (
        id INT PRIMARY KEY AUTO_INCREMENT,
        name VARCHAR(255),
        image VARCHAR(255),
        muscle VARCHAR(255),
        video VARCHAR(255),
        description VARCHAR(255),
        bodyPartID INT,
        FOREIGN KEY (bodyPartID) REFERENCES BodyParts(id)
      )
    `);

    await conn.query(`
      CREATE TABLE Notes (
        id INT PRIMARY KEY AUTO_INCREMENT,
        text VARCHAR(255),
        exerciseID INT,
        FOREIGN KEY (exerciseID) REFERENCES Exercises(id)
      )
    `);

    await conn.query(`
      CREATE TABLE Workouts (
        id INT PRIMARY KEY AUTO_INCREMENT,
        weekDay VARCHAR(50),
        exerciseID INT,
        clientID INT,
        FOREIGN KEY (exerciseID) REFERENCES Exercises(id),
        FOREIGN KEY (clientID) REFERENCES Clients(id)
      )
    `);

    await conn.query(`
      CREATE TABLE Invites (
        coachID INT,
        clientID INT,
        PRIMARY KEY (coachID, clientID),
        FOREIGN KEY (coachID) REFERENCES Coaches(id),
        FOREIGN KEY (clientID) REFERENCES Clients(id)
      )
    `);

    await conn.query(`
      CREATE TABLE Ingredients (
        id INT PRIMARY KEY AUTO_INCREMENT,
        name VARCHAR(255),
        image VARCHAR(255),
        calories INT,
        type VARCHAR(100)
      )
    `);

    await conn.query(`
      CREATE TABLE Recipes (
        id INT PRIMARY KEY AUTO_INCREMENT,
        name VARCHAR(255),
        image VARCHAR(255),
        calories INT,
        clientID INT,
        FOREIGN KEY (clientID) REFERENCES Clients(id)
      )
    `);

    await conn.query(`
      CREATE TABLE NutritionIngredients (
        ingredientID INT,
        clientID INT,
        mealtime VARCHAR(50),
        weekDay VARCHAR(50),
        quantity INT,
        PRIMARY KEY (ingredientID, clientID, mealtime),
        FOREIGN KEY (ingredientID) REFERENCES Ingredients(id),
        FOREIGN KEY (clientID) REFERENCES Clients(id)
      )
    `);

    await conn.query(`
      CREATE TABLE NutritionRecipes (
        recipeID INT,
        clientID INT,
        mealtime VARCHAR(50),
        weekDay VARCHAR(50),
        quantity INT,
        PRIMARY KEY (recipeID, clientID, mealtime),
        FOREIGN KEY (recipeID) REFERENCES Recipes(id),
        FOREIGN KEY (clientID) REFERENCES Clients(id)
      )
    `);

    await conn.query(`
      CREATE TABLE Days (
        id INT PRIMARY KEY AUTO_INCREMENT,
        logDate DATE,
        calories INT,
        clientID INT,
        FOREIGN KEY (clientID) REFERENCES Clients(id)
      )
    `);

    await conn.query(`
      CREATE TABLE Activities (
        id INT PRIMARY KEY AUTO_INCREMENT,
        name VARCHAR(255),
        calories INT,
        dayID INT,
        FOREIGN KEY (dayID) REFERENCES Days(id)
      )
    `);

    await conn.query(`
      CREATE TABLE IngredientsDay (
        ingredientID INT,
        dayID INT,
        mealtime VARCHAR(50),
        quantity INT,
        PRIMARY KEY (ingredientID, dayID, mealtime),
        FOREIGN KEY (ingredientID) REFERENCES Ingredients(id),
        FOREIGN KEY (dayID) REFERENCES Days(id)
      )
    `);

    await conn.query(`
      CREATE TABLE RecipesDay (
        recipeID INT,
        dayID INT,
        mealtime VARCHAR(50),
        quantity INT,
        PRIMARY KEY (recipeID, dayID, mealtime),
        FOREIGN KEY (recipeID) REFERENCES Recipes(id),
        FOREIGN KEY (dayID) REFERENCES Days(id)
      )
    `);

    await conn.query(`
      CREATE TABLE Messages (
        id INT PRIMARY KEY AUTO_INCREMENT,
        text TEXT,
        time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        isUser TINYINT(1) NOT NULL,
        type ENUM('text','image','audio','video') NOT NULL DEFAULT 'text',
        status ENUM('sending','sent','delivered','read') NOT NULL DEFAULT 'sent',
        mediaUrl VARCHAR(512),
        coachID INT NOT NULL,
        clientID INT NOT NULL,
        FOREIGN KEY (coachID) REFERENCES Coaches(id),
        FOREIGN KEY (clientID) REFERENCES Clients(id)
      )
    `);

    await conn.query(`
      CREATE TABLE CoachPrograms (
        id INT PRIMARY KEY AUTO_INCREMENT,
        text TEXT NOT NULL,
        updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        clientID INT NOT NULL UNIQUE,
        coachID INT NOT NULL,
        FOREIGN KEY (clientID) REFERENCES Clients(id),
        FOREIGN KEY (coachID) REFERENCES Coaches(id)
      )
    `);

    await conn.query(`
      CREATE TABLE WeightHistory (
        id INT PRIMARY KEY AUTO_INCREMENT,
        weight DOUBLE NOT NULL,
        logDate DATE NOT NULL,
        clientID INT NOT NULL,
        UNIQUE KEY unique_day (clientID, logDate)
      )
    `);

    await conn.query(`
      INSERT INTO Coaches (
        id,
        name,
        image,
        createdAt,
        email,
        password,
        specialty,
        bio
      )
      VALUES (
        1,
        'Ackerman',
        NULL,
        CURDATE(),
        'ackerman07170@gmail.com',
        '$2b$10$Y4mlWsDvi6LrzSmz5RrqY.sf3n6hNzVZZALvonLFuyjd.idfjcFWi',
        'Fitness',
        'Coach professionnel'
      )
    `);

    await conn.commit();

    res.send(" defaultdb initialized successfully");
  } catch (err) {
    await conn.rollback();
    console.error(err);
    res.status(500).send(err.message);
  } finally {
    conn.release();
  }
});

router.get("/fooder", async (req, res) => {
  const PAGE_SIZE = 100;
  const TOTAL_PAGES = 5;
  const resolveType = (product) => {
    const tags = (product.categories_tags ?? []).join(" ");
    const name = (product.product_name ?? "").toLowerCase();
    if (
      tags.includes("beverages") ||
      tags.includes("drinks") ||
      tags.includes("juices") ||
      tags.includes("waters") ||
      name.includes("juice") ||
      name.includes("water") ||
      name.includes("milk") ||
      name.includes("drink")
    ) {
      return "liquid";
    }
    return "solid";
  };

  try {
    let inserted = 0;
    let skipped = 0;
    for (let page = 1; page <= TOTAL_PAGES; page++) {
      const url =
        `https://world.openfoodfacts.org/cgi/search.pl` +
        `?action=process&json=true&page_size=${PAGE_SIZE}&page=${page}` +
        `&fields=product_name,image_front_url,nutriments,categories_tags` +
        `&sort_by=unique_scans_n`;
      const response = await fetch(url);
      if (!response.ok) {
        console.warn(`Page ${page} failed: HTTP ${response.status}`);
        continue;
      }
      const json = await response.json();
      const products = json.products ?? [];
      for (const product of products) {
        const name = product.product_name?.trim();
        const image = product.image_front_url ?? "";
        const calories = Math.round(
          product.nutriments?.["energy-kcal_100g"] ??
          (product.nutriments?.["energy_100g"] ?? 0) / 4.184
        );
        const type = resolveType(product);
        if (!name || name.length < 2 || calories < 0 || calories > 9000) {
          skipped++;
          continue;
        }
        await pool.query(
          `INSERT IGNORE INTO Ingredients (name, image, calories, type)
           SELECT ?, ?, ?, ?
           FROM DUAL
           WHERE NOT EXISTS (
             SELECT 1 FROM Ingredients WHERE name = ?
           )`,
          [name, image, calories, type, name]
        );
        inserted++;
      }
      await new Promise((r) => setTimeout(r, 300));
    }
    res.json({
      success: true,
      message: `Seeding terminé`,
      inserted,
      skipped,
    });
  } catch (err) {
    console.error("GET /fooder:", err.message);
    res.status(500).json({ success: false, message: "Échec du seeding des ingrédients" });
  }
});

export default router;