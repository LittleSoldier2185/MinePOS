import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/services/app_settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../cashier/models/order.dart';
import '../cashier/models/order_item.dart';
import '../cashier/services/menu_service.dart';

/// Single-order detail view opened by tapping a Kitchen Display card — shows
/// each item larger (with its menu photo, if enabled in Settings) and lets a
/// barista drive the whole order's prep status from this one screen instead
/// of the small chips on the compact card.
class OrderFocusScreen extends StatefulWidget {
  const OrderFocusScreen({
    super.key,
    required this.order,
    required this.onItemTap,
    this.completeLabel,
    this.onComplete,
  });

  final Order order;
  final ValueChanged<OrderItem> onItemTap;

  /// Only set for an order in the READY column — see `_KitchenColumn` in
  /// kitchen_display_screen.dart.
  final String? completeLabel;
  final VoidCallback? onComplete;

  @override
  State<OrderFocusScreen> createState() => _OrderFocusScreenState();
}

class _OrderFocusScreenState extends State<OrderFocusScreen> {
  bool _showImages = true;

  @override
  void initState() {
    super.initState();
    _loadImagePref();
  }

  Future<void> _loadImagePref() async {
    final show = await AppSettingsService.instance.getKitchenShowImages();
    if (mounted) setState(() => _showImages = show);
  }

  String? _imageFor(OrderItem item) {
    if (!_showImages) return null;
    final menuItem = MenuService.instance.allItems
        .where((m) => m.id == item.menuItem.id)
        .firstOrNull;
    return menuItem?.imageBase64;
  }

  String _itemLabel(OrderItem item, AppLocalizations l10n, Locale locale) {
    final name = item.menuItem.displayName(locale);
    return item.sweetness == null
        ? name
        : '$name (${item.sweetness!.label(l10n)})';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.focusModeTitle} · ${order.formattedNumber}'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: AppColors.background,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: order.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final item = order.items[i];
          final image = _imageFor(item);
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.terracottaLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (image != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      base64Decode(image),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.quantity}× ${_itemLabel(item, l10n, locale)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _FocusStatusActions(
                        item: item,
                        l10n: l10n,
                        onTap: () => widget.onItemTap(item),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar:
          widget.completeLabel == null || widget.onComplete == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    widget.onComplete!();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(widget.completeLabel!),
                ),
              ),
            ),
    );
  }
}

class _FocusStatusActions extends StatelessWidget {
  const _FocusStatusActions({
    required this.item,
    required this.l10n,
    required this.onTap,
  });
  final OrderItem item;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return switch (item.status) {
      'pending' => ElevatedButton(
        onPressed: onTap,
        child: Text(l10n.startPreparingButton),
      ),
      'preparing' => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
        child: Text(l10n.readyToServeButton),
      ),
      _ => Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: Colors.green.shade700),
          const SizedBox(width: 6),
          Text(
            l10n.readyStatusLabel,
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    };
  }
}
