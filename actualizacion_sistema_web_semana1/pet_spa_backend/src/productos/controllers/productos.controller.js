const productosService = require('../services/productos.services.js');

exports.getProductos = async (req, res) => {
  try {
    const soloActivos = req.query.activos === 'true';
    const result = await productosService.getProductos(soloActivos);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getProductoById = async (req, res) => {
  try {
    const result = await productosService.getProductoById(req.params.id);
    res.status(result.success ? 200 : 404).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.crearProducto = async (req, res) => {
  try {
    const result = await productosService.crearProducto(req.body);
    res.status(result.success ? 201 : 400).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.actualizarProducto = async (req, res) => {
  try {
    const result = await productosService.actualizarProducto(req.params.id, req.body);
    res.status(result.success ? 200 : 404).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.ajustarStock = async (req, res) => {
  try {
    const result = await productosService.ajustarStock(req.params.id, req.body.cantidad);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getStockBajo = async (req, res) => {
  try {
    const result = await productosService.getStockBajo();
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.crearPedido = async (req, res) => {
  try {
    const result = await productosService.crearPedido(req.body.items, req.user.id_usuario);
    res.status(result.success ? 201 : 400).json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getMisPedidos = async (req, res) => {
  try {
    const result = await productosService.getMisPedidos(req.user.id_usuario);
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};

exports.getAllPedidos = async (req, res) => {
  try {
    const result = await productosService.getAllPedidos();
    res.json(result);
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
};
