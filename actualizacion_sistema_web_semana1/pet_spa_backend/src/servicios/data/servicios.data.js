const pool = require('../../config/db.js');

const getAllServicios = async (soloActivos = false) => {
  let query = 'SELECT * FROM SERVICIOS';
  if (soloActivos) query += " WHERE estado_servicio = 'activo'";
  query += ' ORDER BY nombre_del_servicio';
  const res = await pool.query(query);
  return res.rows;
};

const getServicioById = async (id_servicio) => {
  const res = await pool.query('SELECT * FROM SERVICIOS WHERE id_servicio=$1', [id_servicio]);
  return res.rows[0] || null;
};

const createServicio = async ({ nombre_del_servicio, descripcion, duracion_estimada_minutos, precio }) => {
  const res = await pool.query(
    `INSERT INTO SERVICIOS (nombre_del_servicio, descripcion, duracion_estimada_minutos, precio, estado_servicio)
     VALUES ($1,$2,$3,$4,'activo') RETURNING *`,
    [nombre_del_servicio, descripcion, duracion_estimada_minutos, precio]
  );
  return res.rows[0];
};

const updateServicio = async (id_servicio, { nombre_del_servicio, descripcion, duracion_estimada_minutos, precio, estado_servicio }) => {
  const res = await pool.query(
    `UPDATE SERVICIOS SET
       nombre_del_servicio     = COALESCE($1, nombre_del_servicio),
       descripcion             = COALESCE($2, descripcion),
       duracion_estimada_minutos = COALESCE($3, duracion_estimada_minutos),
       precio                  = COALESCE($4, precio),
       estado_servicio         = COALESCE($5, estado_servicio)
     WHERE id_servicio = $6 RETURNING *`,
    [nombre_del_servicio, descripcion, duracion_estimada_minutos, precio, estado_servicio, id_servicio]
  );
  return res.rows[0];
};

const deleteServicio = async (id_servicio) => {
  await pool.query("UPDATE SERVICIOS SET estado_servicio='inactivo' WHERE id_servicio=$1", [id_servicio]);
};

module.exports = { getAllServicios, getServicioById, createServicio, updateServicio, deleteServicio };
