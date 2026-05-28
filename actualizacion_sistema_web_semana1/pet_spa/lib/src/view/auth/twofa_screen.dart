import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../shell/app_shell.dart';

class TwoFaScreen extends StatefulWidget {
  final String tempToken;
  final String email;
  const TwoFaScreen({super.key, required this.tempToken, required this.email});
  @override
  State<TwoFaScreen> createState() => _TwoFaScreenState();
}

class _TwoFaScreenState extends State<TwoFaScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _verify() async {
    if (_ctrl.text.trim().length != 6) { setState(() => _error = 'Ingresa 6 dígitos'); return; }
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.verify2FA(widget.tempToken, _ctrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true && res['token'] != null) {
      await ApiService.saveSession(res['token'], res['rol'] ?? 'Clientes', widget.email);
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AppShell()), (_) => false);
    } else {
      setState(() => _error = res['message'] ?? 'Código inválido');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/login_bg.png', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: PetSpaTheme.bgDark.withOpacity(0.88))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: PetSpaTheme.bgCard.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [PetSpaTheme.gold.withOpacity(0.3), PetSpaTheme.gold.withOpacity(0.1)]),
                          border: Border.all(color: PetSpaTheme.gold.withOpacity(0.5), width: 2),
                        ),
                        child: const Center(child: Text('🔐', style: TextStyle(fontSize: 40))),
                      ),
                      const SizedBox(height: 20),
                      const Text('Verificación 2FA', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
                      const SizedBox(height: 8),
                      Text('Ingresa el código de Google Authenticator para\n${widget.email}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 13, height: 1.5)),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _ctrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: PetSpaTheme.textPrimary, letterSpacing: 14),
                        decoration: InputDecoration(
                          hintText: '000000',
                          counterText: '',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), letterSpacing: 14),
                        ),
                        onChanged: (v) { if (v.length == 6) _verify(); },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: PetSpaTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text(_error!, style: const TextStyle(color: PetSpaTheme.danger, fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 24),
                      GradientButton(
                        text: 'Verificar Código',
                        onPressed: _verify,
                        isLoading: _loading,
                        colors: const [PetSpaTheme.gold, Color(0xFFf97316)],
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('← Volver al login', style: TextStyle(color: PetSpaTheme.textSecondary)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
