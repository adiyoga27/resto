import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../services/firebase_setup.dart';
import '../../config/theme.dart';

class SetupWizard extends StatefulWidget {
  const SetupWizard({super.key});

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(text: 'ajusadiyoga@gmail.com');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _setup() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Nama restoran wajib diisi');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final setup = FirebaseSetup();
      await setup.setupAll(restaurantName: _nameCtrl.text.trim());

      final uid = context.read<AuthProvider>().userId;
      if (uid == null || !mounted) return;

      final auth = context.read<AuthProvider>();
      await auth.init();

      if (mounted && uid.isNotEmpty) {
        context.read<RestaurantProvider>().load(uid);
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Gagal: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.restaurant_menu_rounded,
                        size: 56, color: Colors.cyanAccent),
                    const SizedBox(height: 16),
                    const Text('Setup Resto POS',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text('Konfigurasi awal untuk resto Anda',
                        style: TextStyle(
                            color: Colors.white.withAlpha(160), fontSize: 14)),
                    const SizedBox(height: 36),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(13),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withAlpha(20)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Informasi Restoran',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _nameCtrl,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: Colors.cyanAccent,
                            decoration: InputDecoration(
                              labelText: 'Nama Restoran *',
                              labelStyle: TextStyle(
                                  color: Colors.white.withAlpha(140)),
                              prefixIcon: const Icon(Icons.store,
                                  color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white.withAlpha(10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withAlpha(25)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.cyanAccent, width: 2),
                              ),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(_error!,
                                  style: const TextStyle(color: Colors.redAccent),
                                  textAlign: TextAlign.center),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(colors: [
                                Color(0xFF11998E),
                                Color(0xFF38EF7D),
                              ]),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _loading ? null : _setup,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  alignment: Alignment.center,
                                  child: _loading
                                      ? const SizedBox(width: 24, height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white))
                                      : const Text('Setup Sekarang',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Setup ini akan:\n'
                            '- Jadikan akun ini sebagai Superadmin\n'
                            '- Buat data restoran\n'
                            '- Set pajak 11% + service 2%\n',
                            style: TextStyle(
                                color: Colors.white.withAlpha(120),
                                fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
