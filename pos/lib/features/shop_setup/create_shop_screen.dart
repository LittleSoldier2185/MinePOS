import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../home/home_placeholder_screen.dart';
import 'models/shop_setup_data.dart';
import 'steps/admin_account_step.dart';
import 'steps/connection_mode_step.dart';
import 'steps/printer_setup_step.dart';
import 'steps/setup_summary_step.dart';
import 'steps/shop_details_step.dart';

const _stepCount = 5;

class CreateShopScreen extends StatefulWidget {
  const CreateShopScreen({super.key});

  @override
  State<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends State<CreateShopScreen> {
  final _data = ShopSetupData();
  final _pageController = PageController();
  final _detailsFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();

  int _currentStep = 0;

  GlobalKey<FormState>? get _currentFormKey {
    switch (_currentStep) {
      case 0:
        return _detailsFormKey;
      case 1:
        return _adminFormKey;
      default:
        return null;
    }
  }

  void _next() {
    final formKey = _currentFormKey;
    if (formKey != null && !(formKey.currentState?.validate() ?? true)) return;

    if (_currentStep == _stepCount - 1) {
      _finish();
      return;
    }

    setState(() => _currentStep++);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _back() {
    if (_currentStep == 0) return;
    setState(() => _currentStep--);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _finish() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomePlaceholderScreen(
          title: _data.shopName.isEmpty ? 'Shop created!' : '${_data.shopName} is ready!',
        ),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Shop')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Step ${_currentStep + 1} of $_stepCount',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / _stepCount,
                      backgroundColor: AppColors.terracottaLight,
                      color: AppColors.primary,
                      minHeight: 6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ShopDetailsStep(formKey: _detailsFormKey, data: _data),
                AdminAccountStep(formKey: _adminFormKey, data: _data),
                ConnectionModeStep(data: _data),
                PrinterSetupStep(data: _data),
                SetupSummaryStep(data: _data),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _back,
                        child: const Text('BACK'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(_currentStep == _stepCount - 1 ? 'FINISH SETUP' : 'NEXT'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
