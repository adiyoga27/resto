import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/settings_service.dart';
import '../../services/print_service.dart';
import '../../models/restaurant_settings.dart';
import '../../config/theme.dart';
import 'manage_users_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langProv = context.watch<LanguageProvider>();
    final themeProv = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (auth.isSuperAdmin) ...[
          _SettingsSection(title: 'Restoran', children: [
            ListTile(
              leading: const Icon(Icons.store, color: AppTheme.secondaryColor),
              title: const Text('Pengaturan Restoran'),
              subtitle: const Text('Nama, alamat, kontak, pajak, printer'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RestaurantSettingsScreen())),
            ),
          ]),
          const SizedBox(height: 8),
          _SettingsSection(title: 'Pengguna', children: [
            ListTile(
              leading: const Icon(Icons.group, color: AppTheme.secondaryColor),
              title: const Text('Kelola Pengguna'),
              subtitle: const Text('Tambah/hapus kasir & dapur'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ManageUsersScreen())),
            ),
          ]),
          const SizedBox(height: 8),
        ],
        _SettingsSection(title: 'Tampilan', children: [
          SwitchListTile(
            title: Text(l10n.darkMode),
            subtitle: Text(themeProv.isDarkMode ? 'Aktif' : 'Nonaktif'),
            value: themeProv.isDarkMode,
            onChanged: (_) => themeProv.toggleTheme(),
            secondary: Icon(
              themeProv.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: AppTheme.secondaryColor,
            ),
          ),
        ]),
        const SizedBox(height: 8),
        _SettingsSection(title: l10n.language, children: [
          ListTile(
            leading: Radio<String>(value: 'id', groupValue: langProv.locale.languageCode,
                onChanged: (v) => langProv.setLocale(const Locale('id'))),
            title: const Text('Bahasa Indonesia'),
            subtitle: const Text('Indonesia'),
            onTap: () => langProv.setLocale(const Locale('id')),
          ),
          ListTile(
            leading: Radio<String>(value: 'en', groupValue: langProv.locale.languageCode,
                onChanged: (v) => langProv.setLocale(const Locale('en'))),
            title: const Text('English'),
            subtitle: const Text('English'),
            onTap: () => langProv.setLocale(const Locale('en')),
          ),
        ]),
        const SizedBox(height: 8),
        _SettingsSection(title: l10n.about, children: [
          const ListTile(leading: Icon(Icons.info_outline), title: Text('Resto POS'), subtitle: Text('Versi 1.0.0')),
          const ListTile(leading: Icon(Icons.code), title: Text('Dibuat dengan Flutter'), subtitle: Text('Cross-platform POS Solution')),
        ]),
      ]),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias, margin: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryColor, fontSize: 14)),
        ),
        ...children,
        const SizedBox(height: 8),
      ]),
    );
  }
}

class RestaurantSettingsScreen extends StatefulWidget {
  const RestaurantSettingsScreen({super.key});
  @override
  State<RestaurantSettingsScreen> createState() => _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends State<RestaurantSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _serviceCtrl = TextEditingController();
  List<Map<String, String>> _printers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSettings());
  }

  void _loadSettings() {
    final auth = context.read<AuthProvider>();
    SettingsService().fetchSettings(auth.restaurantId).then((s) {
      if (mounted) {
        _nameCtrl.text = s.name;
        _addressCtrl.text = s.address;
        _phoneCtrl.text = s.phone;
        _emailCtrl.text = s.email;
        _taxCtrl.text = (s.taxRate * 100).toStringAsFixed(0);
        _serviceCtrl.text = (s.serviceCharge * 100).toStringAsFixed(0);
        _printers = s.printers;
        setState(() {});
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final settings = RestaurantSettings(
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      taxRate: (double.tryParse(_taxCtrl.text) ?? 11) / 100,
      serviceCharge: (double.tryParse(_serviceCtrl.text) ?? 2) / 100,
      printers: _printers,
    );
    await SettingsService().saveSettings(auth.restaurantId, settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan disimpan'), behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickPrinter() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => const _PrinterConfigScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        final exists = _printers.any((p) => p['address'] == result['address']);
        if (!exists) _printers.add(result);
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _addressCtrl.dispose(); _phoneCtrl.dispose();
    _emailCtrl.dispose(); _taxCtrl.dispose(); _serviceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Restoran')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Restoran', prefixIcon: Icon(Icons.store), border: OutlineInputBorder()),
                    validator: (v) => v?.isEmpty == true ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _addressCtrl, maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Alamat', prefixIcon: Icon(Icons.location_on_outlined), border: OutlineInputBorder(), alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 14),
                  TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telepon', prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder())),
                  const SizedBox(height: 14),
                  TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder())),
                  const SizedBox(height: 14),
                  TextField(controller: _taxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pajak Default (%)', suffixText: '%', prefixIcon: Icon(Icons.percent), border: OutlineInputBorder())),
                  const SizedBox(height: 14),
                  TextField(controller: _serviceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Service Charge (%)', suffixText: '%', prefixIcon: Icon(Icons.room_service_outlined), border: OutlineInputBorder())),
                  const SizedBox(height: 24),
                  const Text('Printer Bluetooth', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 10),
                  if (_printers.isNotEmpty)
                    ..._printers.asMap().entries.map((entry) {
                      final p = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(60),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          const Icon(Icons.print, color: AppTheme.secondaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(p['address'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ]),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Colors.red),
                            onPressed: () => setState(() => _printers.removeAt(entry.key)),
                            tooltip: 'Hapus',
                          ),
                        ]),
                      );
                    }),
                  OutlinedButton.icon(
                    onPressed: _pickPrinter,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(_printers.isEmpty ? 'Tambah Printer' : 'Tambah Printer Lain'),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Simpan Pengaturan'),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.successColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PrinterConfigScreen extends StatefulWidget {
  const _PrinterConfigScreen();
  @override
  State<_PrinterConfigScreen> createState() => _PrinterConfigScreenState();
}

class _PrinterConfigScreenState extends State<_PrinterConfigScreen> {
  final _printService = PrintService();
  List<BluetoothDevice> _devices = [];
  bool _scanning = true;
  BluetoothDevice? _connecting;
  StreamSubscription? _scanSub;

  @override
  void initState() { super.initState(); _scan(); }

  @override
  void dispose() { _scanSub?.cancel(); super.dispose(); }

  Future<void> _scan() async {
    setState(() { _scanning = true; _devices.clear(); });
    try {
      await _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        if (!mounted) return;
        final seen = <String>{};
        final list = <BluetoothDevice>[];
        for (final r in results) {
          final key = r.device.platformName.isNotEmpty ? r.device.platformName : r.device.remoteId.toString();
          if (!seen.contains(key)) { seen.add(key); list.add(r.device); }
        }
        setState(() => _devices = list);
      });
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 12));
      await Future.delayed(const Duration(seconds: 12));
    } catch (_) {} finally {
      if (mounted) { setState(() => _scanning = false); try { await FlutterBluePlus.stopScan(); } catch (_) {} } }
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _connecting = device);
    final ok = await _printService.connectToDevice(device);
    if (mounted) {
      setState(() => _connecting = null);
      if (ok) {
        Navigator.pop(context, {
          'name': device.platformName,
          'address': device.remoteId.toString(),
        });
        _printService.disconnect();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal konek')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Printer')),
      body: _scanning && _devices.isEmpty
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(), SizedBox(height: 12), Text('Mencari printer...')]))
          : _devices.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.bluetooth_disabled, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Tidak ada printer ditemukan'),
                  const SizedBox(height: 16),
                  FilledButton.icon(onPressed: _scan, icon: const Icon(Icons.refresh), label: const Text('Scan Ulang')),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _devices.length,
                  itemBuilder: (_, i) {
                    final d = _devices[i];
                    final name = d.platformName.isNotEmpty ? d.platformName : d.remoteId.toString();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.print),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(d.remoteId.toString(), style: const TextStyle(fontSize: 11)),
                        trailing: _connecting?.remoteId == d.remoteId
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : FilledButton(onPressed: () => _connect(d), child: const Text('Pilih')),
                      ),
                    );
                  },
                ),
    );
  }
}
