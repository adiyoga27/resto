import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../../models/table.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../config/theme.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  final FirestoreService _fs = FirestoreService();
  List<TableModel> _tables = [];
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().userId;
      _fs.setUserId(uid);
      _fs.streamTables().listen((tables) {
        if (mounted) setState(() => _tables = tables);
      });
    });
  }

  void _showAddEditTable({TableModel? existing}) {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final capCtrl = TextEditingController(
        text: (existing?.capacity ?? 4).toString());
    int floor = existing?.floor ?? 1;

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(existing != null ? l10n.edit : l10n.addTable),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: l10n.tableName),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: capCtrl,
                  decoration: InputDecoration(labelText: l10n.capacity),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: floor,
                  decoration: const InputDecoration(labelText: 'Lantai'),
                  items: [1, 2, 3]
                      .map((f) => DropdownMenuItem(
                          value: f, child: Text('Lantai $f')))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => floor = v ?? 1),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c), child: Text(l10n.cancel)),
              TextButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final table = TableModel(
                    id: existing?.id ?? _uuid.v4(),
                    name: nameCtrl.text.trim(),
                    capacity: int.tryParse(capCtrl.text) ?? 4,
                    floor: floor,
                    status: existing?.status ?? TableStatus.available,
                  );
                  if (existing != null) {
                    _fs.updateTable(table);
                  } else {
                    _fs.addTable(table);
                  }
                  Navigator.pop(c);
                },
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteTable(TableModel table) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDelete),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              _fs.deleteTable(table.id);
              Navigator.pop(c);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final responsive = ResponsiveLayout(context);

    final floors = _tables.map((t) => t.floor).toSet().toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tables),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addTable,
            onPressed: () => _showAddEditTable(),
          ),
        ],
      ),
      body: _tables.isEmpty
          ? Center(child: Text(l10n.noData))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegend(l10n),
                  const SizedBox(height: 16),
                  ...floors.map((floor) {
                    final floorTables =
                        _tables.where((t) => t.floor == floor).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lantai $floor',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        GridView.count(
                          crossAxisCount: responsive.crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.4,
                          children: floorTables
                              .map((t) => _TableCard(
                                    table: t,
                                    onTap: () => _showAddEditTable(existing: t),
                                    onDelete: () => _deleteTable(t),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildLegend(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(AppTheme.successColor, l10n.available),
        const SizedBox(width: 16),
        _legendItem(AppTheme.secondaryColor, l10n.occupied),
        const SizedBox(width: 16),
        _legendItem(AppTheme.warningColor, l10n.reserved),
      ],
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(3),
        )),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _TableCard extends StatelessWidget {
  final TableModel table;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TableCard({
    required this.table,
    required this.onTap,
    required this.onDelete,
  });

  Color get _color {
    switch (table.status) {
      case TableStatus.available:
        return AppTheme.successColor;
      case TableStatus.occupied:
        return AppTheme.secondaryColor;
      case TableStatus.reserved:
        return AppTheme.warningColor;
    }
  }

  IconData get _icon {
    switch (table.status) {
      case TableStatus.available:
        return Icons.table_bar;
      case TableStatus.occupied:
        return Icons.table_bar;
      case TableStatus.reserved:
        return Icons.table_bar;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: _color, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_icon, color: _color, size: 32),
                const SizedBox(height: 8),
                Text(table.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('${table.capacity} orang',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _color.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    table.status.name.toUpperCase(),
                    style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w700, color: _color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



