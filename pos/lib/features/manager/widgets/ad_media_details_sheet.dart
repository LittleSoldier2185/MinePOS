import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../services/ad_service.dart';

/// Result of [showAdMediaDetailsSheet] — the full new state for an ad
/// slide's name/duration/transition/expiry, all set together in one form
/// rather than via separate dialogs.
class AdMediaDetails {
  AdMediaDetails({
    required this.name,
    required this.durationSeconds,
    required this.transition,
    required this.expiresAt,
  });

  final String? name;

  /// Null for video slides — they play to their own end, not a fixed duration.
  final int? durationSeconds;
  final AdTransition transition;

  /// Null means the slide runs forever until manually removed.
  final DateTime? expiresAt;
}

/// One consolidated "Media Details" sheet for both adding and editing an ad
/// slide — used right after picking a file to upload (so these are set at
/// creation time instead of only editable afterward) and from each slide
/// row's edit icon. Returns null if the user backed out.
Future<AdMediaDetails?> showAdMediaDetailsSheet(
  BuildContext context, {
  required bool isVideo,
  String? initialName,
  int initialDurationSeconds = 8,
  AdTransition initialTransition = AdTransition.fade,
  DateTime? initialExpiresAt,
}) {
  return showModalBottomSheet<AdMediaDetails>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AdMediaDetailsSheet(
      isVideo: isVideo,
      initialName: initialName,
      initialDurationSeconds: initialDurationSeconds,
      initialTransition: initialTransition,
      initialExpiresAt: initialExpiresAt,
    ),
  );
}

class _AdMediaDetailsSheet extends StatefulWidget {
  const _AdMediaDetailsSheet({
    required this.isVideo,
    this.initialName,
    required this.initialDurationSeconds,
    required this.initialTransition,
    this.initialExpiresAt,
  });

  final bool isVideo;
  final String? initialName;
  final int initialDurationSeconds;
  final AdTransition initialTransition;
  final DateTime? initialExpiresAt;

  @override
  State<_AdMediaDetailsSheet> createState() => _AdMediaDetailsSheetState();
}

class _AdMediaDetailsSheetState extends State<_AdMediaDetailsSheet> {
  late final _nameController = TextEditingController(
    text: widget.initialName ?? '',
  );
  late final _durationController = TextEditingController(
    text: '${widget.initialDurationSeconds}',
  );
  late AdTransition _transition = widget.initialTransition;
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    _expiresAt = widget.initialExpiresAt;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  void _save() {
    final name = _nameController.text.trim();
    final duration = int.tryParse(_durationController.text.trim());
    Navigator.pop(
      context,
      AdMediaDetails(
        name: name.isEmpty ? null : name,
        durationSeconds: widget.isVideo
            ? null
            : ((duration != null && duration > 0)
                  ? duration
                  : widget.initialDurationSeconds),
        transition: _transition,
        expiresAt: _expiresAt,
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.muted,
    ),
  );

  Widget _choiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) => ChoiceChip(
    label: Text(label, style: const TextStyle(fontSize: 12)),
    selected: selected,
    onSelected: (_) => onTap(),
    selectedColor: AppColors.primary,
    labelStyle: TextStyle(color: selected ? AppColors.accent : AppColors.ink),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.terracottaLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n.adMediaDetailsTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.adMediaNameLabel,
                  hintText: l10n.adMediaNameHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (!widget.isVideo) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.adMediaDurationLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _sectionLabel(l10n.adMediaTransitionLabel),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _choiceChip(
                    label: l10n.adTransitionNoneOption,
                    selected: _transition == AdTransition.none,
                    onTap: () =>
                        setState(() => _transition = AdTransition.none),
                  ),
                  _choiceChip(
                    label: l10n.adTransitionFadeOption,
                    selected: _transition == AdTransition.fade,
                    onTap: () =>
                        setState(() => _transition = AdTransition.fade),
                  ),
                  _choiceChip(
                    label: l10n.adTransitionSlideOption,
                    selected: _transition == AdTransition.slideLeft,
                    onTap: () =>
                        setState(() => _transition = AdTransition.slideLeft),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionLabel(l10n.adMediaExpiryLabel),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _choiceChip(
                    label: l10n.adExpiryNeverOption,
                    selected: _expiresAt == null,
                    onTap: () => setState(() => _expiresAt = null),
                  ),
                  for (final days in [7, 14, 30])
                    _choiceChip(
                      label: l10n.adExpiryInDaysOption(days),
                      selected: false,
                      onTap: () => setState(
                        () => _expiresAt = DateTime.now().add(
                          Duration(days: days),
                        ),
                      ),
                    ),
                  _choiceChip(
                    label: _expiresAt != null
                        ? '${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year % 100}'
                        : l10n.adExpiryCustomDateOption,
                    selected: _expiresAt != null,
                    onTap: _pickCustomDate,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      child: Text(l10n.saveChangesButton),
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
