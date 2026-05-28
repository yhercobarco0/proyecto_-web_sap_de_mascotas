const pool = require('../../config/db.js');
const citasData = require('../data/citas.data.js');
const mascotasData = require('../../mascotas/data/mascotas.data.js');
const serviciosData = require('../../servicios/data/servicios.data.js');
const mailer = require('../../config/mailer.js');

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
  const { id_mascota, id_servicio, empleado_acargo, monto_pagado, metodo_pago, fecha_cita, hora_cita, id_cliente_override } = payload;

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

  const qualifiedGroomers = await getGroomersForServicio(id_servicio);
  let finalGroomerId = empleado_acargo;

  if (finalGroomerId && fecha_cita) {
    const isQualified = qualifiedGroomers.some(g => g.id_trabajadores === finalGroomerId);
    if (!isQualified && qualifiedGroomers.length > 0) {
      return { success: false, message: 'El groomer seleccionado no está capacitado para realizar este servicio.' };
    }

    const trabajadorResult = await pool.query('SELECT capacidad_maxima_mascotas_dia, turno FROM TRABAJADORES WHERE id_trabajadores=$1', [finalGroomerId]);
    if (trabajadorResult.rows[0]) {
      const maxCap = trabajadorResult.rows[0].capacidad_maxima_mascotas_dia;
      const citasDelDia = await citasData.getCitasByFecha(fecha_cita);
      const citasDelGroomer = citasDelDia.filter(c => c.empleado_acargo === finalGroomerId && c.estado_de_cita !== 'cancelado');
      
      if (citasDelGroomer.length >= maxCap) {
        return { success: false, message: `Capacidad máxima alcanzada. El groomer no puede atender más de ${maxCap} mascotas por día.` };
      }

      if (hora_cita) {
        const errorSolapamiento = await validarDisponibilidadGroomer(finalGroomerId, fecha_cita, hora_cita, id_servicio, null);
        if (errorSolapamiento) return errorSolapamiento;
      }
    }
  } else if (!finalGroomerId && fecha_cita) {
    if (qualifiedGroomers.length === 0) {
      return { success: false, message: 'No hay personal capacitado registrado para realizar este servicio.' };
    }

    if (hora_cita) {
      let freeGroomer = null;
      for (const g of qualifiedGroomers) {
        const citasDelDia = await citasData.getCitasByFecha(fecha_cita);
        const citasDelGroomer = citasDelDia.filter(c => c.empleado_acargo === g.id_trabajadores && c.estado_de_cita !== 'cancelado');
        if (citasDelGroomer.length >= g.capacidad_maxima_mascotas_dia) {
          continue;
        }

        const err = await validarDisponibilidadGroomer(g.id_trabajadores, fecha_cita, hora_cita, id_servicio, null);
        if (!err) {
          freeGroomer = g;
          break;
        }
      }

      if (!freeGroomer) {
        return { success: false, message: 'No hay personal disponible para este servicio en el horario seleccionado.' };
      }

      finalGroomerId = freeGroomer.id_trabajadores;
    }
  }

  const cita = await citasData.createCita({
    id_mascota, id_servicio,
    pagado_por_cliente: id_cliente,
    empleado_acargo: finalGroomerId || null,
    monto_pagado: monto_pagado || 0,
    metodo_pago: metodo_pago || 'efectivo',
    fecha_cita,
    hora_cita
  });

  // Generar la ficha de grooming automáticamente al crear la cita (Punto 4)
  const groomingData = require('../../grooming/data/grooming.data.js');
  await groomingData.createFichaGrooming({
    id_cita: cita.id_cita,
    fecha_creacion: new Date(),
    tiempo_espera: 15
  });

  return { success: true, data: cita, message: 'Cita creada correctamente.' };
};

exports.actualizarCita = async (id_cita, payload, id_usuario) => {
  const existing = await citasData.getCitaById(id_cita);
  if (!existing) return { success: false, message: 'Cita no encontrada.' };

  const nuevaFecha = payload.fecha_cita || existing.fecha_cita?.toISOString().split('T')[0];
  const nuevaHora = payload.hora_cita || existing.hora_cita;
  const nuevoGroomer = payload.empleado_acargo !== undefined ? payload.empleado_acargo : existing.empleado_acargo;
  const qualifiedGroomers = await getGroomersForServicio(existing.id_servicio);
  let finalGroomerId = nuevoGroomer;

  if (finalGroomerId && nuevaFecha && nuevaHora && (payload.fecha_cita || payload.hora_cita || payload.empleado_acargo !== undefined)) {
    const isQualified = qualifiedGroomers.some(g => g.id_trabajadores === finalGroomerId);
    if (!isQualified && qualifiedGroomers.length > 0) {
      return { success: false, message: 'El groomer seleccionado no está capacitado para realizar este servicio.' };
    }

    const trabajadorResult = await pool.query('SELECT capacidad_maxima_mascotas_dia, turno FROM TRABAJADORES WHERE id_trabajadores=$1', [finalGroomerId]);
    if (trabajadorResult.rows[0]) {
      const maxCap = trabajadorResult.rows[0].capacidad_maxima_mascotas_dia;
      const citasDelDia = await citasData.getCitasByFecha(nuevaFecha);
      const citasDelGroomer = citasDelDia.filter(c => c.empleado_acargo === finalGroomerId && c.estado_de_cita !== 'cancelado' && c.id_cita !== id_cita);
      
      if (citasDelGroomer.length >= maxCap) {
        return { success: false, message: `Capacidad máxima alcanzada. El groomer no puede atender más de ${maxCap} mascotas por día.` };
      }

      if (nuevaHora) {
        const errorSolapamiento = await validarDisponibilidadGroomer(finalGroomerId, nuevaFecha, nuevaHora, existing.id_servicio, id_cita);
        if (errorSolapamiento) return errorSolapamiento;
      }
    }
  } else if (!finalGroomerId && nuevaFecha && nuevaHora && (payload.fecha_cita || payload.hora_cita || payload.empleado_acargo !== undefined)) {
    if (qualifiedGroomers.length === 0) {
      return { success: false, message: 'No hay personal capacitado registrado para realizar este servicio.' };
    }

    let freeGroomer = null;
    for (const g of qualifiedGroomers) {
      const citasDelDia = await citasData.getCitasByFecha(nuevaFecha);
      const citasDelGroomer = citasDelDia.filter(c => c.empleado_acargo === g.id_trabajadores && c.estado_de_cita !== 'cancelado' && c.id_cita !== id_cita);
      if (citasDelGroomer.length >= g.capacidad_maxima_mascotas_dia) {
        continue;
      }

      const err = await validarDisponibilidadGroomer(g.id_trabajadores, nuevaFecha, nuevaHora, existing.id_servicio, id_cita);
      if (!err) {
        freeGroomer = g;
        break;
      }
    }

    if (!freeGroomer) {
      return { success: false, message: 'No hay personal disponible para este servicio en el horario seleccionado.' };
    }

    finalGroomerId = freeGroomer.id_trabajadores;
  }

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

  const updateFields = { ...payload };
  if (payload.empleado_acargo !== undefined) {
    updateFields.empleado_acargo = finalGroomerId;
  }

  const cita = await citasData.updateCita(id_cita, updateFields);

  return { success: true, data: cita, message: 'Cita actualizada.' };
};

exports.terminarCita = async (id_cita, payload, id_usuario) => {
  const existing = await citasData.getCitaById(id_cita);
  if (!existing) return { success: false, message: 'Cita no encontrada.' };

  // Obtener la ficha e insumos para el cálculo y el resumen
  const fichaRes = await pool.query('SELECT id_fichas_grooming FROM FICHAS_GROOMING WHERE id_cita = $1', [id_cita]);
  let totalInsumos = 0;
  let listInsumosHtml = '';
  let listInsumosText = '';
  
  if (fichaRes.rows[0]) {
    const idFicha = fichaRes.rows[0].id_fichas_grooming;
    const insumosRes = await pool.query(
      `SELECT p.nombre_producto, f.unidades_usadas, p.precio 
       FROM FICHAS_GROOMING_INSUMOS f 
       JOIN PRODUCTOS p ON f.id_producto = p.id_producto 
       WHERE f.id_fichas_grooming = $1`, 
      [idFicha]
    );
    for (const ins of insumosRes.rows) {
      const precio = parseFloat(ins.precio || 0);
      const subtotal = ins.unidades_usadas * precio;
      totalInsumos += subtotal;
      listInsumosHtml += `
        <tr>
          <td style="padding: 10px; border: 1px solid #ddd;">Insumo: ${ins.nombre_producto} (x${ins.unidades_usadas})</td>
          <td style="padding: 10px; text-align: right; border: 1px solid #ddd;">Bs. ${subtotal.toFixed(2)}</td>
        </tr>`;
      listInsumosText += `\n- Insumo: ${ins.nombre_producto} (x${ins.unidades_usadas}) - Bs. ${subtotal.toFixed(2)}`;
    }
  }

  const precioServicio = parseFloat(existing.precio || 0);
  const montoCalculado = precioServicio + totalInsumos;

  const cita = await citasData.updateCita(id_cita, {
    estado_de_cita: 'terminado',
    estado_de_mascota: payload.estado_de_mascota,
    foto_estado_mascota: payload.foto_estado_mascota,
    monto_pagado: montoCalculado,
    monto_llevado_a_caja: payload.monto_llevado_a_caja,
  });

  // Si se envió caja, afectar la caja y registrar transacción
  if (payload.monto_llevado_a_caja) {
    const groomingData = require('../../grooming/data/grooming.data.js');
    await groomingData.createTransaccion({
      id_usuario_solicitante: id_usuario,
      id_caja: payload.monto_llevado_a_caja,
      tipo: 'ingreso',
      monto: montoCalculado,
      descripcion: `Cobro final de la cita #${id_cita} (Servicio: ${precioServicio} + Insumos: ${totalInsumos})`,
      estado_administracion_aprob: 'aprobado',
      estado_administracion_jefe: 'aprobado'
    });

    // Actualizar el saldo de la caja
    await groomingData.updateSaldoCaja(payload.monto_llevado_a_caja, montoCalculado);
  }

  // Notificación de Listo para Recoger / Terminado
  let emailCliente = existing.correo_cliente || 'cliente@correo.com';
  if (!existing.correo_cliente && existing.pagado_por_cliente) {
    const clienteResult = await pool.query('SELECT c.preferencia_notificacion, c.telefono, u.email FROM CLIENTES c JOIN USUARIOS u ON c.id_usuario = u.id_usuario WHERE c.id_cliente=$1', [existing.pagado_por_cliente]);
    if (clienteResult.rows[0] && clienteResult.rows[0].email) {
      emailCliente = clienteResult.rows[0].email;
    }
  }

  const subject = `¡Servicio Finalizado! listo para recoger 🐾 - PetSpa`;
  
  const textMsg = `¡Hola ${existing.nombre_cliente || 'Cliente'}!\n\nEl servicio para tu mascota ${existing.nombre_mascota || ''} ha finalizado en PetSpa y ya está listo para recoger. 🐾\n\nResumen de la cuenta:\n- Servicio: ${existing.nombre_del_servicio} (Bs. ${precioServicio.toFixed(2)})${listInsumosText}\n\nTotal a pagar: Bs. ${montoCalculado.toFixed(2)}\n\n¡Gracias por confiar en nosotros!`;
  
  const htmlMsg = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; border: 1px solid #008080; padding: 20px; border-radius: 10px; background-color: #ffffff; color: #333;">
      <div style="text-align: center; border-bottom: 2px solid #008080; padding-bottom: 10px; margin-bottom: 20px;">
        <h2 style="color: #008080; margin: 0;">🐾 PetSpa Mascotas 🐾</h2>
      </div>
      <p>Hola, <strong>${existing.nombre_cliente || 'Cliente'}</strong>:</p>
      <p>Nos complace informarte que el servicio de grooming para tu mascota <strong>${existing.nombre_mascota || ''}</strong> ha finalizado exitosamente. ¡Ya está lista para recoger!</p>
      <h3 style="color: #008080; border-bottom: 1px solid #eee; padding-bottom: 5px;">Resumen de la Cuenta:</h3>
      <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
        <thead>
          <tr style="background-color: #f2f2f2; color: #333; font-weight: bold;">
            <th style="text-align: left; padding: 10px; border: 1px solid #ddd;">Detalle</th>
            <th style="text-align: right; padding: 10px; border: 1px solid #ddd;">Monto</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td style="padding: 10px; border: 1px solid #ddd;">Servicio: ${existing.nombre_del_servicio}</td>
            <td style="padding: 10px; text-align: right; border: 1px solid #ddd; font-weight: bold;">Bs. ${precioServicio.toFixed(2)}</td>
          </tr>
          ${listInsumosHtml}
          <tr style="font-weight: bold; background-color: #e6f7f7;">
            <td style="padding: 10px; border: 1px solid #ddd; font-size: 16px;">Total a Pagar:</td>
            <td style="padding: 10px; text-align: right; border: 1px solid #ddd; color: #008080; font-size: 18px;">Bs. ${montoCalculado.toFixed(2)}</td>
          </tr>
        </tbody>
      </table>
      <div style="background-color: #fff9e6; border-left: 4px solid #ffcc00; padding: 15px; border-radius: 4px; margin-bottom: 20px;">
        <p style="margin: 0; font-weight: bold; color: #8a6d3b;">📌 Información importante:</p>
        <p style="margin: 5px 0 0 0; font-size: 14px;">Puedes pasar a recoger a tu mascota en nuestras instalaciones. Por favor, realiza el pago mediante el método acordado (Bs. ${montoCalculado.toFixed(2)}).</p>
      </div>
      <p style="text-align: center; font-size: 14px; color: #666; margin-top: 30px;">¡Gracias por tu preferencia! 🐾</p>
    </div>
  `;

  // Enviar correo asíncronamente
  mailer.sendMail({
    to: emailCliente,
    subject,
    text: textMsg,
    html: htmlMsg
  }).then(res => {
    if (res.success) {
      console.log(`[MAILER SUCCESS] Email sent to ${emailCliente}`);
    } else {
      console.error(`[MAILER ERROR] Failed to send email to ${emailCliente}:`, res.error);
    }
  }).catch(err => {
    console.error(`[MAILER EXCEPTION] Exception during mail send:`, err);
  });

  cita.tipo_notificacion = 'backend_email';
  cita.mensaje_notificacion = 'Correo electrónico enviado automáticamente por el servidor.';

  return { success: true, data: cita, message: 'Cita terminada correctamente, cobro registrado e email enviado.' };
};

exports.cancelarCita = async (id_cita, motivo, id_usuario) => {
  const cita = await citasData.updateCita(id_cita, {
    estado_de_cita: 'cancelado',
    motivo_cancelacion: motivo || 'Cancelado por usuario',
  });
  return { success: true, data: cita, message: 'Cita cancelada y horario liberado.' };
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

// Helper for parsing time strings (e.g. "16:11:00" or "16:11") into Date objects
function parseTimeToDate(timeVal) {
  if (!timeVal) return new Date(0);
  const str = String(timeVal).trim();
  const match = str.match(/(\d{2}):(\d{2})(?::(\d{2}))?/);
  if (match) {
    const hh = match[1];
    const mm = match[2];
    const ss = match[3] || '00';
    return new Date(`1970-01-01T${hh}:${mm}:${ss}`);
  }
  return new Date(`1970-01-01T${str}`);
}

// Función auxiliar de validación de agenda (Punto 1)
async function validarDisponibilidadGroomer(id_trabajador, fecha_cita, hora_cita, id_servicio, id_cita_excluir) {
  const servicioReq = await serviciosData.getServicioById(id_servicio);
  // Sumamos 15 minutos por defecto para el horario de limpieza de la salida de la mascota
  const duracionReq = (servicioReq ? servicioReq.duracion_estimada_minutos : 30) + 15;
  
  const startA = parseTimeToDate(hora_cita);
  const endA = new Date(startA.getTime() + duracionReq * 60000);

  // Validar con otras citas
  const citasDelDia = await citasData.getCitasByFecha(fecha_cita);
  const citasDelGroomer = citasDelDia.filter(c => c.empleado_acargo === id_trabajador && c.estado_de_cita !== 'cancelado' && c.id_cita !== id_cita_excluir);

  for (const c of citasDelGroomer) {
    if (c.hora_cita) {
      const startB = parseTimeToDate(c.hora_cita);
      const durB = (c.duracion_estimada_minutos || 30) + 15;
      const endB = new Date(startB.getTime() + durB * 60000);
      
      if (startA < endB && startB < endA) {
          return { success: false, message: `Horario no disponible. El servicio dura ${duracionReq}m y hay solapamiento con otra cita a las ${c.hora_cita}.` };
      }
    }
  }

  // Validar con bloqueos de agenda
  const bloqueos = await citasData.getBloqueosByFecha(fecha_cita, id_trabajador);
  if (bloqueos && bloqueos.length > 0) {
    // Si hay un bloqueo de todo el día para ese trabajador
    return { success: false, message: 'El groomer tiene un bloqueo de agenda para esa fecha.' };
  }

  return null;
}

exports.getHorariosOcupados = async (id_groomer, fecha) => {
  const query = `
    SELECT c.hora_cita, (c.hora_cita + ((COALESCE(s.duracion_estimada_minutos, 30) + 15) || ' minutes')::interval)::time as hora_fin
    FROM CITAS c
    LEFT JOIN SERVICIOS s ON c.id_servicio = s.id_servicio
    WHERE c.empleado_acargo = $1 AND c.fecha_cita = $2 AND c.estado_de_cita != 'cancelado'
  `;
  const pool = require('../../config/db.js');
  const res = await pool.query(query, [id_groomer, fecha]);
  return { success: true, data: res.rows };
};

async function getGroomersForServicio(id_servicio) {
  const serviceReq = await serviciosData.getServicioById(id_servicio);
  if (!serviceReq) return [];
  
  const sName = serviceReq.nombre_del_servicio.toLowerCase();
  
  const groomingData = require('../../grooming/data/grooming.data.js');
  const allGroomers = await groomingData.getAllGroomers();
  
  return allGroomers.filter(g => {
    const hName = (g.nombre_habilidad || '').toLowerCase();
    if (sName.includes('baño') || sName.includes('bañar')) {
      return hName.includes('baño') || hName.includes('secado') || hName.includes('manejo');
    }
    if (sName.includes('corte') || sName.includes('pelo')) {
      return hName.includes('corte') || hName.includes('pelo') || hName.includes('stripping');
    }
    return true;
  });
}
