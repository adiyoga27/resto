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

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() => _scanning = true);
    final available = await _printService.isBluetoothAvailable();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth tidak tersedia')),
        );
        Navigator.pop(context);
      }
      return;
    }
    final devices = await _printService.scanDevices();
    if (mounted) {
      setState(() {
        _devices = devices;
        _scanning = false;
      });
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
          SnackBar(
            content: Text('Gagal konek ke ${device.platformName}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bluetooth, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text('Pilih Printer Bluetooth',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: _scanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  onPressed: _scanning ? null : _startScan,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_devices.isEmpty && !_scanning)
              Container(
                padding: const EdgeInsets.all(32),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.bluetooth_disabled,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Tidak ada printer ditemukan',
                          style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Text('Pastikan printer menyala dan Bluetooth aktif',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _devices.length,
                  itemBuilder: (_, i) {
                    final device = _devices[i];
                    final name =
                        device.platformName.isNotEmpty
                            ? device.platformName
                            : 'Unknown Device';
                    final isConnecting = _connecting?.remoteId == device.remoteId;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryColor.withAlpha(20),
                          child: Icon(
                            Icons.print,
                            color: AppTheme.primaryColor,
                            size: 22,
                          ),
                        ),
                        title: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        subtitle: Text(device.remoteId.toString(),
                            style: const TextStyle(fontSize: 11)),
                        trailing: isConnecting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : FilledButton(
                                onPressed: () => _connect(device),
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      AppTheme.secondaryColor,
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                ),
                                child: const Text('Pilih',
                                    style:
                                        TextStyle(fontSize: 12)),
                              ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
