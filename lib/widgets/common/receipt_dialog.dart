import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../core/utils/currency_format.dart';
import '../../config/theme.dart';

class ReceiptPreview extends StatelessWidget {
  final OrderModel order;
  final String restaurantName;
  final String restaurantAddress;
  final String cashierName;
  final String customerName;

  const ReceiptPreview({
    super.key,
    required this.order,
    required this.restaurantName,
    this.restaurantAddress = '',
    this.cashierName = '',
    this.customerName = '',
  });

  static Future<PrintResult?> show(
    BuildContext context, {
    required OrderModel order,
    required String restaurantName,
    String restaurantAddress = '',
    String cashierName = '',
    String customerName = '',
  }) {
    return showDialog<PrintResult>(
      context: context,
      builder: (_) => ReceiptPreview(
        order: order,
        restaurantName: restaurantName,
        restaurantAddress: restaurantAddress,
        cashierName: cashierName,
        customerName: customerName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = restaurantName.isNotEmpty ? restaurantName : 'Resto POS';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.grey;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFFDFDFD);
    final footerBg = isDark ? const Color(0xFF16162A) : Colors.grey.shade50;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: screenHeight * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(children: [
                const Icon(Icons.receipt_long, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Struk Pembayaran',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.pop(context, PrintResult.cancel),
                ),
              ]),
            ),
            Expanded(
              child: Container(
                color: bgColor,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(children: [
                    Text(name.toUpperCase(),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
                        textAlign: TextAlign.center),
                    if (restaurantAddress.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(restaurantAddress,
                            style: TextStyle(fontSize: 10, color: subColor),
                            textAlign: TextAlign.center),
                      ),
                    const SizedBox(height: 3),
                    Text(formatDateShort(order.createdAt),
                        style: TextStyle(fontSize: 10, color: subColor),
                        textAlign: TextAlign.center),
                    if (cashierName.isNotEmpty)
                      Text('Dilayani: $cashierName',
                          style: TextStyle(fontSize: 10, color: subColor),
                          textAlign: TextAlign.center),
                    Divider(height: 18, color: isDark ? Colors.white12 : Colors.grey.shade300),
                    _row('No. Pesanan', '#${order.orderNumber}', textColor, subColor),
                    if (order.tableName.isNotEmpty)
                      _row('Meja', order.tableName, textColor, subColor),
                    if (customerName.isNotEmpty || order.customerName.isNotEmpty)
                      _row('Customer', customerName.isNotEmpty ? customerName : order.customerName, textColor, subColor),
                    _row('Tipe', order.orderType.name.toUpperCase(), textColor, subColor),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(flex: 5, child: Text('Item', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: subColor))),
                      Expanded(flex: 2, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: subColor))),
                      Expanded(flex: 3, child: Text('Jumlah', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: subColor))),
                    ]),
                    const SizedBox(height: 4),
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Row(children: [
                            Expanded(flex: 5, child: Text(item.name, style: TextStyle(fontSize: 11, color: textColor))),
                            Expanded(flex: 2, child: Text('${item.quantity}', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: textColor))),
                            Expanded(flex: 3, child: Text(formatCurrency(item.subtotal), textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: textColor))),
                          ]),
                        )),
                    const SizedBox(height: 8),
                    _row('Subtotal', formatCurrency(order.subtotal), textColor, subColor),
                    if (order.taxRate > 0)
                      _row('Pajak ${(order.taxRate * 100).toStringAsFixed(0)}%', formatCurrency(order.taxAmount), textColor, subColor),
                    if (order.serviceCharge > 0)
                      _row('Service ${(order.serviceCharge * 100).toStringAsFixed(0)}%', formatCurrency(order.serviceAmount), textColor, subColor),
                    if (order.discount > 0)
                      _row('Diskon', '-${formatCurrency(order.discount)}', Colors.red, Colors.red),
                    const SizedBox(height: 4),
                    _row('TOTAL', formatCurrency(order.total), textColor, subColor, bold: true, large: true),
                    if (order.amountPaid > 0) ...[
                      const SizedBox(height: 2),
                      _row('Dibayar', formatCurrency(order.amountPaid), textColor, subColor),
                      _row('Kembalian', formatCurrency(order.change), Colors.green, Colors.green),
                    ],
                    const SizedBox(height: 10),
                    Text('Terima Kasih', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textColor), textAlign: TextAlign.center),
                    Text('Atas Kunjungan Anda', style: TextStyle(color: subColor, fontSize: 10), textAlign: TextAlign.center),
                  ]),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: footerBg,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, PrintResult.cancel),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Tutup', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, PrintResult.print),
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('Cetak', style: TextStyle(fontSize: 13)),
                      style: FilledButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color textColor, Color subColor,
      {Color? color, bool bold = false, bool large = false}) {
    final c = color ?? textColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500, fontSize: large ? 14 : 11, color: c)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: large ? 15 : 11, color: c)),
      ]),
    );
  }
}

enum PrintResult { print, cancel }
