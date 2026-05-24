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
    UPDATE TRABAJADORES
    SET sueldo_mensual   = COALESCE($1, sueldo_mensual),
        id_habilidad     = COALESCE($2, id_habilidad),
        estado_trabajador = COALESCE($3, estado_trabajador)
    WHERE id_trabajadores = $4
    RETURNING *
  `;
  const values = [
    sueldo_mensual != null ? sueldo_mensual : null,
    id_habilidad   != null ? id_habilidad   : null,
    estado_trabajador || null,
    id_trabajadores,
  ];
  try {
    const res = await pool.query(query, values);
    if (res.rows.length === 0) throw new Error('Empleado no encontrado');
    // Actualizar usuario si cambia nombre o email
    if (nombre || email) {
      await pool.query(
        `UPDATE USUARIOS SET
           nombre = COALESCE($1, nombre),
           email  = COALESCE($2, email)
         WHERE id_usuario = (SELECT id_usuario FROM TRABAJADORES WHERE id_trabajadores = $3)`,
        [nombre || null, email || null, id_trabajadores]
      );
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