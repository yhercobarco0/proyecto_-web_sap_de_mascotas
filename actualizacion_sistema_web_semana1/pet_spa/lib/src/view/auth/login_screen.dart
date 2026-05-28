import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../shell/app_shell.dart';
import 'twofa_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  double _passStrength = 0;

  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    ApiService.init();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() { _animCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); _nameCtrl.dispose(); _phoneCtrl.dispose(); _addressCtrl.dispose(); super.dispose(); }

  void _checkPassStrength(String v) {
    int score = 0;
    if (v.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(v)) score++;
    if (RegExp(r'[a-z]').hasMatch(v)) score++;
    if (RegExp(r'[0-9]').hasMatch(v)) score++;
    if (RegExp(r'[!@#\$%\^&*]').hasMatch(v)) score++;
    setState(() => _passStrength = score / 5);
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) { PetSpaSnack.show(context, 'Completa email y contraseña', error: true); return; }

    setState(() => _isLoading = true);

    if (_isLogin) {
      final res = await ApiService.login(email, pass);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (res['success'] == true && res['token'] != null) {
        await ApiService.saveSession(res['token'], res['rol'] ?? 'Clientes', email);
        if (mounted) Navigator.pushAndRemoveUntil(context, _fadeRoute(const AppShell()), (_) => false);
      } else if (res['requires2FA'] == true) {
        if (mounted) Navigator.push(context, _fadeRoute(TwoFaScreen(tempToken: res['tempToken'], email: email)));
      } else {
        PetSpaSnack.show(context, res['message'] ?? 'Error de login', error: true);
      }
    } else {
      final name = _nameCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      final addr = _addressCtrl.text.trim();
      if (name.isEmpty || phone.isEmpty || addr.isEmpty) { setState(() => _isLoading = false); PetSpaSnack.show(context, 'Completa todos los campos', error: true); return; }
      final res = await ApiService.registroCliente({'nombre': name, 'email': email, 'password': pass, 'telefono': phone, 'direccion': addr});
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (res['success'] == true) {
        PetSpaSnack.show(context, res['message'] ?? '¡Cuenta creada! Revisa tu email');
        setState(() { _isLogin = true; _passStrength = 0; _passCtrl.clear(); });
      } else {
        PetSpaSnack.show(context, res['message'] ?? 'Error al registrarse', error: true);
      }
    }
  }

  // ─── GOOGLE LOGIN ──────────────────────────────────────────────────────────
  Future<void> _loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      // Cerrar sesión previa de Google para mostrar selector de cuenta
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // Usuario canceló
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }

      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      final idToken = auth.idToken;

      if (accessToken == null && idToken == null) {
        if (mounted) {
          setState(() => _isGoogleLoading = false);
          PetSpaSnack.show(context, 'No se pudo obtener token de Google', error: true);
        }
        return;
      }

      // Enviar al backend
      final res = await ApiService.post('/login_google', {
        if (idToken != null) 'idToken': idToken,
        if (accessToken != null) 'accessToken': accessToken,
      });

      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      if (res['success'] == true && res['token'] != null) {
        await ApiService.saveSession(res['token'], res['rol'] ?? 'Clientes', account.email);
        if (mounted) Navigator.pushAndRemoveUntil(context, _fadeRoute(const AppShell()), (_) => false);
      } else if (res['requires2FA'] == true) {
        if (mounted) Navigator.push(context, _fadeRoute(TwoFaScreen(tempToken: res['tempToken'], email: account.email)));
      } else {
        PetSpaSnack.show(context, res['message'] ?? 'Error al iniciar con Google', error: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
        PetSpaSnack.show(context, 'Error al conectar con Google: ${e.toString().split('\n').first}', error: true);
      }
    }
  }

  PageRoute _fadeRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    transitionDuration: const Duration(milliseconds: 500),
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 768;

    return Scaffold(
      body: Stack(
        children: [
          // BG IMAGE
          Positioned.fill(child: Image.asset('assets/images/login_bg.png', fit: BoxFit.cover)),
          Positioned.fill(child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [PetSpaTheme.bgDark.withOpacity(0.7), PetSpaTheme.bgDark.withOpacity(0.95)],
              ),
            ),
          )),
          // CONTENT
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _buildHeroSection()),
                          const SizedBox(width: 48),
                          SizedBox(width: 420, child: FadeTransition(opacity: _fadeAnim, child: SlideTransition(position: _slideAnim, child: _buildFormCard()))),
                        ],
                      )
                    : Column(children: [
                        _buildBrandMobile(),
                        const SizedBox(height: 24),
                        FadeTransition(opacity: _fadeAnim, child: SlideTransition(position: _slideAnim, child: _buildFormCard())),
                      ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: PetSpaTheme.gradientPurpleTeal,
            boxShadow: [BoxShadow(color: PetSpaTheme.purple.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
          ),
          child: const Center(child: Text('🐾', style: TextStyle(fontSize: 44))),
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (b) => PetSpaTheme.gradientPurpleTeal.createShader(b),
          child: const Text('PetSpa', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
        ),
        const SizedBox(height: 12),
        const Text('Tu mascota merece\nlo mejor del mundo 🌟', style: TextStyle(fontSize: 22, color: Colors.white70, height: 1.5)),
        const SizedBox(height: 32),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset('assets/images/hero_banner.png', height: 260, width: double.infinity, fit: BoxFit.cover),
        ),
        const SizedBox(height: 24),
        Row(children: [
          _FeaturePill('✂️ Grooming Pro'),
          const SizedBox(width: 10),
          _FeaturePill('📅 Citas Online'),
          const SizedBox(width: 10),
          _FeaturePill('🛒 Tienda'),
        ]),
      ],
    );
  }

  Widget _buildBrandMobile() {
    return Column(children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: PetSpaTheme.gradientPurpleTeal,
          boxShadow: [BoxShadow(color: PetSpaTheme.purple.withOpacity(0.5), blurRadius: 24)]),
        child: const Center(child: Text('🐾', style: TextStyle(fontSize: 38))),
      ),
      const SizedBox(height: 14),
      ShaderMask(
        shaderCallback: (b) => PetSpaTheme.gradientPurpleTeal.createShader(b),
        child: const Text('PetSpa', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
      const SizedBox(height: 4),
      const Text('Tu mascota merece lo mejor 🌟', style: TextStyle(color: Colors.white54, fontSize: 14)),
    ]);
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: PetSpaTheme.bgCard.withOpacity(0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, offset: const Offset(0, 16))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(_isLogin ? 'Ingresa con tus credenciales' : 'Únete al mejor spa para mascotas',
            style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 28),

          if (!_isLogin) ...[
            PetSpaTextField(controller: _nameCtrl, label: 'Nombre completo', icon: Icons.person_outline),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: PetSpaTextField(controller: _phoneCtrl, label: 'Teléfono', icon: Icons.phone_outlined, keyboardType: TextInputType.phone)),
            ]),
            const SizedBox(height: 14),
            PetSpaTextField(controller: _addressCtrl, label: 'Dirección', icon: Icons.location_on_outlined),
            const SizedBox(height: 14),
          ],

          PetSpaTextField(controller: _emailCtrl, label: 'Correo electrónico', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          PetSpaTextField(controller: _passCtrl, label: 'Contraseña', icon: Icons.lock_outline, obscure: true, onChanged: _isLogin ? null : _checkPassStrength),

          if (!_isLogin) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _passStrength,
                backgroundColor: Colors.white.withOpacity(0.08),
                color: _passStrength < 0.4 ? PetSpaTheme.danger : _passStrength < 0.8 ? PetSpaTheme.gold : PetSpaTheme.success,
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _passStrength == 1 ? '✅ Contraseña muy segura' : _passStrength >= 0.6 ? '🟡 Contraseña aceptable' : '🔴 Contraseña débil',
              style: TextStyle(fontSize: 11, color: _passStrength == 1 ? PetSpaTheme.success : _passStrength >= 0.6 ? PetSpaTheme.gold : PetSpaTheme.danger),
            ),
          ],

          const SizedBox(height: 24),
          GradientButton(
            text: _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
            onPressed: _submit,
            isLoading: _isLoading,
            colors: const [PetSpaTheme.purple, PetSpaTheme.teal],
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('o', style: TextStyle(color: PetSpaTheme.textSecondary, fontSize: 12))),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
          ]),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isGoogleLoading ? null : _loginWithGoogle,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.05),
              ),
              child: _isGoogleLoading
                  ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.g_mobiledata, color: Colors.redAccent, size: 28),
                        SizedBox(width: 10),
                        Text('Continuar con Google', style: TextStyle(color: PetSpaTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => setState(() { _isLogin = !_isLogin; _passStrength = 0; }),
            child: Text(
              _isLogin ? '¿No tienes cuenta? Regístrate aquí 🐾' : '¿Ya tienes cuenta? Inicia sesión',
              textAlign: TextAlign.center,
              style: const TextStyle(color: PetSpaTheme.purpleLight, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String label;
  const _FeaturePill(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: PetSpaTheme.purple.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PetSpaTheme.purple.withOpacity(0.3)),
      ),
      child: Text(label, style: const TextStyle(color: PetSpaTheme.purpleLight, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
