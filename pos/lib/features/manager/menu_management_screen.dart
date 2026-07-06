import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../cashier/models/menu_item.dart';
import '../cashier/services/menu_service.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final _svc = MenuService.instance;
  String _selectedCategory = 'All';

  List<String> get _filterCategories => ['All', ..._svc.categories];

  List<MenuItem> get _displayedItems => _selectedCategory == 'All'
      ? _svc.allItems.toList()
      : _svc.allItemsForCategory(_selectedCategory);

  void _toggleAvailability(String id) =>
      setState(() => _svc.toggleAvailability(id));

  Future<void> _showItemForm({MenuItem? editing}) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemFormSheet(
        existing: editing,
        categories: _svc.categories,
      ),
    );
    if (changed == true) setState(() {});
  }

  Future<void> _confirmDelete(MenuItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text(
            'Remove "${item.name}" from the menu? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.terracottaDark)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() => _svc.deleteItem(item.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${item.name}" removed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _displayedItems;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add item',
            onPressed: () => _showItemForm(),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category filter chips
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemCount: _filterCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _filterCategories[i];
                final sel = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel
                            ? AppColors.primary
                            : AppColors.terracottaLight,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel ? AppColors.accent : AppColors.ink,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Count + add shortcut
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${items.length} item${items.length == 1 ? '' : 's'}',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                TextButton.icon(
                  onPressed: () => _showItemForm(),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add Item',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'No items in this category.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) => _ItemRow(
                      item: items[i],
                      onToggle: () => _toggleAvailability(items[i].id),
                      onEdit: () => _showItemForm(editing: items[i]),
                      onDelete: () => _confirmDelete(items[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Item row card ───────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });
  final MenuItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: item.available ? 1.0 : 0.55,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.terracottaLight),
        ),
        child: Row(
          children: [
            Switch(
              value: item.available,
              onChanged: (_) => onToggle(),
              activeThumbColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: item.available
                          ? AppColors.ink
                          : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '฿${item.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
              color: AppColors.muted,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
              color: AppColors.terracottaDark,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add / edit bottom sheet ─────────────────────────────────────────────────

class _ItemFormSheet extends StatefulWidget {
  const _ItemFormSheet({
    this.existing,
    required this.categories,
  });
  final MenuItem? existing;
  final List<String> categories;

  @override
  State<_ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<_ItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _priceCtrl;
  late bool _available;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _categoryCtrl = TextEditingController(text: e?.category ?? '');
    _priceCtrl = TextEditingController(
        text: e != null ? e.price.toStringAsFixed(0) : '');
    _available = e?.available ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final svc = MenuService.instance;
    if (_isEdit) {
      svc.updateItem(MenuItem(
        id: widget.existing!.id,
        name: _nameCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        price: price,
        available: _available,
      ));
    } else {
      svc.addItem(
        name: _nameCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        price: price,
        available: _available,
      );
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.terracottaLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEdit ? 'Edit Item' : 'Add Item',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Item name',
                hintText: 'e.g. Caramel Latte',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'e.g. Coffee',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Category is required'
                  : null,
            ),
            if (widget.categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: widget.categories.map((cat) {
                  final sel =
                      _categoryCtrl.text.trim() == cat;
                  return ChoiceChip(
                    label: Text(cat,
                        style: const TextStyle(fontSize: 11)),
                    selected: sel,
                    onSelected: (_) =>
                        setState(() => _categoryCtrl.text = cat),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: sel ? AppColors.accent : AppColors.ink,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(
                labelText: 'Price',
                hintText: '0',
                border: OutlineInputBorder(),
                prefixText: '฿ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: false),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Price is required';
                }
                final n = int.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a valid price';
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Available on menu',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.ink)),
                Switch(
                  value: _available,
                  onChanged: (v) => setState(() => _available = v),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(_isEdit ? 'Save Changes' : 'Add Item'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
