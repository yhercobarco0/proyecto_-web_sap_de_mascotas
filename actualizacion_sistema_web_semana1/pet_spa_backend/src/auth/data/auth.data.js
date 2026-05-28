const pool = require('../../config/db.js');

const ROLE_MAP = {
  ADMINISTRADOR: 'Administrador',
  ADMIN: 'Administrador',
  RECEPCION: 'Recepción',
  RECEPCIONISTA: 'Recepción',
  'RECEPCIÓN': 'Recepción',
  GROOMER: 'Groomers',
  GROOMERS: 'Groomers',
  CLIENTE: 'Clientes',
  CLIENTES: 'Clientes',
};

const findUserByEmail = async (email) => {
  const query = `
    SELECT u.*, r.nombre AS rol, r.description AS rol_description,
           s.failed_attempts, s.locked_until, s.twofa_enabled, s.twofa_secret, s.last_activity
    FROM USUARIOS u
    LEFT JOIN ROLES r ON u.id_rol = r.id_rol
    LEFT JOIN USUARIO_SEGURIDAD s ON u.id_usuario = s.id_usuario
    WHERE UPPER(u.email) = UPPER($1)
    LIMIT 1
  `;
  const values = [email];

  try {
    const res = await pool.query(query, values);
    return res.rows[0] || null;
  } catch (err) {
    console.error('Error en findUserByEmail:', err.message);
    throw err;
  }
};

const findUserById = async (id_usuario) => {
  const query = `
    SELECT u.*, r.nombre AS rol, r.description AS rol_description,
           s.failed_attempts, s.locked_until, s.twofa_enabled, s.twofa_secret, s.last_activity
    FROM USUARIOS u
    LEFT JOIN ROLES r ON u.id_rol = r.id_rol
    LEFT JOIN USUARIO_SEGURIDAD s ON u.id_usuario = s.id_usuario
    WHERE u.id_usuario = $1
    LIMIT 1
  `;
  const values = [id_usuario];

  try {
    const res = await pool.query(query, values);
    return res.rows[0] || null;
  } catch (err) {
    console.error('Error en findUserById:', err.message);
    throw err;
  }
};

const findRoleByName = async (nombre) => {
  const query = 'SELECT * FROM ROLES WHERE UPPER(nombre) = UPPER($1) LIMIT 1';
  const res = await pool.query(query, [nombre]);
  return res.rows[0] || null;
};

const createRoleIfMissing = async (nombre, description) => {
  const existing = await findRoleByName(nombre);
  if (existing) {
    return existing.id_rol;
  }

  const query = 'INSERT INTO ROLES (nombre, description) VALUES ($1, $2) RETURNING id_rol';
  const res = await pool.query(query, [nombre, description || nombre]);
  return res.rows[0].id_rol;
};

// Roles válidos exactamente como están en la BD
const VALID_DB_ROLES = ['Administrador', 'Recepción', 'Groomers', 'Clientes'];

const getMappedRoleName = (rol) => {
  if (!rol) return 'Clientes';
  // Si ya es un nombre exacto de la BD, usarlo directamente
  if (VALID_DB_ROLES.includes(rol.toString().trim())) {
    return rol.toString().trim();
  }
  const normalized = rol.toString().trim().toUpperCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, ''); // Quitar tildes para normalizar
  return ROLE_MAP[normalized] || ROLE_MAP[rol.toString().trim().toUpperCase()] || 'Clientes';
};

const getRoleId = async (rol) => {
  const roleName = getMappedRoleName(rol);
  const descriptions = {
    Administrador: 'Acceso total al sistema',
    'Recepción': 'Personal de atención al cliente y agendamiento',
    Groomers: 'Personal encargado del spa de mascotas',
    Clientes: 'Dueño de mascota registrado en el sistema',
  };

  return await createRoleIfMissing(roleName, descriptions[roleName] || roleName);
};

const createUser = async ({ id_rol, nombre, email, password_hash, estado }) => {
  const query = `
    INSERT INTO USUARIOS (id_rol, nombre, email, password_hash, estado)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING *
  `;
  const values = [id_rol, nombre, email, password_hash, estado];
  const res = await pool.query(query, values);
  return res.rows[0];
};

const createUserSecurity = async (id_usuario) => {
  const query = `
    INSERT INTO USUARIO_SEGURIDAD (id_usuario)
    VALUES ($1)
    ON CONFLICT (id_usuario) DO NOTHING
    RETURNING *
  `;
  const res = await pool.query(query, [id_usuario]);
  return res.rows[0] || { id_usuario };
};

const createCliente = async ({ id_usuario, telefono, direccion, ci }) => {
  const query = `
    INSERT INTO CLIENTES (id_usuario, telefono, direccion, ci)
    VALUES ($1, $2, $3, $4)
    RETURNING *
  `;
  const values = [id_usuario, telefono, direccion, ci];
  const res = await pool.query(query, values);
  return res.rows[0];
};

const createTrabajador = async ({ id_usuario, sueldo_mensual, id_habilidad, estado_trabajador }) => {
  const query = `
    INSERT INTO TRABAJADORES (id_usuario, sueldo_mensual, id_habilidad, estado_trabajador)
    VALUES ($1, $2, $3, $4)
    RETURNING *
  `;
  const values = [id_usuario, sueldo_mensual || 0, id_habilidad || null, estado_trabajador || 'activo'];
  const res = await pool.query(query, values);
  return res.rows[0];
};

const updateFailedLoginAttempts = async (id_usuario, attempts) => {
  const query = `UPDATE USUARIO_SEGURIDAD SET failed_attempts = $1 WHERE id_usuario = $2`;
  await pool.query(query, [attempts, id_usuario]);
};

const lockUser = async (id_usuario, lockedUntil) => {
  const query = `UPDATE USUARIO_SEGURIDAD SET locked_until = $1 WHERE id_usuario = $2`;
  await pool.query(query, [lockedUntil, id_usuario]);
};

const resetFailedLoginAttempts = async (id_usuario) => {
  const query = `
    UPDATE USUARIO_SEGURIDAD
    SET failed_attempts = 0, locked_until = NULL
    WHERE id_usuario = $1
  `;
  await pool.query(query, [id_usuario]);
};

const activateUser = async (id_usuario) => {
  const query = `UPDATE USUARIOS SET estado = 'activo' WHERE id_usuario = $1`;
  await pool.query(query, [id_usuario]);
};

const updateTwoFactorSettings = async ({ id_usuario, twofa_enabled, twofa_secret }) => {
  const query = `
    UPDATE USUARIO_SEGURIDAD
    SET twofa_enabled = $1, twofa_secret = $2
    WHERE id_usuario = $3
  `;
  await pool.query(query, [twofa_enabled, twofa_secret, id_usuario]);
};

const updateLastActivity = async (id_usuario, timestamp) => {
  const query = `UPDATE USUARIO_SEGURIDAD SET last_activity = $1 WHERE id_usuario = $2`;
  await pool.query(query, [timestamp, id_usuario]);
};

module.exports = {
  findUserByEmail,
  findUserById,
  getRoleId,
  createUser,
  createUserSecurity,
  createCliente,
  createTrabajador,
  updateFailedLoginAttempts,
  lockUser,
  resetFailedLoginAttempts,
  activateUser,
  updateTwoFactorSettings,
  updateLastActivity,
};