const pool = require('../../config/db.js');

const getAllGroomers = async () => {
  const res = await pool.query(`
    SELECT t.*, u.nombre, u.email, h.nombre_habilidad
    FROM TRABAJADORES t
    JOIN USUARIOS u ON t.id_usuario = u.id_usuario
    LEFT JOIN HABILIDADES h ON t.id_habilidad = h.id_habilidad
    WHERE u.estado = 'activo' AND t.estado_trabajador = 'activo'
    ORDER BY u.nombre
  `);
  return res.rows;
};

const getTrabajadorByUserId = async (id_usuario) => {
  const res = await pool.query(
    `SELECT t.*, u.nombre, u.email, h.nombre_habilidad
     FROM TRABAJADORES t
     JOIN USUARIOS u ON t.id_usuario = u.id_usuario
     LEFT JOIN HABILIDADES h ON t.id_habilidad = h.id_habilidad
     WHERE t.id_usuario = $1 LIMIT 1`,
    [id_usuario]
  );
  return res.rows[0] || null;
};

// FICHAS GROOMING
const createFichaGrooming = async ({ id_cita, fecha_creacion, tiempo_espera }) => {
  // Check if already exists
  const existing = await pool.query('SELECT * FROM FICHAS_GROOMING WHERE id_cita=$1', [id_cita]);
  if (existing.rows[0]) return existing.rows[0];

  const res = await pool.query(
    `INSERT INTO FICHAS_GROOMING (id_cita, fecha_creacion, tiempo_espera_despues_servicio_minutos)
     VALUES ($1,$2,$3) RETURNING *`,
    [id_cita, fecha_creacion || new Date(), tiempo_espera || 15]
  );
  return res.rows[0];
};

const getFichaGroomingByCita = async (id_cita) => {
  const res = await pool.query(`
    SELECT fg.*, 
      json_agg(json_build_object(
        'id_insumo', fgi.id_ficha_grooming_insumos,
        'id_producto', fgi.id_producto,
        'nombre_producto', p.nombre_producto,
        'unidades_usadas', fgi.unidades_usadas
      )) FILTER (WHERE fgi.id_ficha_grooming_insumos IS NOT NULL) AS insumos
    FROM FICHAS_GROOMING fg
    LEFT JOIN FICHAS_GROOMING_INSUMOS fgi ON fg.id_fichas_grooming = fgi.id_fichas_grooming
    LEFT JOIN PRODUCTOS p ON fgi.id_producto = p.id_producto
    WHERE fg.id_cita = $1
    GROUP BY fg.id_fichas_grooming
  `, [id_cita]);
  return res.rows[0] || null;
};

const closeFichaGrooming = async (id_fichas_grooming) => {
  const res = await pool.query(
    `UPDATE FICHAS_GROOMING SET fecha_cierre = CURRENT_DATE WHERE id_fichas_grooming=$1 RETURNING *`,
    [id_fichas_grooming]
  );
  return res.rows[0];
};

const registrarInsumoGrooming = async ({ id_fichas_grooming, id_producto, unidades_usadas }) => {
  // Reduce stock
  await pool.query(
    `UPDATE PRODUCTOS SET stok_unidad = stok_unidad - $1 WHERE id_producto = $2 AND stok_unidad >= $1`,
    [unidades_usadas, id_producto]
  );
  const res = await pool.query(
    `INSERT INTO FICHAS_GROOMING_INSUMOS (id_fichas_grooming, id_producto, unidades_usadas)
     VALUES ($1,$2,$3) RETURNING *`,
    [id_fichas_grooming, id_producto, unidades_usadas]
  );
  return res.rows[0];
};

const getFichasByGroomer = async (id_trabajadores) => {
  const res = await pool.query(`
    SELECT fg.*, ci.fecha_cita, m.nombre_mascota, s.nombre_del_servicio
    FROM FICHAS_GROOMING fg
    JOIN CITAS ci ON fg.id_cita = ci.id_cita
    LEFT JOIN MASCOTAS m ON ci.id_mascota = m.id_mascota
    LEFT JOIN SERVICIOS s ON ci.id_servicio = s.id_servicio
    WHERE ci.empleado_acargo = $1
    ORDER BY fg.fecha_creacion DESC
  `, [id_trabajadores]);
  return res.rows;
};

// PAGOS EMPLEADOS
const getPagosEmpleado = async (id_trabajadores) => {
  const res = await pool.query(
    `SELECT * FROM PAGO_EMPLEADOS WHERE id_trabajadores=$1 ORDER BY fecha_pago_empleado DESC`,
    [id_trabajadores]
  );
  return res.rows;
};

const getAllPagosEmpleados = async () => {
  const res = await pool.query(`
    SELECT pe.*, u.nombre AS nombre_trabajador
    FROM PAGO_EMPLEADOS pe
    JOIN TRABAJADORES t ON pe.id_trabajadores = t.id_trabajadores
    JOIN USUARIOS u ON t.id_usuario = u.id_usuario
    ORDER BY pe.fecha_pago_empleado DESC
  `);
  return res.rows;
};

const createPagoEmpleado = async ({ id_trabajadores, monto, fecha_pago_empleado, periodo_desde, periodo_hasta, descripcion, estado_pago_empleado }) => {
  const res = await pool.query(
    `INSERT INTO PAGO_EMPLEADOS (id_trabajadores, monto, fecha_pago_empleado, periodo_desde, periodo_hasta, descripcion, estado_pago_empleado)
     VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
    [id_trabajadores, monto, fecha_pago_empleado, periodo_desde, periodo_hasta, descripcion, estado_pago_empleado || 'activo']
  );
  return res.rows[0];
};

// CAJAS
const getAllCajas = async () => {
  const res = await pool.query(`
    SELECT c.*, u.nombre AS nombre_responsable
    FROM CAJAS c
    LEFT JOIN TRABAJADORES t ON c.id_trabajadores = t.id_trabajadores
    LEFT JOIN USUARIOS u ON t.id_usuario = u.id_usuario
    ORDER BY c.nombre_caja
  `);
  return res.rows;
};

const getCajaById = async (id_cajas) => {
  const res = await pool.query('SELECT * FROM CAJAS WHERE id_cajas=$1', [id_cajas]);
  return res.rows[0] || null;
};

const createCaja = async ({ id_trabajadores, nombre_caja, descripcion, saldo_caja, estado_caja }) => {
  const res = await pool.query(
    `INSERT INTO CAJAS (id_trabajadores, nombre_caja, descripcion, saldo_caja, estado_caja)
     VALUES ($1,$2,$3,$4,$5) RETURNING *`,
    [id_trabajadores, nombre_caja, descripcion, saldo_caja || 0, estado_caja || 'activo']
  );
  return res.rows[0];
};

const updateSaldoCaja = async (id_cajas, monto) => {
  const res = await pool.query(
    `UPDATE CAJAS SET saldo_caja = saldo_caja + $1 WHERE id_cajas=$2 RETURNING *`,
    [monto, id_cajas]
  );
  return res.rows[0];
};

// TRANSACCIONES
const createTransaccion = async ({
  id_usuario_solicitante, id_caja, tipo, monto, descripcion,
  estado_administracion_aprob, estado_administracion_jefe
}) => {
  const res = await pool.query(`
    INSERT INTO TRANSACCIONES (id_usuario_solicitante, id_caja, tipo, monto, descripcion, fecha_solicitud,
      estado_administracion_aprob, estado_administracion_jefe)
    VALUES ($1,$2,$3,$4,$5,CURRENT_DATE,$6,$7) RETURNING *
  `, [id_usuario_solicitante, id_caja, tipo, monto, descripcion,
    estado_administracion_aprob || 'aprobado',
    estado_administracion_jefe || 'aprobado']);
  return res.rows[0];
};

const getAllTransacciones = async () => {
  const res = await pool.query(`
    SELECT tr.*, 
      u_sol.nombre AS nombre_solicitante,
      c.nombre_caja
    FROM TRANSACCIONES tr
    LEFT JOIN USUARIOS u_sol ON tr.id_usuario_solicitante = u_sol.id_usuario
    LEFT JOIN CAJAS c ON tr.id_caja = c.id_cajas
    ORDER BY tr.fecha_solicitud DESC
  `);
  return res.rows;
};

module.exports = {
  getAllGroomers, getTrabajadorByUserId,
  createFichaGrooming, getFichaGroomingByCita, closeFichaGrooming,
  registrarInsumoGrooming, getFichasByGroomer,
  getPagosEmpleado, getAllPagosEmpleados, createPagoEmpleado,
  getAllCajas, getCajaById, createCaja, updateSaldoCaja,
  createTransaccion, getAllTransacciones,
};
