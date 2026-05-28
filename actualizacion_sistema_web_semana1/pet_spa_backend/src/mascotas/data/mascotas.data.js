const pool = require('../../config/db.js');

const getMascotasByCliente = async (id_cliente) => {
  const res = await pool.query(
    `SELECT m.*, c.id_usuario FROM MASCOTAS m
     JOIN CLIENTES c ON m.id_cliente = c.id_cliente
     WHERE m.id_cliente = $1 ORDER BY m.id_mascota DESC`,
    [id_cliente]
  );
  return res.rows;
};

const getMascotaById = async (id_mascota) => {
  const res = await pool.query(
    `SELECT m.*, c.id_usuario FROM MASCOTAS m
     JOIN CLIENTES c ON m.id_cliente = c.id_cliente
     WHERE m.id_mascota = $1`,
    [id_mascota]
  );
  return res.rows[0] || null;
};

const getAllMascotas = async () => {
  const res = await pool.query(
    `SELECT m.*, u.nombre AS nombre_dueño, c.telefono, u.email
     FROM MASCOTAS m
     JOIN CLIENTES c ON m.id_cliente = c.id_cliente
     JOIN USUARIOS u ON c.id_usuario = u.id_usuario
     ORDER BY m.id_mascota DESC`
  );
  return res.rows;
};

const createMascota = async ({ id_cliente, nombre_mascota, raza, edad, tamano, peso, foto_mascota }) => {
  const res = await pool.query(
    `INSERT INTO MASCOTAS (id_cliente, nombre_mascota, raza, edad, tamano, peso, foto_mascota)
     VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
    [id_cliente, nombre_mascota, raza, edad, tamano, peso, foto_mascota]
  );
  return res.rows[0];
};

const updateMascota = async (id_mascota, { nombre_mascota, raza, edad, tamano, peso, foto_mascota }) => {
  const res = await pool.query(
    `UPDATE MASCOTAS SET
       nombre_mascota = COALESCE($1, nombre_mascota),
       raza          = COALESCE($2, raza),
       edad          = COALESCE($3, edad),
       tamano        = COALESCE($4, tamano),
       peso          = COALESCE($5, peso),
       foto_mascota  = COALESCE(NULLIF($6, ''), foto_mascota)
     WHERE id_mascota = $7 RETURNING *`,
    [nombre_mascota, raza, edad, tamano, peso, foto_mascota, id_mascota]
  );
  return res.rows[0];
};

const deleteMascota = async (id_mascota) => {
  await pool.query('DELETE FROM MASCOTAS WHERE id_mascota=$1', [id_mascota]);
};

const getVacunasByMascota = async (id_mascota) => {
  const res = await pool.query(
    `SELECT mv.*, v.nombre_vacuna, v.descripcion as desc_vacuna,
            u.nombre as nombre_trabajador
     FROM MASCOTA_VACUNAS mv
     JOIN VACUNAS v ON mv.id_vacuna = v.id_vacuna
     LEFT JOIN TRABAJADORES t ON mv.id_trabajadores = t.id_trabajadores
     LEFT JOIN USUARIOS u ON t.id_usuario = u.id_usuario
     WHERE mv.id_mascota = $1 ORDER BY mv.fecha_aplicacion DESC`,
    [id_mascota]
  );
  return res.rows;
};

const registrarVacuna = async ({ id_trabajadores, id_mascota, id_vacuna, fecha_aplicacion, fecha_proxima, observacion }) => {
  const res = await pool.query(
    `INSERT INTO MASCOTA_VACUNAS (id_trabajadores, id_mascota, id_vacuna, fecha_aplicacion, fecha_proxima, observacion)
     VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [id_trabajadores, id_mascota, id_vacuna, fecha_aplicacion, fecha_proxima, observacion]
  );
  return res.rows[0];
};

const getAllVacunas = async () => {
  const res = await pool.query('SELECT * FROM VACUNAS ORDER BY nombre_vacuna');
  return res.rows;
};

const getClienteByUserId = async (id_usuario) => {
  const res = await pool.query('SELECT * FROM CLIENTES WHERE id_usuario=$1 LIMIT 1', [id_usuario]);
  return res.rows[0] || null;
};

module.exports = {
  getMascotasByCliente,
  getMascotaById,
  getAllMascotas,
  createMascota,
  updateMascota,
  deleteMascota,
  getVacunasByMascota,
  registrarVacuna,
  getAllVacunas,
  getClienteByUserId,
};
