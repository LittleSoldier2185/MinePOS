import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
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
    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shop details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'Tell us about your shop.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
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
            const Center(
              child: Text('Tap to add a logo', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Shop Name',
              controller: _shopNameController,
              hintText: 'Cozy Cafe',
              onChanged: (v) => widget.data.shopName = v,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Shop name is required' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Email',
              controller: _emailController,
              hintText: 'shop@example.com',
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) => widget.data.email = v,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Address',
              controller: _addressController,
              hintText: 'Optional',
              onChanged: (v) => widget.data.address = v,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Tax ID',
              controller: _taxIdController,
              hintText: 'Optional',
              onChanged: (v) => widget.data.taxId = v,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Receipt Footer',
              controller: _receiptFooterController,
              hintText: 'Optional, e.g. "Thank you!"',
              onChanged: (v) => widget.data.receiptFooter = v,
            ),
          ],
        ),
      ),
    );
  }
}
