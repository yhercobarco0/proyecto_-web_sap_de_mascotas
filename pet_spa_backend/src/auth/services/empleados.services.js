const pool = require('../../config/db.js');

const getAllEmpleados = async () => {
  const query = `
    SELECT t.id_trabajadores, u.nombre, u.email, u.estado, t.sueldo_mensual, h.nombre_habilidad, t.estado_trabajador
    FROM TRABAJADORES t
    JOIN USUARIOS u ON t.id_usuario = u.id_usuario
    LEFT JOIN HABILIDADES h ON t.id_habilidad = h.id_habilidad
    ORDER BY t.id_trabajadores
  `;
  try {
    const res = await pool.query(query);
    return res.rows;
  } catch (err) {
    console.error('Error en getAllEmpleados:', err.message);
    throw err;
  }
};

const updateEmpleado = async (id_trabajadores, updates) => {
  const { nombre, email, sueldo_mensual, id_habilidad, estado_trabajador } = updates;
  const query = `
    UPDATE TRABAJADORES t
    SET sueldo_mensual = $1, id_habilidad = $2, estado_trabajador = $3
    FROM USUARIOS u
    WHERE t.id_trabajadores = $4 AND t.id_usuario = u.id_usuario
    RETURNING t.*, u.nombre, u.email
  `;
  const values = [sueldo_mensual, id_habilidad, estado_trabajador, id_trabajadores];
  try {
    const res = await pool.query(query, values);
    if (res.rows.length === 0) throw new Error('Empleado no encontrado');
    // También actualizar usuario si nombre o email cambian
    if (nombre || email) {
      const updateUserQuery = `UPDATE USUARIOS SET nombre = $1, email = $2 WHERE id_usuario = (SELECT id_usuario FROM TRABAJADORES WHERE id_trabajadores = $3)`;
      await pool.query(updateUserQuery, [nombre, email, id_trabajadores]);
    }
    return res.rows[0];
  } catch (err) {
    console.error('Error en updateEmpleado:', err.message);
    throw err;
  }
};

const deleteEmpleado = async (id_trabajadores) => {
  const query = `
    UPDATE USUARIOS SET estado = 'inactivo'
    WHERE id_usuario = (SELECT id_usuario FROM TRABAJADORES WHERE id_trabajadores = $1)
    RETURNING id_usuario
  `;
  try {
    const res = await pool.query(query, [id_trabajadores]);
    if (res.rowCount > 0) {
      await pool.query(`UPDATE TRABAJADORES SET estado_trabajador = 'inactivo' WHERE id_trabajadores = $1`, [id_trabajadores]);
      return true;
    }
    return false;
  } catch (err) {
    console.error('Error en deleteEmpleado:', err.message);
    throw err;
  }
};

const getAllHabilidades = async () => {
  const query = `SELECT * FROM HABILIDADES ORDER BY id_habilidad`;
  try {
    const res = await pool.query(query);
    return res.rows;
  } catch (err) {
    console.error('Error en getAllHabilidades:', err.message);
    throw err;
  }
};

module.exports = { getAllEmpleados, updateEmpleado, deleteEmpleado, getAllHabilidades };