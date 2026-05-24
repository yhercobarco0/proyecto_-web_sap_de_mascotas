const pool = require('../../config/db.js');

const getResumenVentas = async (fechaDesde, fechaHasta) => {
  const res = await pool.query(`
    SELECT 
      COUNT(*) AS total_citas,
      SUM(monto_pagado) AS ingresos_servicios,
      AVG(monto_pagado) AS promedio_servicio
    FROM CITAS
    WHERE fecha_cita BETWEEN $1 AND $2
    AND estado_de_cita = 'terminado'
  `, [fechaDesde, fechaHasta]);
  return res.rows[0];
};

const getServiciosMasPopulares = async () => {
  const res = await pool.query(`
    SELECT s.nombre_del_servicio, COUNT(ci.id_cita) AS total_citas, 
           SUM(ci.monto_pagado) AS ingresos_totales
    FROM CITAS ci
    JOIN SERVICIOS s ON ci.id_servicio = s.id_servicio
    WHERE ci.estado_de_cita = 'terminado'
    GROUP BY s.id_servicio, s.nombre_del_servicio
    ORDER BY total_citas DESC
    LIMIT 10
  `);
  return res.rows;
};

const getRendimientoGroomers = async () => {
  const res = await pool.query(`
    SELECT u.nombre, COUNT(ci.id_cita) AS total_servicios,
           AVG(op.calificacion) AS calificacion_promedio,
           SUM(ci.monto_pagado) AS ingresos_generados
    FROM TRABAJADORES t
    JOIN USUARIOS u ON t.id_usuario = u.id_usuario
    LEFT JOIN CITAS ci ON ci.empleado_acargo = t.id_trabajadores
    LEFT JOIN OPINIONES op ON ci.id_cita = op.id_cita
    GROUP BY t.id_trabajadores, u.nombre
    ORDER BY total_servicios DESC
  `);
  return res.rows;
};

const getCitasPorDia = async (dias = 30) => {
  const res = await pool.query(`
    SELECT fecha_cita, COUNT(*) AS total, SUM(monto_pagado) AS ingresos
    FROM CITAS
    WHERE fecha_cita >= CURRENT_DATE - $1
    GROUP BY fecha_cita
    ORDER BY fecha_cita
  `, [dias]);
  return res.rows;
};

const getStockCritico = async () => {
  const res = await pool.query(`
    SELECT * FROM PRODUCTOS 
    WHERE stok_unidad <= 5 AND estado_de_producto = 'activo'
    ORDER BY stok_unidad
  `);
  return res.rows;
};

const getOpinionesRecientes = async (limite = 10) => {
  const res = await pool.query(`
    SELECT op.calificacion, op.comentario, op.fecha_opinion,
           u.nombre AS nombre_cliente, m.nombre_mascota, s.nombre_del_servicio
    FROM OPINIONES op
    JOIN CLIENTES cl ON op.id_cliente = cl.id_cliente
    JOIN USUARIOS u ON cl.id_usuario = u.id_usuario
    JOIN CITAS ci ON op.id_cita = ci.id_cita
    LEFT JOIN MASCOTAS m ON ci.id_mascota = m.id_mascota
    LEFT JOIN SERVICIOS s ON ci.id_servicio = s.id_servicio
    ORDER BY op.fecha_opinion DESC
    LIMIT $1
  `, [limite]);
  return res.rows;
};

const getDashboardStats = async () => {
  const [citasHoy, clientesTotal, mascotas, ingresosMes, opiniones] = await Promise.all([
    pool.query(`SELECT COUNT(*) AS total FROM CITAS WHERE fecha_cita = CURRENT_DATE AND estado_de_cita='activo'`),
    pool.query(`SELECT COUNT(*) AS total FROM CLIENTES`),
    pool.query(`SELECT COUNT(*) AS total FROM MASCOTAS`),
    pool.query(`SELECT COALESCE(SUM(monto_pagado),0) AS total FROM CITAS WHERE DATE_TRUNC('month', fecha_cita) = DATE_TRUNC('month', CURRENT_DATE) AND estado_de_cita='terminado'`),
    pool.query(`SELECT ROUND(AVG(calificacion),1) AS promedio FROM OPINIONES WHERE fecha_opinion >= CURRENT_DATE - 30`),
  ]);

  return {
    citas_hoy: citasHoy.rows[0].total,
    clientes_total: clientesTotal.rows[0].total,
    mascotas_total: mascotas.rows[0].total,
    ingresos_mes: ingresosMes.rows[0].total,
    calificacion_promedio: opiniones.rows[0].promedio || 0,
  };
};

module.exports = {
  getResumenVentas,
  getServiciosMasPopulares,
  getRendimientoGroomers,
  getCitasPorDia,
  getStockCritico,
  getOpinionesRecientes,
  getDashboardStats,
};
