const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/productos.controller.js');
const { authenticateToken, requireAdmin, requirePersonalOrAdmin } = require('../../auth/middlewares/auth.middleware.js');

// Rutas específicas ANTES de /:id para evitar conflictos con parámetros dinámicos
router.get('/bajo_stock', authenticateToken, requirePersonalOrAdmin, ctrl.getStockBajo);

// Pedidos (rutas específicas antes de /:id)
router.post('/pedidos/nuevo', authenticateToken, ctrl.crearPedido);
router.get('/pedidos/mis_pedidos', authenticateToken, ctrl.getMisPedidos);
router.get('/pedidos/admin', authenticateToken, requirePersonalOrAdmin, ctrl.getAllPedidos);

// Catálogo - rutas genéricas
router.get('/', ctrl.getProductos);
router.get('/:id', ctrl.getProductoById);

// Admin - CRUD
router.post('/', authenticateToken, requireAdmin, ctrl.crearProducto);
router.put('/:id', authenticateToken, requireAdmin, ctrl.actualizarProducto);
router.post('/:id/stock', authenticateToken, requirePersonalOrAdmin, ctrl.ajustarStock);

module.exports = router;
