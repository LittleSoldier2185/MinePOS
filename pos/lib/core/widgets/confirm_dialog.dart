import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared yes/no confirmation dialog. Cancel always pops false; the confirm
/// button pops true and gets the terracotta destructive color unless
/// [destructive] is set to false (e.g. "exit customer display", which isn't
/// a destructive action).
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = true,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmLabel,
            style: destructive ? const TextStyle(color: AppColors.terracottaDark) : null,
          ),
        ),
      ],
    ),
  );
  return ok == true;
}
