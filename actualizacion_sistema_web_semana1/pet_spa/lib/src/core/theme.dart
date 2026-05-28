import 'package:flutter/material.dart';

class PetSpaTheme {
  // COLORS
  static const purple = Color(0xFF7c3aed);
  static const purpleLight = Color(0xFF9f67ff);
  static const teal = Color(0xFF14b8a6);
  static const tealLight = Color(0xFF2dd4bf);
  static const gold = Color(0xFFf59e0b);
  static const goldLight = Color(0xFFfbbf24);
  static const pink = Color(0xFFec4899);
  static const bgDark = Color(0xFF080c14);
  static const bgCard = Color(0xFF0f1623);
  static const bgCard2 = Color(0xFF161e2e);
  static const textPrimary = Color(0xFFe2e8f0);
  static const textSecondary = Color(0xFF94a3b8);
  static const success = Color(0xFF10b981);
  static const danger = Color(0xFFef4444);

  static const gradientPurpleTeal = LinearGradient(
    colors: [purple, teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientBg = LinearGradient(
    colors: [Color(0xFF1a0533), Color(0xFF0d1f3c), Color(0xFF0a2a2a)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: purple,
      secondary: teal,
      surface: bgCard,
      onSurface: textPrimary,
    ),
    scaffoldBackgroundColor: bgDark,
    fontFamily: 'SF Pro Display',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: textPrimary,
      centerTitle: true,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 32),
      headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 24),
      titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 18),
      titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 16),
      bodyLarge: TextStyle(color: textPrimary, fontSize: 15),
      bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.07),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: purple, width: 2),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      prefixIconColor: textSecondary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: purple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        elevation: 8,
        shadowColor: purple.withOpacity(0.4),
      ),
    ),
    cardTheme: CardThemeData(
      color: bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.07)),
      ),
    ),
  );
}

// REUSABLE WIDGETS

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color? borderColor;
  const GlassCard({super.key, required this.child, this.padding, this.borderRadius = 20, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PetSpaTheme.bgCard.withOpacity(0.85),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? Colors.white.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final List<Color> colors;
  final Widget? icon;
  const GradientButton({super.key, required this.text, this.onPressed, this.isLoading = false, this.colors = const [PetSpaTheme.purple, PetSpaTheme.purpleLight], this.icon});

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;
    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: isDisabled ? [Colors.grey.shade800, Colors.grey.shade700] : colors),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDisabled ? [] : [BoxShadow(color: colors.first.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[icon!, const SizedBox(width: 8)],
                    Text(text, style: TextStyle(color: isDisabled ? Colors.white38 : Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  ],
                ),
        ),
      ),
    );
  }
}

class PetSpaTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final String? hint;
  const PetSpaTextField({super.key, required this.controller, required this.label, this.icon, this.obscure = false, this.keyboardType, this.onChanged, this.hint});

  @override
  State<PetSpaTextField> createState() => _PetSpaTextFieldState();
}

class _PetSpaTextFieldState extends State<PetSpaTextField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.obscure && !_visible,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        hintStyle: const TextStyle(color: PetSpaTheme.textSecondary),
        prefixIcon: widget.icon != null ? Icon(widget.icon, size: 20) : null,
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(_visible ? Icons.visibility_off : Icons.visibility, size: 20, color: PetSpaTheme.textSecondary),
                onPressed: () => setState(() => _visible = !_visible),
              )
            : null,
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  final List<Color> colors;
  const StatCard({super.key, required this.label, required this.value, required this.emoji, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors[0].withOpacity(0.18), colors[1].withOpacity(0.08)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors[0].withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: colors[0])),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? emoji;
  final Widget? action;
  const SectionTitle({super.key, required this.title, this.emoji, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (emoji != null) ...[Text(emoji!, style: const TextStyle(fontSize: 18)), const SizedBox(width: 8)],
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: PetSpaTheme.textPrimary)),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

class PetSpaSnack {
  static void show(BuildContext context, String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? PetSpaTheme.danger : PetSpaTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}

class BadgeChip extends StatelessWidget {
  final String label;
  final Color color;
  const BadgeChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
