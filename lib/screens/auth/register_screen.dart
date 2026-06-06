import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _restaurantCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;
  int _step = 0;
  String _role = 'superadmin';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _restaurantCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Kata sandi tidak cocok');
      return;
    }
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      _phoneCtrl.text.trim(),
      _restaurantCtrl.text.trim(),
      _role,
    );
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
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: size.width > 500 ? 48 : 28,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
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
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white70),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            Text(
                              l10n.register,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _StepDot(active: _step >= 0),
                            Expanded(
                                child: Container(
                                    height: 2,
                                    color: _step >= 1
                                        ? Colors.cyanAccent
                                        : Colors.white12)),
                            _StepDot(active: _step >= 1),
                            Expanded(
                                child: Container(
                                    height: 2,
                                    color: _step >= 2
                                        ? Colors.cyanAccent
                                        : Colors.white12)),
                            _StepDot(active: _step >= 2),
                          ],
                        ),
                        const SizedBox(height: 28),
                        if (_step == 0) ...[
                          _ModernTextField(
                            controller: _nameCtrl,
                            label: l10n.name,
                            icon: Icons.person_outline,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return l10n.name;
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _ModernTextField(
                            controller: _restaurantCtrl,
                            label: l10n.restaurantName,
                            icon: Icons.store_mall_directory_outlined,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return l10n.restaurantName;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _ModernTextField(
                            controller: _phoneCtrl,
                            label: l10n.phone,
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(10),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withAlpha(25),
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _role,
                              dropdownColor: const Color(0xFF203A43),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15),
                              decoration: const InputDecoration(
                                labelText: 'Role',
                                labelStyle: TextStyle(
                                    color: Colors.white54, fontSize: 14),
                                prefixIcon: Icon(Icons.badge_outlined,
                                    color: Colors.white54, size: 22),
                                border: InputBorder.none,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'superadmin',
                                  child:
                                      Text('Super Admin (Pemilik)'),
                                ),
                                DropdownMenuItem(
                                  value: 'cashier',
                                  child: Text('Kasir'),
                                ),
                                DropdownMenuItem(
                                  value: 'kitchen',
                                  child: Text('Dapur'),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _role = v ?? 'superadmin'),
                            ),
                          ),
                        ] else if (_step == 1) ...[
                          _ModernTextField(
                            controller: _emailCtrl,
                            label: l10n.email,
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return l10n.email;
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _ModernTextField(
                            controller: _passwordCtrl,
                            label: l10n.password,
                            icon: Icons.lock_outlined,
                            obscure: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) return l10n.password;
                              if (v.length < 6) return 'Minimal 6 karakter';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _ModernTextField(
                            controller: _confirmCtrl,
                            label: l10n.confirmPassword,
                            icon: Icons.lock_outlined,
                            obscure: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return l10n.confirmPassword;
                              }
                              return null;
                            },
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withAlpha(15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.cyanAccent.withAlpha(40),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    color: Colors.cyanAccent, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  'Siap Mendaftar!',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(220),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _nameCtrl.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _restaurantCtrl.text,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(180),
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _emailCtrl.text,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(150),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent.withAlpha(25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _role.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.cyanAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                                        color: Colors.redAccent, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        if (_step < 2)
                          Container(
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
                                  color: const Color(0xFF00B4DB).withAlpha(80),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => setState(() => _step++),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Lanjut',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded,
                                          color: Colors.white, size: 22),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Consumer<AuthProvider>(
                            builder: (_, auth, __) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF11998E),
                                      Color(0xFF38EF7D),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF11998E).withAlpha(80),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap:
                                        auth.isLoading ? null : _register,
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
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
                                          : const Text(
                                              'Daftar Sekarang',
                                              style: TextStyle(
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
                        if (_step > 0) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _step--),
                              style: TextButton.styleFrom(
                                overlayColor: Colors.white.withAlpha(20),
                              ),
                              child: Text(
                                'Kembali',
                                style: TextStyle(
                                    color: Colors.white.withAlpha(160)),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              overlayColor: Colors.white.withAlpha(20),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: l10n.haveAccount,
                                    style: TextStyle(
                                        color: Colors.white.withAlpha(160)),
                                  ),
                                  TextSpan(
                                    text: l10n.login,
                                    style: const TextStyle(
                                      color: Colors.cyanAccent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
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
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  const _StepDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 32 : 12,
      height: 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: active
            ? const LinearGradient(colors: [
                Color(0xFF00B4DB),
                Color(0xFF0083B0),
              ])
            : null,
        color: active ? null : Colors.white12,
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: Colors.cyanAccent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.white.withAlpha(140), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white54, size: 22),
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
