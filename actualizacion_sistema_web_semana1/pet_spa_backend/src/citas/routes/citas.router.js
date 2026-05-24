const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/citas.controller.js');
const { authenticateToken, requireAdmin, requirePersonalOrAdmin, requireGroomerOrAdmin } = require('../../auth/middlewares/auth.middleware.js');

// ─── Rutas específicas ANTES de /:id ─────────────────────────────────────────

// Admin/Recepción - gestión completa
router.get('/admin', authenticateToken, requirePersonalOrAdmin, ctrl.getCitasAdmin);
router.get('/por_fecha', authenticateToken, requirePersonalOrAdmin, ctrl.getCitasByFecha);

// Cliente - sus propias citas
router.get('/mis_citas', authenticateToken, ctrl.getMisCitas);
router.post('/registrar_opinion', authenticateToken, ctrl.registrarOpinion);
router.get('/mis_opiniones', authenticateToken, ctrl.getMisOpiniones);

// Groomer - sus citas
router.get('/mis_servicios', authenticateToken, ctrl.getCitasGroomer);

// Bloqueos de agenda (rutas específicas antes de /:id)
router.get('/bloqueos', authenticateToken, requirePersonalOrAdmin, ctrl.getBloqueos);
router.post('/bloqueos', authenticateToken, requirePersonalOrAdmin, ctrl.crearBloqueo);
router.delete('/bloqueos/:id', authenticateToken, requireAdmin, ctrl.eliminarBloqueo);

// Opiniones admin
router.get('/opiniones/admin', authenticateToken, requireAdmin, ctrl.getAllOpiniones);

// ─── CRUD citas con :id al final ──────────────────────────────────────────────
router.post('/', authenticateToken, ctrl.crearCita);
router.put('/:id', authenticateToken, requirePersonalOrAdmin, ctrl.actualizarCita);
router.post('/:id/terminar', authenticateToken, requireGroomerOrAdmin, ctrl.terminarCita);
router.post('/:id/cancelar', authenticateToken, ctrl.cancelarCita);

module.exports = router;
