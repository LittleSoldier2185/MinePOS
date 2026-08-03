import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import 'config.dart';

/// Sends the password-reset OTP by real email over SMTP — only usable when
/// [ServerConfig.smtpConfigured]; `auth_routes.dart` falls back to its
/// original console-print behavior otherwise (no SMTP configured, or the
/// send itself fails).
class EmailService {
  EmailService(this.config);
  final ServerConfig config;

  Future<bool> sendOtp({required String toEmail, required String otp}) async {
    if (!config.smtpConfigured) return false;
    final smtp = SmtpServer(
      config.smtpHost!,
      port: config.smtpPort ?? 587,
      username: config.smtpUsername,
      password: config.smtpPassword,
    );
    final message = Message()
      ..from = Address(config.smtpFromEmail!, config.shopName)
      ..recipients.add(toEmail)
      ..subject = '${config.shopName} password reset code'
      ..text =
          'Your password reset code is: $otp\n\nThis code expires in 10 minutes. '
          'If you didn\'t request this, you can ignore this email.';
    try {
      await send(message, smtp);
      return true;
    } on MailerException {
      return false;
    }
  }
}
