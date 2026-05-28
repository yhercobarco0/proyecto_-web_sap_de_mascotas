const { Pool } = require('pg');
const path = require('path');
// Usar ruta relativa para que funcione en cualquier máquina
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

// Función autoejecutable para probar la conexión
(async () => {
  try {
    const client = await pool.connect();
    console.log('✅ Conectado a PostgreSQL exitosamente');
    client.release(); // Importante soltar la conexión
  } catch (err) {
    console.error('❌ Error de conexión:', err.message);
  }
})();

module.exports = pool;