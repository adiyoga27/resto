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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isKitchen) setState(() => _currentIndex = 2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final responsive = ResponsiveLayout(context);
    final auth = context.watch<AuthProvider>();

    if (auth.isKitchen) {
      if (responsive.showSidebar) {
        return Scaffold(body: Row(children: [
          _buildSidebar(l10n, responsive, auth),
          const Expanded(child: OrderScreen()),
        ]));
      }
      return const Scaffold(body: OrderScreen());
    }

    if (responsive.showSidebar) {
      return Scaffold(body: Row(children: [
        _buildSidebar(l10n, responsive, auth),
        Expanded(child: _screens[_currentIndex]),
      ]));
    }

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        animationDuration: const Duration(milliseconds: 400),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dashboard_outlined), selectedIcon: const Icon(Icons.dashboard), label: l10n.dashboard),
          NavigationDestination(icon: const Icon(Icons.restaurant_menu_outlined), selectedIcon: const Icon(Icons.restaurant_menu), label: l10n.menu),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: l10n.orders),
          NavigationDestination(icon: const Icon(Icons.table_bar_outlined), selectedIcon: const Icon(Icons.table_bar), label: l10n.tables),
          NavigationDestination(icon: const Icon(Icons.bar_chart_outlined), selectedIcon: const Icon(Icons.bar_chart), label: l10n.reports),
        ],
      ),
    );
  }

  Widget _buildSidebar(AppLocalizations l10n, ResponsiveLayout responsive, AuthProvider auth) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final menuItems = auth.isKitchen
        ? [_SidebarItem(Icons.receipt_long_outlined, Icons.receipt_long, l10n.orders, 2)]
        : [
            _SidebarItem(Icons.dashboard_outlined, Icons.dashboard, l10n.dashboard, 0),
            _SidebarItem(Icons.restaurant_menu_outlined, Icons.restaurant_menu, l10n.menu, 1),
            _SidebarItem(Icons.receipt_long_outlined, Icons.receipt_long, l10n.orders, 2),
            _SidebarItem(Icons.table_bar_outlined, Icons.table_bar, l10n.tables, 3),
            _SidebarItem(Icons.bar_chart_outlined, Icons.bar_chart, l10n.reports, 4),
          ];

    return Container(
      width: responsive.sidebarWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.dividerColor.withAlpha(20), width: 1)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.accentColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppTheme.primaryColor.withAlpha(isDark ? 30 : 60), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.appName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(auth.userName.isNotEmpty ? auth.userName : 'User',
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.primary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(auth.role.toUpperCase(),
                    style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withAlpha(120), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              ...menuItems.map((item) => _sidebarItem(item, theme)),
              if (!auth.isKitchen) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('PENGATURAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface.withAlpha(100), letterSpacing: 1.5)),
                ),
                const SizedBox(height: 12),
                _sidebarItem(_SidebarItem(Icons.settings_outlined, Icons.settings, l10n.settings, 5), theme),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.dividerColor.withAlpha(20)))),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withAlpha(30),
              child: Text(auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : 'U',
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(auth.userName.isNotEmpty ? auth.userName : 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(auth.role.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
              ]),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text(l10n.logout),
                    content: const Text('Yakin ingin keluar?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.cancel)),
                      TextButton(onPressed: () => Navigator.pop(c, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: Text(l10n.logout)),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await auth.logout();
                  if (mounted) Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _sidebarItem(_SidebarItem item, ThemeData theme) {
    final isSelected = _currentIndex == item.index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? AppTheme.secondaryColor.withAlpha(isSelected ? 30 : 0) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _currentIndex = item.index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Icon(isSelected ? item.filledIcon : item.outlinedIcon,
                  color: isSelected ? AppTheme.secondaryColor : theme.colorScheme.onSurface.withAlpha(180), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item.label,
                    style: TextStyle(
                      color: isSelected ? AppTheme.secondaryColor : theme.colorScheme.onSurface.withAlpha(200),
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    )),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem {
  final IconData outlinedIcon;
  final IconData filledIcon;
  final String label;
  final int index;
  const _SidebarItem(this.outlinedIcon, this.filledIcon, this.label, this.index);
}
