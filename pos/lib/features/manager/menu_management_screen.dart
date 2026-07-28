import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/app_settings_service.dart';
import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/access_restricted.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/image_crop_screen.dart';
import '../../l10n/app_localizations.dart';
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
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    AppSettingsService.instance.getMenuGridView().then((v) {
      if (mounted) setState(() => _isGridView = v);
    });
    _svc.addListener(_onMenuChanged);
  }

  @override
  void dispose() {
    _svc.removeListener(_onMenuChanged);
    super.dispose();
  }

  // Menu edits made on another device arrive over MenuService's own
  // /ws/menu connection; this just triggers a rebuild to show them.
  void _onMenuChanged() {
    if (mounted) setState(() {});
  }

  void _setGridView(bool value) {
    setState(() => _isGridView = value);
    AppSettingsService.instance.setMenuGridView(value);
  }

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
      // Barrier tap / drag are disabled so an accidental tap or swipe can't
      // silently discard the form or dismiss it mid-save (see PopScope in
      // _ItemFormSheet, which additionally blocks the back button while a
      // save is actually in flight) — Cancel/Save remain the only way out.
      isDismissible: false,
      enableDrag: false,
      builder: (_) =>
          _ItemFormSheet(existing: editing, categories: _svc.categories),
    );
    if (changed == true) setState(() {});
  }

  Future<void> _confirmDelete(MenuItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await confirmDialog(
      context,
      title: l10n.deleteItemTitle,
      content: l10n.deleteItemContent(item.name),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
    );
    if (ok && mounted) {
      setState(() => _svc.deleteItem(item.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteItemSnackbar(item.name))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!ServerClient.instance.canManageShop) {
      return AccessRestrictedScreen(feature: l10n.menuManagementTitle);
    }
    final items = _displayedItems;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.menuManagementTitle),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? l10n.listViewTooltip : l10n.gridViewTooltip,
            onPressed: () => _setGridView(!_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addItemTooltip,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      horizontal: 16,
                      vertical: 6,
                    ),
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
                  l10n.itemsCount(items.length),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                TextButton.icon(
                  onPressed: () => _showItemForm(),
                  icon: const Icon(Icons.add, size: 14),
                  label: Text(
                    l10n.addItemLabel,
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          // List / grid
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      l10n.noItemsEmpty,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  )
                : _isGridView
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = (constraints.maxWidth / 160).floor().clamp(
                        2,
                        6,
                      );
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, i) => _ItemGridCard(
                          item: items[i],
                          onToggle: () => _toggleAvailability(items[i].id),
                          onEdit: () => _showItemForm(editing: items[i]),
                          onDelete: () => _confirmDelete(items[i]),
                        ),
                      );
                    },
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageBase64 != null
                  ? Image.memory(
                      base64Decode(item.imageBase64!),
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 36,
                      height: 36,
                      color: AppColors.background,
                      child: const Icon(
                        Icons.fastfood_outlined,
                        size: 18,
                        color: AppColors.muted,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName(Localizations.localeOf(context)),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: item.available ? AppColors.ink : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
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

// ── Item grid card ──────────────────────────────────────────────────────────

class _ItemGridCard extends StatelessWidget {
  const _ItemGridCard({
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
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.terracottaLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.imageBase64 != null
                      ? Image.memory(
                          base64Decode(item.imageBase64!),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.background,
                          child: const Icon(
                            Icons.fastfood_outlined,
                            size: 28,
                            color: AppColors.muted,
                          ),
                        ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: item.available,
                          onChanged: (_) => onToggle(),
                          activeThumbColor: AppColors.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName(Localizations.localeOf(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: item.available ? AppColors.ink : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '฿${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                  color: AppColors.muted,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  color: AppColors.terracottaDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add / edit bottom sheet ─────────────────────────────────────────────────

class _ItemFormSheet extends StatefulWidget {
  const _ItemFormSheet({this.existing, required this.categories});
  final MenuItem? existing;
  final List<String> categories;

  @override
  State<_ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<_ItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _nameThCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _priceCtrl;
  late bool _available;
  late bool _hasSweetness;
  String? _imageBase64;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _nameThCtrl = TextEditingController(text: e?.nameTh ?? '');
    _categoryCtrl = TextEditingController(text: e?.category ?? '');
    _priceCtrl = TextEditingController(
      text: e != null ? e.price.toStringAsFixed(0) : '',
    );
    _available = e?.available ?? true;
    _hasSweetness = e?.hasSweetness ?? false;
    _imageBase64 = e?.imageBase64;
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => ImageCropScreen(imageBytes: bytes)),
    );
    if (cropped == null) return;
    setState(() => _imageBase64 = base64Encode(cropped));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameThCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final nameTh = _nameThCtrl.text.trim().isEmpty
        ? null
        : _nameThCtrl.text.trim();
    final svc = MenuService.instance;
    if (_isEdit) {
      svc.updateItem(
        MenuItem(
          id: widget.existing!.id,
          name: _nameCtrl.text.trim(),
          nameTh: nameTh,
          category: _categoryCtrl.text.trim(),
          price: price,
          available: _available,
          imageBase64: _imageBase64,
          hasSweetness: _hasSweetness,
        ),
      );
    } else {
      setState(() => _saving = true);
      await svc.addItem(
        name: _nameCtrl.text.trim(),
        nameTh: nameTh,
        category: _categoryCtrl.text.trim(),
        price: price,
        available: _available,
        imageBase64: _imageBase64,
        hasSweetness: _hasSweetness,
      );
      if (!mounted) return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    // Blocks the back button while a save is in flight, so it can't be used
    // to slip past the disabled Cancel/Save buttons — the barrier tap and
    // drag-to-dismiss routes are already closed off via isDismissible/
    // enableDrag on the showModalBottomSheet call that opens this sheet.
    return PopScope(
      canPop: !_saving,
      child: Container(
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
              _isEdit ? l10n.editItemFormTitle : l10n.addItemLabel,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _imageBase64 != null
                      ? Image.memory(
                          base64Decode(_imageBase64!),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: AppColors.background,
                          child: const Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.muted,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.itemNameLabel,
                hintText: l10n.itemNameHint,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.itemNameRequired
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameThCtrl,
              decoration: InputDecoration(
                labelText: l10n.itemNameThLabel,
                hintText: l10n.itemNameThHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryCtrl,
              decoration: InputDecoration(
                labelText: l10n.categoryLabel,
                hintText: l10n.categoryHint,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.categoryRequired
                  : null,
            ),
            if (widget.categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: widget.categories.map((cat) {
                  final sel = _categoryCtrl.text.trim() == cat;
                  return ChoiceChip(
                    label: Text(cat, style: const TextStyle(fontSize: 11)),
                    selected: sel,
                    onSelected: (_) => setState(() => _categoryCtrl.text = cat),
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
              decoration: InputDecoration(
                labelText: l10n.priceLabel,
                hintText: l10n.priceHint,
                border: const OutlineInputBorder(),
                prefixText: '฿ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.priceRequired;
                }
                final n = int.tryParse(v.trim());
                if (n == null || n <= 0) return l10n.priceInvalid;
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.availableLabel,
                  style: const TextStyle(fontSize: 14, color: AppColors.ink),
                ),
                Switch(
                  value: _available,
                  onChanged: (v) => setState(() => _available = v),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.hasSweetnessLabel,
                  style: const TextStyle(fontSize: 14, color: AppColors.ink),
                ),
                Switch(
                  value: _hasSweetness,
                  onChanged: (v) => setState(() => _hasSweetness = v),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isEdit ? l10n.saveChangesButton : l10n.addItemLabel,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
