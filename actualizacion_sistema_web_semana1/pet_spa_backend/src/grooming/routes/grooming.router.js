const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/grooming.controller.js');
const { authenticateToken, requireAdmin, requirePersonalOrAdmin, requireGroomerOrAdmin } = require('../../auth/middlewares/auth.middleware.js');

// Groomers
router.get('/groomers', authenticateToken, ctrl.getGroomers);

// Fichas grooming
router.post('/fichas', authenticateToken, requireGroomerOrAdmin, ctrl.crearFicha);
router.get('/fichas/mis_fichas', authenticateToken, ctrl.getMisFichas);
router.get('/fichas/cita/:id_cita', authenticateToken, ctrl.getFichaByCita);
router.post('/fichas/:id/cerrar', authenticateToken, requireGroomerOrAdmin, ctrl.cerrarFicha);
router.post('/fichas/insumos', authenticateToken, requireGroomerOrAdmin, ctrl.registrarInsumo);
router.get('/insumos/log', authenticateToken, requirePersonalOrAdmin, ctrl.getLogInsumos);

// Pagos empleados
router.get('/pagos', authenticateToken, requireAdmin, ctrl.getAllPagos);
router.get('/pagos/trabajador/:id_trabajador', authenticateToken, ctrl.getPagosEmpleado);
router.post('/pagos', authenticateToken, requireAdmin, ctrl.registrarPago);

// Cajas
router.get('/cajas', authenticateToken, requirePersonalOrAdmin, ctrl.getCajas);
router.post('/cajas', authenticateToken, requireAdmin, ctrl.crearCaja);
router.put('/cajas/:id/saldo', authenticateToken, requireAdmin, ctrl.actualizarSaldo);

// Transacciones
router.get('/transacciones', authenticateToken, requireAdmin, ctrl.getAllTransacciones);
router.get('/transacciones/:id', authenticateToken, requireAdmin, ctrl.getTransaccion);
router.post('/transacciones', authenticateToken, requirePersonalOrAdmin, ctrl.crearTransaccion);
router.put('/transacciones/:id', authenticateToken, requireAdmin, ctrl.actualizarTransaccion);

module.exports = router;
