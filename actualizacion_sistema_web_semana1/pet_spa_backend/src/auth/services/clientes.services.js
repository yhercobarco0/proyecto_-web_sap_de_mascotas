const pool = require('../../config/db.js');

const getAllClientes = async () => {
  const query = `
    SELECT c.id_cliente, c.id_usuario, u.nombre, u.email, u.estado,
           c.telefono, c.direccion, c.ci
    FROM CLIENTES c
    JOIN USUARIOS u ON c.id_usuario = u.id_usuario
    ORDER BY c.id_cliente
  `;
  try {
    const res = await pool.query(query);
    return res.rows;
  } catch (err) {
    console.error('Error en getAllClientes:', err.message);
    throw err;
  }
};

const updateCliente = async (id_cliente, updates) => {
  const { nombre, email, telefono, direccion, ci } = updates;
  const query = `
    UPDATE CLIENTES c
    SET telefono  = COALESCE($1, c.telefono),
        direccion = COALESCE($2, c.direccion),
        ci        = COALESCE($3, c.ci)
    FROM USUARIOS u
    WHERE c.id_cliente = $4 AND c.id_usuario = u.id_usuario
    RETURNING c.*, u.nombre, u.email
  `;
  const values = [telefono || null, direccion || null, ci || null, id_cliente];
  try {
    const res = await pool.query(query, values);
    if (res.rows.length === 0) throw new Error('Cliente no encontrado');
    // Actualizar usuario si cambia nombre o email
    if (nombre || email) {
      await pool.query(
        `UPDATE USUARIOS SET
           nombre = COALESCE($1, nombre),
           email  = COALESCE($2, email)
         WHERE id_usuario = (SELECT id_usuario FROM CLIENTES WHERE id_cliente = $3)`,
        [nombre || null, email || null, id_cliente]
      );
    }
    return res.rows[0];
  } catch (err) {
    console.error('Error en updateCliente:', err.message);
    throw err;
  }
};

const deleteCliente = async (id_cliente) => {
  const query = `
    UPDATE USUARIOS SET estado = 'inactivo'
    WHERE id_usuario = (SELECT id_usuario FROM CLIENTES WHERE id_cliente = $1)
  `;
  try {
    const res = await pool.query(query, [id_cliente]);
    return res.rowCount > 0;
  } catch (err) {
    console.error('Error en deleteCliente:', err.message);
    throw err;
  }
};

module.exports = { getAllClientes, updateCliente, deleteCliente };