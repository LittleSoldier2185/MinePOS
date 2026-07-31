import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../services/app_settings_service.dart';

/// Shared sort-order picker for a menu item list — used by both Menu
/// Management and the cashier Order screen so "how I like the menu sorted"
/// behaves the same in both places.
class MenuSortButton extends StatelessWidget {
  const MenuSortButton({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final MenuSortMode value;
  final ValueChanged<MenuSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String label(MenuSortMode mode) => switch (mode) {
      MenuSortMode.defaultOrder => l10n.sortDefaultOption,
      MenuSortMode.nameAsc => l10n.sortNameAscOption,
      MenuSortMode.nameDesc => l10n.sortNameDescOption,
      MenuSortMode.priceAsc => l10n.sortPriceAscOption,
      MenuSortMode.priceDesc => l10n.sortPriceDescOption,
    };
    return PopupMenuButton<MenuSortMode>(
      icon: const Icon(Icons.sort),
      tooltip: l10n.sortMenuTooltip,
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final mode in MenuSortMode.values)
          PopupMenuItem(
            value: mode,
            child: Row(
              children: [
                if (mode == value)
                  const Icon(Icons.check, size: 16)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(label(mode)),
              ],
            ),
          ),
      ],
    );
  }
}
