import 'dart:typed_data';

enum ConnectionMode { local, cloud }

enum PrinterChoice { bluetooth, usb, skip }

/// Collects every field gathered across the Create Shop onboarding wizard.
/// Held in memory only for now — nothing is sent to a server yet.
class ShopSetupData {
  String shopName = '';
  Uint8List? logoBytes;
  String address = '';
  String taxId = '';
  String email = '';
  String receiptFooter = '';

  String adminUsername = '';
  String adminPassword = '';

  ConnectionMode connectionMode = ConnectionMode.cloud;
  String cloudServerAddress = '';

  PrinterChoice printerChoice = PrinterChoice.skip;
}
