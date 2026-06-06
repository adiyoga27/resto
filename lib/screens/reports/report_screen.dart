import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import '../../core/utils/currency_format.dart';
import '../../config/theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _period = 'daily';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _customRange = false;

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    var filtered = orders.where((o) => o.status == OrderStatus.completed).toList();

    if (_customRange && _startDate != null && _endDate != null) {
      final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      filtered = filtered.where((o) =>
          o.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
          o.createdAt.isBefore(end.add(const Duration(seconds: 1)))).toList();
    }

    return filtered;
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('id'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppTheme.secondaryColor,
          ),
        ),
        child: child!,
      ),
    );

    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
        _customRange = true;
        _period = 'custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prov = context.watch<OrderProvider>();

    final completedOrders = _filterOrders(prov.orders);
    final totalRevenue = completedOrders.fold<double>(0, (s, o) => s + o.total);
    final avgOrder = completedOrders.isEmpty ? 0.0 : totalRevenue / completedOrders.length;
    final chartData = _generateChartData(completedOrders);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reports)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            _PeriodChip('Harian', 'daily'),
            _PeriodChip('Mingguan', 'weekly'),
            _PeriodChip('Bulanan', 'monthly'),
            _PeriodChip('Custom', 'custom'),
          ]),
          if (_customRange) ...[
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  const Icon(Icons.date_range, color: AppTheme.secondaryColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDateRange,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_startDate != null ? formatDateShort(_startDate!) : 'Tanggal Mulai',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                      color: _startDate != null ? null : Colors.grey)),
                              Text(_endDate != null ? formatDateShort(_endDate!) : 'Tanggal Akhir',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                      color: _endDate != null ? null : Colors.grey)),
                            ]),
                          ),
                          const Icon(Icons.edit_calendar, size: 20, color: AppTheme.secondaryColor),
                        ]),
                      ),
                    ),
                  ),
                  if (_startDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Colors.red),
                      onPressed: () => setState(() {
                        _startDate = null;
                        _endDate = null;
                        _customRange = false;
                        _period = 'daily';
                      }),
                    ),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _ReportCard(label: l10n.totalRevenue, value: formatCurrency(totalRevenue), icon: Icons.trending_up, color: AppTheme.successColor)),
            const SizedBox(width: 12),
            Expanded(child: _ReportCard(label: l10n.totalOrders, value: '${completedOrders.length}', icon: Icons.receipt_long, color: AppTheme.secondaryColor)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _ReportCard(label: 'Rata-rata', value: formatCurrency(avgOrder), icon: Icons.analytics, color: AppTheme.warningColor)),
            const SizedBox(width: 12),
            Expanded(child: _ReportCard(label: 'Item Terjual', value: '${completedOrders.fold<int>(0, (s, o) => s + o.totalItems)}', icon: Icons.shopping_basket, color: AppTheme.accentColor)),
          ]),
          const SizedBox(height: 24),
          Text('Grafik Penjualan', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 250,
                child: chartData.isEmpty
                    ? Center(child: Text(l10n.noData))
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: chartData.isEmpty ? 100 : chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(formatCurrency(rod.toY), const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < chartData.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(chartData[value.toInt()].label, style: const TextStyle(fontSize: 11)),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: chartData.asMap().entries.map((e) {
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value.value,
                                  color: AppTheme.secondaryColor,
                                  width: 20,
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Menu Populer', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (completedOrders.isEmpty)
            Card(child: Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(l10n.noData))))
          else
            ..._getPopularItems(completedOrders).map((item) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.secondaryColor.withAlpha(20),
                      child: const Icon(Icons.fastfood, color: AppTheme.secondaryColor, size: 20),
                    ),
                    title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text('${item['count']}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )),
        ]),
      ),
    );
  }

  List<_ChartData> _generateChartData(List<OrderModel> orders) {
    if (_period == 'daily' || _period == 'custom') {
      final weekData = <int, double>{};
      for (var o in orders) {
        final day = o.createdAt.weekday;
        weekData[day] = (weekData[day] ?? 0) + o.total;
      }
      final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      return List.generate(7, (i) => _ChartData(days[i], weekData[i + 1] ?? 0));
    } else if (_period == 'weekly') {
      final data = <int, double>{};
      for (var o in orders) {
        final weekNum = int.tryParse('${o.createdAt.year}${o.createdAt.month.toString().padLeft(2, '0')}${((o.createdAt.day - 1) ~/ 7 + 1)}') ?? 0;
        data[weekNum] = (data[weekNum] ?? 0) + o.total;
      }
      final sorted = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
      return sorted.take(8).map((e) => _ChartData('W${e.key.toString().substring(6)}', e.value)).toList();
    } else {
      final data = <int, double>{};
      for (var o in orders) {
        final month = o.createdAt.month;
        data[month] = (data[month] ?? 0) + o.total;
      }
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return months.asMap().entries.map((e) => _ChartData(e.value, data[e.key + 1] ?? 0)).toList();
    }
  }

  List<Map<String, dynamic>> _getPopularItems(List<OrderModel> orders) {
    final itemMap = <String, Map<String, dynamic>>{};
    for (var order in orders) {
      for (var item in order.items) {
        if (itemMap.containsKey(item.name)) {
          itemMap[item.name]!['count'] += item.quantity;
        } else {
          itemMap[item.name] = {'name': item.name, 'count': item.quantity};
        }
      }
    }
    final sorted = itemMap.values.toList()..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return sorted.take(5).toList();
  }

  Widget _PeriodChip(String label, String value) {
    final selected = _period == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppTheme.secondaryColor.withAlpha(30),
      labelStyle: TextStyle(
          color: selected ? AppTheme.secondaryColor : null,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
      onSelected: (_) {
        if (value == 'custom') {
          _pickDateRange();
        } else {
          setState(() {
            _period = value;
            _customRange = false;
            _startDate = null;
            _endDate = null;
          });
        }
      },
    );
  }
}

class _ChartData {
  final String label;
  final double value;
  _ChartData(this.label, this.value);
}

class _ReportCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _ReportCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ),
    );
  }
}
