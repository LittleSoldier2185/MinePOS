import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';

import '../../../core/services/app_settings_service.dart';
import '../models/order.dart';

enum PrintOutcome { skipped, success, noPrinterFound, failed }

class PrintResult {
  const PrintResult(this.outcome, {this.errorDetail});
  final PrintOutcome outcome;
  final String? errorDetail;
}

/// Prints a receipt to whatever printer is set in Settings (Bluetooth/USB),
/// via the real ESC/POS transport in `package:unified_esc_pos_printer`.
///
/// This is best-effort: it scans for a matching printer, connects to the
/// first one found, prints, and disconnects — there's no "paired device"
/// picker/memory yet, so it re-scans on every print.
class PrinterService {
  Future<PrintResult> printReceipt(Order order) async {
    final choice = await AppSettingsService.instance.getPrinterChoice();
    if (choice == PrinterChoice.skip) {
      return const PrintResult(PrintOutcome.skipped);
    }

    final types = choice == PrinterChoice.bluetooth
        ? const {PrinterConnectionType.bluetooth, PrinterConnectionType.ble}
        : const {PrinterConnectionType.usb};

    final manager = PrinterManager();
    try {
      final devices = await manager.scanPrinters(
        timeout: const Duration(seconds: 5),
        types: types,
      );
      if (devices.isEmpty) {
        return const PrintResult(PrintOutcome.noPrinterFound);
      }

      await manager.connect(devices.first);
      final ticket = await Ticket.create(PaperSize.mm80);
      _buildReceipt(ticket, order);
      await manager.printTicket(ticket);
      return const PrintResult(PrintOutcome.success);
    } on PrinterException catch (e) {
      return PrintResult(PrintOutcome.failed, errorDetail: e.message);
    } catch (e) {
      return PrintResult(PrintOutcome.failed, errorDetail: e.toString());
    } finally {
      await manager.dispose();
    }
  }

  // The printed ticket's own copy is kept in plain English rather than
  // pulled from AppLocalizations: this runs with no BuildContext, and Thai
  // text needs the async textRaster() path (rendered via Flutter's text
  // engine) rather than the plain Latin-1 text() used here — not worth the
  // extra complexity for content that's currently unverifiable against real
  // hardware anyway.
  void _buildReceipt(Ticket ticket, Order order) {
    String baht(double v) => '฿${v.toStringAsFixed(0)}';

    ticket.text(
      'MinePOS Coffee',
      align: PrintAlign.center,
      style: const PrintTextStyle(bold: true, height: TextSize.size2, width: TextSize.size2),
    );
    ticket.text('Thank you for your order!', align: PrintAlign.center, linesAfter: 1);

    ticket.row([
      PrintColumn(text: 'Order', flex: 1),
      PrintColumn(text: order.formattedNumber, flex: 1, align: PrintAlign.right),
    ]);
    ticket.row([
      PrintColumn(text: 'Date', flex: 1),
      PrintColumn(text: order.formattedDate, flex: 1, align: PrintAlign.right),
    ]);
    ticket.row([
      PrintColumn(text: 'Payment', flex: 1),
      PrintColumn(
        text: order.paymentMethod == PaymentMethod.cash ? 'Cash' : 'PromptPay',
        flex: 1,
        align: PrintAlign.right,
      ),
    ]);
    ticket.separator();

    for (final item in order.items) {
      ticket.row([
        PrintColumn(text: '${item.quantity}x ${item.menuItem.name}', flex: 3),
        PrintColumn(text: baht(item.subtotal), flex: 1, align: PrintAlign.right),
      ]);
    }
    ticket.separator();

    ticket.row([
      PrintColumn(text: 'Total', flex: 1, style: const PrintTextStyle(bold: true)),
      PrintColumn(
        text: baht(order.total),
        flex: 1,
        align: PrintAlign.right,
        style: const PrintTextStyle(bold: true),
      ),
    ]);
    if (order.paymentMethod == PaymentMethod.cash) {
      ticket.row([
        PrintColumn(text: 'Cash', flex: 1),
        PrintColumn(text: baht(order.amountPaid ?? 0), flex: 1, align: PrintAlign.right),
      ]);
      ticket.row([
        PrintColumn(text: 'Change', flex: 1),
        PrintColumn(text: baht(order.change), flex: 1, align: PrintAlign.right),
      ]);
    }

    ticket.text('-- See you again! --', align: PrintAlign.center, linesAfter: 1);
    ticket.cut();
  }
}
