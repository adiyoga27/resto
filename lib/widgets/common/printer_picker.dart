import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../services/print_service.dart';
import '../../config/theme.dart';

class PrinterPicker extends StatefulWidget {
  const PrinterPicker({super.key});

  static Future<BluetoothDevice?> show(BuildContext context) {
    return showModalBottomSheet<BluetoothDevice>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const PrinterPicker(),
    );
  }

  @override
  State<PrinterPicker> createState() => _PrinterPickerState();
}

class _PrinterPickerState extends State<PrinterPicker> {
  final _printService = PrintService();
  List<BluetoothDevice> _devices = [];
  bool _scanning = false;
  BluetoothDevice? _connecting;
  StreamSubscription? _scanSub;

  @override
  void initState() {
    super.initState();
    _ensurePermissions();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  Future<void> _ensurePermissions() async {
    try {
      if (await FlutterBluePlus.isSupported == false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bluetooth tidak didukung di perangkat ini')),
          );
          Navigator.pop(context);
        }
        return;
      }
    } catch (_) {}

    await _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
      _devices.clear();
    });

    try {
      await _scanSub?.cancel();

      FlutterBluePlus.adapterState.listen((state) {
        if (state == BluetoothAdapterState.off) {
          FlutterBluePlus.turnOn();
        }
      });

      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        if (!mounted) return;
        setState(() {
          _devices.clear();
          final seen = <String>{};
          for (final r in results) {
            final name = r.device.platformName.isNotEmpty
                ? r.device.platformName
                : r.device.remoteId.toString();
            if (!seen.contains(name)) {
              seen.add(name);
              _devices.add(r.device);
            }
          }
        });
      });

      await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first;

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );

      await Future.delayed(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Scan error: $e');
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
        try { await FlutterBluePlus.stopScan(); } catch (_) {}
      }
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _connecting = device);
    final ok = await _printService.connectToDevice(device);
    if (mounted) {
      setState(() => _connecting = null);
      if (ok) {
        Navigator.pop(context, device);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal konek ke ${device.platformName}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollCtrl) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.bluetooth, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  const Text('Pilih Printer Bluetooth',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: _scanning
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh),
                    onPressed: _scanning ? null : _startScan,
                  ),
                ]),
                const SizedBox(height: 4),
                Text('Pastikan printer menyala & tidak terhubung ke perangkat lain',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 12),
                Expanded(
                  child: _scanning && _devices.isEmpty
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            const Text('Mencari printer...'),
                            const SizedBox(height: 8),
                            Text('Nyalakan printer & pastikan Bluetooth aktif',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          ]),
                        )
                      : _devices.isEmpty
                          ? Center(
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.bluetooth_disabled, size: 56, color: Colors.grey),
                                const SizedBox(height: 12),
                                const Text('Tidak ada printer ditemukan',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                const Text('Tips:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const Text('1. Matikan & nyalakan ulang printer'),
                                const Text('2. Pastikan Bluetooth HP aktif'),
                                const Text('3. Printer tidak terhubung ke HP lain'),
                                const Text('4. Coba pairing manual dari Settings HP'),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: _startScan,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Scan Ulang'),
                                ),
                              ]),
                            )
                          : ListView.builder(
                              controller: scrollCtrl,
                              shrinkWrap: true,
                              itemCount: _devices.length,
                              itemBuilder: (_, i) {
                                final device = _devices[i];
                                final name = device.platformName.isNotEmpty
                                    ? device.platformName
                                    : device.remoteId.toString();
                                final isConnecting =
                                    _connecting?.remoteId == device.remoteId;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          AppTheme.primaryColor.withAlpha(20),
                                      child: const Icon(Icons.print,
                                          color: AppTheme.primaryColor, size: 22),
                                    ),
                                    title: Text(name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600, fontSize: 14)),
                                    subtitle: Text(device.remoteId.toString(),
                                        style: const TextStyle(fontSize: 11)),
                                    trailing: isConnecting
                                        ? const SizedBox(width: 24, height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2))
                                        : FilledButton(
                                            onPressed: () => _connect(device),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: AppTheme.secondaryColor,
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 6),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: const Text('Pilih', style: TextStyle(fontSize: 12)),
                                          ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
