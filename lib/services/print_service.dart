import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../core/utils/currency_format.dart';

class PrintService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _printChar;

  Future<bool> isBluetoothAvailable() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (_) {
      return false;
    }
  }

  Future<List<BluetoothDevice>> scanDevices() async {
    final devices = <BluetoothDevice>[];

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
      FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          if (!devices.any((d) => d.remoteId == r.device.remoteId)) {
            devices.add(r.device);
          }
        }
      });
      await Future.delayed(const Duration(seconds: 8));
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    return devices;
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _device = device;
      await device.connect(autoConnect: false);
      final services = await device.discoverServices();

      for (final service in services) {
        for (final char in service.characteristics) {
          if (char.properties.write || char.properties.writeWithoutResponse) {
            _printChar = char;
            break;
          }
        }
        if (_printChar != null) break;
      }

      return _printChar != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    _printChar = null;
  }

  Future<bool> printReceipt(OrderModel order, String restaurantName) async {
    if (_printChar == null) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);

      final bytes = <int>[];

      bytes.addAll(generator.reset());

      String center(String text, int width) {
        final spaces = (width - text.length) ~/ 2;
        if (spaces <= 0) return text;
        return ' ' * spaces + text;
      }

      final lineWidth = 32;

      bytes.addAll(generator.text(
          center(restaurantName.toUpperCase(), lineWidth),
          styles: const PosStyles(bold: true, align: PosAlign.center)));
      bytes.addAll(generator.text(
          center('Restaurant POS System', lineWidth),
          styles: const PosStyles(
              align: PosAlign.center, height: PosTextSize.size1)));

      bytes.addAll(generator.hr());
      bytes.addAll(generator.emptyLines(1));

      bytes.addAll(generator.row([
        PosColumn(text: 'No: ${order.orderNumber}', width: 6),
        PosColumn(
            text: formatDateShort(order.createdAt), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]));

      if (order.tableName.isNotEmpty) {
        bytes.addAll(generator.text('Meja: ${order.tableName}'));
      }
      if (order.customerName.isNotEmpty) {
        bytes.addAll(generator.text('Customer: ${order.customerName}'));
      }

      bytes.addAll(generator.text(
          'Tipe: ${order.orderType.name.toUpperCase()}'));
      bytes.addAll(generator.hr());

      bytes.addAll(generator.row([
        PosColumn(text: 'Item', width: 6),
        PosColumn(
            text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.center)),
        PosColumn(
            text: 'Harga', width: 4,
            styles: const PosStyles(align: PosAlign.right)),
      ]));

      bytes.addAll(generator.hr(ch: '-', linesAfter: 1));

      for (final item in order.items) {
        bytes.addAll(generator.row([
          PosColumn(text: item.name, width: 6),
          PosColumn(
              text: '${item.quantity}',
              width: 2,
              styles: const PosStyles(align: PosAlign.center)),
          PosColumn(
              text: formatCurrency(item.subtotal),
              width: 4,
              styles: const PosStyles(align: PosAlign.right)),
        ]));
      }

      bytes.addAll(generator.hr());

      bytes.addAll(generator.row([
        PosColumn(
            text: 'Subtotal',
            width: 6,
            styles: const PosStyles(bold: true)),
        PosColumn(
            text: formatCurrency(order.subtotal),
            width: 6,
            styles:
                const PosStyles(bold: true, align: PosAlign.right)),
      ]));

      if (order.taxRate > 0) {
        bytes.addAll(generator.row([
          PosColumn(text: 'Pajak (${(order.taxRate * 100).toStringAsFixed(0)}%)', width: 6),
          PosColumn(
              text: formatCurrency(order.taxAmount),
              width: 6,
              styles: const PosStyles(align: PosAlign.right)),
        ]));
      }

      if (order.discount > 0) {
        bytes.addAll(generator.row([
          PosColumn(text: 'Diskon', width: 6),
          PosColumn(
              text: '-${formatCurrency(order.discount)}',
              width: 6,
              styles: const PosStyles(align: PosAlign.right)),
        ]));
      }

      bytes.addAll(generator.hr(ch: '='));
      bytes.addAll(generator.row([
        PosColumn(
            text: 'TOTAL',
            width: 6,
            styles: const PosStyles(
                bold: true, height: PosTextSize.size2)),
        PosColumn(
            text: formatCurrency(order.total),
            width: 6,
            styles: const PosStyles(
                bold: true,
                align: PosAlign.right,
                height: PosTextSize.size2)),
      ]));

      bytes.addAll(generator.hr(ch: '='));
      bytes.addAll(generator.emptyLines(1));

      bytes.addAll(generator.text(
          center('Terima Kasih', lineWidth),
          styles: const PosStyles(
              align: PosAlign.center, bold: true)));
      bytes.addAll(generator.text(
          center('Atas Kunjungan Anda', lineWidth),
          styles:
              const PosStyles(align: PosAlign.center)));

      bytes.addAll(generator.emptyLines(2));
      bytes.addAll(generator.cut());

      await _printChar!.write(bytes, withoutResponse: false);
      return true;
    } catch (e) {
      debugPrint('Print error: $e');
      return false;
    }
  }
}
