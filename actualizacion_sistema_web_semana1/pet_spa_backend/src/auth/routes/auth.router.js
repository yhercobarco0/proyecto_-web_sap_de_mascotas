const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const empleadosController = require('../controllers/empleados.controller');
const clientesController = require('../controllers/clientes.controller');
const { authenticateToken, requireAdmin } = require('../middlewares/auth.middleware');

router.post('/registro_cliente', authController.registroCliente);
router.post('/registro_cliente_admin', authenticateToken, requireAdmin, authController.registroClienteAdmin);
router.post('/registro_empleado', authenticateToken, requireAdmin, authController.registroEmpleado);
router.post('/registro_admin', authController.registroAdmin);
router.post('/login', authController.login);
router.post('/login_google', authController.loginWithGoogle);
router.post('/verify_2fa', authController.verifyTwoFactor);
router.get('/activar/:token', authController.activarCuenta);

router.get('/empleados', authenticateToken, requireAdmin, empleadosController.getEmpleados);
router.put('/empleados/:id', authenticateToken, requireAdmin, empleadosController.updateEmpleado);
router.delete('/empleados/:id', authenticateToken, requireAdmin, empleadosController.deleteEmpleado);
router.get('/habilidades', authenticateToken, requireAdmin, empleadosController.getHabilidades);

router.get('/clientes', authenticateToken, requireAdmin, clientesController.getClientes);
router.put('/clientes/:id', authenticateToken, requireAdmin, clientesController.updateCliente);
router.delete('/clientes/:id', authenticateToken, requireAdmin, clientesController.deleteCliente);

module.exports = router;