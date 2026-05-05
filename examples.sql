-- Insertion des données dans toutes les tables
INSERT INTO BodyParts (name, image) VALUES
('Chest', 'chest.jpg'),
('Back', 'back.jpg'),
('Legs', 'legs.jpg'),
('Shoulders', 'shoulders.jpg'),
('Arms', 'arms.jpg');

INSERT INTO Coaches (name, image, createdAt) VALUES
('John Doe', 'john_doe.jpg', '2024-01-15'),
('Jane Smith', 'jane_smith.jpg', '2024-02-20'),
('Mike Johnson', 'mike_johnson.jpg', '2024-03-10');

INSERT INTO Clients (name, image, birth, gender, email, password, weight, height, frequency, goal, weightGoal, createdAt, coachID) VALUES
('Alice Brown', 'alice_brown.jpg', '1990-05-10', 'Female', 'alice@example.com', 'password123', 65.5, 170, 3, 'Lose weight', 60.0, '2024-01-20', 1),
('Bob Green', 'bob_green.jpg', '1985-08-15', 'Male', 'bob@example.com', 'password456', 80.0, 180, 4, 'Gain muscle', 85.0, '2024-02-01', 2),
('Charlie Davis', 'charlie_davis.jpg', '1995-11-25', 'Male', 'charlie@example.com', 'password789', 70.0, 175, 2, 'Maintain', 70.0, '2024-03-05', 1);

INSERT INTO Exercises (name, image, muscle, video, description, bodyPartID) VALUES
('Bench Press', 'bench_press.jpg', 'Pectorals', 'bench_press.mp4', 'Lie on a bench and press the barbell upwards.', 1),
('Squats', 'squats.jpg', 'Quadriceps', 'squats.mp4', 'Stand with feet shoulder-width apart and lower your body.', 3),
('Deadlift', 'deadlift.jpg', 'Hamstrings', 'deadlift.mp4', 'Bend at the hips and knees to lift the barbell.', 3),
('Pull-Ups', 'pullups.jpg', 'Latissimus Dorsi', 'pullups.mp4', 'Hang from a bar and pull your body upwards.', 2),
('Shoulder Press', 'shoulder_press.jpg', 'Deltoids', 'shoulder_press.mp4', 'Press the barbell overhead from shoulder height.', 4);

INSERT INTO Notes (text, exerciseID) VALUES
('Focus on form, not weight.', 1),
('Keep your back straight.', 2),
('Engage your core.', 3),
('Use a wide grip for better results.', 4),
('Control the movement.', 5);

INSERT INTO Workouts (weekDay, exerciseID, clientID) VALUES
('Monday', 1, 1),
('Monday', 2, 1),
('Tuesday', 3, 2),
('Tuesday', 4, 2),
('Wednesday', 5, 3),
('Wednesday', 1, 3);

INSERT INTO Invites (coachID, clientID) VALUES
(1, 1),
(2, 2),
(1, 3);

INSERT INTO Ingredients (name, image, calories, type) VALUES
('Chicken Breast', 'chicken_breast.jpg', 165, 'Protein'),
('Rice', 'rice.jpg', 130, 'Carbohydrate'),
('Broccoli', 'broccoli.jpg', 55, 'Vegetable'),
('Almonds', 'almonds.jpg', 164, 'Fat'),
('Eggs', 'eggs.jpg', 70, 'Protein');

INSERT INTO Recipes (name, image, calories, clientID) VALUES
('Grilled Chicken Salad', 'grilled_chicken_salad.jpg', 350, 1),
('Beef Stir-Fry', 'beef_stir_fry.jpg', 450, 2),
('Vegetable Soup', 'vegetable_soup.jpg', 200, 3);

INSERT INTO NutritionIngredients (ingredientID, clientID, mealtime, weekDay, quantity) VALUES
(1, 1, 'Lunch', 'Monday', 200),
(2, 1, 'Lunch', 'Monday', 150),
(3, 2, 'Dinner', 'Tuesday', 100),
(4, 3, 'Breakfast', 'Wednesday', 50),
(5, 1, 'Breakfast', 'Monday', 100);

INSERT INTO NutritionRecipes (recipeID, clientID, mealtime, weekDay, quantity) VALUES
(1, 1, 'Lunch', 'Monday', 1),
(2, 2, 'Dinner', 'Tuesday', 1),
(3, 3, 'Lunch', 'Wednesday', 1);

INSERT INTO Days (logDate, calories, clientID) VALUES
('2024-05-01', 2000, 1),
('2024-05-02', 2200, 2),
('2024-05-03', 1800, 3);

INSERT INTO Activities (name, calories, dayID) VALUES
('Running', 300, 1),
('Swimming', 400, 2),
('Cycling', 250, 3);

INSERT INTO IngredientsDay (ingredientID, dayID, mealtime, quantity) VALUES
(1, 1, 'Lunch', 200),
(2, 1, 'Dinner', 150),
(3, 2, 'Breakfast', 100),
(4, 3, 'Snack', 50),
(5, 1, 'Breakfast', 100);

INSERT INTO RecipesDay (recipeID, dayID, mealtime, quantity) VALUES
(1, 1, 'Lunch', 1),
(2, 2, 'Dinner', 1),
(3, 3, 'Lunch', 1);

INSERT INTO Messages (text, time, isUser, coachID, clientID) VALUES
('Hi, how are you?', '2024-05-01 10:00:00', FALSE, 1, 1),
('I am good, thanks!', '2024-05-01 10:05:00', TRUE, NULL, 1),
('Let me know if you need help.', '2024-05-01 10:10:00', FALSE, 1, 1),
('Can we schedule a session?', '2024-05-02 14:00:00', TRUE, NULL, 2),
('Sure, tomorrow at 3 PM?', '2024-05-02 14:05:00', FALSE, 2, 2);

INSERT INTO CoachPrograms (text, updatedAt, clientID, coachID) VALUES
('Focus on upper body this week.', '2024-05-01 09:00:00', 1, 1),
('Leg day on Wednesday.', '2024-05-02 11:00:00', 2, 2),
('Cardio and core exercises.', '2024-05-03 13:00:00', 3, 1);

INSERT INTO WeightHistory (weight, logDate, clientID) VALUES
(65.5, '2024-05-01', 1),
(80.0, '2024-05-02', 2),
(70.0, '2024-05-03', 3),
(64.0, '2024-05-04', 1),
(79.5, '2024-05-05', 2);