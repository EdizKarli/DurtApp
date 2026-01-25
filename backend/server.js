const express = require('express');
const cors = require('cors'); 
const app = express();
const db = require('./db'); // Ensure this file correctly exports your pool
const PORT = 3000;

// 1. Middleware
app.use(cors()); // Critical for Chrome mobile emulation
app.use(express.json());

// 2. Database Handshake
db.query('SELECT NOW()', (err, res) => {
    if (err) {
        console.error('❌ Connection Error:', err.stack);
    } else {
        console.log('✅ Database Handshake Successful! Server time:', res.rows[0].now);
    }
});

// 3. GET Endpoint
app.get('/api/message', (req, res) => {
    res.json({ message: "Hello from the Node.js backend!" });
});

// 4. POST Endpoint (Save Reminder)
app.post('/api/reminders', async (req, res) => {
    const { title, reminder_time } = req.body;
    try {
        const result = await db.query(
            'INSERT INTO reminders (title, reminder_time) VALUES ($1, $2) RETURNING *',
            [title, reminder_time]
        );
        res.json(result.rows[0]);
    } catch (err) {
        console.error('❌ DB Insert Error:', err);
        res.status(500).json({ error: "Database error" });
    }
});

app.get('/api/reminders', async (req, res) => {
    const { date } = req.query; // Frontend'den ?date=2026-01-25 diye gelecek
    try {
        // Postgres'te tarih karşılaştırması yapıyoruz
        const result = await db.query(
            "SELECT * FROM reminders WHERE TO_CHAR(reminder_time::date, 'YYYY-MM-DD') = $1", 
            [date]
        );
        res.json(result.rows);
    } catch (err) {
        console.error('❌ Veri Çekme Hatası:', err);
        res.status(500).json({ error: "Veritabanı hatası" });
    }
});

// 5. THE ONLY LISTEN CALL
app.listen(PORT, () => {
    console.log(`🚀 Server is running on http://localhost:${PORT}`);
    console.log(`Press Ctrl+C to stop`);
});