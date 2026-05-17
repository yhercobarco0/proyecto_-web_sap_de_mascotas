import 'dart:async';

import 'package:flutter/material.dart';
import 'admin.view.dart';

class HomeScreen extends StatefulWidget {
  final String email;
  final String role;
  final String authToken;

  const HomeScreen({
    super.key,
    required this.email,
    required this.role,
    required this.authToken,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const inactivityDuration = Duration(minutes: 30);
  Timer? _logoutTimer;
  String _message = 'Sesión activa. Toca la pantalla para mantenerla abierta.';

  @override
  void initState() {
    super.initState();
    _resetLogoutTimer();
  }

  @override
  void dispose() {
    _logoutTimer?.cancel();
    super.dispose();
  }

  void _resetLogoutTimer() {
    _logoutTimer?.cancel();
    _logoutTimer = Timer(inactivityDuration, _handleLogout);
    setState(() {
      _message = 'Sesión activa. Toca la pantalla para mantenerla abierta.';
    });
  }

  void _handleLogout() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesión cerrada por inactividad. Por favor inicia sesión de nuevo.'),
      ),
    );
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _resetLogoutTimer,
      onPanDown: (_) => _resetLogoutTimer(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pet Spa - Panel de Usuario'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                _logoutTimer?.cancel();
                Navigator.pushReplacementNamed(context, '/login');
              },
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Bienvenido, ${widget.email}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Rol: ${widget.role}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 12),
              Text(_message, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 32),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Acciones disponibles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      Text('• Gestión de usuarios'),
                      Text('• Registro de mascotas'),
                      Text('• Reservas de servicios'),
                      Text('• Consulta de estado de cuenta'),
                    ],
                  ),
                ),
              ),
              if (widget.role == 'Administrador') ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminScreen(authToken: widget.authToken),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Abrir panel de administrador', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: _resetLogoutTimer,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Renovar sesión', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
