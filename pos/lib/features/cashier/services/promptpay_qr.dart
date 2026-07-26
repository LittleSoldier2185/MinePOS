/// Builds an EMVCo-compatible PromptPay QR payload (the Thai national
/// interbank QR payment standard) — a direct port of the reference
/// implementation (`dtinth/promptpay-qr`, MIT), which every Thai banking
/// app's scanner is built against. Field order and target-ID formatting
/// mirror it exactly so the output is byte-for-byte what a real bank app
/// expects, not just "looks right."
class PromptPayQr {
  static const _guidPromptPay = 'A000000677010111';

  /// [target] is a Thai mobile number (e.g. "0812345678") or a 13-digit
  /// citizen/tax ID, digits only or with common separators — both get
  /// sanitized. [amount] makes the QR a fixed-amount ("dynamic") payment;
  /// omit it for a reusable ("static") QR the payer types the amount into.
  static String generatePayload(String target, {double? amount}) {
    final digits = sanitize(target);
    final targetTag = digits.length >= 15
        ? '03' // e-wallet ID
        : digits.length >= 13
            ? '02' // citizen/tax ID
            : '01'; // phone number

    final fields = [
      _tlv('00', '01'), // payload format indicator
      _tlv('01', amount != null ? '12' : '11'), // point of initiation method
      _tlv(
        '29',
        _tlv('00', _guidPromptPay) + _tlv(targetTag, formatTarget(digits)),
      ),
      _tlv('58', 'TH'), // country code
      _tlv('53', '764'), // currency: THB
      if (amount != null) _tlv('54', amount.toStringAsFixed(2)),
    ];

    final withCrcTag = '${fields.join()}6304';
    final crc = crc16CcittFalse(
      withCrcTag,
    ).toRadixString(16).toUpperCase().padLeft(4, '0');
    return '$withCrcTag$crc';
  }

  static String sanitize(String id) => id.replaceAll(RegExp(r'[^0-9]'), '');

  /// Phone numbers get the country-code substitution (leading 0 -> 66),
  /// zero-padded to 13 digits; citizen/tax IDs (13+ digits) pass through as-is.
  static String formatTarget(String digits) {
    if (digits.length >= 13) return digits;
    final withCountryCode = digits.startsWith('0')
        ? '66${digits.substring(1)}'
        : digits;
    return withCountryCode.padLeft(13, '0');
  }

  static String _tlv(String id, String value) =>
      '$id${value.length.toString().padLeft(2, '0')}$value';

  /// CRC-16/CCITT-FALSE (poly 0x1021, init 0xFFFF) — the checksum every
  /// EMVCo QR payload ends with.
  static int crc16CcittFalse(String data) {
    var crc = 0xFFFF;
    for (final byte in data.codeUnits) {
      crc = (crc ^ (byte << 8)) & 0xFFFF;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 0x8000) != 0
            ? ((crc << 1) ^ 0x1021) & 0xFFFF
            : (crc << 1) & 0xFFFF;
      }
    }
    return crc;
  }
}
