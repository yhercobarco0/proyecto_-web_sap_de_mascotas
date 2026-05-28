const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/reportes.controller.js');
const { authenticateToken, requireAdmin } = require('../../auth/middlewares/auth.middleware.js');

router.get('/dashboard', authenticateToken, requireAdmin, ctrl.getDashboard);
router.get('/ventas', authenticateToken, requireAdmin, ctrl.getResumenVentas);
router.get('/servicios_populares', authenticateToken, requireAdmin, ctrl.getServiciosMasPopulares);
router.get('/rendimiento_groomers', authenticateToken, requireAdmin, ctrl.getRendimientoGroomers);
router.get('/citas_por_dia', authenticateToken, requireAdmin, ctrl.getCitasPorDia);
router.get('/stock_critico', authenticateToken, requireAdmin, ctrl.getStockCritico);
router.get('/opiniones_recientes', authenticateToken, requireAdmin, ctrl.getOpinionesRecientes);

module.exports = router;
