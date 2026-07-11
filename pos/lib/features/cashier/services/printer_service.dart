import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';

import '../../../core/services/app_settings_service.dart';
import '../models/order.dart';

enum PrintOutcome { skipped, success, noPrinterFound, failed }

class PrintResult {
  const PrintResult(this.outcome, {this.errorDetail});
  final PrintOutcome outcome;
  final String? errorDetail;
}

/// Stable identifier for a discovered device, built from its transport +
/// address — used to remember "this exact printer" across scans, since scans
/// don't return the same Dart object twice.
String printerDeviceKey(PrinterDevice d) => switch (d) {
      BluetoothPrinterDevice() => 'bluetooth:${d.address}',
      BlePrinterDevice() => 'ble:${d.deviceId}',
      UsbPrinterDevice() => 'usb:${d.identifier}',
      NetworkPrinterDevice() => 'network:${d.host}:${d.port}',
      _ => 'unknown:${d.name}',
    };

Set<PrinterConnectionType> _typesFor(PrinterChoice choice) =>
    choice == PrinterChoice.bluetooth
        ? const {PrinterConnectionType.bluetooth, PrinterConnectionType.ble}
        : const {PrinterConnectionType.usb};

PaperSize _paperSizeFor(ReceiptPaperSize size) =>
    size == ReceiptPaperSize.mm58 ? PaperSize.mm58 : PaperSize.mm80;

/// Prints a receipt to whatever printer is set in Settings (Bluetooth/USB),
/// via the real ESC/POS transport in `package:unified_esc_pos_printer`.
///
/// If the user has picked a specific device in Settings, every print scans
/// then connects to that remembered device by key; otherwise (or if that
/// device isn't found this time) it falls back to the first match, same as
/// before a device was ever picked.
class PrinterService {
  /// Scans for devices matching [choice]'s transport — used by the Settings
  /// screen's "select printer" picker.
  Future<List<PrinterDevice>> scanAvailable(PrinterChoice choice) async {
    final manager = PrinterManager();
    try {
      return await manager.scanPrinters(
        timeout: const Duration(seconds: 5),
        types: _typesFor(choice),
      );
    } finally {
      await manager.dispose();
    }
  }

  Future<PrintResult> printReceipt(Order order) async {
    final settings = AppSettingsService.instance;
    final choice = await settings.getPrinterChoice();
    if (choice == PrinterChoice.skip) {
      return const PrintResult(PrintOutcome.skipped);
    }

    final manager = PrinterManager();
    try {
      final devices = await manager.scanPrinters(
        timeout: const Duration(seconds: 5),
        types: _typesFor(choice),
      );
      if (devices.isEmpty) {
        return const PrintResult(PrintOutcome.noPrinterFound);
      }

      final selectedId = await settings.getSelectedPrinterId();
      PrinterDevice? matched;
      if (selectedId != null) {
        for (final d in devices) {
          if (printerDeviceKey(d) == selectedId) {
            matched = d;
            break;
          }
        }
      }
      final target = matched ?? devices.first;

      final paperSize = _paperSizeFor(await settings.getPaperSize());
      await manager.connect(target);
      final ticket = await Ticket.create(paperSize);
      await _buildReceipt(ticket, order);
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

  // Fixed labels (headers, "Order"/"Date"/"Total"/etc.) are plain English —
  // pulled straight from here rather than AppLocalizations, since this runs
  // with no BuildContext — and printed via the cheap Latin-1 text()/row()
  // path, which is fine since they're always ASCII. Item names are
  // user-entered and may be Thai, so those go through rowRaster() instead:
  // it renders the text as a bitmap via Flutter's text engine, so it prints
  // correctly regardless of the printer's active codepage.
  Future<void> _buildReceipt(Ticket ticket, Order order) async {
    // "THB" not "฿": the ticket's default codec is Latin-1, which can't
    // represent the Baht sign — encoding falls back to UTF-8 for the whole
    // string, and a single-byte-codepage printer prints those raw UTF-8
    // bytes as garbage instead of the symbol.
    String baht(double v) => 'THB ${v.toStringAsFixed(0)}';

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
      await ticket.rowRaster([
        PrintRasterColumn(text: '${item.quantity}x ${item.menuItem.name}', flex: 3),
        PrintRasterColumn(text: baht(item.subtotal), flex: 1, align: PrintAlign.right),
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
