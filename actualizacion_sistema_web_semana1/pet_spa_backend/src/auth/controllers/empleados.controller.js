const empleadosService = require('../services/empleados.services.js');

exports.getEmpleados = async (req, res) => {
  try {
    const empleados = await empleadosService.getAllEmpleados();
    res.status(200).json(empleados);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al obtener empleados.' });
  }
};

exports.updateEmpleado = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    const empleado = await empleadosService.updateEmpleado(id, updates);
    res.status(200).json({ message: 'Empleado actualizado.', empleado });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al actualizar empleado.' });
  }
};

exports.deleteEmpleado = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await empleadosService.deleteEmpleado(id);
    if (deleted) {
      res.status(200).json({ message: 'Empleado eliminado.' });
    } else {
      res.status(404).json({ message: 'Empleado no encontrado.' });
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al eliminar empleado.' });
  }
};

exports.getHabilidades = async (req, res) => {
  try {
    const habilidades = await empleadosService.getAllHabilidades();
    res.status(200).json(habilidades);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al obtener habilidades.' });
  }
};