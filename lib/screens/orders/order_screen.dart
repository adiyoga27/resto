import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/order_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order.dart';
import '../../models/menu_item.dart';
import '../../models/table.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/utils/currency_format.dart';
import '../../core/utils/currency_formatter.dart';
import '../../config/theme.dart';
import '../../services/print_service.dart';
import '../../widgets/common/receipt_dialog.dart';
import '../../widgets/common/printer_picker.dart';
import '../../providers/restaurant_provider.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isKitchen) {
        context.read<OrderProvider>().setStatusFilter('active');
      }
    });
  }
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prov = context.watch<OrderProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.orders),
        actions: [
          Consumer<AuthProvider>(
            builder: (_, auth, __) {
              if (auth.isKitchen) return const SizedBox.shrink();
              return FilledButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateOrderScreen())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('POS'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withAlpha(30),
                  foregroundColor: Colors.white,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusFilter(prov, theme),
          Expanded(
            child: prov.filteredOrders.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 64, color: theme.colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(l10n.noData,
                          style: TextStyle(color: theme.colorScheme.outline)),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: prov.filteredOrders.length,
                    itemBuilder: (_, i) =>
                        _OrderCard(order: prov.filteredOrders[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(OrderProvider prov, ThemeData theme) {
    final auth = context.watch<AuthProvider>();
    final filters = auth.isKitchen
        ? {
            'pending': 'Menunggu',
            'preparing': 'Disiapkan',
            'ready': 'Siap',
            'served': 'Disajikan',
          }
        : {
            'all': 'Semua',
            'active': 'Aktif',
            'pending': 'Menunggu',
            'preparing': 'Disiapkan',
            'ready': 'Siap',
            'completed': 'Selesai',
            'cancelled': 'Dibatalkan',
          };
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: filters.entries.map((e) {
          final selected = prov.statusFilter == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.value, style: const TextStyle(fontSize: 12)),
              selected: selected,
              selectedColor: AppTheme.secondaryColor.withAlpha(30),
              labelStyle: TextStyle(
                color: selected ? AppTheme.secondaryColor : null,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (_) => prov.setStatusFilter(e.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return AppTheme.warningColor;
      case OrderStatus.preparing: return Colors.blue;
      case OrderStatus.ready: return AppTheme.successColor;
      case OrderStatus.served: return Colors.purple;
      case OrderStatus.completed: return Colors.teal;
      case OrderStatus.cancelled: return AppTheme.errorColor;
    }
  }

  String _paymentLabel(OrderModel o) {
    if (o.paymentStatus == PaymentStatus.paid) return 'LUNAS';
    return 'BELUM BAYAR';
  }

  Color _paymentColor(OrderModel o) {
    return o.paymentStatus == PaymentStatus.paid ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withAlpha(20)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          collapsedBackgroundColor: Colors.transparent,
          backgroundColor: isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _statusColor(widget.order.status).withAlpha(30),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.receipt_long, color: _statusColor(widget.order.status), size: 24),
          ),
          title: Text('#${widget.order.orderNumber}',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: theme.colorScheme.onSurface)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 4),
            Text(formatDateShort(widget.order.createdAt), style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(150))),
            if (widget.order.customerName.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(widget.order.customerName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            ],
          ]),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatCurrency(widget.order.total),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 6),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _paymentColor(widget.order).withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_paymentLabel(widget.order),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _paymentColor(widget.order))),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(widget.order.status).withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.order.status.name.toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _statusColor(widget.order.status))),
              ),
            ]),
          ]),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 16),
            if (widget.order.tableName.isNotEmpty) _infoRow(Icons.table_bar, 'Meja: ${widget.order.tableName}', theme),
            if (widget.order.customerName.isNotEmpty) _infoRow(Icons.person, widget.order.customerName, theme),
            _infoRow(Icons.storefront, widget.order.orderType.name.toUpperCase(), theme),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withAlpha(20)),
              ),
              child: Column(
                children: [
                  ...widget.order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withAlpha(30), 
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Center(
                          child: Text('${item.quantity}x', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.secondaryColor)
                          )
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface))),
                      Text(formatCurrency(item.subtotal), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                    ]),
                  )),
                  const Divider(height: 24),
                  if (widget.order.discount > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Diskon', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                        Text('-${formatCurrency(widget.order.discount)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Total Akhir', style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                    Text(formatCurrency(widget.order.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.primaryColor)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Wrap(spacing: 8, runSpacing: 8, children: _actionButtons(context, widget.order)),
                ),
              ],
            ),
            if (widget.order.status == OrderStatus.completed || widget.order.paymentStatus == PaymentStatus.paid)
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _handlePrint(context, widget.order),
                  icon: const Icon(Icons.print_outlined, size: 20),
                  label: const Text('Cetak Ulang Nota', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface.withAlpha(200))),
      ]),
    );
  }

  List<Widget> _actionButtons(BuildContext context, OrderModel order) {
    final prov = context.read<OrderProvider>();
    final buttons = <Widget>[];
    final bool isPaid = order.paymentStatus == PaymentStatus.paid;

    if (!isPaid && order.status != OrderStatus.cancelled) {
      buttons.add(FilledButton.icon(
        onPressed: () => _showPaymentDialog(context, order),
        icon: const Icon(Icons.payments_outlined, size: 18),
        label: const Text('BAYAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.successColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ));
    }

    if (isPaid) {
      OrderStatus? next;
      switch (order.status) {
        case OrderStatus.pending: next = OrderStatus.preparing; break;
        case OrderStatus.preparing: next = OrderStatus.ready; break;
        case OrderStatus.ready: next = OrderStatus.served; break;
        case OrderStatus.served: break;
        default: break;
      }
      if (next != null) {
        buttons.add(ElevatedButton.icon(
          onPressed: () => prov.updateOrderStatus(order.id, next!),
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: Text(next.name.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryColor.withAlpha(20),
            foregroundColor: AppTheme.secondaryColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ));
      }
    }

    if (order.status == OrderStatus.pending) {
      buttons.add(OutlinedButton.icon(
        onPressed: () => _showEditOrderDialog(context, order),
        icon: const Icon(Icons.edit, size: 16),
        label: const Text('Edit', style: TextStyle(fontSize: 11)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue,
          side: const BorderSide(color: Colors.blue),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ));
    }

    if (order.status != OrderStatus.completed && order.status != OrderStatus.cancelled) {
      buttons.add(TextButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Batalkan Pesanan?'),
              content: const Text('Yakin ingin membatalkan pesanan ini? Aksi ini tidak dapat dibatalkan.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Tidak')),
                FilledButton(
                  onPressed: () => Navigator.pop(c, true),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Ya, Batalkan'),
                ),
              ],
            ),
          );
          if (confirm == true) prov.updateOrderStatus(order.id, OrderStatus.cancelled);
        },
        icon: const Icon(Icons.cancel_outlined, size: 18),
        label: const Text('Batal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ));
    }

    return buttons;
  }

  void _showEditOrderDialog(BuildContext context, OrderModel order) {
    final prov = context.read<OrderProvider>();
    final nameCtrl = TextEditingController(text: order.customerName);
    final items = List<OrderItem>.from(order.items.map((e) => OrderItem(
      menuItemId: e.menuItemId, name: e.name, price: e.price, quantity: e.quantity, notes: e.notes,
    )));

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  const Text('Edit Pesanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: 4),
                Text('#${order.orderNumber}', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Pelanggan', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 14),
                const Text('Item Pesanan', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...List.generate(items.length, (i) {
                  final item = items[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Expanded(
                        child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                      ),
                      SizedBox(
                        width: 100,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                            onPressed: () {
                              setDialogState(() {
                                if (item.quantity > 1) {
                                  item.quantity--;
                                } else {
                                  items.removeAt(i);
                                }
                              });
                            },
                          ),
                          Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.green),
                            onPressed: () => setDialogState(() => item.quantity++),
                          ),
                        ]),
                      ),
                      Text(formatCurrency(item.subtotal), style: const TextStyle(fontSize: 12)),
                    ]),
                  );
                }),
                const Divider(height: 20),
                Text('Total: ${formatCurrency(items.fold<double>(0, (s, i) => s + i.subtotal))}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final updated = order.copyWith(
                          customerName: nameCtrl.text.trim(),
                          items: items,
                        );
                        await prov.updateOrder(updated);
                        Navigator.pop(c);
                      },
                      child: const Text('Simpan'),
                    ),
                  ),
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, OrderModel order) {
    final prov = context.read<OrderProvider>();
    PaymentMethod method = PaymentMethod.cash;
    final amountCtrl = TextEditingController(text: order.total.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(builder: (context, setDialogState) {
        final paid = double.tryParse(amountCtrl.text) ?? 0;
        final change = paid - order.total;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total Tagihan', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.outline)),
              const SizedBox(height: 4),
              Text(formatCurrency(order.total),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
              const SizedBox(height: 24),
              const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: PaymentMethod.values.map((m) {
                final sel = method == m;
                String label; IconData icon;
                switch (m) {
                  case PaymentMethod.cash: label = 'Tunai'; icon = Icons.payments_outlined; break;
                  case PaymentMethod.card: label = 'Kartu'; icon = Icons.credit_card; break;
                  case PaymentMethod.qris: label = 'QRIS'; icon = Icons.qr_code_2; break;
                }
                return ChoiceChip(
                  avatar: Icon(icon, size: 18, color: sel ? Colors.white : AppTheme.secondaryColor),
                  label: Text(label),
                  selected: sel,
                  selectedColor: AppTheme.secondaryColor,
                  labelStyle: TextStyle(
                    color: sel ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal
                  ),
                  onSelected: (_) => setDialogState(() => method = m),
                );
              }).toList()),
              if (method == PaymentMethod.cash) ...[
                const SizedBox(height: 24),
                TextField(
                  controller: amountCtrl,
                  decoration: InputDecoration(
                    labelText: 'Jumlah Dibayar', 
                    prefixText: 'Rp ', 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setDialogState(() {}),
                ),
                if (change >= 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.green.withAlpha(20), borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kembalian', style: TextStyle(fontSize: 11, color: Colors.green)),
                          Text(formatCurrency(change),
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w800, fontSize: 16)),
                        ],
                      ),
                    ]),
                  ),
                ],
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
            FilledButton.icon(
              onPressed: () async {
                final actualPaid = method == PaymentMethod.cash ? (double.tryParse(amountCtrl.text) ?? order.total) : order.total;
                await prov.processPayment(order.id, method, actualPaid);
                Navigator.pop(c);
                if (!context.mounted) return;
                final auth = context.read<AuthProvider>();
                final resto = context.read<RestaurantProvider>();

                final result = await ReceiptPreview.show(context,
                  order: order,
                  restaurantName: auth.restaurantName,
                  restaurantAddress: resto.settings.address,
                  cashierName: auth.userName,
                );
                if (result == PrintResult.print && context.mounted) {
                  await _handlePrint(context, order);
                }
              },
              icon: const Icon(Icons.check, size: 18),
              label: Text('Bayar ${formatCurrency(order.total)}'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _handlePrint(BuildContext context, OrderModel order) async {
    final auth = context.read<AuthProvider>();
    final resto = context.read<RestaurantProvider>();
    resto.load(auth.restaurantId);
    await Future.delayed(const Duration(milliseconds: 300));
    final printers = resto.settings.printers;

    if (printers.isEmpty) {
      final pick = await PrinterPicker.show(context);
      if (pick == null) return;
      await _printSingle(context, order, auth, resto, pick);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mencetak ke ${printers.length} printer...')),
      );
    }

    for (final p in printers) {
      try {
        final device = BluetoothDevice(remoteId: p['address']! as DeviceIdentifier);
        final printService = PrintService();
        final ok = await printService.connectToDevice(device);
        if (ok) {
          await printService.printReceipt(order,
            restaurantName: auth.restaurantName,
            restaurantAddress: resto.settings.address,
            cashierName: auth.userName,
          );
          await printService.disconnect();
        }
      } catch (_) {}
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cetak selesai')),
      );
    }
  }

  Future<void> _printSingle(BuildContext context, OrderModel order, AuthProvider auth, RestaurantProvider resto, BluetoothDevice device) async {
    final printService = PrintService();
    final connected = await printService.connectToDevice(device);
    if (!connected) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal konek ke printer')));
      return;
    }
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mencetak...')));
    final ok = await printService.printReceipt(order,
      restaurantName: auth.restaurantName,
      restaurantAddress: resto.settings.address,
      cashierName: auth.userName);
    await printService.disconnect();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Struk berhasil dicetak' : 'Gagal mencetak')));
    }
  }
}

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});
  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _searchCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _discountPercentCtrl = TextEditingController(text: '0');
  String _searchQuery = '';
  OrderType _orderType = OrderType.dineIn;
  TableModel? _selectedTable;
  bool _useDiscountPercent = false;
  List<TableModel> _tables = [];
  bool _showPayment = false;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final _amountPaidCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  String? _createdOrderId;
  double _finalTotal = 0;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final prov = context.read<OrderProvider>();
    _customerCtrl.text = prov.currentCustomerName;
    _orderType = prov.currentOrderType;
    _discountCtrl.text = prov.currentDiscount.toStringAsFixed(0);
    if (prov.currentTableId.isNotEmpty) {
      _selectedTable = TableModel(id: prov.currentTableId, name: prov.currentTableName);
    }
    prov.firestoreService.setRestaurantId(auth.restaurantId);
    prov.firestoreService.streamTables().listen((tables) {
      if (mounted) setState(() => _tables = tables);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose(); _customerCtrl.dispose();
    _discountCtrl.dispose(); _discountPercentCtrl.dispose(); _amountPaidCtrl.dispose();
    _bankCtrl.dispose(); _cardNumberCtrl.dispose();
    super.dispose();
  }

  double get _taxRate => context.read<RestaurantProvider>().taxRate;
  double get _serviceCharge => context.read<RestaurantProvider>().serviceCharge;
  double get _discountAmount {
    if (_useDiscountPercent) {
      return _cartSubtotal * ((double.tryParse(_discountPercentCtrl.text) ?? 0) / 100);
    }
    return double.tryParse(_discountCtrl.text) ?? 0;
  }
  double get _cartSubtotal => _round(context.read<OrderProvider>().cart.fold(0.0, (s, i) => s + i.subtotal));
  double get _cartTax => _round(_cartSubtotal * _taxRate);
  double get _cartService => _round(_cartSubtotal * _serviceCharge);
  double get _cartTotal => _round(_cartSubtotal + _cartTax + _cartService - _discountAmount);

  double _round(double v) => (v * 100).roundToDouble() / 100;
  double get _amountPaid => double.tryParse(_amountPaidCtrl.text.replaceAll('.', '')) ?? _finalTotal;

  Future<void> _submitAndPay() async {
    final customerName = _customerCtrl.text.trim();
    if (customerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama pelanggan wajib diisi!'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_orderType == OrderType.dineIn && _selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih meja untuk makan di tempat!'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final total = _cartTotal;

    final prov = context.read<OrderProvider>();
    prov.setOrderType(_orderType);
    prov.setCustomerName(customerName);
    if (_selectedTable != null) {
      prov.setTable(_selectedTable!.id, _selectedTable!.name);
    } else {
      prov.setTable('', '');
    }

    final id = await prov.submitOrder(taxRate: _taxRate, discount: _discountAmount, serviceCharge: _serviceCharge);
    _createdOrderId = id;
    _finalTotal = total;
    _amountPaidCtrl.text = total.toStringAsFixed(0);
    setState(() => _showPayment = true);
  }

  Future<void> _confirmPayment() async {
    if (_createdOrderId == null) return;

    if (_paymentMethod == PaymentMethod.card) {
      if (_bankCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama bank wajib diisi!'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
      if (_cardNumberCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nomor kartu wajib diisi!'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
    }

    if (_paymentMethod == PaymentMethod.cash && (_amountPaid + 0.001) < _finalTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah pembayaran kurang'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final prov = context.read<OrderProvider>();
    await prov.processPayment(_createdOrderId!, _paymentMethod, _paymentMethod == PaymentMethod.cash ? _amountPaid : _finalTotal);

    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final resto = context.read<RestaurantProvider>();
    final order = prov.orders.firstWhere((o) => o.id == _createdOrderId,
        orElse: () => OrderModel(id: '', orderNumber: '', items: []));

    final result = await ReceiptPreview.show(context,
      order: order,
      restaurantName: auth.restaurantName,
      restaurantAddress: resto.settings.address,
      cashierName: auth.userName,
    );

    if (result == PrintResult.print && mounted) {
      resto.load(auth.restaurantId);
      await Future.delayed(const Duration(milliseconds: 300));
      final printers = resto.settings.printers;

      if (printers.isEmpty) {
        final pick = await PrinterPicker.show(context);
        if (pick != null) {
          final ps = PrintService();
          if (await ps.connectToDevice(pick)) {
            await ps.printReceipt(order,
              restaurantName: auth.restaurantName,
              restaurantAddress: resto.settings.address,
              cashierName: auth.userName,
            );
            await ps.disconnect();
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mencetak ke ${printers.length} printer...')),
        );
        for (final p in printers) {
          try {
            final device = BluetoothDevice(remoteId: p['address']! as DeviceIdentifier);
            final ps = PrintService();
            if (await ps.connectToDevice(device)) {
              await ps.printReceipt(order,
                restaurantName: auth.restaurantName,
                restaurantAddress: resto.settings.address,
                cashierName: auth.userName,
              );
              await ps.disconnect();
            }
          } catch (_) {}
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cetak selesai')),
          );
        }
      }
    }

    if (mounted) {
      prov.clearCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran berhasil!'), behavior: SnackBarBehavior.floating),
      );
      setState(() {
        _showPayment = false;
        _createdOrderId = null;
        _customerCtrl.clear();
        _discountCtrl.text = '0';
        _discountPercentCtrl.text = '0';
        _orderType = OrderType.dineIn;
        _selectedTable = null;
        _bankCtrl.clear();
        _cardNumberCtrl.clear();
      });
    }
  }

  void _clearAll() {
    context.read<OrderProvider>().clearCart();
    _customerCtrl.clear();
    setState(() {
      _orderType = OrderType.dineIn;
      _selectedTable = null;
      _showPayment = false;
      _createdOrderId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrderProvider>();
    final menuProv = context.watch<MenuProvider>();
    final responsive = ResponsiveLayout(context);
    final theme = Theme.of(context);

    var menuItems = menuProv.items;
    if (_searchQuery.isNotEmpty) {
      menuItems = menuItems.where((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    if (_showPayment) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Pembayaran', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => setState(() => _showPayment = false),
          ),
        ),
        body: _buildPaymentScreen(theme),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('POS Kasir', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          if (prov.cart.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white70), tooltip: 'Bersihkan', onPressed: _clearAll),
        ],
      ),
      body: responsive.showSidebar
          ? Row(children: [
              Expanded(flex: 5, child: _buildMenuPanel(menuProv, menuItems, theme)),
              Container(width: 380, decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(left: BorderSide(color: theme.dividerColor)),
              ), child: _buildSidePanel(prov, theme)),
            ])
          : Column(children: [
              Expanded(flex: 3, child: _buildMenuPanel(menuProv, menuItems, theme)),
              if (prov.cart.isNotEmpty)
                _buildPortraitCart(prov, theme),
            ]),
    );
  }

  Widget _buildPaymentScreen(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Icon(Icons.payment, size: 48, color: AppTheme.secondaryColor),
              const SizedBox(height: 12),
              Text('Total Pembayaran', style: TextStyle(color: theme.colorScheme.outline, fontSize: 14)),
              const SizedBox(height: 4),
              Text(formatCurrency(_finalTotal), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 10, children: PaymentMethod.values.map((m) {
                final sel = _paymentMethod == m;
                String label; IconData icon;
                switch (m) {
                  case PaymentMethod.cash: label = 'Tunai'; icon = Icons.money; break;
                  case PaymentMethod.card: label = 'Kartu'; icon = Icons.credit_card; break;
                  case PaymentMethod.qris: label = 'QRIS'; icon = Icons.qr_code; break;
                }
                return ChoiceChip(
                  avatar: Icon(icon, size: 18),
                  label: Text(label),
                  selected: sel,
                  selectedColor: AppTheme.secondaryColor.withAlpha(30),
                  labelStyle: TextStyle(fontWeight: sel ? FontWeight.w600 : FontWeight.normal),
                  onSelected: (_) => setState(() => _paymentMethod = m),
                );
              }).toList()),
              if (_paymentMethod == PaymentMethod.cash) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: _amountPaidCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Dibayar', prefixText: 'Rp ',
                    border: OutlineInputBorder(), isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (_amountPaid - _finalTotal > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.money, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('Kembalian: ${formatCurrency(_amountPaid - _finalTotal)}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700, fontSize: 16)),
                    ]),
                  ),
                ],
              ],
              if (_paymentMethod == PaymentMethod.card) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: _bankCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Bank',
                    prefixIcon: Icon(Icons.account_balance),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _cardNumberCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Kartu',
                    prefixIcon: Icon(Icons.credit_card),
                    border: OutlineInputBorder(),
                    isDense: true,
                    hintText: '1234 5678 9012',
                  ),
                ),
              ],
              if (_paymentMethod == PaymentMethod.qris) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(children: [
                    Icon(Icons.qr_code, size: 100, color: theme.colorScheme.onSurface),
                    const SizedBox(height: 12),
                    Text('Scan QRIS untuk membayar',
                        style: TextStyle(color: theme.colorScheme.outline)),
                    const SizedBox(height: 4),
                    Text(formatCurrency(_finalTotal),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  ]),
                ),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _confirmPayment,
            icon: const Icon(Icons.check_circle_outline),
            label: Text('Konfirmasi Pembayaran ${formatCurrency(_finalTotal)}'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(onPressed: () => setState(() => _showPayment = false), child: const Text('Kembali ke Pesanan')),
      ]),
    );
  }

  Widget _buildMenuPanel(MenuProvider menuProv, List<MenuItem> items, ThemeData theme) {
    return Column(children: [
      _buildOrderInfoBar(theme),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Cari menu...',
            prefixIcon: const Icon(Icons.search_rounded, size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 20),
                    onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                  )
                : null,
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.secondaryColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
      ),
      Container(
        height: 40,
        margin: const EdgeInsets.only(bottom: 6),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          children: [
            _catChip('Semua', menuProv.selectedCategoryId.isEmpty || menuProv.selectedCategoryId == 'all',
                () => menuProv.setSelectedCategory('all'), theme),
            ...menuProv.categories.map((cat) {
              final sel = menuProv.selectedCategoryId == cat.id;
              return _catChip(cat.name, sel, () => menuProv.setSelectedCategory(cat.id), theme);
            }),
          ],
        ),
      ),
      Expanded(
        child: items.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.restaurant_menu_outlined, size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context).noData, style: TextStyle(color: theme.colorScheme.outline)),
                ]),
              )
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveLayout(context).crossAxisCount,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: ResponsiveLayout(context).isMobile ? 3.0 : 2.6,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  final isDark = theme.brightness == Brightness.dark;

                  return Material(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 0,
                    child: InkWell(
                      onTap: item.available
                          ? () => context.read<OrderProvider>().addToCart(OrderItem(
                                menuItemId: item.id, name: item.name, price: item.price))
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 0.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: item.imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: item.imageUrl.startsWith('http')
                                        ? Image.network(
                                            item.imageUrl,
                                            width: 48, height: 48, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _defaultAvatar(item, isDark),
                                          )
                                        : Image.file(
                                            File(item.imageUrl),
                                            width: 48, height: 48, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _defaultAvatar(item, isDark),
                                          ),
                                  )
                                : _defaultAvatar(item, isDark),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(item.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 3),
                                Text(formatCurrency(item.price),
                                    style: const TextStyle(
                                        color: AppTheme.secondaryColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                          if (!item.available)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Habis', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w600)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryColor.withAlpha(isDark ? 30 : 20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.add, color: AppTheme.secondaryColor, size: 20),
                            ),
                        ]),
                      ),
                    ),
                  );
                },
              ),
      ),
    ]);
  }

  SizedBox _defaultAvatar(MenuItem item, bool isDark) {
    return SizedBox(
      width: 48, height: 48,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.secondaryColor.withAlpha(isDark ? 40 : 25),
              AppTheme.accentColor.withAlpha(isDark ? 30 : 15),
            ],
          ),
        ),
        child: Center(
          child: Text(
            item.name.isNotEmpty ? item.name[0].toUpperCase() : 'M',
            style: TextStyle(
              color: AppTheme.secondaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _catChip(String label, bool selected, VoidCallback onTap, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: selected
              ? AppTheme.secondaryColor
              : (isDark ? Colors.white12 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(label,
                  style: TextStyle(
                    color: selected ? Colors.white : theme.colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInfoBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [BoxShadow(color: theme.shadowColor.withAlpha(20), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 6, children: [
          _typeChip('Makan di Tempat', Icons.table_bar, OrderType.dineIn, theme),
          _typeChip('Bawa Pulang', Icons.takeout_dining, OrderType.takeAway, theme),
          _typeChip('Antar', Icons.delivery_dining, OrderType.delivery, theme),
          if (_orderType == OrderType.dineIn)
            ActionChip(
              avatar: Icon(Icons.table_bar, size: 18,
                  color: _selectedTable != null ? AppTheme.successColor : AppTheme.warningColor),
              label: Text(
                _selectedTable != null ? 'Meja ${_selectedTable!.name}' : 'Pilih Meja *',
                style: TextStyle(
                    color: _selectedTable != null ? AppTheme.successColor : AppTheme.warningColor, fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              onPressed: _showTablePicker,
            ),
        ]),
        const SizedBox(height: 8),
        TextField(
          controller: _customerCtrl,
          decoration: InputDecoration(
            hintText: 'Nama Pelanggan (wajib) *',
            prefixIcon: const Icon(Icons.person, size: 20),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ]),
    );
  }

  Widget _typeChip(String label, IconData icon, OrderType type, ThemeData theme) {
    final selected = _orderType == type;
    return ChoiceChip(
      avatar: Icon(icon, size: 18, color: selected ? Colors.white : AppTheme.secondaryColor),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      selectedColor: AppTheme.secondaryColor,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
          color: selected ? Colors.white : null,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
      side: selected ? BorderSide.none : BorderSide(color: theme.dividerColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) {
        setState(() { _orderType = type; if (type != OrderType.dineIn) _selectedTable = null; });
        if (type == OrderType.dineIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _showTablePicker());
        }
      },
    );
  }

  void _showTablePicker() {
    final availableTables = _tables.where((t) => t.status == TableStatus.available).toList();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.25,
        maxChildSize: 0.75,
        expand: false,
        builder: (context, scrollCtrl) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.table_bar, color: AppTheme.successColor),
                ),
                const SizedBox(width: 12),
                const Text('Pilih Meja', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton(onPressed: () { setState(() => _selectedTable = null); Navigator.pop(c); },
                    child: const Text('Tanpa Meja')),
              ]),
              const SizedBox(height: 16),
              Expanded(
                child: availableTables.isEmpty
                    ? Center(child: Text('Tidak ada meja tersedia', style: TextStyle(color: theme.colorScheme.outline)))
                    : GridView.builder(
                        controller: scrollCtrl,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.85),
                        itemCount: availableTables.length,
                        itemBuilder: (_, i) {
                          final t = availableTables[i];
                          final sel = _selectedTable?.id == t.id;
                          return GestureDetector(
                            onTap: () { setState(() => _selectedTable = t); Navigator.pop(c); },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: sel ? AppTheme.successColor : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                                border: sel ? null : Border.all(color: theme.dividerColor),
                                boxShadow: sel ? [BoxShadow(color: AppTheme.successColor.withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))] : null,
                              ),
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.table_bar,
                                    size: 28,
                                    color: sel ? Colors.white : AppTheme.successColor.withAlpha(180)),
                                const SizedBox(height: 8),
                                Text(t.name,
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w700,
                                        color: sel ? Colors.white : theme.colorScheme.onSurface)),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: sel ? Colors.white.withAlpha(30) : AppTheme.successColor.withAlpha(20),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('${t.capacity} org',
                                      style: TextStyle(
                                          fontSize: 10, fontWeight: FontWeight.w600,
                                          color: sel ? Colors.white70 : AppTheme.successColor)),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildSidePanel(OrderProvider prov, ThemeData theme) {
    return Column(children: [
      _buildCustomerTaxDiscount(prov, theme),
      Expanded(child: _buildCartList(prov, theme)),
      _buildCartFooter(prov, theme),
    ]);
  }

  Widget _buildCustomerTaxDiscount(OrderProvider prov, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.dividerColor))),
      child: Row(children: [
        Expanded(
          flex: 2,
          child: _useDiscountPercent
              ? TextField(
                  controller: _discountPercentCtrl,
                  decoration: const InputDecoration(labelText: 'Diskon (%)', suffixText: '%', border: OutlineInputBorder(),
                      isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  keyboardType: TextInputType.number,
                )
              : TextField(
                  controller: _discountCtrl,
                  decoration: const InputDecoration(labelText: 'Diskon (Rp)', prefixText: 'Rp ', border: OutlineInputBorder(),
                      isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  keyboardType: TextInputType.number,
                ),
        ),
        IconButton(
          icon: Icon(_useDiscountPercent ? Icons.percent : Icons.monetization_on_outlined, size: 20),
          onPressed: () => setState(() => _useDiscountPercent = !_useDiscountPercent),
          tooltip: 'Ganti tipe diskon',
        ),
      ]),
    );
  }

  Widget _buildCartList(OrderProvider prov, ThemeData theme) {
    return prov.cart.isEmpty
        ? Center(child: Text(AppLocalizations.of(context).noData))
        : ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: prov.cart.length,
            itemBuilder: (_, i) {
              final item = prov.cart[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(formatCurrency(item.price),
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                      ]),
                    ),
                    Container(
                      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        InkWell(
                          onTap: () => prov.updateCartItemQuantity(item.menuItemId, item.quantity - 1),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.remove, size: 16)),
                        ),
                        SizedBox(width: 28, child: Text('${item.quantity}', textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                        InkWell(
                          onTap: () => prov.updateCartItemQuantity(item.menuItemId, item.quantity + 1),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.add, size: 16)),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Text(formatCurrency(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                ),
              );
            },
          );
  }

  Widget _buildCartFooter(OrderProvider prov, ThemeData theme) {
    String orderInfo = _orderType == OrderType.dineIn ? 'Makan di Tempat' : _orderType == OrderType.takeAway ? 'Bawa Pulang' : 'Antar';
    if (_selectedTable != null) orderInfo += ' • Meja ${_selectedTable!.name}';
    if (_customerCtrl.text.trim().isNotEmpty) orderInfo += ' • ${_customerCtrl.text.trim()}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(children: [
        if (orderInfo.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(_orderType == OrderType.dineIn ? Icons.table_bar : Icons.takeout_dining,
                  size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(child: Text(orderInfo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            ]),
          ),
          _totalRow('Subtotal', _cartSubtotal, theme),
          _totalRow('Pajak (${(_taxRate * 100).toStringAsFixed(0)}%)', _cartTax, theme),
          _totalRow('Service (${(_serviceCharge * 100).toStringAsFixed(0)}%)', _cartService, theme),
          if (_discountAmount > 0) _totalRow('Diskon', -_discountAmount, theme, color: Colors.red),
          Divider(color: theme.dividerColor),
          _totalRow('Total', _cartTotal, theme, bold: true),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 48,
          child: FilledButton.icon(
            onPressed: prov.cart.isEmpty ? null : _submitAndPay,
            icon: const Icon(Icons.payment),
            label: Text('Bayar ${formatCurrency(_cartTotal)}'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _totalRow(String label, double value, ThemeData theme, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color, fontSize: bold ? 16 : 13)),
        Text(formatCurrency(value), style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: bold ? 18 : 14)),
      ]),
    );
  }

  Widget _buildPortraitCart(OrderProvider prov, ThemeData theme) {
    String orderInfo = _orderType == OrderType.dineIn ? 'Makan di Tempat' : _orderType == OrderType.takeAway ? 'Bawa Pulang' : 'Antar';
    if (_selectedTable != null) orderInfo += ' • M${_selectedTable!.name}';

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, -4))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(children: [
            Text('${prov.cartItemCount} item | $orderInfo',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const Spacer(),
            Text(formatCurrency(_cartTotal),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.secondaryColor)),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: prov.cart.length,
            itemBuilder: (_, i) {
              final item = prov.cart[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(formatCurrency(item.price), style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
                    ]),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      InkWell(
                        onTap: () => prov.updateCartItemQuantity(item.menuItemId, item.quantity - 1),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.remove, size: 16)),
                      ),
                      SizedBox(width: 24, child: Text('${item.quantity}', textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                      InkWell(
                        onTap: () => prov.updateCartItemQuantity(item.menuItemId, item.quantity + 1),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.add, size: 16)),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Text(formatCurrency(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ]),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total: ${formatCurrency(_cartTotal)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              if (_discountAmount > 0)
                Text('Diskon: -${formatCurrency(_discountAmount)}',
                    style: const TextStyle(fontSize: 11, color: Colors.red)),
            ]),
            const Spacer(),
            SizedBox(
              height: 42,
              child: FilledButton.icon(
                onPressed: _submitAndPay,
                icon: const Icon(Icons.payment, size: 18),
                label: const Text('Bayar'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
