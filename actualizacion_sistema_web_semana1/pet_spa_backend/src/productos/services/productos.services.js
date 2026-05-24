const productosData = require('../data/productos.data.js');
const mascotasData = require('../../mascotas/data/mascotas.data.js');

exports.getProductos = async (soloActivos) => {
  const productos = await productosData.getAllProductos(soloActivos);
  return { success: true, data: productos };
};

exports.getProductoById = async (id_producto) => {
  const producto = await productosData.getProductoById(id_producto);
  if (!producto) return { success: false, message: 'Producto no encontrado.' };
  return { success: true, data: producto };
};

exports.crearProducto = async ({ nombre_producto, descripcion, precio, stok_unidad, categoria }) => {
  if (!nombre_producto || !precio) return { success: false, message: 'Nombre y precio son requeridos.' };
  const producto = await productosData.createProducto({ nombre_producto, descripcion, precio, stok_unidad, categoria });
  return { success: true, data: producto, message: 'Producto creado.' };
};

exports.actualizarProducto = async (id_producto, payload) => {
  const producto = await productosData.updateProducto(id_producto, payload);
  if (!producto) return { success: false, message: 'Producto no encontrado.' };
  return { success: true, data: producto, message: 'Producto actualizado.' };
};

exports.ajustarStock = async (id_producto, cantidad) => {
  const producto = await productosData.updateStock(id_producto, cantidad);
  return { success: true, data: producto, message: `Stock ajustado en ${cantidad} unidades.` };
};

exports.getStockBajo = async () => {
  const productos = await productosData.getProductosBajoStock();
  return { success: true, data: productos };
};

exports.crearPedido = async (items, id_usuario) => {
  if (!items || items.length === 0) return { success: false, message: 'El pedido debe tener al menos un producto.' };

  const cliente = await mascotasData.getClienteByUserId(id_usuario);
  if (!cliente) return { success: false, message: 'Cliente no encontrado.' };

  const pedido = await productosData.createPedido({ id_cliente: cliente.id_cliente, fecha_pedido: new Date() });

  const detalles = [];
  for (const item of items) {
    const producto = await productosData.getProductoById(item.id_producto);
    if (!producto) continue;
    if (producto.stok_unidad < item.cantidad) {
      return { success: false, message: `Stock insuficiente para ${producto.nombre_producto}.` };
    }
    const detalle = await productosData.createDetallePedido({
      id_pedidio_cliente: pedido.id_pedidio_cliente,
      id_producto: item.id_producto,
      cantidad: item.cantidad,
      precio_unitario: producto.precio,
      total: producto.precio * item.cantidad,
    });
    // Descuento automatizado de stock
    await productosData.updateStock(item.id_producto, -item.cantidad);
    detalles.push(detalle);
  }

  return { success: true, data: { pedido, detalles }, message: 'Pedido creado correctamente.' };
};

exports.getMisPedidos = async (id_usuario) => {
  const cliente = await mascotasData.getClienteByUserId(id_usuario);
  if (!cliente) return { success: false, message: 'Cliente no encontrado.' };
  const pedidos = await productosData.getPedidosByCliente(cliente.id_cliente);
  return { success: true, data: pedidos };
};

exports.getAllPedidos = async () => {
  const pedidos = await productosData.getAllPedidos();
  return { success: true, data: pedidos };
};
