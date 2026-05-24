const serviciosData = require('../data/servicios.data.js');

exports.getServicios = async (soloActivos) => {
  const servicios = await serviciosData.getAllServicios(soloActivos);
  return { success: true, data: servicios };
};

exports.getServicioById = async (id_servicio) => {
  const servicio = await serviciosData.getServicioById(id_servicio);
  if (!servicio) return { success: false, message: 'Servicio no encontrado.' };
  return { success: true, data: servicio };
};

exports.crearServicio = async ({ nombre_del_servicio, descripcion, duracion_estimada_minutos, precio }) => {
  if (!nombre_del_servicio || !precio) return { success: false, message: 'Nombre y precio son requeridos.' };
  const servicio = await serviciosData.createServicio({ nombre_del_servicio, descripcion, duracion_estimada_minutos, precio });
  return { success: true, data: servicio, message: 'Servicio creado.' };
};

exports.actualizarServicio = async (id_servicio, payload) => {
  const servicio = await serviciosData.updateServicio(id_servicio, payload);
  if (!servicio) return { success: false, message: 'Servicio no encontrado.' };
  return { success: true, data: servicio, message: 'Servicio actualizado.' };
};

exports.eliminarServicio = async (id_servicio) => {
  await serviciosData.deleteServicio(id_servicio);
  return { success: true, message: 'Servicio desactivado.' };
};
