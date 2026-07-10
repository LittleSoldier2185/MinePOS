import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../models/shop_setup_data.dart';

class ShopDetailsStep extends StatefulWidget {
  const ShopDetailsStep({super.key, required this.formKey, required this.data});

  final GlobalKey<FormState> formKey;
  final ShopSetupData data;

  @override
  State<ShopDetailsStep> createState() => _ShopDetailsStepState();
}

class _ShopDetailsStepState extends State<ShopDetailsStep> {
  late final _shopNameController = TextEditingController(text: widget.data.shopName);
  late final _addressController = TextEditingController(text: widget.data.address);
  late final _taxIdController = TextEditingController(text: widget.data.taxId);
  late final _emailController = TextEditingController(text: widget.data.email);
  late final _receiptFooterController = TextEditingController(text: widget.data.receiptFooter);

  final _picker = ImagePicker();

  Future<void> _pickLogo() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => widget.data.logoBytes = bytes);
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _addressController.dispose();
    _taxIdController.dispose();
    _emailController.dispose();
    _receiptFooterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.shopDetailsStepTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              l10n.shopDetailsStepSubtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _pickLogo,
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.terracottaLight,
                  backgroundImage:
                      widget.data.logoBytes != null ? MemoryImage(widget.data.logoBytes!) : null,
                  child: widget.data.logoBytes == null
                      ? const Icon(Icons.add_a_photo, color: AppColors.terracotta)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(l10n.shopLogoTapInstruction, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: l10n.shopNameFieldLabel,
              controller: _shopNameController,
              hintText: l10n.shopNameFieldHint,
              onChanged: (v) => widget.data.shopName = v,
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.shopNameValidatorError : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: l10n.emailFieldLabel,
              controller: _emailController,
              hintText: l10n.emailFieldHint,
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) => widget.data.email = v,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.emailRequiredValidatorError;
                if (!v.contains('@') || !v.contains('.')) return l10n.emailInvalidValidatorError;
                return null;
              },
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: l10n.addressFieldLabel,
              controller: _addressController,
              hintText: l10n.optionalHint,
              onChanged: (v) => widget.data.address = v,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: l10n.taxIdFieldLabel,
              controller: _taxIdController,
              hintText: l10n.optionalHint,
              onChanged: (v) => widget.data.taxId = v,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: l10n.receiptFooterFieldLabel,
              controller: _receiptFooterController,
              hintText: l10n.receiptFooterFieldHint,
              onChanged: (v) => widget.data.receiptFooter = v,
            ),
          ],
        ),
      ),
    );
  }
}
