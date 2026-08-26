import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_message.dart';
import '../../l10n/app_localizations.dart';
import '../cashier/services/menu_service.dart';

/// Reorder (drag) and rename the shop's menu categories — categories aren't
/// a separate entity server-side (each item just carries a free-text
/// category string), so "renaming" here bulk-updates every item currently in
/// that category and "reordering" persists a shop-wide display order via
/// [MenuService.setCategoryOrder].
class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _svc = MenuService.instance;
  late List<String> _order = List.of(_svc.categories);

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onMenuChanged);
  }

  @override
  void dispose() {
    _svc.removeListener(_onMenuChanged);
    super.dispose();
  }

  // A rename or an item add/delete changing which categories exist should
  // resync the local drag order — but not clobber an in-flight local
  // reorder, so only when the set of categories actually differs.
  void _onMenuChanged() {
    if (!mounted) return;
    final fresh = _svc.categories;
    if (fresh.length != _order.length || !fresh.toSet().containsAll(_order)) {
      setState(() => _order = List.of(fresh));
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final moved = _order.removeAt(oldIndex);
      _order.insert(newIndex, moved);
    });
    _svc.setCategoryOrder(_order);
  }

  Future<void> _rename(String category) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: category);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.renameCategoryTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.renameCategoryLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(l10n.saveChangesButton),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty || result == category) return;
    await _svc.renameCategory(category, result);
    setState(() {
      final i = _order.indexOf(category);
      if (i != -1) _order[i] = result;
    });
    if (!mounted) return;
    showAppMessage(context, l10n.renameCategorySnackbar);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageCategoriesTitle),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.manageCategoriesHint,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _order.length,
              onReorderItem: _onReorder,
              itemBuilder: (context, i) {
                final category = _order[i];
                return Container(
                  key: ValueKey(category),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.terracottaLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.drag_indicator,
                        size: 18,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: AppColors.muted,
                        onPressed: () => _rename(category),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
