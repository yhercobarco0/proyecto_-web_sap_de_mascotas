const reportesService = require('../services/reportes.services.js');

exports.getDashboard = async (req, res) => {
  try {
    const result = await reportesService.getDashboard();
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getResumenVentas = async (req, res) => {
  try {
    const result = await reportesService.getResumenVentas(req.query.desde, req.query.hasta);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getServiciosMasPopulares = async (req, res) => {
  try {
    const result = await reportesService.getServiciosMasPopulares();
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getRendimientoGroomers = async (req, res) => {
  try {
    const result = await reportesService.getRendimientoGroomers();
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getCitasPorDia = async (req, res) => {
  try {
    const result = await reportesService.getCitasPorDia(req.query.dias);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getStockCritico = async (req, res) => {
  try {
    const result = await reportesService.getStockCritico();
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getOpinionesRecientes = async (req, res) => {
  try {
    const result = await reportesService.getOpinionesRecientes(req.query.limite);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};
