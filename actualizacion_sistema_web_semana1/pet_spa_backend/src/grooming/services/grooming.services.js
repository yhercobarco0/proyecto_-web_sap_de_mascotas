const groomingData = require('../data/grooming.data.js');

exports.getGroomers = async () => {
  const groomers = await groomingData.getAllGroomers();
  return { success: true, data: groomers };
};

exports.crearFichaGrooming = async (payload) => {
  const { id_cita, tiempo_espera } = payload;
  if (!id_cita) return { success: false, message: 'ID de cita requerido.' };
  const ficha = await groomingData.createFichaGrooming({ id_cita, fecha_creacion: new Date(), tiempo_espera });
  return { success: true, data: ficha, message: 'Ficha de grooming creada.' };
};

exports.getFichaByCita = async (id_cita) => {
  const ficha = await groomingData.getFichaGroomingByCita(id_cita);
  if (!ficha) return { success: false, message: 'Ficha no encontrada.' };
  return { success: true, data: ficha };
};

exports.cerrarFicha = async (id_fichas_grooming) => {
  const ficha = await groomingData.closeFichaGrooming(id_fichas_grooming);
  return { success: true, data: ficha, message: 'Ficha cerrada correctamente.' };
};

exports.registrarInsumo = async ({ id_fichas_grooming, id_producto, unidades_usadas }) => {
  if (!id_fichas_grooming || !id_producto || !unidades_usadas) {
    return { success: false, message: 'Datos incompletos.' };
  }
  const insumo = await groomingData.registrarInsumoGrooming({ id_fichas_grooming, id_producto, unidades_usadas });
  return { success: true, data: insumo, message: 'Insumo registrado y stock descontado.' };
};

exports.getMisFichas = async (id_usuario) => {
  const trabajador = await groomingData.getTrabajadorByUserId(id_usuario);
  if (!trabajador) return { success: false, message: 'Trabajador no encontrado.' };
  const fichas = await groomingData.getFichasByGroomer(trabajador.id_trabajadores);
  return { success: true, data: fichas };
};

// PAGOS
exports.getPagosEmpleado = async (id_trabajadores) => {
  const pagos = await groomingData.getPagosEmpleado(id_trabajadores);
  return { success: true, data: pagos };
};

exports.getAllPagosEmpleados = async () => {
  const pagos = await groomingData.getAllPagosEmpleados();
  return { success: true, data: pagos };
};

exports.registrarPago = async (payload) => {
  const { id_trabajadores, monto, fecha_pago_empleado, periodo_desde, periodo_hasta, descripcion, estado_pago_empleado } = payload;
  if (!id_trabajadores || !monto) return { success: false, message: 'Datos incompletos.' };
  const pago = await groomingData.createPagoEmpleado({ id_trabajadores, monto, fecha_pago_empleado, periodo_desde, periodo_hasta, descripcion, estado_pago_empleado });
  return { success: true, data: pago, message: 'Pago registrado correctamente.' };
};

// CAJAS
exports.getCajas = async () => {
  const cajas = await groomingData.getAllCajas();
  return { success: true, data: cajas };
};

exports.crearCaja = async (payload) => {
  const { nombre_caja, id_trabajadores, descripcion, saldo_caja, estado_caja } = payload;
  if (!nombre_caja) return { success: false, message: 'Nombre de caja requerido.' };
  const caja = await groomingData.createCaja({ id_trabajadores, nombre_caja, descripcion, saldo_caja, estado_caja });
  return { success: true, data: caja, message: 'Caja creada.' };
};

exports.actualizarSaldo = async (id_cajas, monto) => {
  const caja = await groomingData.updateSaldoCaja(id_cajas, monto);
  return { success: true, data: caja, message: 'Saldo actualizado.' };
};

// TRANSACCIONES
exports.crearTransaccion = async (payload, id_usuario) => {
  const { id_caja, tipo, monto, descripcion } = payload;
  if (!id_caja || !tipo || !monto) return { success: false, message: 'Datos incompletos.' };

  const transaccion = await groomingData.createTransaccion({
    id_usuario_solicitante: id_usuario,
    id_caja, tipo, monto, descripcion,
  });

  // Update caja balance
  const delta = tipo === 'ingreso' ? Number(monto) : -Number(monto);
  await groomingData.updateSaldoCaja(id_caja, delta);

  return { success: true, data: transaccion, message: 'Transacción registrada.' };
};

exports.getAllTransacciones = async () => {
  const transacciones = await groomingData.getAllTransacciones();
  return { success: true, data: transacciones };
};
