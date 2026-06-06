import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../core/utils/currency_format.dart';
import '../../config/theme.dart';

class ReceiptPreview extends StatelessWidget {
  final OrderModel order;
  final String restaurantName;
  final String customerName;

  const ReceiptPreview({
    super.key,
    required this.order,
    required this.restaurantName,
    this.customerName = '',
  });

  static Future<PrintResult?> show(
    BuildContext context, {
    required OrderModel order,
    required String restaurantName,
    String customerName = '',
  }) {
    return showDialog<PrintResult>(
      context: context,
      builder: (_) => ReceiptPreview(
        order: order,
        restaurantName: restaurantName,
        customerName: customerName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = restaurantName.isNotEmpty ? restaurantName : 'Resto POS';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long,
                      color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Struk Pembayaran',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFFFDFDFD),
              child: Column(
                children: [
                  Text(name.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center),
                  const Text('Restaurant POS System',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center),
                  const Divider(height: 24),
                  _row('No. Pesanan', '#${order.orderNumber}'),
                  if (order.tableName.isNotEmpty)
                    _row('Meja', order.tableName),
                  if (customerName.isNotEmpty || order.customerName.isNotEmpty)
                    _row('Customer',
                        customerName.isNotEmpty ? customerName : order.customerName),
                  _row('Tipe', order.orderType.name.toUpperCase()),
                  _row('Tanggal', formatDateShort(order.createdAt)),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Expanded(
                          flex: 5,
                          child: Text('Item',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12))),
                      const Expanded(
                          flex: 2,
                          child: Text('Qty',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12))),
                      const Expanded(
                          flex: 3,
                          child: Text('Harga',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                flex: 5,
                                child: Text(item.name,
                                    style: const TextStyle(fontSize: 12))),
                            Expanded(
                                flex: 2,
                                child: Text('${item.quantity}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12))),
                            Expanded(
                                flex: 3,
                                child: Text(
                                    formatCurrency(item.subtotal),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontSize: 12))),
                          ],
                        ),
                      )),
                  const Divider(height: 20),
                  _row('Subtotal', formatCurrency(order.subtotal)),
                  if (order.taxRate > 0)
                    _row(
                        'Pajak (${(order.taxRate * 100).toStringAsFixed(0)}%)',
                        formatCurrency(order.taxAmount)),
                  if (order.discount > 0)
                    _row('Diskon', '-${formatCurrency(order.discount)}',
                        color: Colors.red),
                  const Divider(height: 16),
                  _row('TOTAL', formatCurrency(order.total),
                      bold: true, large: true),
                  if (order.amountPaid > 0) ...[
                    const SizedBox(height: 4),
                    _row('Dibayar', formatCurrency(order.amountPaid)),
                    _row('Kembalian', formatCurrency(order.change),
                        color: Colors.green),
                  ],
                  const SizedBox(height: 16),
                  const Text('Terima Kasih',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      textAlign: TextAlign.center),
                  const Text('Atas Kunjungan Anda',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 11),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context, PrintResult.cancel);
                        },
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Tutup'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context, PrintResult.print);
                        },
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('Cetak'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
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
    );
  }

  Widget _row(String label, String value,
      {Color? color, bool bold = false, bool large = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  fontSize: large ? 15 : 12,
                  color: color)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: large ? 16 : 12,
                  color: color)),
        ],
      ),
    );
  }
}

enum PrintResult { print, cancel }
