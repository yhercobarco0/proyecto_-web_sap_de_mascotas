const citasData = require('../data/citas.data.js');
const mascotasData = require('../../mascotas/data/mascotas.data.js');

exports.getCitasAdmin = async () => {
  const citas = await citasData.getAllCitas();
  return { success: true, data: citas };
};

exports.getCitasByFecha = async (fecha) => {
  const citas = await citasData.getCitasByFecha(fecha);
  return { success: true, data: citas };
};

exports.getMisCitas = async (id_usuario) => {
  const cliente = await mascotasData.getClienteByUserId(id_usuario);
  if (!cliente) return { success: false, message: 'Cliente no encontrado.' };
  const citas = await citasData.getCitasByCliente(cliente.id_cliente);
  return { success: true, data: citas };
};

exports.getCitasGroomer = async (id_usuario) => {
  const { getTrabajadorByUserId } = require('../../grooming/data/grooming.data.js');
  const trabajador = await getTrabajadorByUserId(id_usuario);
  if (!trabajador) return { success: false, message: 'Trabajador no encontrado.' };
  const citas = await citasData.getCitasByGroomer(trabajador.id_trabajadores);
  return { success: true, data: citas };
};

exports.crearCita = async (payload, id_usuario, rol) => {
  const { id_mascota, id_servicio, empleado_acargo, monto_pagado, fecha_cita, id_cliente_override } = payload;

  if (!id_mascota || !id_servicio || !fecha_cita) {
    return { success: false, message: 'Faltan datos obligatorios (mascota, servicio, fecha).' };
  }

  let id_cliente = id_cliente_override;
  if (!id_cliente) {
    const cliente = await mascotasData.getClienteByUserId(id_usuario);
    if (cliente) {
      id_cliente = cliente.id_cliente;
    } else if (rol && rol.toString().toUpperCase() === 'CLIENTES') {
      return { success: false, message: 'Cliente no encontrado.' };
    }
  }

  const cita = await citasData.createCita({
    id_mascota, id_servicio,
    pagado_por_cliente: id_cliente,
    empleado_acargo: empleado_acargo || null,
    monto_pagado: monto_pagado || 0,
    fecha_cita,
  });
  return { success: true, data: cita, message: 'Cita creada correctamente.' };
};

exports.actualizarCita = async (id_cita, payload, id_usuario) => {
  const existing = await citasData.getCitaById(id_cita);
  if (!existing) return { success: false, message: 'Cita no encontrada.' };

  // Register movement if date changes
  if (payload.fecha_cita && payload.fecha_cita !== existing.fecha_cita?.toISOString().split('T')[0]) {
    await citasData.registrarMovimiento({
      id_cita,
      fecha_anterior: existing.fecha_cita,
      fecha_nueva: payload.fecha_cita,
      id_usuario,
      descripcion: payload.motivo_reprogramacion || 'Reprogramación',
    });
  }

  const cita = await citasData.updateCita(id_cita, payload);
  return { success: true, data: cita, message: 'Cita actualizada.' };
};

exports.terminarCita = async (id_cita, payload, id_usuario) => {
  const existing = await citasData.getCitaById(id_cita);
  if (!existing) return { success: false, message: 'Cita no encontrada.' };

  const cita = await citasData.updateCita(id_cita, {
    estado_de_cita: 'terminado',
    estado_de_mascota: payload.estado_de_mascota,
    foto_estado_mascota: payload.foto_estado_mascota,
    monto_pagado: payload.monto_pagado || existing.monto_pagado,
    monto_llevado_a_caja: payload.monto_llevado_a_caja,
  });

  // Si se envió caja, afectar la caja y registrar transacción
  if (payload.monto_llevado_a_caja && (payload.monto_pagado || existing.monto_pagado)) {
    const groomingData = require('../../grooming/data/grooming.data.js');
    const monto = payload.monto_pagado || existing.monto_pagado;
    
    // Crear la transacción
    await groomingData.createTransaccion({
      id_usuario_solicitante: id_usuario,
      id_caja: payload.monto_llevado_a_caja,
      tipo: 'ingreso',
      monto: monto,
      descripcion: `Cobro final de la cita #${id_cita}`,
    });

    // Actualizar el saldo de la caja
    await groomingData.updateSaldoCaja(payload.monto_llevado_a_caja, monto);
  }

  // Generar la ficha de grooming automáticamente
  const groomingData = require('../../grooming/data/grooming.data.js');
  await groomingData.createFichaGrooming({
    id_cita: id_cita,
    fecha_creacion: new Date(),
    tiempo_espera: 15
  });

  return { success: true, data: cita, message: 'Cita terminada correctamente. Ficha generada y cobro registrado.' };
};

exports.cancelarCita = async (id_cita, motivo, id_usuario) => {
  const cita = await citasData.updateCita(id_cita, {
    estado_de_cita: 'activo',
    motivo_cancelacion: motivo || 'Cancelado por usuario',
  });
  return { success: true, data: cita, message: 'Cita cancelada.' };
};

exports.getBloqueos = async (fecha, id_trabajador) => {
  const bloqueos = await citasData.getBloqueosByFecha(fecha, id_trabajador);
  return { success: true, data: bloqueos };
};

exports.crearBloqueo = async ({ id_trabajadores, fecha_bloqueo, motivo }) => {
  const bloqueo = await citasData.createBloqueo({ id_trabajadores, fecha_bloqueo, motivo });
  return { success: true, data: bloqueo, message: 'Bloqueo de agenda registrado.' };
};

exports.eliminarBloqueo = async (id_bloqueo) => {
  await citasData.deleteBloqueo(id_bloqueo);
  return { success: true, message: 'Bloqueo eliminado.' };
};

exports.registrarOpinion = async (payload, id_usuario) => {
  const { id_cita, calificacion, comentario } = payload;
  const cliente = await mascotasData.getClienteByUserId(id_usuario);
  if (!cliente) return { success: false, message: 'Cliente no encontrado.' };
  if (!calificacion || calificacion < 1 || calificacion > 5) {
    return { success: false, message: 'La calificación debe ser entre 1 y 5.' };
  }
  const opinion = await citasData.registrarOpinion({ id_cita, id_cliente: cliente.id_cliente, calificacion, comentario });
  return { success: true, data: opinion, message: '¡Gracias por tu opinión!' };
};

exports.getOpinionesByCliente = async (id_usuario) => {
  const cliente = await mascotasData.getClienteByUserId(id_usuario);
  if (!cliente) return { success: false, message: 'Cliente no encontrado.' };
  const opiniones = await citasData.getOpinionesByCliente(cliente.id_cliente);
  return { success: true, data: opiniones };
};

exports.getAllOpiniones = async () => {
  const opiniones = await citasData.getAllOpiniones();
  return { success: true, data: opiniones };
};
