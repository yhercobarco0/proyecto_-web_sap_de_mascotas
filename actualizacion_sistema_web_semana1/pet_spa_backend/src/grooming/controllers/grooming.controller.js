const groomingService = require('../services/grooming.services.js');

exports.getGroomers = async (req, res) => {
  try {
    const result = await groomingService.getGroomers();
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.crearFicha = async (req, res) => {
  try {
    const result = await groomingService.crearFichaGrooming(req.body);
    res.status(result.success ? 201 : 400).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getFichaByCita = async (req, res) => {
  try {
    const result = await groomingService.getFichaByCita(req.params.id_cita);
    res.status(result.success ? 200 : 404).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.cerrarFicha = async (req, res) => {
  try {
    const result = await groomingService.cerrarFicha(req.params.id);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.registrarInsumo = async (req, res) => {
  try {
    const result = await groomingService.registrarInsumo(req.body);
    res.status(result.success ? 201 : 400).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getMisFichas = async (req, res) => {
  try {
    const result = await groomingService.getMisFichas(req.user.id_usuario);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

// PAGOS
exports.getPagosEmpleado = async (req, res) => {
  try {
    const result = await groomingService.getPagosEmpleado(req.params.id_trabajador);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getAllPagos = async (req, res) => {
  try {
    const result = await groomingService.getAllPagosEmpleados();
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.registrarPago = async (req, res) => {
  try {
    const result = await groomingService.registrarPago(req.body);
    res.status(result.success ? 201 : 400).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

// CAJAS
exports.getCajas = async (req, res) => {
  try {
    const result = await groomingService.getCajas();
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.crearCaja = async (req, res) => {
  try {
    const result = await groomingService.crearCaja(req.body);
    res.status(result.success ? 201 : 400).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.actualizarSaldo = async (req, res) => {
  try {
    const result = await groomingService.actualizarSaldo(req.params.id, req.body.monto);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

// TRANSACCIONES
exports.crearTransaccion = async (req, res) => {
  try {
    const result = await groomingService.crearTransaccion(req.body, req.user.id_usuario);
    res.status(result.success ? 201 : 400).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getAllTransacciones = async (req, res) => {
  try {
    const result = await groomingService.getAllTransacciones();
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};
