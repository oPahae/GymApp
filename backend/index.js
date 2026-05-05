import express from "express";
import cors from "cors"

const app = express();
app.use(cors());
app.use(express.json());

// routes, matalan :
// import clientsRoute from './routes/pahae/clients' <- li fiha /getAll, /addClient...
// app.use("/clients", clientsRoute) <- pash twli accessible f /clients/getAll, /clients/addClient...

const port = 5000
app.listen(port, () => {
    console.log("Server Started on port " + port);
})