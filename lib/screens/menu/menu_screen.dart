import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/menu_item.dart';
import '../../models/menu_category.dart';
import '../../models/order.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/utils/currency_format.dart';
import '../../core/utils/currency_formatter.dart';
import '../../config/theme.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  final _picker = ImagePicker();

  void _showAddCategoryDialog() {
    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.addCategory),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: 'Nama Kategori',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            prefixIcon: Icon(Icons.category_outlined),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                context.read<MenuProvider>().addCategory(nameCtrl.text.trim());
                Navigator.pop(c);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(MenuCategory category) {
    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: category.name);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.editCategory),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: 'Nama Kategori',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                context
                    .read<MenuProvider>()
                    .updateCategory(category.copyWith(name: nameCtrl.text.trim()));
                Navigator.pop(c);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog({MenuItem? existing}) {
    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl =
        TextEditingController(text: existing?.price.toString() ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final prov = context.read<MenuProvider>();
    String selectedCategoryId = existing?.categoryId ??
        (prov.categories.isNotEmpty ? prov.categories.first.id : '');
    String imageUrl = existing?.imageUrl ?? '';

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          existing != null ? l10n.editItem : l10n.addItem,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(c),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () async {
                        final file = await _picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 800,
                          maxHeight: 800,
                          imageQuality: 85,
                        );
                        if (file != null) {
                          setDialogState(() => imageUrl = file.path);
                        }
                      },
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                          image: imageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: FileImage(File(imageUrl)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: imageUrl.isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap untuk upload gambar',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 13),
                                  ),
                                ],
                              )
                            : Stack(
                                children: [
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.edit,
                                          color: Colors.white, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Nama Menu',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        prefixIcon: Icon(Icons.fastfood_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: priceCtrl,
                      style: const TextStyle(fontSize: 15),
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      decoration: InputDecoration(
                        labelText: 'Harga',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        prefixIcon: Icon(Icons.monetization_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedCategoryId.isNotEmpty
                          ? selectedCategoryId
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: prov.categories
                          .map((cat) => DropdownMenuItem(
                              value: cat.id, child: Text(cat.name)))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedCategoryId = v ?? ''),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Deskripsi',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 48),
                          child: Icon(Icons.description_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty ||
                              priceCtrl.text.trim().isEmpty ||
                              selectedCategoryId.isEmpty) {
                            return;
                          }
                          final cat = prov.getCategoryById(selectedCategoryId);
                          if (existing != null) {
                            prov.updateItem(existing.copyWith(
                              name: nameCtrl.text.trim(),
                              categoryId: selectedCategoryId,
                              categoryName: cat?.name ?? '',
                              price: double.tryParse(priceCtrl.text.replaceAll('.', '')) ?? 0,
                              description: descCtrl.text.trim(),
                              imageUrl: imageUrl,
                            ));
                          } else {
                            prov.addItem(
                              nameCtrl.text.trim(),
                              selectedCategoryId,
                              cat?.name ?? '',
                              double.tryParse(priceCtrl.text) ?? 0,
                              descCtrl.text.trim(),
                              imageUrl: imageUrl,
                            );
                          }
                          Navigator.pop(c);
                        },
                        icon: const Icon(Icons.check),
                        label: Text(l10n.save),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prov = context.watch<MenuProvider>();
    final responsive = ResponsiveLayout(context);

    var items = prov.filteredItems;
    if (_searchQuery.isNotEmpty) {
      items = items
          .where((i) =>
              i.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              i.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.menu, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () => _showAddItemDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addItem, style: const TextStyle(fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: '${l10n.search} menu...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Tooltip(
                      message: l10n.addCategory,
                      child: Material(
                        color: Theme.of(context).colorScheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _showAddCategoryDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(50)),
                            ),
                            child: Icon(Icons.create_new_folder_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _CategoryChip(
                      label: 'Semua',
                      isSelected: prov.selectedCategoryId.isEmpty || prov.selectedCategoryId == 'all',
                      onTap: () => prov.setSelectedCategory('all'),
                    ),
                    ...prov.categories.map((cat) => _CategoryChip(
                          label: cat.name,
                          isSelected: prov.selectedCategoryId == cat.id,
                          onTap: () => prov.setSelectedCategory(cat.id),
                          onEdit: () => _showEditCategoryDialog(cat),
                          onDelete: () => _confirmDeleteCategory(cat),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant_menu_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(l10n.noData,
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: responsive.crossAxisCount,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: responsive.isTablet ? 0.85 : 0.8,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => _MenuItemCard(
                item: items[i],
                onTap: () => _showAddItemDialog(existing: items[i]),
                onDelete: () => _confirmDeleteItem(items[i]),
                onAddToCart: () {
                  context.read<OrderProvider>().addToCart(OrderItem(
                        menuItemId: items[i].id,
                        name: items[i].name,
                        price: items[i].price,
                      ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${items[i].name} ditambahkan'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _confirmDeleteCategory(MenuCategory cat) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.delete),
        content: Text(l10n.confirmDelete),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              context.read<MenuProvider>().deleteCategory(cat.id);
              Navigator.pop(c);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteItem(MenuItem item) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.delete),
        content: Text(l10n.confirmDelete),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              context.read<MenuProvider>().deleteItem(item.id);
              Navigator.pop(c);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primary
            : isDark ? Colors.white10 : Colors.black.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          onLongPress: onEdit != null ? onEdit : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withAlpha(200),
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onAddToCart;

  const _MenuItemCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onAddToCart,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.imageUrl.isNotEmpty)
                    Image.file(
                      File(item.imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultImage(),
                    )
                  else
                    _defaultImage(),
                  if (!item.available)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: Text('Tidak Tersedia',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withAlpha(220),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(item.categoryName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(item.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatCurrency(item.price),
                            style: const TextStyle(
                              color: AppTheme.secondaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            )),
                        GestureDetector(
                          onTap: onAddToCart,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
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

  Widget _defaultImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondaryColor.withAlpha(30),
            AppTheme.accentColor.withAlpha(30),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.fastfood_rounded, size: 44, color: Colors.black26),
      ),
    );
  }
}
