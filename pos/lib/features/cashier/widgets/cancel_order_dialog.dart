import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Shared "why are you cancelling?" dialog used by both Order History and
/// Kitchen Display. Returns the composed reason string on confirm, or null
/// if the user backed out.
Future<String?> showCancelOrderDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const _CancelOrderDialog(),
  );
}

class _CancelOrderDialog extends StatefulWidget {
  const _CancelOrderDialog();

  @override
  State<_CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<_CancelOrderDialog> {
  String? _selected;
  final _extraCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _extraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reasons = [
      l10n.cancelReasonCustomerChanged,
      l10n.cancelReasonDuplicate,
      l10n.cancelReasonWrongItem,
      l10n.cancelReasonOutOfStock,
      l10n.cancelReasonOther,
    ];

    return AlertDialog(
      title: Text(l10n.cancelOrderDialogTitle),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.cancelReasonPromptLabel,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              RadioGroup<String>(
                groupValue: _selected,
                onChanged: (v) => setState(() {
                  _selected = v;
                  _error = null;
                }),
                child: Column(
                  children: reasons
                      .map((r) => RadioListTile<String>(
                            value: r,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(r, style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _extraCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: l10n.cancelReasonExtraHint,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.terracottaDark)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.terracottaDark),
          onPressed: () {
            final selected = _selected;
            if (selected == null) {
              setState(() => _error = l10n.cancelReasonRequiredError);
              return;
            }
            final extra = _extraCtrl.text.trim();
            Navigator.pop(context, extra.isEmpty ? selected : '$selected — $extra');
          },
          child: Text(l10n.cancelOrderLabel),
        ),
      ],
    );
  }
}
