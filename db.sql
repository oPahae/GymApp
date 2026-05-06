DROP DATABASE IF EXISTS gymappdb;
CREATE DATABASE gymappdb;
USE gymappdb;

-- ======================
-- TABLE: BodyParts
-- ======================
CREATE TABLE BodyParts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255),
    image VARCHAR(255)
);

-- ======================
-- TABLE: Coaches
-- ======================
CREATE TABLE Coaches (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255),
    image VARCHAR(255),
    createdAt DATE,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    specialty VARCHAR(255) NULL,
    bio TEXT NULL,
    resetToken VARCHAR(255) NULL,
    resetTokenExpiry DATETIME NULL
);
-- ======================
-- TABLE: Clients
-- ======================
CREATE TABLE Clients (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255),
    image VARCHAR(255),
    birth DATE,
    gender VARCHAR(255) NOT NULL DEFAULT 'Male',
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    weight DOUBLE,
    height DOUBLE,
    frequency INT,
    goal VARCHAR(255),
    weightGoal DOUBLE,
    createdAt DATE,
    coachID INT,
    gender VARCHAR(10) NOT NULL DEFAULT 'Male',
    passwordHash VARCHAR(255) NOT NULL DEFAULT '',
    FOREIGN KEY (coachID) REFERENCES Coaches(id)
);

-- ======================
-- TABLE: Exercises
-- ======================
CREATE TABLE Exercises (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255),
    image VARCHAR(255),
    muscle VARCHAR(255),
    video VARCHAR(255),
    description VARCHAR(255),
    bodyPartID INT,
    FOREIGN KEY (bodyPartID) REFERENCES BodyParts(id)
);

-- ======================
-- TABLE: Notes
-- ======================
CREATE TABLE Notes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    text VARCHAR(255),
    exerciseID INT,
    FOREIGN KEY (exerciseID) REFERENCES Exercises(id)
);

-- ======================
-- TABLE: Workouts
-- ======================
CREATE TABLE Workouts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    weekDay VARCHAR(50),
    exerciseID INT,
    clientID INT,
    FOREIGN KEY (exerciseID) REFERENCES Exercises(id),
    FOREIGN KEY (clientID) REFERENCES Clients(id)
);

-- ======================
-- TABLE: Invites
-- ======================
CREATE TABLE Invites (
    coachID INT,
    clientID INT,
    PRIMARY KEY (coachID, clientID),
    FOREIGN KEY (coachID) REFERENCES Coaches(id),
    FOREIGN KEY (clientID) REFERENCES Clients(id)
);

-- ======================
-- TABLE: Ingredients
-- ======================
CREATE TABLE Ingredients (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255),
    image VARCHAR(255),
    calories INT,
    type VARCHAR(100)
);

-- ======================
-- TABLE: Recipes
-- ======================
CREATE TABLE Recipes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255),
    image VARCHAR(255),
    calories INT,
    clientID INT,
    FOREIGN KEY (clientID) REFERENCES Clients(id)
);

-- ======================
-- TABLE: NutritionIngredients
-- ======================
CREATE TABLE NutritionIngredients (
    ingredientID INT,
    clientID INT,
    mealtime VARCHAR(50),
    weekDay VARCHAR(50),
    quantity INT,
    PRIMARY KEY (ingredientID, clientID, mealtime),
    FOREIGN KEY (ingredientID) REFERENCES Ingredients(id),
    FOREIGN KEY (clientID) REFERENCES Clients(id)
);

-- ======================
-- TABLE: NutritionRecipes
-- ======================
CREATE TABLE NutritionRecipes (
    recipeID INT,
    clientID INT,
    mealtime VARCHAR(50),
    weekDay VARCHAR(50),
    quantity INT,
    PRIMARY KEY (recipeID, clientID, mealtime),
    FOREIGN KEY (recipeID) REFERENCES Recipes(id),
    FOREIGN KEY (clientID) REFERENCES Clients(id)
);

-- ======================
-- TABLE: Days
-- ======================
CREATE TABLE Days (
    id INT PRIMARY KEY AUTO_INCREMENT,
    logDate DATE,
    calories INT,
    clientID INT,
    FOREIGN KEY (clientID) REFERENCES Clients(id)
);

-- ======================
-- TABLE: Activities
-- ======================
CREATE TABLE Activities (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255),
    calories INT,
    dayID INT,
    FOREIGN KEY (dayID) REFERENCES Days(id)
);

-- ======================
-- TABLE: IngredientsDay
-- ======================
CREATE TABLE IngredientsDay (
    ingredientID INT,
    dayID INT,
    mealtime VARCHAR(50),
    quantity INT,
    PRIMARY KEY (ingredientID, dayID, mealtime),
    FOREIGN KEY (ingredientID) REFERENCES Ingredients(id),
    FOREIGN KEY (dayID) REFERENCES Days(id)
);

-- ======================
-- TABLE: RecipesDay
-- ======================
CREATE TABLE RecipesDay (
    recipeID INT,
    dayID INT,
    mealtime VARCHAR(50),
    quantity INT,
    PRIMARY KEY (recipeID, dayID, mealtime),
    FOREIGN KEY (recipeID) REFERENCES Recipes(id),
    FOREIGN KEY (dayID) REFERENCES Days(id)
);

-- ======================
-- TABLE: Messages
-- ======================
CREATE TABLE Messages (
    id INT PRIMARY KEY AUTO_INCREMENT,
    text VARCHAR(255),
    time DATETIME,
    isUser BOOLEAN,
    coachID INT,
    clientID INT,
    FOREIGN KEY (coachID) REFERENCES Coaches(id),
    FOREIGN KEY (clientID) REFERENCES Clients(id)
);
-- Programme coach
CREATE TABLE CoachPrograms (
    id INT PRIMARY KEY AUTO_INCREMENT,
    text TEXT NOT NULL,
    updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    clientID INT NOT NULL UNIQUE,
    coachID INT NOT NULL,
    FOREIGN KEY (clientID) REFERENCES Clients(id),
    FOREIGN KEY (coachID) REFERENCES Coaches(id)
);
CREATE TABLE WeightHistory (
    id        INT PRIMARY KEY AUTO_INCREMENT,
    weight    DOUBLE NOT NULL,
    logDate   DATE NOT NULL,
    clientID  INT NOT NULL,
    FOREIGN KEY (clientID) REFERENCES Clients(id),
    UNIQUE KEY unique_day (clientID, logDate)
);

