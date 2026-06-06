import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/menu_provider.dart';
import '../../core/utils/currency_format.dart';
import '../../config/theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final orderProv = context.watch<OrderProvider>();
    final menuProv = context.watch<MenuProvider>();
    final responsive = MediaQuery.of(context).size.width;

    final today = DateTime.now();
    final todayOrders = orderProv.orders.where((o) {
      final diff = today.difference(o.createdAt);
      return diff.inHours < 24 && o.paymentStatus.name == 'paid';
    }).toList();
    final todayRevenue =
        todayOrders.fold<double>(0, (sum, o) => sum + o.total);
    final activeCount = orderProv.activeOrders.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.accentColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withAlpha(50),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(getGreeting(auth.userName, true),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  )),
                              const SizedBox(height: 4),
                              Text(l10n.appDescription,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 32),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(formatCurrency(todayRevenue),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 4),
                    Text('${l10n.todaySales} • $todayRevenue',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: responsive > 600 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: responsive > 600 ? 1.8 : 1.6,
                children: [
                  _StatCard(
                    icon: Icons.trending_up,
                    label: l10n.totalRevenue,
                    value: formatCurrency(todayRevenue),
                    color: AppTheme.successColor,
                  ),
                  _StatCard(
                    icon: Icons.receipt_long,
                    label: l10n.totalOrders,
                    value: '${orderProv.orders.length}',
                    color: AppTheme.secondaryColor,
                  ),
                  _StatCard(
                    icon: Icons.pending_actions,
                    label: l10n.activeOrders,
                    value: '$activeCount',
                    color: AppTheme.warningColor,
                  ),
                  _StatCard(
                    icon: Icons.restaurant_menu,
                    label: l10n.totalItems,
                    value: '${menuProv.items.length}',
                    color: AppTheme.accentColor,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(l10n.recentOrders,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (orderProv.orders.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text(l10n.noData)),
                  ),
                )
              else
                ...orderProv.orders.take(5).map((order) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.secondaryColor.withAlpha(30),
                          child: const Icon(Icons.receipt,
                              color: AppTheme.secondaryColor, size: 20),
                        ),
                        title: Text('#${order.orderNumber}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(formatDateShort(order.createdAt)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(formatCurrency(order.total),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status.name)
                                    .withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.status.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(order.status.name),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warningColor;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return AppTheme.successColor;
      case 'served':
        return Colors.purple;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onSurface.withAlpha(50), size: 12),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  )),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
