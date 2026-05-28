const clientesService = require('../services/clientes.services.js');

exports.getClientes = async (req, res) => {
  try {
    const clientes = await clientesService.getAllClientes();
    res.status(200).json(clientes);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al obtener clientes.' });
  }
};

exports.updateCliente = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    const cliente = await clientesService.updateCliente(id, updates);
    res.status(200).json({ message: 'Cliente actualizado.', cliente });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al actualizar cliente.' });
  }
};

exports.deleteCliente = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await clientesService.deleteCliente(id);
    if (deleted) {
      res.status(200).json({ message: 'Cliente eliminado.' });
    } else {
      res.status(404).json({ message: 'Cliente no encontrado.' });
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al eliminar cliente.' });
  }
};