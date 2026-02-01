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
// POST: Yeni Dürt Ekle (group_id eklendi)
app.post('/api/reminders', async (req, res) => {
    // group_id parametresini de alıyoruz
    const { title, type, reminder_time, frequency, group_id } = req.body;
    try {
        const result = await db.query(
            "INSERT INTO reminders (title, type, reminder_time, frequency, group_id) VALUES ($1, $2, $3, $4, $5) RETURNING *",
            [title, type, reminder_time, frequency, group_id] // group_id $5 olarak eklendi
        );
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Veri eklenemedi" });
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

// ÖZEL DELETE: Belirli bir tarihten sonraki grup üyelerini sil
app.delete('/api/reminders/group/:groupId/future', async (req, res) => {
    const { groupId } = req.params;
    const { date } = req.query; // Hangi tarihten sonrasını silelim?

    try {
        await db.query(
            "DELETE FROM reminders WHERE group_id = $1 AND reminder_time > $2",
            [groupId, date]
        );
        res.json({ message: "Gelecek kayıtlar temizlendi" });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Silme hatası" });
    }
});

// 5. THE ONLY LISTEN CALL
app.listen(PORT, () => {
    console.log(`🚀 Server is running on http://localhost:${PORT}`);
    console.log(`Press Ctrl+C to stop`);
});