import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String? _error;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final success = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, '/');
    } else {
      setState(() => _error = AppLocalizations.of(context).error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width > 500 ? 48 : 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.cyanAccent, Colors.pinkAccent],
                        ).createShader(bounds),
                        child: const Icon(
                          Icons.restaurant_menu_rounded,
                          size: 72,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.appName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.appSubtitle,
                          style: TextStyle(
                            color: Colors.white.withAlpha(180),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(13),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withAlpha(20),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(40),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.welcomeBack,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),
                              _ModernTextField(
                                controller: _emailCtrl,
                                label: l10n.email,
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return l10n.email;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              _ModernTextField(
                                controller: _passwordCtrl,
                                label: l10n.password,
                                icon: Icons.lock_outlined,
                                obscure: _obscurePassword,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: Colors.white54,
                                    size: 22,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return l10n.password;
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _login(),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Colors.redAccent, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 28),
                              Consumer<AuthProvider>(
                                builder: (_, auth, __) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF00B4DB),
                                          Color(0xFF0083B0),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              const Color(0xFF00B4DB).withAlpha(80),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: auth.isLoading ? null : _login,
                                        borderRadius: BorderRadius.circular(14),
                                        child: Container(
                                          padding:
                                              const EdgeInsets.symmetric(vertical: 16),
                                          alignment: Alignment.center,
                                          child: auth.isLoading
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Text(
                                                  l10n.login,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.all(12),
                                  overlayColor:
                                      Colors.white.withAlpha(20),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const RegisterScreen()),
                                  );
                                },
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 14),
                                    children: [
                                      TextSpan(
                                        text: l10n.dontHaveAccount,
                                        style: TextStyle(
                                            color: Colors.white.withAlpha(160),
                                            fontWeight: FontWeight.w500),
                                      ),
                                      TextSpan(
                                        text: l10n.register,
                                        style: const TextStyle(
                                          color: Colors.cyanAccent,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: Colors.cyanAccent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.white.withAlpha(140), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white54, size: 22),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withAlpha(10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Colors.white.withAlpha(25), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
      ),
    );
  }
}
