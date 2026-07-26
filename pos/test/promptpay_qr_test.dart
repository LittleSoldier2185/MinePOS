import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/cashier/services/promptpay_qr.dart';

void main() {
  test('CRC-16/CCITT-FALSE matches the standard check value', () {
    // Published check value for the "123456789" test string (CRC catalogue),
    // independent of this project — confirms the checksum routine itself
    // before trusting anything built on top of it.
    expect(PromptPayQr.crc16CcittFalse('123456789'), 0x29B1);
  });

  test('formatTarget: phone number gets 66-country-code substitution, padded to 13', () {
    expect(PromptPayQr.formatTarget('0812345678'), '0066812345678');
  });

  test('formatTarget: 13-digit citizen/tax ID passes through unchanged', () {
    expect(PromptPayQr.formatTarget('1234567890123'), '1234567890123');
  });

  test('generatePayload: static QR (no amount) has the right tags and ends in a valid CRC', () {
    final payload = PromptPayQr.generatePayload('0812345678');
    expect(payload, startsWith('000201010211'));
    expect(payload, contains('A000000677010111'));
    expect(payload, contains('011300668123456785802TH5303764'));
    expect(payload, endsWith('6304${payload.substring(payload.length - 4)}'));
    // Payload must self-validate: recomputing the CRC over everything before
    // the trailing 4 hex digits must reproduce them exactly.
    final crc = PromptPayQr.crc16CcittFalse(
      payload.substring(0, payload.length - 4),
    ).toRadixString(16).toUpperCase().padLeft(4, '0');
    expect(payload.substring(payload.length - 4), crc);
  });

  test('generatePayload: dynamic QR (with amount) uses POI method 12 and includes tag 54', () {
    final payload = PromptPayQr.generatePayload('0812345678', amount: 65.0);
    expect(payload, contains('010212')); // point of initiation: dynamic
    expect(payload, contains('540565.00')); // tag 54, length 05, "65.00"
  });
}
