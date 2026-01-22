const express = require('express');
const cors = require('cors'); // Allows your frontend to talk to the backend
const app = express();
const db = require('./db');
const PORT = 3000;

db.query('SELECT NOW()', (err, res) => {
    if (err) {
      console.error('❌ Connection Error:', err.stack);
    } else {
      console.log('✅ Database Handshake Successful! Server time:', res.rows[0].now);
    }
  });

app.use(cors());
app.use(express.json());

// This is your first "Endpoint"
app.get('/api/message', (req, res) => {
    res.json({ message: "Hello from the Node.js backend!" });
});

app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});

// Endpoint to create a new reminder
app.post('/api/reminders', async (req, res) => {
    const { title, reminder_time } = req.body;
    
    try {
      const result = await db.query(
        'INSERT INTO reminders (title, reminder_time) VALUES ($1, $2) RETURNING *',
        [title, reminder_time]
      );
      res.json(result.rows[0]);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: "Database error" });
    }
  });
  
  app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
