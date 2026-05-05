import express from "express";
import cors from "cors"
import clientRoute from './routes/anas/client.js'
import exerciceRoute from './routes/anas/exercice.js'
import statRoute from './routes/anas/stat.js'
import homeRoutes from './routes/pahae/home.js'
import addFoodRoutes from './routes/pahae/addFood.js'
import addRecipeRoutes from './routes/pahae/addRecipe.js'

const app = express();
app.use(cors());
app.use(express.json());
app.use("/api/client", clientRoute);
app.use("/api/exercice", exerciceRoute);
app.use("/api/stat", statRoute);
app.use('/api/pahae/home/', homeRoutes)
app.use('/api/pahae/addFood/', addFoodRoutes)
app.use('/api/pahae/addRecipe/', addRecipeRoutes)

const port = 5000
app.listen(port, () => {
    console.log("Server Started on port " + port);
})