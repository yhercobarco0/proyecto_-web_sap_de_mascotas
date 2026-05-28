const mascotasData = require('../data/mascotas.data.js');

exports.getMismascotas = async (id_usuario) => {
  const cliente = await mascotasData.getClienteByUserId(id_usuario);
  if (!cliente) return { success: false, message: 'Cliente no encontrado.' };
  const mascotas = await mascotasData.getMascotasByCliente(cliente.id_cliente);
  return { success: true, data: mascotas };
};

exports.getAllMascotas = async () => {
  const mascotas = await mascotasData.getAllMascotas();
  return { success: true, data: mascotas };
};

exports.getMascotaById = async (id_mascota) => {
  const mascota = await mascotasData.getMascotaById(id_mascota);
  if (!mascota) return { success: false, message: 'Mascota no encontrada.' };
  return { success: true, data: mascota };
};

exports.crearMascota = async (payload, id_usuario, rol) => {
  const { nombre_mascota, raza, edad, tamano, peso, foto_mascota, id_cliente_override } = payload;
  if (!nombre_mascota) return { success: false, message: 'El nombre de la mascota es requerido.' };

  let id_cliente = id_cliente_override;
  if (!id_cliente) {
    const cliente = await mascotasData.getClienteByUserId(id_usuario);
    if (!cliente) return { success: false, message: 'No se encontró el perfil de cliente.' };
    id_cliente = cliente.id_cliente;
  }

  const mascota = await mascotasData.createMascota({ id_cliente, nombre_mascota, raza, edad, tamano, peso, foto_mascota });
  return { success: true, data: mascota, message: 'Mascota registrada correctamente.' };
};

exports.actualizarMascota = async (id_mascota, payload) => {
  const mascota = await mascotasData.updateMascota(id_mascota, payload);
  if (!mascota) return { success: false, message: 'Mascota no encontrada.' };
  return { success: true, data: mascota, message: 'Mascota actualizada.' };
};

exports.eliminarMascota = async (id_mascota) => {
  await mascotasData.deleteMascota(id_mascota);
  return { success: true, message: 'Mascota eliminada.' };
};

exports.getVacunas = async (id_mascota) => {
  const vacunas = await mascotasData.getVacunasByMascota(id_mascota);
  return { success: true, data: vacunas };
};

exports.registrarVacuna = async (payload) => {
  const { id_mascota, id_vacuna, id_trabajadores, fecha_aplicacion, fecha_proxima, observacion } = payload;
  if (!id_mascota || !id_vacuna) return { success: false, message: 'Datos incompletos.' };
  const vacuna = await mascotasData.registrarVacuna({ id_trabajadores, id_mascota, id_vacuna, fecha_aplicacion, fecha_proxima, observacion });
  return { success: true, data: vacuna, message: 'Vacuna registrada.' };
};

exports.getCatalogoVacunas = async () => {
  const vacunas = await mascotasData.getAllVacunas();
  return { success: true, data: vacunas };
};
