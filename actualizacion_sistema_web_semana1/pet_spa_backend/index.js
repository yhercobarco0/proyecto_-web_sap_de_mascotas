require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { initializeDatabase } = require('./src/config/db-init.js');
const app = express();

// Routers
const authRouter = require('./src/auth/routes/auth.router.js');
const mascotasRouter = require('./src/mascotas/routes/mascotas.router.js');
const citasRouter = require('./src/citas/routes/citas.router.js');
const serviciosRouter = require('./src/servicios/routes/servicios.router.js');
const productosRouter = require('./src/productos/routes/productos.router.js');
const groomingRouter = require('./src/grooming/routes/grooming.router.js');
const reportesRouter = require('./src/reportes/routes/reportes.router.js');

// ─── CORS ─────────────────────────────────────────────────────────────────
// Permitir Flutter Web (cualquier puerto localhost) + Producción
const allowedOrigins = [
  'http://localhost:3000',
  'http://localhost:4000',
  'http://localhost:5000',
  'http://localhost:5173',
  'http://localhost:8080',
  'http://localhost:8081',
  'http://127.0.0.1:3000',
  'http://127.0.0.1:4000',
  'http://127.0.0.1:5000',
];

app.use(cors({
  origin: (origin, callback) => {
    // Permite solicitudes sin origen (Postman, apps móviles nativas, curl)
    if (!origin) return callback(null, true);
    if (allowedOrigins.includes(origin) || origin.startsWith('http://localhost:')) {
      callback(null, true);
    } else {
      callback(null, true); // En desarrollo: permitir todo
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
}));

// Manejar preflight OPTIONS globalmente (Express 5: wildcard con /{*splat})
app.options('/{*splat}', cors());

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Nota: No servimos archivos estáticos — el frontend es Flutter


// API Routes
app.use('/api', authRouter);
app.use('/api/mascotas', mascotasRouter);
app.use('/api/citas', citasRouter);
app.use('/api/servicios', serviciosRouter);
app.use('/api/productos', productosRouter);
app.use('/api/grooming', groomingRouter);
app.use('/api/reportes', reportesRouter);

// Health check
app.get('/api/health', (req, res) => res.json({ status: 'ok', timestamp: new Date().toISOString() }));

// 404 handler para rutas desconocidas
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Ruta no encontrada: ${req.method} ${req.path}` });
});


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

initializeDatabase().then(() => {
  const server = app.listen(PORT, () => console.log(`🐾 PetSpa servidor listo en http://localhost:${PORT} 🚀`));

  server.on('error', (error) => {
    console.error('❌ Error en el servidor:', error);
  });
});