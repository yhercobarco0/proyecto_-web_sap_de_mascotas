require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { initializeDatabase } = require('./src/config/db-init.js');
const app = express();
const authRouter = require('./src/auth/routes/auth.router.js');

app.use(cors());
app.use(express.json());
app.use('/api', authRouter);

const PORT = process.env.PORT || 3000;

process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught exception:', error);
});

process.on('unhandledRejection', (reason) => {
  console.error('❌ Unhandled rejection:', reason);
});

process.on('SIGINT', () => {
  console.log('⚠️ Recibido SIGINT, deteniendo servidor...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('⚠️ Recibido SIGTERM, deteniendo servidor...');
  process.exit(0);
});

process.on('exit', (code) => {
  console.log(`⚠️ Proceso de Node.js finaliza con código: ${code}`);
});

initializeDatabase().then(() => {
  const server = app.listen(PORT, () => console.log(`Servidor listo en http://localhost:${PORT} 🚀`));

  server.on('error', (error) => {
    console.error('❌ Error en el servidor:', error);
  });

  server.on('close', () => {
    console.log('⚠️ Servidor HTTP cerrado.');
  });

  setInterval(() => {
    // Mantener el event loop activo mientras el servidor está en ejecución.
  }, 1000);
});