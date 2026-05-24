const jwt = require('jsonwebtoken');
const authdata = require('../data/auth.data.js');

const JWT_SECRET = process.env.JWT_SECRET || 'petspa_secret_2026';

const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Token requerido.' });
  }

  try {
    const payload = jwt.verify(token, JWT_SECRET);
    const user = await authdata.findUserById(payload.id_usuario);
    if (!user || user.estado !== 'activo') {
      return res.status(401).json({ message: 'Usuario no válido.' });
    }

    req.user = user;
    next();
  } catch (error) {
    return res.status(403).json({ message: 'Token inválido.' });
  }
};

const requireAdmin = (req, res, next) => {
  if (req.user.rol?.toUpperCase() !== 'ADMINISTRADOR') {
    return res.status(403).json({ message: 'Acceso denegado. Solo administradores.' });
  }
  next();
};

const requireAdminOrRecepcion = (req, res, next) => {
  const r = req.user.rol?.toUpperCase();
  if (r !== 'ADMINISTRADOR' && r !== 'RECEPCIÓN' && r !== 'RECEPCION') {
    return res.status(403).json({ message: 'Acceso denegado. Se requiere Administrador o Recepción.' });
  }
  next();
};

const requirePersonalOrAdmin = (req, res, next) => {
  const allowedRoles = ['ADMINISTRADOR', 'RECEPCIÓN', 'RECEPCION', 'GROOMERS'];
  if (!allowedRoles.includes(req.user.rol?.toUpperCase())) {
    return res.status(403).json({ message: 'Acceso denegado.' });
  }
  next();
};

const requireGroomerOrAdmin = (req, res, next) => {
  const allowedRoles = ['ADMINISTRADOR', 'GROOMERS'];
  if (!allowedRoles.includes(req.user.rol?.toUpperCase())) {
    return res.status(403).json({ message: 'Acceso denegado. Se requiere Groomer o Administrador.' });
  }
  next();
};

const requireCliente = (req, res, next) => {
  if (req.user.rol?.toUpperCase() !== 'CLIENTES' && req.user.rol?.toUpperCase() !== 'CLIENTE') {
    return res.status(403).json({ message: 'Acceso denegado. Solo clientes.' });
  }
  next();
};

const requireClienteOrAdmin = (req, res, next) => {
  const r = req.user.rol?.toUpperCase();
  if (r !== 'CLIENTES' && r !== 'CLIENTE' && r !== 'ADMINISTRADOR' && r !== 'RECEPCIÓN' && r !== 'RECEPCION') {
    return res.status(403).json({ message: 'Acceso denegado.' });
  }
  next();
};

module.exports = {
  authenticateToken,
  requireAdmin,
  requireAdminOrRecepcion,
  requirePersonalOrAdmin,
  requireGroomerOrAdmin,
  requireCliente,
  requireClienteOrAdmin,
};