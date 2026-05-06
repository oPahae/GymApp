import express from "express";
import cors from "cors"
import pool from "./config/db.js";
import clientRoute from './routes/anas/client.js'
import exerciceRoute from './routes/anas/exercice.js'
import statRoute from './routes/anas/stat.js'
import homeRoutes from './routes/pahae/home.js'
import addFoodRoutes from './routes/pahae/addFood.js'
import addRecipeRoutes from './routes/pahae/addRecipe.js'
import coachRoute from './routes/zaynab/coach.js'
import inviteRoute from './routes/zaynab/invite.js'
import programRoute from './routes/zaynab/program.js'
import programCoachRoute from './routes/zaynab/programCoach.js'


const app = express();
app.use(cors());
app.use(express.json());
app.use("/api/client", clientRoute);
app.use("/api/exercice", exerciceRoute);
app.use("/api/stat", statRoute);
app.use('/api/pahae/home/', homeRoutes)
app.use('/api/pahae/addFood/', addFoodRoutes)
app.use('/api/pahae/addRecipe/', addRecipeRoutes)
app.use("/api/coach", coachRoute)
app.use("/api/invite", inviteRoute)
app.use("/api/program", programRoute)
app.use("/api/programCoach", programCoachRoute);

const port = 5000
app.listen(port, () => {
    console.log("Server Started on port " + port);
})