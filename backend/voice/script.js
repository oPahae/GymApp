// script.js complete updated version

const socket = io();
let myId = null;  // This will store the database user ID
let myFirstname = null; // This will store the user's first name
let peerConnections = {};
let localStream = null;
let currentRoom = null;

// WebRTC configuration with multiple STUN servers
const config = {
    iceServers: [
        { urls: "stun:stun.l.google.com:19302" },
        { urls: "stun:stun1.l.google.com:19302" },
        { urls: "stun:stun2.l.google.com:19302" },
        { urls: "stun:stun3.l.google.com:19302" },
        { urls: "stun:stun4.l.google.com:19302" }
    ],
    iceCandidatePoolSize: 10
};

const statusDiv = document.getElementById("status");
const logsDiv = document.getElementById("connectionLogs");

// Add a log message
function addLog(message) {
    const now = new Date();
    const timestamp = now.toLocaleTimeString() + "." + now.getMilliseconds();
    const logItem = document.createElement("div");
    logItem.textContent = `[${timestamp}] ${message}`;
    logsDiv.prepend(logItem);
    console.log(message);
}

// Join a room
window.onload = async () => {
    const roomId = new URLSearchParams(window.location.search).get("roomID");
    if (!roomId) return alert("Enter a Room ID!");

    // Get user ID and firstname from URL parameters
    const userID = new URLSearchParams(window.location.search).get('userID');
    const firstname = new URLSearchParams(window.location.search).get('username');

    if (!userID) {
        alert("User ID not found in URL parameters");
        return;
    }

    // Register our database user ID and firstname with the socket connection
    if (!myId) {
        myId = userID;
        myFirstname = firstname || "Anonymous"; // Default to "Anonymous" if firstname not provided
        socket.emit("register-user", { userID, firstname: myFirstname });
        addLog(`Registered user: ${myFirstname} (ID: ${userID})`);
    }

    // If we are already in this room, do nothing
    if (currentRoom === roomId && localStream) {
        addLog(`Already connected to room ${roomId}`);
        return;
    }

    // If we were in another room, clean up
    if (currentRoom && currentRoom !== roomId) {
        cleanupConnections();
    }

    try {
        // Get local audio stream if it doesn't already exist
        if (!localStream) {
            localStream = await navigator.mediaDevices.getUserMedia({
                audio: {
                    echoCancellation: true,
                    noiseSuppression: true,
                    autoGainControl: true
                }
            });

            // Add local audio to the interface
            displayAudioElement("local", localStream, true, myFirstname);

            addLog("Local audio enabled");
        }

        statusDiv.textContent = "Local audio enabled. Joining room...";

        // Store the current room
        currentRoom = roomId;

        // Join the room
        socket.emit("join-room", roomId);

        addLog(`Connecting to room: ${roomId} with user ID: ${myId}`);
    } catch (error) {
        console.error("Error accessing microphone:", error);
        statusDiv.textContent = "Error: Cannot access microphone";
        addLog(`Microphone access error: ${error.message}`);
        alert(`Microphone access error: ${error.message}`);
    }
};

// Modify the displayAudioElement function to show the firstname
function displayAudioElement(id, stream, isLocal, firstname) {
    // Look for an existing container or create a new one
    let container = document.getElementById(`container-${id}`);
    
    if (!container) {
        // Generate a color for the avatar
        const colors = ["bg-green-500", "bg-red-500", "bg-yellow-500", "bg-pink-500", "bg-indigo-400"];
        const colorIndex = Math.abs(id.toString().split('').reduce((a, b) => a + b.charCodeAt(0), 0)) % colors.length;
        const avatarColor = isLocal ? "bg-blue-500" : colors[colorIndex];
        
        // Create the complete HTML with Tailwind
        const html = `
            <div id="container-${id}" class="glass-light grow max-w-[200px] h-[200px] flex flex-col justify-around items-center cursor-pointer rounded-lg m-2 p-4 shadow-md hover:bg-gray-700 hover:-translate-y-1 transition-all">
                <div class="flex items-center mb-2">
                    <div class="${avatarColor} w-10 h-10 rounded-full flex items-center justify-center mr-3 text-white font-bold">
                        ${isLocal ? 'Y' : (firstname ? firstname.charAt(0).toUpperCase() : 'U')}
                    </div>
                    <div class="flex flex-col">
                        <div class="font-semibold text-base ${isLocal ? 'text-blue-500' : 'text-white'}">
                            ${isLocal ? 'You' : (firstname || `User ${id}`)}
                        </div>
                        <div id="status-${id}" class="text-xs text-gray-400 mt-0.5">
                            Connected
                        </div>
                    </div>
                    <div id="voice-indicator-${id}" class="w-2.5 h-2.5 rounded-full bg-gray-500 ml-auto transition-colors"></div>
                </div>
                <div class="w-full">
                    <audio id="${id}" autoplay ${isLocal ? 'muted' : ''} style="display: none;"></audio>
                    <div class="flex items-center justify-between p-2 glass rounded">
                        <button class="bg-transparent border-0 text-${isLocal ? 'blue-500' : 'gray-400'} text-base cursor-pointer" 
                                title="${isLocal ? 'Mute/Unmute' : 'Volume'}">
                            ${isLocal ? '🎙️' : '🔊'}
                        </button>
                        <input type="range" min="0" max="100" value="100" 
                               class="w-20 accent-blue-500 ${isLocal ? 'opacity-50' : ''}" 
                               ${isLocal ? 'disabled' : ''}>
                    </div>
                </div>
            </div>
        `;
        
        // Add to the page
        document.getElementById("audios").innerHTML += html;
        
        // Get the created elements
        container = document.getElementById(`container-${id}`);
        const audio = document.getElementById(id);
        const micButton = container.querySelector('button');
        const volumeControl = container.querySelector('input[type="range"]');
        const voiceIndicator = document.getElementById(`voice-indicator-${id}`);
        const userStatus = document.getElementById(`status-${id}`);
        
        // Set audio source
        audio.srcObject = stream;
        
        // Events for the microphone button (local user)
        if (isLocal) {
            micButton.onclick = function() {
                const tracks = localStream.getAudioTracks();
                const enabled = !tracks[0].enabled;
                tracks[0].enabled = enabled;
                this.className = `bg-transparent border-0 text-${enabled ? 'blue-500' : 'red-500'} text-base cursor-pointer`;
                userStatus.textContent = enabled ? "Connected" : "Muted";
            };
        }
        
        // Volume control (for remote streams)
        if (!isLocal) {
            volumeControl.oninput = function() {
                audio.volume = this.value / 100;
                if (this.value < 5) {
                    micButton.innerHTML = "🔇";
                } else if (this.value < 50) {
                    micButton.innerHTML = "🔉";
                } else {
                    micButton.innerHTML = "🔊";
                }
            };
            
            // Audio activity analysis for remote streams
            const audioContext = new AudioContext();
            const source = audioContext.createMediaStreamSource(stream);
            const analyser = audioContext.createAnalyser();
            analyser.fftSize = 256;
            source.connect(analyser);
            
            const bufferLength = analyser.frequencyBinCount;
            const dataArray = new Uint8Array(bufferLength);
            
            function checkAudioActivity() {
                analyser.getByteFrequencyData(dataArray);
                let sum = 0;
                for (let i = 0; i < bufferLength; i++) {
                    sum += dataArray[i];
                }
                const average = sum / bufferLength;
                
                if (average > 20) {
                    voiceIndicator.className = "w-2.5 h-2.5 rounded-full bg-green-500 ml-auto transition-colors";
                    userStatus.textContent = "Speaking";
                } else {
                    voiceIndicator.className = "w-2.5 h-2.5 rounded-full bg-gray-500 ml-auto transition-colors";
                    userStatus.textContent = "Connected";
                }
                
                requestAnimationFrame(checkAudioActivity);
            }
            
            checkAudioActivity();
        }
        
        // Audio events
        audio.onplay = () => {
            addLog(`Audio playback from ${firstname || id} started`);
            userStatus.textContent = "Connected";
        };
        
        audio.onerror = (error) => {
            addLog(`Audio playback error from ${firstname || id}: ${error}`);
            userStatus.textContent = "Error connecting";
            voiceIndicator.className = "w-2.5 h-2.5 rounded-full bg-red-500 ml-auto transition-colors";
        };
    } else {
        // Update existing stream
        const audio = document.getElementById(id);
        if (audio) {
            audio.srcObject = stream;
        }
    }
}

// Receive the list of users already in the room
socket.on("room-users", (users) => {
    if (!users || users.length === 0) {
        addLog("No users in the room");
        return;
    }

    const userNames = users.map(user => {
        // Check if user is an object with the proper structure
        if (user && typeof user === 'object') {
            return user.firstname || `User ${user.userID}`;
        } else {
            return `User ${user}`;  // Fallback for old format
        }
    }).join(', ');
    
    addLog(`Users already in the room: ${userNames}`);

    // Connect to each existing user
    users.forEach(user => {
        // Handle both object format and string format
        const userId = typeof user === 'object' ? user.userID : user;
        const userFirstname = typeof user === 'object' ? user.firstname : null;
        
        if (userId && userId !== myId) {
            addLog(`Initiating call to user: ${userFirstname || userId}`);
            initiateCall(userId, userFirstname);
        }
    });
});

// A new user has joined the room
socket.on("user-joined", (userData) => {
    // Handle both object format and string format
    if (typeof userData === 'object') {
        const { userID, firstname } = userData;
        addLog(`User ${firstname || userID} has joined the room`);
        statusDiv.textContent = `User ${firstname || userID} has joined. Waiting for connection...`;
    } else {
        // Old format (just the userID as string)
        addLog(`User ${userData} has joined the room`);
        statusDiv.textContent = `User ${userData} has joined. Waiting for connection...`;
    }
});

// Receiving an offer
socket.on("offer", async (data) => {
    const { offer, from, firstname } = data;
    addLog(`Offer received from ${firstname || from}`);
    statusDiv.textContent = `Offer received from ${firstname || from}`;

    try {
        // Create a peer connection for this user
        const peerConnection = createPeerConnection(from, firstname);

        // Set the remote description (the received offer)
        await peerConnection.setRemoteDescription(new RTCSessionDescription(offer));
        addLog(`Remote description set for ${firstname || from}`);

        // Add local audio tracks
        localStream.getTracks().forEach(track => {
            peerConnection.addTrack(track, localStream);
        });

        // Create an answer
        const answer = await peerConnection.createAnswer();
        await peerConnection.setLocalDescription(answer);

        // Send the answer
        socket.emit("answer", {
            answer: peerConnection.localDescription,
            to: from
        });

        addLog(`Answer sent to ${firstname || from}`);
    } catch (error) {
        addLog(`Error processing offer from ${firstname || from}: ${error.message}`);
        console.error("Error processing offer:", error);
    }
});

// Receiving an answer
socket.on("answer", (data) => {
    const { answer, from, firstname } = data;
    addLog(`Answer received from ${firstname || from}`);
    statusDiv.textContent = `Answer received from ${firstname || from}`;

    try {
        const peerConnection = peerConnections[from];
        if (peerConnection) {
            peerConnection.setRemoteDescription(new RTCSessionDescription(answer))
                .then(() => {
                    addLog(`Remote description set for ${firstname || from} (answer)`);
                })
                .catch(error => {
                    addLog(`Error setting remote description: ${error.message}`);
                });
        } else {
            addLog(`No connection for ${firstname || from}`);
        }
    } catch (error) {
        addLog(`Error processing answer from ${firstname || from}: ${error.message}`);
        console.error("Error processing answer:", error);
    }
});

// Receiving an ICE candidate
socket.on("ice-candidate", (data) => {
    const { candidate, from, firstname } = data;
    
    try {
        const peerConnection = peerConnections[from];
        if (peerConnection) {
            peerConnection.addIceCandidate(new RTCIceCandidate(candidate))
                .then(() => {
                    addLog(`ICE candidate added for ${firstname || from}`);
                })
                .catch(error => {
                    addLog(`Error adding ICE candidate: ${error.message}`);
                });
        } else {
            addLog(`No connection to add ICE candidate from ${firstname || from}`);
        }
    } catch (error) {
        addLog(`Error processing ICE candidate from ${firstname || from}: ${error.message}`);
        console.error("Error processing ICE candidate:", error);
    }
});

// A user leaves the room
socket.on("user-left", (userData) => {
    // Handle both object format and string format
    let userID, firstname;
    
    if (typeof userData === 'object') {
        userID = userData.userID;
        firstname = userData.firstname;
    } else {
        userID = userData;
        firstname = null;
    }
    
    addLog(`User ${firstname || userID} has left the room`);
    statusDiv.textContent = `User ${firstname || userID} has left the room`;

    // Close the connection with this user
    if (peerConnections[userID]) {
        peerConnections[userID].close();
        delete peerConnections[userID];
    }

    // Remove the audio element
    const audioContainer = document.getElementById(`container-${userID}`);
    if (audioContainer) {
        audioContainer.remove();
    }
});

// Initiate a call to a user
function initiateCall(userID, firstname) {
    if (!userID) {
        addLog("Attempt to initiate a call with a missing user ID");
        return;
    }

    addLog(`Initiating a call to ${firstname || userID}`);

    // Create a peer connection
    const peerConnection = createPeerConnection(userID, firstname);

    // Add local audio tracks
    localStream.getTracks().forEach(track => {
        peerConnection.addTrack(track, localStream);
    });

    // Create an offer
    peerConnection.createOffer()
        .then(offer => {
            return peerConnection.setLocalDescription(offer);
        })
        .then(() => {
            // Send the offer
            socket.emit("offer", {
                offer: peerConnection.localDescription,
                to: userID
            });

            addLog(`Offer sent to ${firstname || userID}`);
        })
        .catch(error => {
            addLog(`Error creating offer: ${error.message}`);
            console.error("Error creating offer:", error);
        });
}

// Create a peer connection
function createPeerConnection(userID, firstname) {
    if (!userID) {
        addLog("Attempt to create a peer connection with a missing user ID");
        return null;
    }

    // If the connection already exists, close it
    if (peerConnections[userID]) {
        peerConnections[userID].close();
    }

    addLog(`Creating a peer connection for ${firstname || userID}`);

    // Create a new connection
    const peerConnection = new RTCPeerConnection(config);
    peerConnections[userID] = peerConnection;

    // Store the firstname with the connection
    peerConnection.remoteFirstname = firstname;

    // ICE candidate handler
    peerConnection.onicecandidate = (event) => {
        if (event.candidate) {
            socket.emit("ice-candidate", {
                candidate: event.candidate,
                to: userID
            });
        }
    };

    // ICE connection state change handler
    peerConnection.oniceconnectionstatechange = () => {
        const state = peerConnection.iceConnectionState;
        addLog(`ICE connection state with ${firstname || userID}: ${state}`);

        if (state === "connected" || state === "completed") {
            statusDiv.textContent = `Audio connection established with ${firstname || userID}`;
        } else if (state === "failed") {
            statusDiv.textContent = `Connection failed with ${firstname || userID}`;

            // Attempt to reconnect
            setTimeout(() => {
                if (currentRoom) {
                    addLog(`Attempting to reconnect with ${firstname || userID}`);
                    initiateCall(userID, firstname);
                }
            }, 2000);
        }
    };

    // Track received handler
    peerConnection.ontrack = (event) => {
        addLog(`Audio track received from ${firstname || userID}`);

        // Display remote audio with firstname
        displayAudioElement(userID, event.streams[0], false, firstname);
    };

    return peerConnection;
}

// Clean up connections
function cleanupConnections() {
    // Close all connections
    for (const userID in peerConnections) {
        peerConnections[userID].close();

        // Remove the audio element
        const audioContainer = document.getElementById(`container-${userID}`);
        if (audioContainer) {
            audioContainer.remove();
        }
    }

    // Reset
    peerConnections = {};
    addLog("Connections cleaned up");
}

// Connection to Socket.IO server
socket.on("connect", () => {
    const socketId = socket.id;
    addLog(`Connected to Socket.IO server with socket ID: ${socketId}`);

    // If we already have a user ID, register it with the new socket connection
    if (myId) {
        socket.emit("register-user", { userID: myId, firstname: myFirstname });
        addLog(`Re-registered user: ${myFirstname} (ID: ${myId})`);
    }
});

// Disconnection from Socket.IO server
socket.on("disconnect", () => {
    addLog("Disconnected from Socket.IO server");
    statusDiv.textContent = "Disconnected from server";

    // Clean up connections
    cleanupConnections();
    currentRoom = null;
});