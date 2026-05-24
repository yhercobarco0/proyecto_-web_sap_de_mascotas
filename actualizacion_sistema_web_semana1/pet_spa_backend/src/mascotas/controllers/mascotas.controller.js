const mascotasService = require('../services/mascotas.services.js');

exports.getMisMascotas = async (req, res) => {
  try {
    const result = await mascotasService.getMismascotas(req.user.id_usuario);
    res.status(result.success ? 200 : 404).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getAllMascotas = async (req, res) => {
  try {
    const result = await mascotasService.getAllMascotas();
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getMascotaById = async (req, res) => {
  try {
    const result = await mascotasService.getMascotaById(req.params.id);
    res.status(result.success ? 200 : 404).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.crearMascota = async (req, res) => {
  try {
    const result = await mascotasService.crearMascota(req.body, req.user.id_usuario, req.user.rol);
    res.status(result.success ? 201 : 400).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.actualizarMascota = async (req, res) => {
  try {
    const result = await mascotasService.actualizarMascota(req.params.id, req.body);
    res.status(result.success ? 200 : 404).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.eliminarMascota = async (req, res) => {
  try {
    const result = await mascotasService.eliminarMascota(req.params.id);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getVacunas = async (req, res) => {
  try {
    const result = await mascotasService.getVacunas(req.params.id);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.registrarVacuna = async (req, res) => {
  try {
    const result = await mascotasService.registrarVacuna(req.body);
    res.status(result.success ? 201 : 400).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getCatalogoVacunas = async (req, res) => {
  try {
    const result = await mascotasService.getCatalogoVacunas();
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};
