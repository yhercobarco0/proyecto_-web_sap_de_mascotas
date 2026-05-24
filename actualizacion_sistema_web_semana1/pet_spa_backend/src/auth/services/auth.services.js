require('dotenv').config();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const speakeasy = require('speakeasy');
const { OAuth2Client } = require('google-auth-library');
const authdata = require('../data/auth.data.js');
const emailService = require('../utils/email.js');
const logger = require('../utils/logger.js');

const JWT_SECRET = process.env.JWT_SECRET || 'petspa_secret_2026';
const ADMIN_CREATION_KEY = process.env.ADMIN_CREATION_KEY || 'admin_creation_2026';
const ACTIVATION_EXPIRY_MINUTES = 15;
const LOCKOUT_THRESHOLD = 5;
const LOCKOUT_DURATION_MINUTES = 15;
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;

const googleClient = GOOGLE_CLIENT_ID ? new OAuth2Client(GOOGLE_CLIENT_ID) : null;

const validatePassword = (password) => {
  const errors = [];
  if (!password || password.length < 8) {
    errors.push('La contraseña debe tener al menos 8 caracteres.');
  }
  if (!/[A-Z]/.test(password)) {
    errors.push('Incluye al menos una letra mayúscula.');
  }
  if (!/[a-z]/.test(password)) {
    errors.push('Incluye al menos una letra minúscula.');
  }
  if (!/[0-9]/.test(password)) {
    errors.push('Incluye al menos un número.');
  }
  if (!/[!@#\$%\^&*(),.?":{}|<>]/.test(password)) {
    errors.push('Incluye al menos un símbolo especial.');
  }
  return errors;
};

const buildAuthToken = (user) => {
  return jwt.sign(
    {
      id_usuario: user.id_usuario,
      rol: user.rol,
      email: user.email,
    },
    JWT_SECRET,
    { expiresIn: '8h' }
  );
};

const buildActivationToken = (user) => {
  return jwt.sign(
    {
      id_usuario: user.id_usuario,
      email: user.email,
      action: 'activar_cuenta',
    },
    JWT_SECRET,
    { expiresIn: `${ACTIVATION_EXPIRY_MINUTES}m` }
  );
};

const buildTwoFactorTempToken = (user) => {
  return jwt.sign(
    {
      id_usuario: user.id_usuario,
      twofa: true,
    },
    JWT_SECRET,
    { expiresIn: '5m' }
  );
};

exports.registerCliente = async (payload, ip, browser) => {
  const { nombre, email, password, telefono, direccion, ci } = payload;

  if (!nombre || !email || !password || !telefono || !direccion) {
    return { success: false, message: 'Faltan datos obligatorios para el registro.' };
  }

  const passwordErrors = validatePassword(password);
  if (passwordErrors.length > 0) {
    return { success: false, message: passwordErrors.join(' ') };
  }

  const existingUser = await authdata.findUserByEmail(email);
  if (existingUser) {
    return { success: false, message: 'Ya existe una cuenta con ese correo.' };
  }

  const roleId = await authdata.getRoleId('CLIENTES');
  const passwordHash = await bcrypt.hash(password, 10);
  const user = await authdata.createUser({
    id_rol: roleId,
    nombre,
    email,
    password_hash: passwordHash,
    estado: 'inactivo',
  });

  await authdata.createUserSecurity(user.id_usuario);
  await authdata.createCliente({
    id_usuario: user.id_usuario,
    telefono,
    direccion,
    ci,
  });

  const activationToken = buildActivationToken(user);
  const activationLink = `http://localhost:${process.env.PORT || 3000}/api/activar/${activationToken}`;

  try {
    await emailService.sendActivationEmail({ email, nombre, activationLink });
  } catch (error) {
    console.error('Error enviando correo de activación:', error.message);
  }

  await logger.audit({
    userId: user.id_usuario,
    rol: 'Clientes',
    ip,
    browser,
    action: 'Registro cliente',
    details: { email, nombre },
  });

  return {
    success: true,
    message: 'Registro completado. Revisa tu correo para activar la cuenta.',
    activationLink,
  };
};

exports.registerAdmin = async (payload, ip, browser) => {
  const { nombre, email, password, adminKey } = payload;

  if (adminKey !== ADMIN_CREATION_KEY) {
    return { success: false, message: 'Llave de administrador inválida.' };
  }

  if (!nombre || !email || !password) {
    return { success: false, message: 'Faltan datos obligatorios para crear el administrador.' };
  }

  const passwordErrors = validatePassword(password);
  if (passwordErrors.length > 0) {
    return { success: false, message: passwordErrors.join(' ') };
  }

  const existingUser = await authdata.findUserByEmail(email);
  if (existingUser) {
    return { success: false, message: 'Ya existe una cuenta con ese correo.' };
  }

  const roleId = await authdata.getRoleId('ADMINISTRADOR');
  const passwordHash = await bcrypt.hash(password, 10);
  const user = await authdata.createUser({
    id_rol: roleId,
    nombre,
    email,
    password_hash: passwordHash,
    estado: 'activo',
  });

  await authdata.createUserSecurity(user.id_usuario);

  const secret = speakeasy.generateSecret({ name: `PetSpa Admin (${email})` });
  await authdata.updateTwoFactorSettings({
    id_usuario: user.id_usuario,
    twofa_enabled: true,
    twofa_secret: secret.base32,
  });

  await logger.audit({
    userId: user.id_usuario,
    rol: 'Administrador',
    ip,
    browser,
    action: 'Creación administrador',
    details: { email, nombre },
  });

  return {
    success: true,
    message: 'Administrador creado con 2FA obligatorio. Guarda este código en tu aplicación de autenticación.',
    twofaSecret: secret.base32,
    otpauthUrl: secret.otpauth_url,
  };
};

exports.registerEmpleado = async (payload, currentUser, ip, browser) => {
  const { nombre, email, password, rol, sueldo_mensual, id_habilidad } = payload;

  if (!currentUser || currentUser.rol !== 'Administrador') {
    return { success: false, message: 'Solo el administrador puede crear cuentas de personal.' };
  }

  if (!nombre || !email || !password) {
    return { success: false, message: 'Faltan datos obligatorios para crear al empleado.' };
  }

  const passwordErrors = validatePassword(password);
  if (passwordErrors.length > 0) {
    return { success: false, message: passwordErrors.join(' ') };
  }

  const existingUser = await authdata.findUserByEmail(email);
  if (existingUser) {
    return { success: false, message: 'Ya existe una cuenta con ese correo.' };
  }

  const roleId = await authdata.getRoleId(rol || 'Recepción');
  const passwordHash = await bcrypt.hash(password, 10);
  const user = await authdata.createUser({
    id_rol: roleId,
    nombre,
    email,
    password_hash: passwordHash,
    estado: 'activo',
  });

  await authdata.createUserSecurity(user.id_usuario);
  await authdata.createTrabajador({
    id_usuario: user.id_usuario,
    sueldo_mensual: Number.isFinite(Number(sueldo_mensual)) ? Number(sueldo_mensual) : 0,
    id_habilidad: Number.isInteger(Number(id_habilidad)) ? Number(id_habilidad) : null,
    estado_trabajador: 'activo',
  });

  await logger.audit({
    userId: user.id_usuario,
    rol: rol || 'Recepción',
    ip,
    browser,
    action: 'Creación empleado',
    details: { email, nombre, sueldo_mensual: Number.isFinite(Number(sueldo_mensual)) ? Number(sueldo_mensual) : 0, id_habilidad: Number.isInteger(Number(id_habilidad)) ? Number(id_habilidad) : null },
  });

  return {
    success: true,
    message: 'Empleado creado correctamente. Ya puede iniciar sesión con su cuenta.',
  };
};

exports.registerClienteAdmin = async (payload, ip, browser) => {
  const { nombre, email, password, telefono, direccion, ci } = payload;

  if (!nombre || !email || !password || !telefono || !direccion) {
    return { success: false, message: 'Faltan datos obligatorios para el registro.' };
  }

  const passwordErrors = validatePassword(password);
  if (passwordErrors.length > 0) {
    return { success: false, message: passwordErrors.join(' ') };
  }

  const existingUser = await authdata.findUserByEmail(email);
  if (existingUser) {
    return { success: false, message: 'Ya existe una cuenta con ese correo.' };
  }

  const roleId = await authdata.getRoleId('CLIENTES');
  const passwordHash = await bcrypt.hash(password, 10);
  const user = await authdata.createUser({
    id_rol: roleId,
    nombre,
    email,
    password_hash: passwordHash,
    estado: 'activo',
  });

  await authdata.createUserSecurity(user.id_usuario);
  await authdata.createCliente({
    id_usuario: user.id_usuario,
    telefono,
    direccion,
    ci: ci || null,
  });

  await logger.audit({
    userId: user.id_usuario,
    rol: 'Clientes',
    ip,
    browser,
    action: 'Creación cliente por admin',
    details: { email, nombre, telefono, direccion },
  });

  return { success: true, message: 'Cliente creado correctamente.' };
};

exports.login = async (email, password, ip, browser) => {
  const user = await authdata.findUserByEmail(email);
  if (!user) {
    return { success: false, message: 'Credenciales no válidas.' };
  }

  if (user.estado !== 'activo') {
    return { success: false, message: 'La cuenta no está activa. Revisa el correo de activación.' };
  }

  const lockedUntil = user.locked_until ? new Date(user.locked_until) : null;
  if (lockedUntil && lockedUntil > new Date()) {
    const diff = Math.ceil((lockedUntil - new Date()) / 60000);
    return { success: false, message: `Cuenta bloqueada por ${diff} minuto(s). Intenta nuevamente más tarde.` };
  }

  const passwordMatch = await bcrypt.compare(password, user.password_hash);
  if (!passwordMatch) {
    const newAttempts = (user.failed_attempts || 0) + 1;
    await authdata.updateFailedLoginAttempts(user.id_usuario, newAttempts);

    if (newAttempts >= LOCKOUT_THRESHOLD) {
      const lockedUntilDate = new Date(Date.now() + LOCKOUT_DURATION_MINUTES * 60 * 1000);
      await authdata.lockUser(user.id_usuario, lockedUntilDate);
      await logger.audit({
        userId: user.id_usuario,
        rol: user.rol,
        ip,
        browser,
        action: 'Bloqueo por intentos fallidos',
        details: { attempts: newAttempts },
      });
      return { success: false, message: 'Has superado los intentos permitidos. Tu cuenta queda bloqueada por 15 minutos.' };
    }

    await logger.audit({
      userId: user.id_usuario,
      rol: user.rol,
      ip,
      browser,
      action: 'Intento de login fallido',
      details: { attempts: newAttempts },
    });
    return { success: false, message: 'Credenciales no válidas.' };
  }

  await authdata.resetFailedLoginAttempts(user.id_usuario);
  await authdata.updateLastActivity(user.id_usuario, new Date());

  if (user.twofa_enabled) {
    const tempToken = buildTwoFactorTempToken(user);
    await logger.audit({
      userId: user.id_usuario,
      rol: user.rol,
      ip,
      browser,
      action: 'Login 2FA requerido',
      details: { email },
    });
    return { success: true, requires2FA: true, tempToken, rol: user.rol };
  }

  const token = buildAuthToken(user);
  await logger.audit({
    userId: user.id_usuario,
    rol: user.rol,
    ip,
    browser,
    action: 'Login exitoso',
    details: { email },
  });

  return { success: true, token, rol: user.rol };
};

const getGooglePayload = async ({ idToken, accessToken }) => {
  if (idToken) {
    const ticket = await googleClient.verifyIdToken({
      idToken,
      // audience: GOOGLE_CLIENT_ID, // Removido para aceptar tokens de cualquier cliente en el proyecto (web/mobile)
    });
    return ticket.getPayload();
  }

  if (accessToken) {
    const response = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    if (!response.ok) {
      throw new Error('No se pudo consultar userinfo de Google.');
    }
    return response.json();
  }

  return null;
};

exports.loginWithGoogle = async (googleTokens, ip, browser) => {
  if (!googleClient) {
    return { success: false, message: 'Google OAuth no configurado.' };
  }

  try {
    const payload = await getGooglePayload(googleTokens || {});

    if (!payload || !payload.email_verified) {
      return { success: false, message: 'Cuenta de Google no verificada.' };
    }

    const googleUser = {
      email: payload.email,
      name: payload.name,
      sub: payload.sub,
    };

    const existingUser = await authdata.findUserByEmail(googleUser.email);
    if (existingUser) {
      if (existingUser.estado !== 'activo') {
        return { success: false, message: 'La cuenta no está activa. Activa tu cuenta antes de iniciar sesión.' };
      }

      if (existingUser.twofa_enabled) {
        const tempToken = buildTwoFactorTempToken(existingUser);
        await logger.audit({
          userId: existingUser.id_usuario,
          rol: existingUser.rol,
          ip,
          browser,
          action: 'Login con Google 2FA requerido',
          details: { email: existingUser.email },
        });
        return { success: true, requires2FA: true, tempToken, rol: existingUser.rol };
      }

      const token = buildAuthToken(existingUser);
      await authdata.resetFailedLoginAttempts(existingUser.id_usuario);
      await authdata.updateLastActivity(existingUser.id_usuario, new Date());
      await logger.audit({
        userId: existingUser.id_usuario,
        rol: existingUser.rol,
        ip,
        browser,
        action: 'Login con Google',
        details: { email: existingUser.email },
      });
      return { success: true, token, rol: existingUser.rol };
    }

    const nombre = googleUser.name || googleUser.email.split('@')[0];
    const roleId = await authdata.getRoleId('Clientes');
    const passwordHash = await bcrypt.hash(Math.random().toString(36).slice(-12), 10);
    const user = await authdata.createUser({
      id_rol: roleId,
      nombre,
      email: googleUser.email,
      password_hash: passwordHash,
      estado: 'activo',
    });

    await authdata.createUserSecurity(user.id_usuario);
    await authdata.createCliente({
      id_usuario: user.id_usuario,
      telefono: null,
      direccion: null,
      ci: null,
    });

    await logger.audit({
      userId: user.id_usuario,
      rol: 'Clientes',
      ip,
      browser,
      action: 'Registro con Google',
      details: { email: user.email, nombre },
    });

    const token = buildAuthToken(user);
    return { success: true, token };
  } catch (error) {
    console.error('❌ Error en loginWithGoogle:', error);
    return { success: false, message: 'No se pudo validar la autenticación con Google.' };
  }
};

exports.verifyTwoFactor = async (tempToken, otp, ip, browser) => {
  try {
    const payload = jwt.verify(tempToken, JWT_SECRET);
    if (!payload.twofa) {
      return { success: false, message: 'Token 2FA inválido.' };
    }

    const user = await authdata.findUserById(payload.id_usuario);
    if (!user || !user.twofa_secret) {
      return { success: false, message: 'Usuario 2FA no encontrado.' };
    }

    const isValid = speakeasy.totp.verify({
      secret: user.twofa_secret,
      encoding: 'base32',
      token: otp,
      window: 1,
    });

    if (!isValid) {
      return { success: false, message: 'Código 2FA incorrecto.' };
    }

    const token = buildAuthToken(user);
    await authdata.updateLastActivity(user.id_usuario, new Date());
    await logger.audit({
      userId: user.id_usuario,
      rol: user.rol,
      ip,
      browser,
      action: 'Login 2FA exitoso',
      details: { email: user.email },
    });
    return { success: true, token, rol: user.rol };
  } catch (error) {
    return { success: false, message: 'Verificación 2FA inválida o expirada.' };
  }
};

exports.activateAccount = async (token, ip, browser) => {
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    if (payload.action !== 'activar_cuenta') {
      return { success: false, message: 'Token de activación inválido.' };
    }

    const user = await authdata.findUserById(payload.id_usuario);
    if (!user) {
      return { success: false, message: 'Usuario no encontrado.' };
    }
    if (user.estado === 'activo') {
      return { success: true, message: 'La cuenta ya está activa.' };
    }

    await authdata.activateUser(user.id_usuario);
    await authdata.resetFailedLoginAttempts(user.id_usuario);
    await logger.audit({
      userId: user.id_usuario,
      rol: user.rol,
      ip,
      browser,
      action: 'Activación de cuenta',
      details: { email: user.email },
    });
    return { success: true, message: 'Cuenta activada correctamente.' };
  } catch (error) {
    return { success: false, message: 'Token de activación inválido o expirado.' };
  }
};

