USE gymappdb;

-- ======================
-- INSERT INTO BodyParts
-- ======================
INSERT INTO BodyParts (id, name, image) VALUES
(1, 'Chest', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=2070&auto=format&fit=crop'),
(2, 'Back', 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=2120&auto=format&fit=crop'),
(3, 'Legs', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=2070&auto=format&fit=crop'),
(4, 'Shoulders', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=2070&auto=format&fit=crop'),
(5, 'Arms', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=2070&auto=format&fit=crop'),
(6, 'Abs', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=2070&auto=format&fit=crop');

-- ======================
-- INSERT INTO Coaches
-- ======================
INSERT INTO Coaches (id, name, image, createdAt) VALUES
(1, 'John Doe', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=2070&auto=format&fit=crop', '2025-01-15'),
(2, 'Jane Smith', 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=2120&auto=format&fit=crop', '2025-02-20'),
(3, 'Mike Johnson', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=2070&auto=format&fit=crop', '2025-03-10');

-- ======================
-- INSERT INTO Clients
-- ======================
INSERT INTO Clients (id, name, image, birth, weight, height, frequency, goal, weightGoal, createdAt, coachID) VALUES
(1, 'Alice Brown', 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=2120&auto=format&fit=crop', '1990-05-15', 65.5, 165.0, 4, 'Lose weight', 60.0, '2025-04-01', 1),
(2, 'Bob Green', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=2070&auto=format&fit=crop', '1985-08-22', 80.0, 180.0, 5, 'Gain muscle', 85.0, '2025-04-05', 2),
(3, 'Charlie Davis', 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=2120&auto=format&fit=crop', '1995-11-30', 70.0, 175.0, 3, 'Stay fit', 70.0, '2025-04-10', 3);

-- ======================
-- INSERT INTO Exercises
-- ======================
INSERT INTO Exercises (id, name, image, muscle, video, description, bodyPartID) VALUES
(1, 'Bench Press', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=2070&auto=format&fit=crop', 'Pectorals', 'https://www.youtube.com/watch?v=EHBtFpYTQ1Q', 'Lie on a bench and press the barbell upwards.', 1),
(2, 'Pull Ups', 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=2120&auto=format&fit=crop', 'Latissimus Dorsi', 'https://www.youtube.com/watch?v=8B9V5IyXxJY', 'Hang from a bar and pull your body up.', 2),
(3, 'Squats', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=2070&auto=format&fit=crop', 'Quadriceps', 'https://www.youtube.com/watch?v=U3HlXQM7GQE', 'Stand with feet shoulder-width apart and lower your body.', 3),
(4, 'Shoulder Press', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=2070&auto=format&fit=crop', 'Deltoids', 'https://www.youtube.com/watch?v=zQOaXsXgE1I', 'Press the barbell from shoulder height to overhead.', 4),
(5, 'Bicep Curls', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=2070&auto=format&fit=crop', 'Biceps', 'https://www.youtube.com/watch?v=ykJmrZ5v0Oo', 'Curl the dumbbell from arm\'s length to shoulder.', 5),
(6, 'Plank', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=2070&auto=format&fit=crop', 'Abdominals', 'https://www.youtube.com/watch?v=pSHjTRCQxIw', 'Hold a push-up position with body in a straight line.', 6);

-- ======================
-- INSERT INTO Notes
-- ======================
INSERT INTO Notes (id, text, exerciseID) VALUES
(1, 'Keep your back straight and core engaged.', 1),
(2, 'Use a wide grip for better lat activation.', 2),
(3, 'Go as low as possible for maximum effect.', 3),
(4, 'Do not lock your elbows at the top.', 4),
(5, 'Control the movement, do not swing.', 5),
(6, 'Hold for at least 30 seconds for best results.', 6);

-- ======================
-- INSERT INTO Workouts
-- ======================
INSERT INTO Workouts (id, weekDay, exerciseID, clientID) VALUES
(1, 'Monday', 1, 1),
(2, 'Monday', 3, 1),
(3, 'Tuesday', 2, 1),
(4, 'Wednesday', 4, 2),
(5, 'Wednesday', 5, 2),
(6, 'Thursday', 6, 2),
(7, 'Friday', 1, 3),
(8, 'Friday', 6, 3);

-- ======================
-- INSERT INTO Invites
-- ======================
INSERT INTO Invites (coachID, clientID) VALUES
(1, 1),
(2, 2),
(3, 3);

-- ======================
-- INSERT INTO Ingredients
-- ======================
INSERT INTO Ingredients (id, name, image, calories, type) VALUES
(1, 'Chicken Breast', 'https://images.unsplash.com/photo-1594736797933-d0401ba2fe65?q=80&w=2071&auto=format&fit=crop', 165, 'Protein'),
(2, 'Brown Rice', 'https://images.unsplash.com/photo-1586201375761-83867e78571f?q=80&w=2070&auto=format&fit=crop', 110, 'Carbohydrate'),
(3, 'Broccoli', 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?q=80&w=1974&auto=format&fit=crop', 34, 'Vegetable'),
(4, 'Salmon', 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?q=80&w=2070&auto=format&fit=crop', 206, 'Protein'),
(5, 'Eggs', 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?q=80&w=1974&auto=format&fit=crop', 70, 'Protein'),
(6, 'Oats', 'https://images.unsplash.com/photo-1586201375761-83867e78571f?q=80&w=2070&auto=format&fit=crop', 68, 'Carbohydrate');

-- ======================
-- INSERT INTO Recipes
-- ======================
INSERT INTO Recipes (id, name, image, calories, clientID) VALUES
(1, 'Chicken and Rice', 'https://images.unsplash.com/photo-1594736797933-d0401ba2fe65?q=80&w=2071&auto=format&fit=crop', 400, 1),
(2, 'Salmon and Broccoli', 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?q=80&w=2070&auto=format&fit=crop', 450, 2),
(3, 'Omelette with Oats', 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?q=80&w=1974&auto=format&fit=crop', 300, 3);

-- ======================
-- INSERT INTO NutritionIngredients
-- ======================
INSERT INTO NutritionIngredients (ingredientID, clientID, mealtime, quantity) VALUES
(1, 1, 'Breakfast', 150),
(2, 1, 'Lunch', 200),
(3, 1, 'Dinner', 100),
(4, 2, 'Lunch', 150),
(5, 2, 'Breakfast', 100),
(6, 3, 'Breakfast', 50);

-- ======================
-- INSERT INTO NutritionRecipes
-- ======================
INSERT INTO NutritionRecipes (recipeID, clientID, mealtime, quantity) VALUES
(1, 1, 'Lunch', 1),
(2, 2, 'Dinner', 1),
(3, 3, 'Breakfast', 1);

-- ======================
-- INSERT INTO Days
-- ======================
INSERT INTO Days (id, logDate, calories, clientID) VALUES
(1, '2026-05-01', 2000, 1),
(2, '2026-05-02', 2200, 2),
(3, '2026-05-03', 1800, 3);

-- ======================
-- INSERT INTO Activities
-- ======================
INSERT INTO Activities (id, name, calories, dayID) VALUES
(1, 'Running', 300, 1),
(2, 'Swimming', 400, 2),
(3, 'Cycling', 250, 3);

-- ======================
-- INSERT INTO IngredientsDay
-- ======================
INSERT INTO IngredientsDay (ingredientID, dayID, mealtime, quantity) VALUES
(1, 1, 'Breakfast', 150),
(2, 1, 'Lunch', 200),
(3, 2, 'Dinner', 100),
(4, 2, 'Lunch', 150),
(5, 3, 'Breakfast', 100);

-- ======================
-- INSERT INTO RecipesDay
-- ======================
INSERT INTO RecipesDay (recipeID, dayID, mealtime, quantity) VALUES
(1, 1, 'Lunch', 1),
(2, 2, 'Dinner', 1),
(3, 3, 'Breakfast', 1);

-- ======================
-- INSERT INTO Messages
-- ======================
INSERT INTO Messages (id, text, time, isUser, coachID, clientID) VALUES
(1, 'Hi, how is my workout plan?', '2026-05-01 09:00:00', TRUE, 1, 1),
(2, 'Your plan is ready, check it out!', '2026-05-01 09:05:00', FALSE, 1, 1),
(3, 'Can I change my goal?', '2026-05-02 10:00:00', TRUE, 2, 2),
(4, 'Sure, let’s discuss it.', '2026-05-02 10:10:00', FALSE, 2, 2);