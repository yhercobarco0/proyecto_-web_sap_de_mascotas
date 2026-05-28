const reportesData = require('../data/reportes.data.js');

exports.getDashboard = async () => {
  const stats = await reportesData.getDashboardStats();
  return { success: true, data: stats };
};

exports.getResumenVentas = async (fechaDesde, fechaHasta) => {
  const hoy = new Date().toISOString().split('T')[0];
  const desde = fechaDesde || new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString().split('T')[0];
  const hasta = fechaHasta || hoy;
  const resumen = await reportesData.getResumenVentas(desde, hasta);
  return { success: true, data: resumen };
};

exports.getServiciosMasPopulares = async () => {
  const servicios = await reportesData.getServiciosMasPopulares();
  return { success: true, data: servicios };
};

exports.getRendimientoGroomers = async () => {
  const groomers = await reportesData.getRendimientoGroomers();
  return { success: true, data: groomers };
};

exports.getCitasPorDia = async (dias) => {
  const data = await reportesData.getCitasPorDia(dias || 30);
  return { success: true, data };
};

exports.getStockCritico = async () => {
  const productos = await reportesData.getStockCritico();
  return { success: true, data: productos };
};

exports.getOpinionesRecientes = async (limite) => {
  const opiniones = await reportesData.getOpinionesRecientes(limite || 10);
  return { success: true, data: opiniones };
};
