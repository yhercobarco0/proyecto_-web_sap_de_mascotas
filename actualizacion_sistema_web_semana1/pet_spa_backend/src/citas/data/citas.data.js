const pool = require('../../config/db.js');

const getAllCitas = async () => {
  const res = await pool.query(`
    SELECT ci.*, 
      m.nombre_mascota, m.raza, m.tamano, m.peso,
      s.nombre_del_servicio, s.duracion_estimada_minutos, s.precio,
      u_cliente.nombre AS nombre_cliente,
      u_cliente.email AS email_cliente,
      cl.telefono AS telefono_cliente,
      u_groomer.nombre AS nombre_groomer,
      cl.id_cliente AS id_cliente_ref,
      fg.id_fichas_grooming, fg.fecha_cierre
    FROM CITAS ci
    LEFT JOIN MASCOTAS m ON ci.id_mascota = m.id_mascota
    LEFT JOIN SERVICIOS s ON ci.id_servicio = s.id_servicio
    LEFT JOIN CLIENTES cl ON ci.pagado_por_cliente = cl.id_cliente
    LEFT JOIN USUARIOS u_cliente ON cl.id_usuario = u_cliente.id_usuario
    LEFT JOIN TRABAJADORES t ON ci.empleado_acargo = t.id_trabajadores
    LEFT JOIN USUARIOS u_groomer ON t.id_usuario = u_groomer.id_usuario
    LEFT JOIN FICHAS_GROOMING fg ON ci.id_cita = fg.id_cita
    ORDER BY ci.fecha_cita DESC, ci.id_cita DESC
  `);
  return res.rows;
};

const getCitaById = async (id_cita) => {
  const res = await pool.query(`
    SELECT ci.*, 
      m.nombre_mascota, m.raza, m.tamano, m.peso,
      s.nombre_del_servicio, s.duracion_estimada_minutos, s.precio,
      u_cliente.nombre AS nombre_cliente,
      u_cliente.email AS correo_cliente,
      u_groomer.nombre AS nombre_groomer
    FROM CITAS ci
    LEFT JOIN MASCOTAS m ON ci.id_mascota = m.id_mascota
    LEFT JOIN SERVICIOS s ON ci.id_servicio = s.id_servicio
    LEFT JOIN CLIENTES cl ON ci.pagado_por_cliente = cl.id_cliente
    LEFT JOIN USUARIOS u_cliente ON cl.id_usuario = u_cliente.id_usuario
    LEFT JOIN TRABAJADORES t ON ci.empleado_acargo = t.id_trabajadores
    LEFT JOIN USUARIOS u_groomer ON t.id_usuario = u_groomer.id_usuario
    WHERE ci.id_cita = $1
  `, [id_cita]);
  return res.rows[0] || null;
};

const getCitasByFecha = async (fecha) => {
  const res = await pool.query(`
    SELECT ci.*, 
      m.nombre_mascota, m.raza, m.tamano, m.peso,
      s.nombre_del_servicio, s.duracion_estimada_minutos, s.precio,
      u_cliente.nombre AS nombre_cliente,
      u_groomer.nombre AS nombre_groomer
    FROM CITAS ci
    LEFT JOIN MASCOTAS m ON ci.id_mascota = m.id_mascota
    LEFT JOIN SERVICIOS s ON ci.id_servicio = s.id_servicio
    LEFT JOIN CLIENTES cl ON ci.pagado_por_cliente = cl.id_cliente
    LEFT JOIN USUARIOS u_cliente ON cl.id_usuario = u_cliente.id_usuario
    LEFT JOIN TRABAJADORES t ON ci.empleado_acargo = t.id_trabajadores
    LEFT JOIN USUARIOS u_groomer ON t.id_usuario = u_groomer.id_usuario
    WHERE ci.fecha_cita = $1
    ORDER BY ci.id_cita
  `, [fecha]);
  return res.rows;
};

const getCitasByCliente = async (id_cliente) => {
  const res = await pool.query(`
    SELECT ci.*, 
      m.nombre_mascota, m.raza,
      s.nombre_del_servicio, s.precio,
      u_groomer.nombre AS nombre_groomer,
      op.calificacion, op.comentario
    FROM CITAS ci
    LEFT JOIN MASCOTAS m ON ci.id_mascota = m.id_mascota
    LEFT JOIN SERVICIOS s ON ci.id_servicio = s.id_servicio
    LEFT JOIN TRABAJADORES t ON ci.empleado_acargo = t.id_trabajadores
    LEFT JOIN USUARIOS u_groomer ON t.id_usuario = u_groomer.id_usuario
    LEFT JOIN OPINIONES op ON ci.id_cita = op.id_cita AND op.id_cliente = $1
    WHERE ci.pagado_por_cliente = $1
    ORDER BY ci.fecha_cita DESC
  `, [id_cliente]);
  return res.rows;
};

const getCitasByGroomer = async (id_trabajador) => {
  const res = await pool.query(`
    SELECT ci.*, 
      m.nombre_mascota, m.raza, m.tamano, m.peso,
      s.nombre_del_servicio, s.duracion_estimada_minutos,
      u_cliente.nombre AS nombre_cliente
    FROM CITAS ci
    LEFT JOIN MASCOTAS m ON ci.id_mascota = m.id_mascota
    LEFT JOIN SERVICIOS s ON ci.id_servicio = s.id_servicio
    LEFT JOIN CLIENTES cl ON ci.pagado_por_cliente = cl.id_cliente
    LEFT JOIN USUARIOS u_cliente ON cl.id_usuario = u_cliente.id_usuario
    WHERE ci.empleado_acargo = $1
    ORDER BY ci.fecha_cita DESC
  `, [id_trabajador]);
  return res.rows;
};

const createCita = async ({
  id_mascota, id_servicio, pagado_por_cliente,
  empleado_acargo, monto_pagado, metodo_pago, fecha_cita, hora_cita, estado_de_cita
}) => {
  const res = await pool.query(`
    INSERT INTO CITAS (id_mascota, id_servicio, pagado_por_cliente, empleado_acargo,
      monto_pagado, metodo_pago, fecha_cita, hora_cita, estado_de_cita, motivo_cancelacion)
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,'No cancelado') RETURNING *
  `, [id_mascota, id_servicio, pagado_por_cliente, empleado_acargo,
    monto_pagado, metodo_pago || 'efectivo', fecha_cita, hora_cita, estado_de_cita || 'activo']);
  return res.rows[0];
};

const updateCita = async (id_cita, fields) => {
  const { estado_de_cita, motivo_cancelacion, monto_pagado, metodo_pago, empleado_acargo, fecha_cita, hora_cita,
    estado_de_mascota, foto_estado_mascota, monto_llevado_a_caja, conforme_cliente } = fields;
  const res = await pool.query(`
    UPDATE CITAS SET
      estado_de_cita = COALESCE($1, estado_de_cita),
      motivo_cancelacion = COALESCE($2, motivo_cancelacion),
      monto_pagado = COALESCE($3, monto_pagado),
      metodo_pago = COALESCE($4, metodo_pago),
      empleado_acargo = COALESCE($5, empleado_acargo),
      fecha_cita = COALESCE($6, fecha_cita),
      hora_cita = COALESCE($7, hora_cita),
      estado_de_mascota = COALESCE($8, estado_de_mascota),
      foto_estado_mascota = COALESCE($9, foto_estado_mascota),
      monto_llevado_a_caja = COALESCE($10, monto_llevado_a_caja),
      conforme_cliente = COALESCE($11, conforme_cliente)
    WHERE id_cita = $12 RETURNING *
  `, [estado_de_cita, motivo_cancelacion, monto_pagado, metodo_pago, empleado_acargo,
    fecha_cita, hora_cita, estado_de_mascota, foto_estado_mascota,
    monto_llevado_a_caja, conforme_cliente, id_cita]);
  return res.rows[0];
};

const registrarMovimiento = async ({ id_cita, fecha_anterior, fecha_nueva, id_usuario, descripcion }) => {
  const res = await pool.query(`
    INSERT INTO CITA_MOVIMIENTO (id_cita, fecha_anterior, fecha_nueva, id_usuario, descripcion, fecha_registro)
    VALUES ($1,$2,$3,$4,$5, CURRENT_DATE) RETURNING *
  `, [id_cita, fecha_anterior, fecha_nueva, id_usuario, descripcion]);
  return res.rows[0];
};

const getBloqueosByFecha = async (fecha, id_trabajador) => {
  let query = 'SELECT * FROM BLOQUEO_AGENDA WHERE fecha_bloqueo = $1';
  const params = [fecha];
  if (id_trabajador) {
    query += ' AND id_trabajadores = $2';
    params.push(id_trabajador);
  }
  const res = await pool.query(query, params);
  return res.rows;
};

const createBloqueo = async ({ id_trabajadores, fecha_bloqueo, motivo }) => {
  const res = await pool.query(
    `INSERT INTO BLOQUEO_AGENDA (id_trabajadores, fecha_bloqueo, motivo) VALUES ($1,$2,$3) RETURNING *`,
    [id_trabajadores, fecha_bloqueo, motivo]
  );
  return res.rows[0];
};

const deleteBloqueo = async (id_bloqueo) => {
  await pool.query('DELETE FROM BLOQUEO_AGENDA WHERE id_bloqueo_agenda=$1', [id_bloqueo]);
};

const registrarOpinion = async ({ id_cita, id_cliente, calificacion, comentario }) => {
  const res = await pool.query(`
    INSERT INTO OPINIONES (id_cita, id_cliente, calificacion, comentario, fecha_opinion)
    VALUES ($1,$2,$3,$4, CURRENT_DATE)
    ON CONFLICT DO NOTHING RETURNING *
  `, [id_cita, id_cliente, calificacion, comentario]);
  return res.rows[0];
};

const getOpinionesByCliente = async (id_cliente) => {
  const res = await pool.query(`
    SELECT op.*, m.nombre_mascota, s.nombre_del_servicio
    FROM OPINIONES op
    JOIN CITAS ci ON op.id_cita = ci.id_cita
    LEFT JOIN MASCOTAS m ON ci.id_mascota = m.id_mascota
    LEFT JOIN SERVICIOS s ON ci.id_servicio = s.id_servicio
    WHERE op.id_cliente = $1 ORDER BY op.fecha_opinion DESC
  `, [id_cliente]);
  return res.rows;
};

const getAllOpiniones = async () => {
  const res = await pool.query(`
    SELECT op.*, u.nombre AS nombre_cliente, m.nombre_mascota, s.nombre_del_servicio,
           u_g.nombre AS nombre_groomer
    FROM OPINIONES op
    JOIN CLIENTES cl ON op.id_cliente = cl.id_cliente
    JOIN USUARIOS u ON cl.id_usuario = u.id_usuario
    JOIN CITAS ci ON op.id_cita = ci.id_cita
    LEFT JOIN MASCOTAS m ON ci.id_mascota = m.id_mascota
    LEFT JOIN SERVICIOS s ON ci.id_servicio = s.id_servicio
    LEFT JOIN TRABAJADORES t ON ci.empleado_acargo = t.id_trabajadores
    LEFT JOIN USUARIOS u_g ON t.id_usuario = u_g.id_usuario
    ORDER BY op.fecha_opinion DESC
  `);
  return res.rows;
};

module.exports = {
  getAllCitas, getCitaById, getCitasByFecha, getCitasByCliente, getCitasByGroomer,
  createCita, updateCita, registrarMovimiento,
  getBloqueosByFecha, createBloqueo, deleteBloqueo,
  registrarOpinion, getOpinionesByCliente, getAllOpiniones,
};
