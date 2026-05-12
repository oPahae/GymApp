import express from "express";
import cors from "cors";
import http from "http";
import { Server } from "socket.io";
import path from "path";
import { fileURLToPath } from "url";

import clientRoute from './routes/anas/client.js';
import exerciceRoute from './routes/anas/exercice.js';
import statRoute from './routes/anas/stat.js';

import homeRoutes from './routes/pahae/home.js';
import addFoodRoutes from './routes/pahae/addFood.js';
import addRecipeRoutes from './routes/pahae/addRecipe.js';
import clientsRoutes from './routes/pahae/clients.js';

import authRoutes from './routes/jihane/auth.js'; 
import clientRoutes from './routes/jihane/client.js';
import coachRoutes from './routes/jihane/coach.js';
import chatRoutes from './routes/jihane/chat.js';

import coachRoute from './routes/zaynab/coach.js'
import inviteRoute from './routes/zaynab/invite.js'
import programRoute from './routes/zaynab/program.js'
import programCoachRoute from './routes/zaynab/programCoach.js'


const app = express();
app.use(cors());
app.use(express.json());

// Routes Pahae
app.use('/api/pahae/home/', homeRoutes);
app.use('/api/pahae/addFood/', addFoodRoutes);
app.use('/api/pahae/addRecipe/', addRecipeRoutes);
app.use('/api/pahae/clients/', clientsRoutes);

// Routes Anas
app.use("/api/client", clientRoute);
app.use("/api/exercice", exerciceRoute);
app.use("/api/stat", statRoute);

// Routes Jihane
app.use('/api/jihane/auth', authRoutes); 
app.use('/api/jihane/clients', clientRoutes);
app.use('/api/jihane/coaches', coachRoutes);
app.use('/api/jihane/chat', chatRoutes);

// Routes Zaynab
app.use("/api/coach", coachRoute)
app.use("/api/invite", inviteRoute)
app.use("/api/program", programRoute)
app.use("/api/programCoach", programCoachRoute);

// WebRTC

const server = http.createServer(app);
const io = new Server(server);

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
app.use(express.static(path.join(__dirname, "voice")));

const rooms = {};
const socketToUserMap = {};

io.on("connection", (socket) => {
    console.log("New user connected:", socket.id);
    
    socket.on("register-user", (userData) => {
        let userID, firstname;
        
        if (typeof userData === 'object' && userData !== null) {
            userID = userData.userID;
            firstname = userData.firstname || 'Anonymous';
        } else {
            userID = userData;
            firstname = 'Anonymous';
        }
        
        if (!userID) {
            console.error(`Socket ${socket.id} tried to register without a valid user ID`);
            return;
        }
        
        console.log(`Mapping socket ${socket.id} to user ${userID} (${firstname})`);
        
        socketToUserMap[socket.id] = {
            userID,
            firstname
        };
    });

    socket.on("join-room", (roomId) => {
        const userData = socketToUserMap[socket.id];
        
        if (!userData || !userData.userID) {
            console.error(`Socket ${socket.id} tried to join room without registering a user ID`);
            return;
        }
        
        if (socket.roomId) {
            socket.leave(socket.roomId);
            if (rooms[socket.roomId]) {
                rooms[socket.roomId] = rooms[socket.roomId].filter(user => user.userID !== userData.userID);
                socket.to(socket.roomId).emit("user-left", userData);
            }
        }

        socket.join(roomId);
        socket.roomId = roomId;
        console.log(`User ${userData.firstname} (ID: ${userData.userID}, socket: ${socket.id}) joined room ${roomId}`);

        if (!rooms[roomId]) {
            rooms[roomId] = [];
        }

        const existingUserIndex = rooms[roomId].findIndex(user => user.userID === userData.userID);
        if (existingUserIndex >= 0) {
            rooms[roomId][existingUserIndex] = userData;
        } else {
            rooms[roomId].push(userData);
        }

        const otherUsers = rooms[roomId].filter(user => user.userID !== userData.userID);
        socket.emit("room-users", otherUsers);
        
        socket.to(roomId).emit("user-joined", userData);
    });

    socket.on("offer", (data) => {
        const targetSocketId = findSocketIdByUserId(data.to);
        if (targetSocketId) {
            const senderData = socketToUserMap[socket.id];
            
            socket.to(targetSocketId).emit("offer", { 
                offer: data.offer, 
                from: senderData.userID,
                firstname: senderData.firstname
            });
        } else {
            console.error(`Cannot find socket for user ID: ${data.to}`);
        }
    });

    socket.on("answer", (data) => {
        const targetSocketId = findSocketIdByUserId(data.to);
        if (targetSocketId) {
            const senderData = socketToUserMap[socket.id];
            
            socket.to(targetSocketId).emit("answer", { 
                answer: data.answer, 
                from: senderData.userID,
                firstname: senderData.firstname
            });
        }
    });

    socket.on("ice-candidate", (data) => {
        const targetSocketId = findSocketIdByUserId(data.to);
        if (targetSocketId) {
            const senderData = socketToUserMap[socket.id];
            
            socket.to(targetSocketId).emit("ice-candidate", { 
                candidate: data.candidate, 
                from: senderData.userID,
                firstname: senderData.firstname
            });
        }
    });

    socket.on("disconnect", () => {
        const userData = socketToUserMap[socket.id];
        if (!userData) return;
        
        console.log(`User ${userData.firstname} (ID: ${userData.userID}, socket: ${socket.id}) disconnected`);
        
        for (const roomId in rooms) {
            if (rooms[roomId].some(user => user.userID === userData.userID)) {
                rooms[roomId] = rooms[roomId].filter(user => user.userID !== userData.userID);
                socket.to(roomId).emit("user-left", userData);
            }
        }
        
        delete socketToUserMap[socket.id];
    });
});

function findSocketIdByUserId(userId) {
    for (const socketId in socketToUserMap) {
        if (socketToUserMap[socketId].userID === userId) {
            return socketId;
        }
    }
    return null;
}

const port = 5000;
server.listen(port, '0.0.0.0', () => {  
    console.log("✅ Server Started on port " + port);
    console.log("______________________");
});