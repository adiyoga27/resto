import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/localization/app_localizations.dart';
import '../core/responsive/responsive_layout.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'menu/menu_screen.dart';
import 'orders/order_screen.dart';
import 'tables/table_screen.dart';
import 'reports/report_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const DashboardScreen(),
    const MenuScreen(),
    const OrderScreen(),
    const TableScreen(),
    const ReportScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final responsive = ResponsiveLayout(context);

    if (responsive.showSidebar) {
      return _buildDesktopLayout(l10n, responsive);
    }
    return _buildMobileLayout(l10n);
  }

  Widget _buildDesktopLayout(AppLocalizations l10n, ResponsiveLayout responsive) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(l10n, responsive),
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(AppLocalizations l10n) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        animationDuration: const Duration(milliseconds: 400),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.restaurant_menu_outlined),
            selectedIcon: const Icon(Icons.restaurant_menu),
            label: l10n.menu,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.orders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.table_bar_outlined),
            selectedIcon: const Icon(Icons.table_bar),
            label: l10n.tables,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.reports,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(AppLocalizations l10n, ResponsiveLayout responsive) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: responsive.sidebarWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.onSurface.withAlpha(15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.onSurface.withAlpha(15)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(isDark ? 50 : 30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.restaurant_menu,
                          color: theme.colorScheme.primary, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.appName,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  auth.restaurantName.isNotEmpty
                      ? auth.restaurantName
                      : l10n.appSubtitle,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withAlpha(150),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _sidebarItem(Icons.dashboard, l10n.dashboard, 0),
                _sidebarItem(Icons.restaurant_menu, l10n.menu, 1),
                _sidebarItem(Icons.receipt_long, l10n.orders, 2),
                _sidebarItem(Icons.table_bar, l10n.tables, 3),
                _sidebarItem(Icons.bar_chart, l10n.reports, 4),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Divider(color: theme.colorScheme.onSurface.withAlpha(15)),
                ),
                const SizedBox(height: 8),
                _sidebarItem(Icons.settings, l10n.settings, 5),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.colorScheme.onSurface.withAlpha(15))),
            ),
            child: InkWell(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text(l10n.logout),
                    content: const Text('Yakin ingin keluar?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: Text(l10n.cancel)),
                      TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                          child: Text(l10n.logout)),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await auth.logout();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppTheme.errorColor.withAlpha(200), size: 22),
                    const SizedBox(width: 12),
                    Text(l10n.logout,
                        style: TextStyle(
                            color: AppTheme.errorColor.withAlpha(200),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : theme.colorScheme.onSurface.withAlpha(150),
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface.withAlpha(180),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
