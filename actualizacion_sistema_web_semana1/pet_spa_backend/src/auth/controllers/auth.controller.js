const authservice = require('../services/auth.services.js');

const requestMeta = (req) => ({
  ip: req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'unknown',
  browser: req.headers['user-agent'] || 'unknown',
});

exports.registroCliente = async (req, res) => {
  try {
    const result = await authservice.registerCliente(req.body, requestMeta(req).ip, requestMeta(req).browser);
    if (result.success) {
      return res.status(201).json(result);
    }
    return res.status(400).json({ message: result.message });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: 'Error interno en registro de cliente.' });
  }
};

exports.registroAdmin = async (req, res) => {
  try {
    const result = await authservice.registerAdmin(req.body, requestMeta(req).ip, requestMeta(req).browser);
    if (result.success) {
      return res.status(201).json(result);
    }
    return res.status(400).json({ message: result.message });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: 'Error interno en registro de administrador.' });
  }
};

exports.registroEmpleado = async (req, res) => {
  try {
    const result = await authservice.registerEmpleado(req.body, req.user, requestMeta(req).ip, requestMeta(req).browser);
    if (result.success) {
      return res.status(201).json(result);
    }
    return res.status(400).json({ message: result.message });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: 'Error interno en registro de empleado.' });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const result = await authservice.login(email, password, requestMeta(req).ip, requestMeta(req).browser);
    if (result.success) {
      return res.status(200).json(result);
    }
    return res.status(401).json({ message: result.message });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: 'Error interno en inicio de sesión.' });
  }
};

exports.loginWithGoogle = async (req, res) => {
  try {
    const { idToken, accessToken } = req.body;
    const result = await authservice.loginWithGoogle(
      { idToken, accessToken },
      requestMeta(req).ip,
      requestMeta(req).browser
    );
    if (result.success) {
      return res.status(200).json(result);
    }
    return res.status(401).json({ message: result.message });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: 'Error interno en inicio con Google.' });
  }
};

exports.verifyTwoFactor = async (req, res) => {
  try {
    const { token, otp } = req.body;
    const result = await authservice.verifyTwoFactor(token, otp, requestMeta(req).ip, requestMeta(req).browser);
    if (result.success) {
      return res.status(200).json(result);
    }
    return res.status(401).json({ message: result.message });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: 'Error interno en verificación 2FA.' });
  }
};

exports.activarCuenta = async (req, res) => {
  try {
    const { token } = req.params;
    const result = await authservice.activateAccount(token, requestMeta(req).ip, requestMeta(req).browser);
    if (result.success) {
      return res.status(200).json(result);
    }
    return res.status(400).json({ message: result.message });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: 'Error interno al activar cuenta.' });
  }
};
exports.registroClienteAdmin = async (req, res) => {
  try {
    const result = await authservice.registerClienteAdmin(req.body, requestMeta(req).ip, requestMeta(req).browser);
    if (result.success) {
      return res.status(201).json(result);
    }
    return res.status(400).json({ message: result.message });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: 'Error interno en registro de cliente por admin.' });
  }
};














