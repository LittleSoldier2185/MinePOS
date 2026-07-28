/// Formats an amount as a whole-baht string (e.g. `฿65`, `฿500`) — the
/// shared display format for money everywhere in the app (cart, receipt,
/// reports, customer display, order history).
String baht(double v) => '฿${v.toStringAsFixed(0)}';
