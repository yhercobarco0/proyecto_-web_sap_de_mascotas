const groomingData = require('../data/grooming.data.js');
const pool = require('../../config/db.js');

exports.getGroomers = async () => {
  const groomers = await groomingData.getAllGroomers();
  return { success: true, data: groomers };
};

exports.crearFichaGrooming = async (payload) => {
  const { id_cita, tiempo_espera, checklist_items } = payload;
  if (!id_cita) return { success: false, message: 'ID de cita requerido.' };
  const ficha = await groomingData.createFichaGrooming({ 
    id_cita, 
    fecha_creacion: new Date(), 
    tiempo_espera,
    checklist_items: checklist_items || []
  });
  return { success: true, data: ficha, message: 'Ficha de grooming creada.' };
};

exports.getFichaByCita = async (id_cita) => {
  const ficha = await groomingData.getFichaGroomingByCita(id_cita);
  return { success: true, data: ficha };
};

exports.cerrarFicha = async (id_fichas_grooming, checklist_items) => {
  const requiredKeys = ['estado_piel', 'nudos', 'parasitos', 'agresividad'];
  if (!checklist_items || !Array.isArray(checklist_items) || checklist_items.length === 0) {
    return { success: false, message: 'El checklist no puede estar vacío.' };
  }
  
  const checkNames = checklist_items.map(item => item.name || item.key);
  const faltantes = requiredKeys.filter(k => !checkNames.includes(k));
  if (faltantes.length > 0) {
    return { success: false, message: `Faltan campos obligatorios en el checklist: ${faltantes.join(', ')}` };
  }

  // DESCUENTO AUTOMÁTICO DE STOCK (Inventario Integrado - Punto 7)
  const fichaCompleta = await groomingData.getFichaGroomingById(id_fichas_grooming);
  // Nota: getFichaGroomingByCita usa id_cita. Necesitamos los insumos de esta ficha.
  // Hagamos una consulta directa de los insumos
  const insumosRes = await pool.query('SELECT id_producto, unidades_usadas FROM FICHAS_GROOMING_INSUMOS WHERE id_fichas_grooming = $1', [id_fichas_grooming]);
  
  for (const ins of insumosRes.rows) {
    const pId = ins.id_producto;
    const qty = ins.unidades_usadas;
    
    // Descontar
    const updateRes = await pool.query(
      'UPDATE PRODUCTOS SET stok_unidad = stok_unidad - $1 WHERE id_producto = $2 RETURNING *',
      [qty, pId]
    );

    // Alerta de faltantes (Punto 8)
    const prod = updateRes.rows[0];
    if (prod && prod.stok_unidad <= prod.stock_minimo) {
      console.warn(`[ALERTA INVENTARIO] El producto ${prod.nombre_producto} está en stock crítico (${prod.stok_unidad}).`);
      // Aquí se podría insertar en una tabla de NOTIFICACIONES si existiera
    }
  }

  const resultado = await groomingData.closeFichaGrooming(id_fichas_grooming, checklist_items);
  return resultado;
};

exports.getLogInsumos = async () => {
  const log = await groomingData.getLogInsumos();
  return { success: true, data: log };
};

exports.registrarInsumo = async ({ id_fichas_grooming, id_producto, unidades_usadas }) => {
  if (!id_fichas_grooming || !id_producto || !unidades_usadas) {
    return { success: false, message: 'Datos incompletos.' };
  }
  const insumo = await groomingData.registrarInsumoGrooming({ id_fichas_grooming, id_producto, unidades_usadas });
  return { success: true, data: insumo, message: 'Insumo registrado en la ficha.' };
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

// TRANSACCIONES
exports.crearTransaccion = async (payload) => {
  const { id_usuario_solicitante, id_usuario_administracion, id_usuario_jefe, id_caja, tipo, monto, descripcion, estado_administracion_aprob, estado_administracion_jefe } = payload;
  if (!id_usuario_solicitante || !monto) return { success: false, message: 'Datos incompletos.' };
  const transaccion = await groomingData.createTransaccion({ 
    id_usuario_solicitante, id_usuario_administracion, id_usuario_jefe, id_caja, tipo, monto, descripcion,
    estado_administracion_aprob, estado_administracion_jefe 
  });
  return { success: true, data: transaccion, message: 'Transacción creada correctamente.' };
};

exports.actualizarTransaccion = async (id_transaccion, payload) => {
  const { id_usuario_administracion, id_usuario_jefe, estado_administracion_aprob, estado_administracion_jefe, fecha_aprobacion_administracion, fecha_aprobacion_jefe } = payload;
  const transaccion = await groomingData.updateTransaccion(id_transaccion, {
    id_usuario_administracion, id_usuario_jefe, estado_administracion_aprob, estado_administracion_jefe,
    fecha_aprobacion_administracion, fecha_aprobacion_jefe
  });
  if (!transaccion) return { success: false, message: 'Transacción no encontrada.' };
  return { success: true, data: transaccion, message: 'Transacción actualizada.' };
};

exports.getTransaccion = async (id_transaccion) => {
  const transaccion = await groomingData.getTransaccionById(id_transaccion);
  if (!transaccion) return { success: false, message: 'Transacción no encontrada.' };
  return { success: true, data: transaccion };
};

exports.getAllTransacciones = async () => {
  const transacciones = await groomingData.getAllTransacciones();
  return { success: true, data: transacciones };
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
