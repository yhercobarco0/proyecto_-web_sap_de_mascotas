import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'home.view.dart';

const String googleWebClientId = '1060703810535-lb1i4upatckp3taivn54jj4ga25eklv6.apps.googleusercontent.com';
const String backendApiBase = 'http://localhost:3000/api';
// Si usas Android emulador: http://10.0.2.2:3000/api
// Si usas un teléfono real: usa la IP de tu PC como http://192.168.X.X:3000/api

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  double _passwordStrength = 0.0;
  bool _isLoading = false;
  Timer? _inactivityTimer;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    clientId: googleWebClientId,
    serverClientId: kIsWeb ? null : googleWebClientId,
  );

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ciController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  int _passwordLevel(String password) {
    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%\^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score;
  }

  void _checkPasswordStrength(String value) {
    setState(() {
      final score = _passwordLevel(value);
      _passwordStrength = score / 5;
    });
  }

  String _passwordHint(String value) {
    final errors = <String>[];
    if (value.length < 8) errors.add('8 caracteres');
    if (!RegExp(r'[A-Z]').hasMatch(value)) errors.add('mayúscula');
    if (!RegExp(r'[a-z]').hasMatch(value)) errors.add('minúscula');
    if (!RegExp(r'[0-9]').hasMatch(value)) errors.add('número');
    if (!RegExp(r'[!@#\$%\^&*(),.?":{}|<>]').hasMatch(value)) errors.add('símbolo');
    return errors.isEmpty ? 'Contraseña segura' : 'Falta: ${errors.join(', ')}';
  }

  Future<void> _submitForm() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena los campos obligatorios')),
      );
      return;
    }

    if (!_isLogin) {
      if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _addressController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completa todos los datos de registro del cliente')),
        );
        return;
      }
      if (_passwordLevel(_passwordController.text) < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tu contraseña no cumple los requisitos de seguridad')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    final endpoint = _isLogin ? 'login' : 'registro_cliente';
    final url = Uri.parse('$backendApiBase/$endpoint');

    final body = _isLogin
        ? {
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          }
        : {
            'nombre': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
            'telefono': _phoneController.text.trim(),
            'direccion': _addressController.text.trim(),
            'ci': _ciController.text.trim(),
          };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Acción completada correctamente'),
              backgroundColor: Colors.green,
            ),
          );

          if (_isLogin) {
            if (responseData['token'] != null) {
              _startInactivityTimer();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeScreen(
                    email: _emailController.text.trim(),
                    role: responseData['rol'] ?? 'Clientes',
                    authToken: responseData['token'],
                  ),
                ),
              );
            } else if (responseData['requires2FA'] == true && responseData['tempToken'] != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TwoFactorScreen(
                    tempToken: responseData['tempToken'],
                    email: _emailController.text.trim(),
                    role: responseData['rol'] ?? 'Clientes',
                  ),
                ),
              );
            }
          }

          if (!_isLogin) {
            setState(() {
              _isLogin = true;
            });
            _nameController.clear();
            _phoneController.clear();
            _ciController.clear();
            _addressController.clear();
            _passwordController.clear();
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Error al procesar la solicitud'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo conectar con el servidor.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fuerza nuevo flujo de autenticación para evitar sesiones incompletas sin idToken.
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inicio con Google cancelado')),
          );
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null && accessToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google no devolvió token de sesión. Revisa la configuración OAuth del cliente web.'),
            ),
          );
        }
        return;
      }

      final url = Uri.parse('$backendApiBase/login_google');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'idToken': idToken,
          'accessToken': accessToken,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        if (mounted) {
          if (responseData['token'] != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['message'] ?? 'Sesión iniciada con Google'),
                backgroundColor: Colors.green,
              ),
            );
            _startInactivityTimer();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HomeScreen(
                  email: googleUser.email,
                  role: responseData['rol'] ?? 'Clientes',
                  authToken: responseData['token'],
                ),
              ),
            );
          } else if (responseData['requires2FA'] == true && responseData['tempToken'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TwoFactorScreen(
                  tempToken: responseData['tempToken'],
                  email: googleUser.email,
                  role: responseData['rol'] ?? 'Clientes',
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['message'] ?? 'No se pudo iniciar sesión con Google.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Error al iniciar con Google'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error conectando con Google: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 30), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión cerrada por inactividad')),
        );
      }
    });
  }

  void _resetInactivityTimer() {
    _startInactivityTimer();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool obscureText = false,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetInactivityTimer,
      onPanDown: (_) => _resetInactivityTimer,
      child: Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                const BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.08),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pets, size: 72, color: Colors.teal),
                const SizedBox(height: 18),
                Text(
                  _isLogin ? 'Bienvenido al Pet Spa' : 'Registro de Cliente',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin
                      ? 'Ingresa con tu correo y contraseña'
                      : 'Registra tu cuenta para acceder al Spa',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),

                if (!_isLogin) ...[
                  _buildTextField(controller: _nameController, label: 'Nombre completo', icon: Icons.person),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _phoneController, label: 'Teléfono', icon: Icons.phone),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _ciController, label: 'C.I. / Identificación', icon: Icons.badge),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _addressController, label: 'Dirección', icon: Icons.location_on),
                  const SizedBox(height: 16),
                ],

                _buildTextField(controller: _emailController, label: 'Correo electrónico', icon: Icons.email),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Contraseña',
                  icon: Icons.lock,
                  obscureText: true,
                  onChanged: _isLogin ? null : _checkPasswordStrength,
                ),
                if (!_isLogin) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _passwordStrength,
                    backgroundColor: Colors.grey[300],
                    color: _passwordStrength < 0.4
                        ? Colors.red
                        : _passwordStrength < 0.8
                            ? Colors.orange
                            : Colors.green,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _passwordHint(_passwordController.text),
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    onPressed: _isLoading ? null : _submitForm,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(_isLogin ? 'INICIAR SESIÓN' : 'REGISTRARSE'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('O', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                    label: const Text('Continuar con Google'),
                    onPressed: _isLoading ? null : _loginWithGoogle,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _passwordStrength = 0.0;
                      _emailController.clear();
                      _passwordController.clear();
                      _nameController.clear();
                      _phoneController.clear();
                      _ciController.clear();
                      _addressController.clear();
                    });
                  },
                  child: Text(
                    _isLogin
                        ? '¿No tienes cuenta? Regístrate aquí (Solo clientes)'
                        : '¿Ya tienes cuenta? Inicia sesión',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }
}

class TwoFactorScreen extends StatefulWidget {
  final String tempToken;
  final String email;
  final String role;

  const TwoFactorScreen({
    super.key,
    required this.tempToken,
    required this.email,
    required this.role,
  });

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  String? _errorMessage;

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Ingresa el código de autenticación.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final url = Uri.parse('$backendApiBase/verify_2fa');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': widget.tempToken,
          'otp': _otpController.text.trim(),
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['token'] != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(
                email: widget.email,
                role: responseData['rol'] ?? widget.role,
                authToken: responseData['token'],
              ),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Código 2FA inválido.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudo verificar el código 2FA. Error: $e';
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación 2FA'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ingresa el código de tu aplicación de autenticación.', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            const Text(
              'Este código NO es captcha. Es el código de 6 dígitos que genera Google Authenticator/Authy para tu cuenta.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Text('Usuario: ${widget.email}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Código 2FA',
                border: OutlineInputBorder(),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isVerifying ? null : _verifyOtp,
              child: _isVerifying
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Verificar código'),
            ),
          ],
        ),
      ),
    );
  }
}
