const { Pool } = require('pg');

// Replace these values with your actual database credentials
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'durtapp_db',
  password: '1234',
  port: 5432,
});

pool.on('connect', () => {
    console.log('✅ Node.js successfully connected to PostgreSQL!');
});

pool.on('error', (err) => {
    console.error('❌ Unexpected error on idle client', err);
    process.exit(-1);
  });

module.exports = {
  query: (text, params) => pool.query(text, params),
};
