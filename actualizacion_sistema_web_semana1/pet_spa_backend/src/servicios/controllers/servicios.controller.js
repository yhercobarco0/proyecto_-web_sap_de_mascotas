const serviciosService = require('../services/servicios.services.js');

exports.getServicios = async (req, res) => {
  try {
    const soloActivos = req.query.activos === 'true';
    const result = await serviciosService.getServicios(soloActivos);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getServicioById = async (req, res) => {
  try {
    const result = await serviciosService.getServicioById(req.params.id);
    res.status(result.success ? 200 : 404).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.crearServicio = async (req, res) => {
  try {
    const result = await serviciosService.crearServicio(req.body);
    res.status(result.success ? 201 : 400).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.actualizarServicio = async (req, res) => {
  try {
    const result = await serviciosService.actualizarServicio(req.params.id, req.body);
    res.status(result.success ? 200 : 404).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.eliminarServicio = async (req, res) => {
  try {
    const result = await serviciosService.eliminarServicio(req.params.id);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};
