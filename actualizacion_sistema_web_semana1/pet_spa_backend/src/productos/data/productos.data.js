const pool = require('../../config/db.js');

const getAllProductos = async (soloActivos = false) => {
  let query = 'SELECT * FROM PRODUCTOS';
  if (soloActivos) query += " WHERE estado_de_producto = 'activo'";
  query += ' ORDER BY nombre_producto';
  const res = await pool.query(query);
  return res.rows;
};

const getProductoById = async (id_producto) => {
  const res = await pool.query('SELECT * FROM PRODUCTOS WHERE id_producto=$1', [id_producto]);
  return res.rows[0] || null;
};

const createProducto = async ({ nombre_producto, descripcion, precio, stok_unidad, categoria }) => {
  const res = await pool.query(
    `INSERT INTO PRODUCTOS (nombre_producto, descripcion, precio, stok_unidad, categoria, estado_de_producto)
     VALUES ($1,$2,$3,$4,$5,'activo') RETURNING *`,
    [nombre_producto, descripcion, precio, stok_unidad, categoria]
  );
  return res.rows[0];
};

const updateProducto = async (id_producto, { nombre_producto, descripcion, precio, stok_unidad, categoria, estado_de_producto }) => {
  const res = await pool.query(
    `UPDATE PRODUCTOS SET
       nombre_producto   = COALESCE($1, nombre_producto),
       descripcion       = COALESCE($2, descripcion),
       precio            = COALESCE($3, precio),
       stok_unidad       = COALESCE($4, stok_unidad),
       categoria         = COALESCE($5, categoria),
       estado_de_producto = COALESCE($6, estado_de_producto)
     WHERE id_producto = $7 RETURNING *`,
    [nombre_producto, descripcion, precio, stok_unidad, categoria, estado_de_producto, id_producto]
  );
  return res.rows[0];
};

const updateStock = async (id_producto, cantidad) => {
  const res = await pool.query(
    `UPDATE PRODUCTOS SET stok_unidad = stok_unidad + $1 WHERE id_producto=$2 RETURNING *`,
    [cantidad, id_producto]
  );
  return res.rows[0];
};

const getProductosBajoStock = async () => {
  const res = await pool.query(
    `SELECT * FROM PRODUCTOS WHERE stok_unidad <= stock_minimo AND estado_de_producto = 'activo' ORDER BY stok_unidad`
  );
  return res.rows;
};

const createPedido = async ({ id_cliente, fecha_pedido }) => {
  const res = await pool.query(
    `INSERT INTO PEDIDIO_CLIENTE (id_cliente, fecha_pedido) VALUES ($1,$2) RETURNING *`,
    [id_cliente, fecha_pedido || new Date()]
  );
  return res.rows[0];
};

const createDetallePedido = async ({ id_pedidio_cliente, id_producto, cantidad, precio_unitario, total, id_total_mandado_a_caja }) => {
  // Reduce stock
  await pool.query(
    `UPDATE PRODUCTOS SET stok_unidad = stok_unidad - $1 WHERE id_producto = $2 AND stok_unidad >= $1`,
    [cantidad, id_producto]
  );
  const res = await pool.query(
    `INSERT INTO DETALLE_PEDIDO_CLIENTE (id_pedidio_cliente, id_producto, cantidad, precio_unitario, total, id_total_mandado_a_caja)
     VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [id_pedidio_cliente, id_producto, cantidad, precio_unitario, total, id_total_mandado_a_caja || null]
  );
  return res.rows[0];
};

const getPedidosByCliente = async (id_cliente) => {
  const res = await pool.query(`
    SELECT p.*, 
      json_agg(json_build_object(
        'id_detalle', d.id_detalle_pedido_cliente,
        'id_producto', d.id_producto,
        'nombre_producto', pr.nombre_producto,
        'cantidad', d.cantidad,
        'precio_unitario', d.precio_unitario,
        'total', d.total
      )) AS detalles
    FROM PEDIDIO_CLIENTE p
    LEFT JOIN DETALLE_PEDIDO_CLIENTE d ON p.id_pedidio_cliente = d.id_pedidio_cliente
    LEFT JOIN PRODUCTOS pr ON d.id_producto = pr.id_producto
    WHERE p.id_cliente = $1
    GROUP BY p.id_pedidio_cliente
    ORDER BY p.fecha_pedido DESC
  `, [id_cliente]);
  return res.rows;
};

const getAllPedidos = async () => {
  const res = await pool.query(`
    SELECT p.*, u.nombre AS nombre_cliente,
      json_agg(json_build_object(
        'id_producto', d.id_producto,
        'nombre_producto', pr.nombre_producto,
        'cantidad', d.cantidad,
        'precio_unitario', d.precio_unitario,
        'total', d.total
      )) AS detalles
    FROM PEDIDIO_CLIENTE p
    LEFT JOIN CLIENTES cl ON p.id_cliente = cl.id_cliente
    LEFT JOIN USUARIOS u ON cl.id_usuario = u.id_usuario
    LEFT JOIN DETALLE_PEDIDO_CLIENTE d ON p.id_pedidio_cliente = d.id_pedidio_cliente
    LEFT JOIN PRODUCTOS pr ON d.id_producto = pr.id_producto
    GROUP BY p.id_pedidio_cliente, u.nombre
    ORDER BY p.fecha_pedido DESC
  `);
  return res.rows;
};

module.exports = {
  getAllProductos, getProductoById, createProducto, updateProducto,
  updateStock, getProductosBajoStock,
  createPedido, createDetallePedido, getPedidosByCliente, getAllPedidos,
};
