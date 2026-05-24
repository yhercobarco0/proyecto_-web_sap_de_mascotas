const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/mascotas.controller.js');
const { authenticateToken, requireAdmin, requirePersonalOrAdmin, requireClienteOrAdmin } = require('../../auth/middlewares/auth.middleware.js');

// Admin/Personal - ver todas las mascotas
router.get('/admin', authenticateToken, requirePersonalOrAdmin, ctrl.getAllMascotas);

// Cliente - sus propias mascotas
router.get('/mis_mascotas', authenticateToken, ctrl.getMisMascotas);

// Vacunas (rutas específicas ANTES que /:id para evitar conflictos)
router.get('/vacunas/catalogo', authenticateToken, ctrl.getCatalogoVacunas);
router.post('/vacunas/registrar', authenticateToken, requirePersonalOrAdmin, ctrl.registrarVacuna);

// CRUD de mascotas (rutas con :id al final)
router.get('/:id', authenticateToken, ctrl.getMascotaById);
router.get('/:id/vacunas', authenticateToken, ctrl.getVacunas);
router.post('/', authenticateToken, ctrl.crearMascota);
router.put('/:id', authenticateToken, ctrl.actualizarMascota);
router.delete('/:id', authenticateToken, requireAdmin, ctrl.eliminarMascota);

module.exports = router;
