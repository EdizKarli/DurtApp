const express = require('express');
const cors = require('cors'); // Allows your frontend to talk to the backend
const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// This is your first "Endpoint"
app.get('/api/message', (req, res) => {
    res.json({ message: "Hello from the Node.js backend!" });
});

app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});