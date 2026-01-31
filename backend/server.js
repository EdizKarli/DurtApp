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
// server.js içindeki POST Endpoint (GÜNCEL)
app.post('/api/reminders', async (req, res) => {
    // 1. Frontend'den gelen 'type' ve 'frequency' verilerini aldığımızdan emin oluyoruz
    const { title, reminder_time, type, frequency } = req.body; 

    try {
        const result = await db.query(
            // 2. SQL sorgusuna bu yeni sütunları eklediğimizden emin oluyoruz
            'INSERT INTO reminders (title, reminder_time, type, frequency) VALUES ($1, $2, $3, $4) RETURNING *',
            [title, reminder_time, type, frequency]
        );
        console.log('✅ Veritabanına Yazıldı:', result.rows[0]); 
        res.json(result.rows[0]);
    } catch (err) {
        console.error('❌ DB Insert Error:', err);
        res.status(500).json({ error: "Database error" });
    }
});

// 5. GET Endpoint (Güncellenmiş: Tarih varsa o günü, yoksa HEPSİNİ getir)
app.get('/api/reminders', async (req, res) => {
    const { date } = req.query; 
    try {
        let queryText;
        let queryParams;

        if (date) {
            // Tarih varsa sadece o günü getir (Eski mantık korunuyor)
            queryText = "SELECT * FROM reminders WHERE TO_CHAR(reminder_time::date, 'YYYY-MM-DD') = $1";
            queryParams = [date];
        } else {
            // Tarih yoksa TÜM kayıtları getir (Takvim ekranı için)
            queryText = "SELECT * FROM reminders";
            queryParams = [];
        }

        const result = await db.query(queryText, queryParams);
        res.json(result.rows);
    } catch (err) {
        console.error('❌ Veri Çekme Hatası:', err);
        res.status(500).json({ error: "Veritabanı hatası" });
    }
});

// 6. PUT Endpoint (Dürt Güncelleme)
app.put('/api/reminders/:id', async (req, res) => {
    const { id } = req.params;
    const { title, type, reminder_time, frequency } = req.body;
    try {
        const result = await db.query(
            'UPDATE reminders SET title = $1, type = $2, reminder_time = $3, frequency = $4 WHERE id = $5 RETURNING *',
            [title, type, reminder_time, frequency, id]
        );
        res.json(result.rows[0]);
    } catch (err) {
        console.error('❌ Güncelleme Hatası:', err);
        res.status(500).json({ error: "Güncelleme yapılamadı" });
    }
});

// 7. DELETE Endpoint (Dürt Silme)
app.delete('/api/reminders/:id', async (req, res) => {
    const { id } = req.params;
    try {
        await db.query('DELETE FROM reminders WHERE id = $1', [id]);
        res.json({ message: "Silindi" });
    } catch (err) {
        console.error('❌ Silme Hatası:', err);
        res.status(500).json({ error: "Silinemedi" });
    }
});

// 5. THE ONLY LISTEN CALL
app.listen(PORT, () => {
    console.log(`🚀 Server is running on http://localhost:${PORT}`);
    console.log(`Press Ctrl+C to stop`);
});