import 'package:flutter/material.dart';
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
import '../../config/theme.dart';
import '../../services/print_service.dart';
import '../../widgets/common/receipt_dialog.dart';
import '../../widgets/common/printer_picker.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prov = context.watch<OrderProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.orders),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CreateOrderScreen())),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('POS'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(30),
              foregroundColor: Colors.white,
            ),
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
    final filters = {
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

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(order.status).withAlpha(30),
          child: Icon(Icons.receipt_long, color: _statusColor(order.status), size: 20),
        ),
        title: Text('#${order.orderNumber}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(formatDateShort(order.createdAt), style: const TextStyle(fontSize: 12)),
          if (order.customerName.isNotEmpty)
            Text(order.customerName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(formatCurrency(order.total),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 2),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _paymentColor(order).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_paymentLabel(order),
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _paymentColor(order))),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(order.status).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(order.status.name.toUpperCase(),
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _statusColor(order.status))),
            ),
          ]),
        ]),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (order.tableName.isNotEmpty) _infoRow(Icons.table_bar, 'Meja: ${order.tableName}', theme),
          if (order.customerName.isNotEmpty) _infoRow(Icons.person, order.customerName, theme),
          _infoRow(Icons.storefront, order.orderType.name.toUpperCase(), theme),
          const Divider(height: 20),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              SizedBox(width: 30, child: Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.w600))),
              Expanded(child: Text(item.name, style: const TextStyle(fontSize: 13))),
              Text(formatCurrency(item.subtotal), style: const TextStyle(fontSize: 13)),
            ]),
          )),
          const Divider(height: 20),
          if (order.discount > 0)
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Diskon', style: TextStyle(color: Colors.red)),
              Text('-${formatCurrency(order.discount)}', style: const TextStyle(color: Colors.red)),
            ]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
            Text(formatCurrency(order.total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
          const SizedBox(height: 12),
          if (order.status != OrderStatus.completed && order.status != OrderStatus.cancelled)
            Wrap(spacing: 8, runSpacing: 8, children: _actionButtons(context, order)),
          if (order.status == OrderStatus.completed || order.paymentStatus == PaymentStatus.paid)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: () => _handlePrint(context, order),
                icon: const Icon(Icons.print, size: 16),
                label: const Text('Cetak Ulang'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(children: [
        Icon(icon, size: 14, color: theme.colorScheme.outline),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(180))),
      ]),
    );
  }

  List<Widget> _actionButtons(BuildContext context, OrderModel order) {
    final prov = context.read<OrderProvider>();
    final buttons = <Widget>[];
    final bool isPaid = order.paymentStatus == PaymentStatus.paid;

    if (!isPaid) {
      buttons.add(ElevatedButton.icon(
        onPressed: () => _showPaymentDialog(context, order),
        icon: const Icon(Icons.payment, size: 16),
        label: const Text('BAYAR', style: TextStyle(fontSize: 11)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ));
      buttons.add(const SizedBox(width: 4));
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
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: Text(next.name.toUpperCase(), style: const TextStyle(fontSize: 11)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor.withAlpha(220),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ));
        buttons.add(const SizedBox(width: 4));
      }
    }

    buttons.add(TextButton.icon(
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Batalkan?'),
            content: const Text('Yakin ingin membatalkan pesanan ini?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Tidak')),
              TextButton(onPressed: () => Navigator.pop(c, true),
                  child: const Text('Ya', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (confirm == true) prov.updateOrderStatus(order.id, OrderStatus.cancelled);
      },
      icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
      label: const Text('Batal', style: TextStyle(color: Colors.red, fontSize: 11)),
    ));

    return buttons;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Pembayaran'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total: ${formatCurrency(order.total)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: PaymentMethod.values.map((m) {
                final sel = method == m;
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
                  onSelected: (_) => setDialogState(() => method = m),
                );
              }).toList()),
              if (method == PaymentMethod.cash) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(labelText: 'Jumlah Dibayar', prefixText: 'Rp ', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setDialogState(() {}),
                ),
                if (change >= 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.money, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('Kembalian: ${formatCurrency(change)}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700, fontSize: 15)),
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

                final result = await ReceiptPreview.show(context,
                  order: order, restaurantName: context.read<AuthProvider>().restaurantName);
                if (result == PrintResult.print && context.mounted) {
                  await _handlePrint(context, order);
                }
              },
              icon: const Icon(Icons.check, size: 18),
              label: Text('Bayar ${formatCurrency(order.total)}'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _handlePrint(BuildContext context, OrderModel order) async {
    final auth = context.read<AuthProvider>();
    final printService = PrintService();
    final device = await PrinterPicker.show(context);
    if (device == null) return;
    final connected = await printService.connectToDevice(device);
    if (!connected) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal konek ke printer')));
      return;
    }
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mencetak...')));
    final ok = await printService.printReceipt(order, auth.restaurantName);
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
  final _taxCtrl = TextEditingController(text: '10');
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
  String? _createdOrderId;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final prov = context.read<OrderProvider>();
    _customerCtrl.text = prov.currentCustomerName;
    _orderType = prov.currentOrderType;
    _taxCtrl.text = ((prov.currentTaxRate) * 100).toStringAsFixed(0);
    _discountCtrl.text = prov.currentDiscount.toStringAsFixed(0);
    if (prov.currentTableId.isNotEmpty) {
      _selectedTable = TableModel(id: prov.currentTableId, name: prov.currentTableName);
    }
    prov.firestoreService.setUserId(auth.userId);
    prov.firestoreService.streamTables().listen((tables) {
      if (mounted) setState(() => _tables = tables);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose(); _customerCtrl.dispose(); _taxCtrl.dispose();
    _discountCtrl.dispose(); _discountPercentCtrl.dispose(); _amountPaidCtrl.dispose();
    super.dispose();
  }

  double get _taxRate => (double.tryParse(_taxCtrl.text) ?? 10) / 100;
  double get _discountAmount {
    if (_useDiscountPercent) {
      return _cartSubtotal * ((double.tryParse(_discountPercentCtrl.text) ?? 0) / 100);
    }
    return double.tryParse(_discountCtrl.text) ?? 0;
  }
  double get _cartSubtotal => context.read<OrderProvider>().cart.fold(0, (s, i) => s + i.subtotal);
  double get _cartTax => _cartSubtotal * _taxRate;
  double get _cartTotal => _cartSubtotal + _cartTax - _discountAmount;
  double get _amountPaid => double.tryParse(_amountPaidCtrl.text) ?? _cartTotal;
  double get _change => _amountPaid - _cartTotal;

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

    final prov = context.read<OrderProvider>();
    prov.setOrderType(_orderType);
    prov.setCustomerName(customerName);
    if (_selectedTable != null) {
      prov.setTable(_selectedTable!.id, _selectedTable!.name);
    } else {
      prov.setTable('', '');
    }

    final id = await prov.submitOrder(taxRate: _taxRate, discount: _discountAmount);
    _createdOrderId = id;
    _amountPaidCtrl.text = _cartTotal.toStringAsFixed(0);
    setState(() => _showPayment = true);
  }

  Future<void> _confirmPayment() async {
    if (_createdOrderId == null) return;
    if (_paymentMethod == PaymentMethod.cash && _amountPaid < _cartTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah pembayaran kurang'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final prov = context.read<OrderProvider>();
    await prov.processPayment(_createdOrderId!, _paymentMethod, _amountPaid);

    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final order = prov.orders.firstWhere((o) => o.id == _createdOrderId,
        orElse: () => OrderModel(id: '', orderNumber: '', items: []));

    final result = await ReceiptPreview.show(context,
      order: order, restaurantName: auth.restaurantName);

    if (result == PrintResult.print && mounted) {
      final printService = PrintService();
      final device = await PrinterPicker.show(context);
      if (device != null) {
        final ok = await printService.connectToDevice(device);
        if (ok) {
          await printService.printReceipt(order, auth.restaurantName);
          await printService.disconnect();
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran berhasil!'), behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context);
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
              Expanded(child: _buildMenuPanel(menuProv, menuItems, theme)),
              if (prov.cart.isNotEmpty) _buildBottomBar(prov, theme),
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
              Text(formatCurrency(_cartTotal), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
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
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Dibayar', prefixText: 'Rp ',
                    border: OutlineInputBorder(), isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (_change > 0) ...[
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
                      Text('Kembalian: ${formatCurrency(_change)}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700, fontSize: 16)),
                    ]),
                  ),
                ],
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
            label: Text('Konfirmasi Pembayaran ${formatCurrency(_cartTotal)}'),
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
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
        child: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Cari menu...', prefixIcon: const Icon(Icons.search_rounded, size: 22),
            filled: true, fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
      ),
      _buildCategoryChips(menuProv, theme),
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
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveLayout(context).crossAxisCount,
                  mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.4,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: InkWell(
                      onTap: item.available
                          ? () => context.read<OrderProvider>().addToCart(OrderItem(
                                menuItemId: item.id, name: item.name, price: item.price))
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppTheme.secondaryColor.withAlpha(18),
                            ),
                            child: const Icon(Icons.fastfood, color: AppTheme.secondaryColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(formatCurrency(item.price), style: const TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
                            ]),
                          ),
                          if (!item.available) const Icon(Icons.block, color: Colors.red, size: 18),
                        ]),
                      ),
                    ),
                  );
                },
              ),
      ),
    ]);
  }

  Widget _buildCategoryChips(MenuProvider menuProv, ThemeData theme) {
    return SizedBox(
      height: 38,
      child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 14), children: [
        _catChip('Semua', menuProv.selectedCategoryId.isEmpty || menuProv.selectedCategoryId == 'all',
            () => menuProv.setSelectedCategory('all'), theme),
        ...menuProv.categories.map((cat) {
          final sel = menuProv.selectedCategoryId == cat.id;
          return _catChip(cat.name, sel, () => menuProv.setSelectedCategory(cat.id), theme);
        }),
      ]),
    );
  }

  Widget _catChip(String label, bool selected, VoidCallback onTap, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: selected ? AppTheme.primaryColor : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(label, style: TextStyle(
              color: selected ? Colors.white : theme.colorScheme.onSurface,
              fontSize: 12, fontWeight: FontWeight.w600,
            )),
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
        const SizedBox(height: 8),
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
      ]),
    );
  }

  Widget _typeChip(String label, IconData icon, OrderType type, ThemeData theme) {
    final selected = _orderType == type;
    return ChoiceChip(
      avatar: Icon(icon, size: 18, color: selected ? Colors.white : AppTheme.primaryColor),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(color: selected ? Colors.white : null, fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pilih Meja', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (availableTables.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Tidak ada meja tersedia', style: TextStyle(color: Colors.grey.shade500))))
          else
            Wrap(spacing: 10, runSpacing: 10, children: availableTables.map((t) {
              final sel = _selectedTable?.id == t.id;
              return ChoiceChip(
                label: Text('${t.name} (${t.capacity} org)'),
                selected: sel, selectedColor: AppTheme.successColor,
                labelStyle: TextStyle(color: sel ? Colors.white : null, fontWeight: sel ? FontWeight.w600 : FontWeight.normal),
                onSelected: (_) { setState(() => _selectedTable = t); Navigator.pop(c); },
              );
            }).toList()),
          const SizedBox(height: 12),
          TextButton(onPressed: () { setState(() => _selectedTable = null); Navigator.pop(c); }, child: const Text('Tanpa Meja')),
        ]),
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
      child: Column(children: [
        TextField(
          controller: _customerCtrl,
          decoration: const InputDecoration(labelText: 'Nama Pelanggan', prefixIcon: Icon(Icons.person_outline, size: 20),
              border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _taxCtrl,
              decoration: const InputDecoration(labelText: 'Pajak (%)', suffixText: '%', border: OutlineInputBorder(),
                  isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 10),
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
        _totalRow('Pajak (${_taxCtrl.text}%)', _cartTax, theme),
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

  Widget _buildBottomBar(OrderProvider prov, ThemeData theme) {
    String orderInfo = _orderType == OrderType.dineIn ? 'Makan di Tempat' : _orderType == OrderType.takeAway ? 'Bawa Pulang' : 'Antar';
    if (_selectedTable != null) orderInfo += ' • M${_selectedTable!.name}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${prov.cartItemCount} item | $orderInfo',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            TextField(
              controller: _customerCtrl,
              decoration: const InputDecoration(hintText: 'Nama Pelanggan (wajib) *', isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
              style: const TextStyle(fontSize: 13),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _submitAndPay,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.successColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.payment, size: 18),
            const SizedBox(width: 6),
            Text(formatCurrency(_cartTotal), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
        ),
      ]),
    );
  }
}
