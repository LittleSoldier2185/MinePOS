import 'package:flutter/material.dart';

/// Placeholder for the password recovery flow (username entry, OTP
/// verification, reset — screens 8-10). Real implementation comes next.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
