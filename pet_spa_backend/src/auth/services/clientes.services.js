const pool = require('../../config/db.js');

const getAllClientes = async () => {
  const query = `
    SELECT c.id_cliente, u.nombre, u.email, u.estado, c.telefono, c.direccion
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
  const { nombre, email, telefono, direccion } = updates;
  const query = `
    UPDATE CLIENTES c
    SET telefono = $1, direccion = $2
    FROM USUARIOS u
    WHERE c.id_cliente = $3 AND c.id_usuario = u.id_usuario
    RETURNING c.*, u.nombre, u.email
  `;
  const values = [telefono, direccion, id_cliente];
  try {
    const res = await pool.query(query, values);
    if (res.rows.length === 0) throw new Error('Cliente no encontrado');
    // Actualizar usuario
    if (nombre || email) {
      const updateUserQuery = `UPDATE USUARIOS SET nombre = $1, email = $2 WHERE id_usuario = (SELECT id_usuario FROM CLIENTES WHERE id_cliente = $3)`;
      await pool.query(updateUserQuery, [nombre, email, id_cliente]);
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