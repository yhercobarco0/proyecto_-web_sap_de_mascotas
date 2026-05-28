const citasService = require('../services/citas.services.js');

exports.getCitasAdmin = async (req, res) => {
  try {
    const result = await citasService.getCitasAdmin();
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getCitasByFecha = async (req, res) => {
  try {
    const result = await citasService.getCitasByFecha(req.query.fecha);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getHorariosOcupados = async (req, res) => {
  try {
    const result = await citasService.getHorariosOcupados(req.params.id_groomer, req.params.fecha);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getMisCitas = async (req, res) => {
  try {
    const result = await citasService.getMisCitas(req.user.id_usuario);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getCitasGroomer = async (req, res) => {
  try {
    const result = await citasService.getCitasGroomer(req.user.id_usuario);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.crearCita = async (req, res) => {
  try {
    const result = await citasService.crearCita(req.body, req.user.id_usuario, req.user.rol);
    res.status(result.success ? 201 : 400).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.actualizarCita = async (req, res) => {
  try {
    const result = await citasService.actualizarCita(req.params.id, req.body, req.user.id_usuario);
    res.status(result.success ? 200 : 404).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.terminarCita = async (req, res) => {
  try {
    const result = await citasService.terminarCita(req.params.id, req.body, req.user.id_usuario);
    res.status(result.success ? 200 : 404).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.cancelarCita = async (req, res) => {
  try {
    const result = await citasService.cancelarCita(req.params.id, req.body.motivo, req.user.id_usuario);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getBloqueos = async (req, res) => {
  try {
    const result = await citasService.getBloqueos(req.query.fecha, req.query.id_trabajador);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.crearBloqueo = async (req, res) => {
  try {
    const result = await citasService.crearBloqueo(req.body);
    res.status(result.success ? 201 : 400).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.eliminarBloqueo = async (req, res) => {
  try {
    const result = await citasService.eliminarBloqueo(req.params.id);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.registrarOpinion = async (req, res) => {
  try {
    const result = await citasService.registrarOpinion(req.body, req.user.id_usuario);
    res.status(result.success ? 201 : 400).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getMisOpiniones = async (req, res) => {
  try {
    const result = await citasService.getOpinionesByCliente(req.user.id_usuario);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getAllOpiniones = async (req, res) => {
  try {
    const result = await citasService.getAllOpiniones();
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};
