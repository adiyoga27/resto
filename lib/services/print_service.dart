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
      await Future.delayed(const Duration(milliseconds: 500));
      final services = await device.discoverServices();

      BluetoothCharacteristic? writeChar;
      BluetoothCharacteristic? writeNoRespChar;

      for (final service in services) {
        debugPrint('Service: ${service.uuid}');
        for (final char in service.characteristics) {
          debugPrint('  Char: ${char.uuid} props=${char.properties}');
          if (char.properties.write) {
            writeChar = char;
          }
          if (char.properties.writeWithoutResponse) {
            writeNoRespChar = char;
          }
        }
      }

      _printChar = writeNoRespChar ?? writeChar;

      if (_printChar != null) {
        debugPrint('Found print char: ${_printChar!.uuid}');
      } else {
        debugPrint('No writable characteristic found!');
      }

      return _printChar != null;
    } catch (e) {
      debugPrint('Connect error: $e');
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

  Future<bool> printReceipt(OrderModel order,
      {String restaurantName = '', String restaurantAddress = '', String cashierName = ''}) async {
    if (_printChar == null) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      final bytes = <int>[];

      final sm = const PosStyles(
        height: PosTextSize.size1,
        width: PosTextSize.size1,
      );
      final bold = sm.copyWith(bold: true);
      final center = sm.copyWith(align: PosAlign.center);
      final centerBold = bold.copyWith(align: PosAlign.center);
      final right = sm.copyWith(align: PosAlign.right);

      final name = restaurantName.isNotEmpty ? restaurantName : 'Resto POS';

      bytes.addAll(generator.reset());
      bytes.addAll(generator.text(name, styles: centerBold));
      if (restaurantAddress.isNotEmpty) {
        bytes.addAll(generator.text(restaurantAddress, styles: center));
      }
      bytes.addAll(generator.text(formatDateShort(order.createdAt), styles: center));
      if (cashierName.isNotEmpty) {
        bytes.addAll(generator.text('Dilayani: $cashierName', styles: center));
      }

      bytes.addAll(generator.hr());

      bytes.addAll(generator.row([
        PosColumn(text: 'No', width: 3, styles: sm),
        PosColumn(text: ': ${order.orderNumber}', width: 9, styles: sm),
      ]));
      if (order.tableName.isNotEmpty) {
        bytes.addAll(generator.row([
          PosColumn(text: 'Meja', width: 3, styles: sm),
          PosColumn(text: ': ${order.tableName}', width: 9, styles: sm),
        ]));
      }
      if (order.customerName.isNotEmpty) {
        bytes.addAll(generator.row([
          PosColumn(text: 'Customer', width: 3, styles: sm),
          PosColumn(text: ': ${order.customerName}', width: 9, styles: sm),
        ]));
      }
      bytes.addAll(generator.row([
        PosColumn(text: 'Tipe', width: 3, styles: sm),
        PosColumn(text: ': ${order.orderType.name.toUpperCase()}', width: 9, styles: sm),
      ]));

      bytes.addAll(generator.hr());

      bytes.addAll(generator.row([
        PosColumn(text: 'Item', width: 6, styles: bold),
        PosColumn(text: 'Qty', width: 2, styles: bold.copyWith(align: PosAlign.center)),
        PosColumn(text: 'Jumlah', width: 4, styles: bold.copyWith(align: PosAlign.right)),
      ]));

      for (final item in order.items) {
        bytes.addAll(generator.row([
          PosColumn(text: item.name, width: 6, styles: sm),
          PosColumn(text: '${item.quantity}', width: 2, styles: sm.copyWith(align: PosAlign.center)),
          PosColumn(text: formatCurrency(item.subtotal), width: 4, styles: sm.copyWith(align: PosAlign.right)),
        ]));
      }

      bytes.addAll(generator.hr());

      bytes.addAll(generator.row([
        PosColumn(text: 'Subtotal', width: 6, styles: sm),
        PosColumn(text: formatCurrency(order.subtotal), width: 6, styles: right),
      ]));

      if (order.taxRate > 0) {
        bytes.addAll(generator.row([
          PosColumn(text: 'Pajak ${(order.taxRate * 100).toStringAsFixed(0)}%', width: 6, styles: sm),
          PosColumn(text: formatCurrency(order.taxAmount), width: 6, styles: right),
        ]));
      }

      if (order.serviceCharge > 0) {
        bytes.addAll(generator.row([
          PosColumn(text: 'Service ${(order.serviceCharge * 100).toStringAsFixed(0)}%', width: 6, styles: sm),
          PosColumn(text: formatCurrency(order.serviceAmount), width: 6, styles: right),
        ]));
      }

      if (order.discount > 0) {
        bytes.addAll(generator.row([
          PosColumn(text: 'Diskon', width: 6, styles: sm),
          PosColumn(text: '-${formatCurrency(order.discount)}', width: 6, styles: right),
        ]));
      }

      bytes.addAll(generator.hr(ch: '='));

      bytes.addAll(generator.row([
        PosColumn(text: 'TOTAL', width: 6, styles: bold.copyWith(height: PosTextSize.size2)),
        PosColumn(text: formatCurrency(order.total), width: 6,
            styles: bold.copyWith(align: PosAlign.right, height: PosTextSize.size2)),
      ]));

      bytes.addAll(generator.hr(ch: '='));

      bytes.addAll(generator.text('', styles: sm));

      bytes.addAll(generator.text('Terima Kasih', styles: centerBold));
      bytes.addAll(generator.text('Atas Kunjungan Anda', styles: center));

      bytes.addAll(generator.emptyLines(2));
      bytes.addAll(generator.cut());

      debugPrint('Printing ${bytes.length} bytes...');

      if (_printChar!.properties.writeWithoutResponse) {
        const chunkSize = 20;
        for (var i = 0; i < bytes.length; i += chunkSize) {
          final end = (i + chunkSize > bytes.length) ? bytes.length : i + chunkSize;
          await _printChar!.write(bytes.sublist(i, end), withoutResponse: true);
        }
      } else {
        await _printChar!.write(bytes, withoutResponse: false);
      }

      debugPrint('Print completed');
      return true;
    } catch (e) {
      debugPrint('Print error: $e');
      return false;
    }
  }
}
