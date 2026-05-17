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
  if (req.user.rol !== 'Administrador') {
    return res.status(403).json({ message: 'Acceso denegado. Solo administradores.' });
  }
  next();
};

const requirePersonalOrAdmin = (req, res, next) => {
  if (req.user.rol !== 'Administrador' && req.user.rol !== 'Recepción' && req.user.rol !== 'Groomers') {
    return res.status(403).json({ message: 'Acceso denegado.' });
  }
  next();
};

module.exports = { authenticateToken, requireAdmin, requirePersonalOrAdmin };