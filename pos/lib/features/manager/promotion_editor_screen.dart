import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_message.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/image_crop_screen.dart';
import '../../l10n/app_localizations.dart';
import '../cashier/services/menu_service.dart';
import 'services/promotion_admin_service.dart';

const _kPromotionTypes = [
  'percent',
  'flat',
  'bogo',
  'code',
  'combo',
  'min_spend',
  'tiered',
];

/// Full-page editor for one promotion — pushed from Settings → Promotions
/// (too many conditional fields to fit a bottom sheet, unlike the simpler
/// Advertising slide/menu item forms). Creating a new promotion saves it
/// immediately once required fields are filled, then flips into "editing"
/// mode in place so code management (which needs a real promotion id) can
/// follow on the same screen without a separate navigation round-trip.
class PromotionEditorScreen extends StatefulWidget {
  const PromotionEditorScreen({super.key, this.existing});

  final Promotion? existing;

  @override
  State<PromotionEditorScreen> createState() => _PromotionEditorScreenState();
}

class _PromotionEditorScreenState extends State<PromotionEditorScreen> {
  Promotion? _saved;

  late final _nameController = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final _percentController = TextEditingController(
    text: widget.existing?.percentValue?.toStringAsFixed(0) ?? '',
  );
  late final _flatController = TextEditingController(
    text: widget.existing?.flatAmount?.toStringAsFixed(0) ?? '',
  );
  late final _maxCapController = TextEditingController(
    text: widget.existing?.maxDiscountCap?.toStringAsFixed(0) ?? '',
  );
  late final _minSpendController = TextEditingController(
    text: widget.existing?.minSpendAmount?.toStringAsFixed(0) ?? '',
  );
  late final _bogoBuyController = TextEditingController(
    text: widget.existing?.bogoBuyQty?.toString() ?? '2',
  );
  late final _bogoGetController = TextEditingController(
    text: widget.existing?.bogoGetQty?.toString() ?? '1',
  );
  late final _bogoDiscountController = TextEditingController(
    text: widget.existing?.bogoGetDiscountPercent?.toStringAsFixed(0) ?? '100',
  );
  late final _comboPriceController = TextEditingController(
    text: widget.existing?.comboPrice?.toStringAsFixed(0) ?? '',
  );
  late final _approvalThresholdController = TextEditingController(
    text: widget.existing?.approvalThresholdAmount?.toStringAsFixed(0) ?? '',
  );
  late final _newCodeController = TextEditingController();
  late final _newCodeMaxUsesController = TextEditingController();

  late String _type = widget.existing?.type ?? 'percent';
  late bool _active = widget.existing?.active ?? true;
  late String _scopeType = widget.existing?.scopeType ?? 'shop';
  late Set<String> _scopeItemIds = {
    ...(widget.existing?.scopeItemIds ?? const []),
  };
  final Set<String> _scopeCategories = {};
  late Set<String> _excludeItemIds = {
    ...(widget.existing?.excludeItemIds ?? const []),
  };
  late String _rewardKind =
      (widget.existing?.flatAmount != null &&
          widget.existing?.percentValue == null)
      ? 'flat'
      : 'percent';
  final List<_TieredRow> _tiered = [];
  late DateTime? _startDate = widget.existing?.startDate;
  late DateTime? _endDate = widget.existing?.endDate;
  late Set<int>? _daysOfWeek = widget.existing?.daysOfWeek == null
      ? null
      : {...widget.existing!.daysOfWeek!};
  late String? _timeStart = widget.existing?.timeStart;
  late String? _timeEnd = widget.existing?.timeEnd;
  late bool _requiresApproval =
      widget.existing?.requiresManagerApproval ?? false;
  late String? _imageBase64 = widget.existing?.imageBase64;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _saved = widget.existing;
    _scopeCategories.addAll(widget.existing?.scopeCategories ?? const []);
    for (final t in widget.existing?.tiered ?? const []) {
      _tiered.add(
        _TieredRow(
          qty: TextEditingController(text: '${t['qty']}'),
          price: TextEditingController(text: '${t['price']}'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _percentController.dispose();
    _flatController.dispose();
    _maxCapController.dispose();
    _minSpendController.dispose();
    _bogoBuyController.dispose();
    _bogoGetController.dispose();
    _bogoDiscountController.dispose();
    _comboPriceController.dispose();
    _approvalThresholdController.dispose();
    _newCodeController.dispose();
    _newCodeMaxUsesController.dispose();
    for (final row in _tiered) {
      row.qty.dispose();
      row.price.dispose();
    }
    super.dispose();
  }

  double? _parse(TextEditingController c) =>
      c.text.trim().isEmpty ? null : double.tryParse(c.text.trim());
  int? _parseInt(TextEditingController c) =>
      c.text.trim().isEmpty ? null : int.tryParse(c.text.trim());

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

  Promotion _buildPromotion() {
    final isCombo = _type == 'combo';
    return Promotion(
      id: _saved?.id ?? '',
      name: _nameController.text.trim(),
      type: _type,
      active: _active,
      scopeType: isCombo ? 'item' : _scopeType,
      scopeItemIds: (isCombo || _scopeType == 'item')
          ? _scopeItemIds.toList()
          : const [],
      scopeCategories: _scopeType == 'category' && !isCombo
          ? _scopeCategories.toList()
          : const [],
      excludeItemIds: _scopeType == 'shop' && !isCombo
          ? _excludeItemIds.toList()
          : const [],
      percentValue:
          (_type == 'percent' ||
              ((_type == 'code' || _type == 'min_spend') &&
                  _rewardKind == 'percent'))
          ? _parse(_percentController)
          : null,
      flatAmount:
          (_type == 'flat' ||
              ((_type == 'code' || _type == 'min_spend') &&
                  _rewardKind == 'flat'))
          ? _parse(_flatController)
          : null,
      maxDiscountCap: _type == 'percent' ? _parse(_maxCapController) : null,
      minSpendAmount: _type == 'min_spend' ? _parse(_minSpendController) : null,
      bogoBuyQty: _type == 'bogo' ? _parseInt(_bogoBuyController) : null,
      bogoGetQty: _type == 'bogo' ? _parseInt(_bogoGetController) : null,
      bogoGetDiscountPercent: _type == 'bogo'
          ? _parse(_bogoDiscountController)
          : null,
      comboPrice: isCombo ? _parse(_comboPriceController) : null,
      tiered: _type == 'tiered'
          ? _tiered
                .where(
                  (r) =>
                      r.qty.text.trim().isNotEmpty &&
                      r.price.text.trim().isNotEmpty,
                )
                .map(
                  (r) => {
                    'qty': int.parse(r.qty.text.trim()),
                    'price': double.parse(r.price.text.trim()),
                  },
                )
                .toList()
          : const [],
      startDate: _startDate,
      endDate: _endDate,
      daysOfWeek: _daysOfWeek?.toList(),
      timeStart: _timeStart,
      timeEnd: _timeEnd,
      requiresManagerApproval: _requiresApproval,
      approvalThresholdAmount: _requiresApproval
          ? _parse(_approvalThresholdController)
          : null,
      imageBase64: isCombo ? _imageBase64 : null,
      codes: _saved?.codes ?? const [],
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = l10n.promotionNameRequiredError);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final promotion = _buildPromotion();
      final result = _saved == null
          ? await PromotionAdminService.instance.create(promotion)
          : await PromotionAdminService.instance.update(_saved!.id, promotion);
      if (!mounted) return;
      setState(() => _saved = result);
      showAppMessage(context, l10n.promotionSavedMessage);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addCode() async {
    final code = _newCodeController.text.trim();
    if (code.isEmpty || _saved == null) return;
    final maxUses = _newCodeMaxUsesController.text.trim().isEmpty
        ? null
        : int.tryParse(_newCodeMaxUsesController.text.trim());
    try {
      final added = await PromotionAdminService.instance.addCode(
        _saved!.id,
        code,
        maxUses: maxUses,
      );
      if (!mounted) return;
      setState(() {
        _saved = _saved!.copyWith(codes: [..._saved!.codes, added]);
        _newCodeController.clear();
        _newCodeMaxUsesController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  Future<void> _deleteCode(PromotionCode code) async {
    if (_saved == null) return;
    try {
      await PromotionAdminService.instance.deleteCode(_saved!.id, code.id);
      if (!mounted) return;
      setState(() {
        _saved = _saved!.copyWith(
          codes: _saved!.codes.where((c) => c.id != code.id).toList(),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _timeStart : _timeEnd;
    final initial = current != null
        ? TimeOfDay(
            hour: int.parse(current.split(':')[0]),
            minute: int.parse(current.split(':')[1]),
          )
        : TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isStart) {
        _timeStart = formatted;
      } else {
        _timeEnd = formatted;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final menu = MenuService.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _saved == null
              ? l10n.promotionEditorNewTitle
              : l10n.promotionEditorEditTitle,
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppTextField(
              label: l10n.promotionNameLabel,
              controller: _nameController,
              hintText: l10n.promotionNameHint,
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: Text(l10n.promotionActiveLabel),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.promotionTypeLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kPromotionTypes
                  .map(
                    (t) => ChoiceChip(
                      label: Text(_typeLabel(l10n, t)),
                      selected: _type == t,
                      onSelected: (_) => setState(() => _type = t),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            if (_type != 'combo') ...[
              Text(
                l10n.promotionScopeLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.promotionScopeItem),
                    selected: _scopeType == 'item',
                    onSelected: (_) => setState(() => _scopeType = 'item'),
                  ),
                  ChoiceChip(
                    label: Text(l10n.promotionScopeCategory),
                    selected: _scopeType == 'category',
                    onSelected: (_) => setState(() => _scopeType = 'category'),
                  ),
                  ChoiceChip(
                    label: Text(l10n.promotionScopeShop),
                    selected: _scopeType == 'shop',
                    onSelected: (_) => setState(() => _scopeType = 'shop'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_scopeType == 'item')
                _ItemPicker(
                  selected: _scopeItemIds,
                  onChanged: (s) => setState(() => _scopeItemIds = s),
                ),
              if (_scopeType == 'category')
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: menu.categories
                      .map(
                        (c) => FilterChip(
                          label: Text(c),
                          selected: _scopeCategories.contains(c),
                          onSelected: (sel) => setState(
                            () => sel
                                ? _scopeCategories.add(c)
                                : _scopeCategories.remove(c),
                          ),
                        ),
                      )
                      .toList(),
                ),
              if (_scopeType == 'shop') ...[
                Text(
                  l10n.promotionExcludeItemsLabel,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                _ItemPicker(
                  selected: _excludeItemIds,
                  onChanged: (s) => setState(() => _excludeItemIds = s),
                ),
              ],
              const SizedBox(height: 20),
            ],
            ..._typeSpecificFields(l10n, menu),
            const SizedBox(height: 20),
            Text(
              l10n.promotionScheduleLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: true),
                    child: Text(
                      _startDate == null
                          ? l10n.promotionStartDateLabel
                          : DateFormat.yMd().format(_startDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: false),
                    child: Text(
                      _endDate == null
                          ? l10n.promotionEndDateLabel
                          : DateFormat.yMd().format(_endDate!),
                    ),
                  ),
                ),
                if (_startDate != null || _endDate != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _startDate = null;
                      _endDate = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.promotionDaysOfWeekLabel,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: List.generate(7, (i) {
                // Encoding: 0=Monday..6=Sunday, i.e. `DateTime.weekday - 1` —
                // must match `PromotionService`'s schedule check exactly.
                // Deriving this week's actual Monday (rather than a
                // hardcoded date whose weekday would have to be memorized
                // correctly) keeps this self-consistent by construction;
                // `intl` (already a dependency) then gives locale-correct
                // short names without hand-translating 7 more strings.
                final thisMonday = DateTime.now().subtract(
                  Duration(days: DateTime.now().weekday - 1),
                );
                final label = DateFormat.E().format(
                  thisMonday.add(Duration(days: i)),
                );
                final selected = _daysOfWeek?.contains(i) ?? false;
                return FilterChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    final next = {...?_daysOfWeek};
                    if (v) {
                      next.add(i);
                    } else {
                      next.remove(i);
                    }
                    _daysOfWeek = next.isEmpty ? null : next;
                  }),
                );
              }),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(isStart: true),
                    child: Text(
                      _timeStart == null
                          ? l10n.promotionTimeStartLabel
                          : _timeStart!,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(isStart: false),
                    child: Text(
                      _timeEnd == null ? l10n.promotionTimeEndLabel : _timeEnd!,
                    ),
                  ),
                ),
                if (_timeStart != null || _timeEnd != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _timeStart = null;
                      _timeEnd = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _requiresApproval,
              onChanged: (v) => setState(() => _requiresApproval = v),
              title: Text(l10n.promotionApprovalLabel),
            ),
            if (_requiresApproval) ...[
              const SizedBox(height: 8),
              AppTextField(
                label: l10n.promotionApprovalThresholdLabel,
                controller: _approvalThresholdController,
                keyboardType: TextInputType.number,
              ),
            ],
            if (_type == 'code' && _saved != null) ...[
              const SizedBox(height: 20),
              Text(
                l10n.promotionCodesLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              for (final code in _saved!.codes)
                Card(
                  child: ListTile(
                    title: Text(code.code),
                    subtitle: Text(
                      l10n.promotionCodeUsageLabel(
                        code.usedCount,
                        code.maxUses?.toString() ?? '∞',
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.terracottaDark,
                      ),
                      onPressed: () => _deleteCode(code),
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AppTextField(
                      label: l10n.promotionNewCodeLabel,
                      controller: _newCodeController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppTextField(
                      label: l10n.promotionMaxUsesLabel,
                      controller: _newCodeMaxUsesController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _addCode,
                  child: Text(l10n.promotionAddCodeButton),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.terracottaDark,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.promotionSaveButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _typeSpecificFields(AppLocalizations l10n, MenuService menu) {
    switch (_type) {
      case 'percent':
        return [
          AppTextField(
            label: l10n.promotionPercentLabel,
            controller: _percentController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: l10n.promotionMaxCapLabel,
            controller: _maxCapController,
            keyboardType: TextInputType.number,
          ),
        ];
      case 'flat':
        return [
          AppTextField(
            label: l10n.promotionFlatAmountLabel,
            controller: _flatController,
            keyboardType: TextInputType.number,
          ),
        ];
      case 'bogo':
        return [
          AppTextField(
            label: l10n.promotionBogoBuyQtyLabel,
            controller: _bogoBuyController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: l10n.promotionBogoGetQtyLabel,
            controller: _bogoGetController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: l10n.promotionBogoDiscountLabel,
            controller: _bogoDiscountController,
            keyboardType: TextInputType.number,
          ),
        ];
      case 'code':
      case 'min_spend':
        return [
          if (_type == 'min_spend') ...[
            AppTextField(
              label: l10n.promotionMinSpendLabel,
              controller: _minSpendController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
          ],
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.promotionRewardPercent),
                selected: _rewardKind == 'percent',
                onSelected: (_) => setState(() => _rewardKind = 'percent'),
              ),
              ChoiceChip(
                label: Text(l10n.promotionRewardFlat),
                selected: _rewardKind == 'flat',
                onSelected: (_) => setState(() => _rewardKind = 'flat'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_rewardKind == 'percent')
            AppTextField(
              label: l10n.promotionPercentLabel,
              controller: _percentController,
              keyboardType: TextInputType.number,
            )
          else
            AppTextField(
              label: l10n.promotionFlatAmountLabel,
              controller: _flatController,
              keyboardType: TextInputType.number,
            ),
        ];
      case 'combo':
        return [
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
          const SizedBox(height: 4),
          Center(
            child: Text(
              l10n.promotionComboImageLabel,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: l10n.promotionComboPriceLabel,
            controller: _comboPriceController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.promotionComboItemsLabel,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          _ItemPicker(
            selected: _scopeItemIds,
            onChanged: (s) => setState(() => _scopeItemIds = s),
          ),
        ];
      case 'tiered':
        return [
          Text(
            l10n.promotionTieredLabel,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _tiered.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: l10n.promotionTieredQtyLabel,
                      controller: _tiered[i].qty,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppTextField(
                      label: l10n.promotionTieredPriceLabel,
                      controller: _tiered[i].price,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _tiered[i].qty.dispose();
                      _tiered[i].price.dispose();
                      _tiered.removeAt(i);
                    }),
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => setState(
              () => _tiered.add(
                _TieredRow(
                  qty: TextEditingController(),
                  price: TextEditingController(),
                ),
              ),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: Text(l10n.promotionTieredAddRow),
          ),
        ];
      default:
        return const [];
    }
  }

  String _typeLabel(AppLocalizations l10n, String type) => switch (type) {
    'percent' => l10n.promotionTypePercent,
    'flat' => l10n.promotionTypeFlat,
    'bogo' => l10n.promotionTypeBogo,
    'code' => l10n.promotionTypeCode,
    'combo' => l10n.promotionTypeCombo,
    'min_spend' => l10n.promotionTypeMinSpend,
    'tiered' => l10n.promotionTypeTiered,
    _ => type,
  };
}

class _TieredRow {
  _TieredRow({required this.qty, required this.price});
  final TextEditingController qty;
  final TextEditingController price;
}

/// Checkbox list of every menu item, grouped loosely by category order —
/// reused for "item" scope, combo contents, and shop-scope exclusions.
class _ItemPicker extends StatelessWidget {
  const _ItemPicker({required this.selected, required this.onChanged});
  final Set<String> selected;
  final void Function(Set<String>) onChanged;

  @override
  Widget build(BuildContext context) {
    final items = MenuService.instance.allItems;
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.terracottaLight),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return CheckboxListTile(
            dense: true,
            title: Text(item.name),
            subtitle: Text(item.category, style: const TextStyle(fontSize: 11)),
            value: selected.contains(item.id),
            onChanged: (v) {
              final next = {...selected};
              if (v ?? false) {
                next.add(item.id);
              } else {
                next.remove(item.id);
              }
              onChanged(next);
            },
          );
        },
      ),
    );
  }
}
