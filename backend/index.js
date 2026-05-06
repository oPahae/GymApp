import express from "express";
import cors from "cors";
import clientRoute from './routes/anas/client.js';
import exerciceRoute from './routes/anas/exercice.js';
import statRoute from './routes/anas/stat.js';
import homeRoutes from './routes/pahae/home.js';
import addFoodRoutes from './routes/pahae/addFood.js';
import addRecipeRoutes from './routes/pahae/addRecipe.js';
import authRoutes from './routes/jihane/auth.js'; 
import clientJihane from './routes/jihane/client.js';
import coachJihane from './routes/jihane/coach.js';

const app = express();
app.use(cors());
app.use(express.json());

// Routes
app.use("/api/client", clientRoute);
app.use("/api/exercice", exerciceRoute);
app.use("/api/stat", statRoute);
app.use('/api/pahae/home/', homeRoutes);
app.use('/api/pahae/addFood/', addFoodRoutes);
app.use('/api/pahae/addRecipe/', addRecipeRoutes);
app.use('/api/jihane/auth', authRoutes); 
app.use('/api/jihane/clients', clientJihane);
app.use('/api/jihane/coaches', coachJihane);

const port = 5000;
app.listen(port, '0.0.0.0', () => {  
    console.log("Server Started on port " + port);
});