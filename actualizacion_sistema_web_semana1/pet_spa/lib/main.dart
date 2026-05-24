import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/core/theme.dart';
import 'src/core/api_service.dart';
import 'src/view/auth/login_screen.dart';
import 'src/view/shell/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const PetSpaApp());
}

class PetSpaApp extends StatelessWidget {
  const PetSpaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetSpa — Tu mascota merece lo mejor',
      debugShowCheckedModeBanner: false,
      theme: PetSpaTheme.theme,
      home: const SplashRouter(),
    );
  }
}

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});
  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), _navigate);
  }

  void _navigate() {
    final token = ApiService.token;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => token != null ? const AppShell() : const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a0533), Color(0xFF0d1f3c), Color(0xFF0a2a2a)],
          ),
        ),
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFF7c3aed), Color(0xFF14b8a6)]),
                    boxShadow: [BoxShadow(color: const Color(0xFF7c3aed).withOpacity(0.5), blurRadius: 40, spreadRadius: 10)],
                  ),
                  child: const Center(child: Text('🐾', style: TextStyle(fontSize: 60))),
                ),
                const SizedBox(height: 28),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF9f67ff), Color(0xFF14b8a6)],
                  ).createShader(bounds),
                  child: const Text('PetSpa', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
                const SizedBox(height: 10),
                const Text('Tu mascota merece lo mejor', style: TextStyle(color: Colors.white54, fontSize: 16, letterSpacing: 1.2)),
                const SizedBox(height: 60),
                const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Color(0xFF14b8a6)),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
