const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/servicios.controller.js');
const { authenticateToken, requireAdmin } = require('../../auth/middlewares/auth.middleware.js');

// Público (catálogo)
router.get('/', ctrl.getServicios);
router.get('/:id', ctrl.getServicioById);

// Solo admin
router.post('/', authenticateToken, requireAdmin, ctrl.crearServicio);
router.put('/:id', authenticateToken, requireAdmin, ctrl.actualizarServicio);
router.delete('/:id', authenticateToken, requireAdmin, ctrl.eliminarServicio);

module.exports = router;
