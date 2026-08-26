import 'package:flutter/painting.dart' show FontWeight, TextStyle;
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';

import '../../../core/services/app_settings_service.dart';
import '../../../core/services/locale_controller.dart';
import '../../../core/utils/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../manager/services/shop_config_service.dart';
import '../models/order.dart';
import '../models/order_item.dart';

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

/// Finds the device matching a remembered [printerDeviceKey], or null if
/// [selectedId] is unset or not present in [devices].
PrinterDevice? _findMatch(List<PrinterDevice> devices, String? selectedId) {
  if (selectedId == null) return null;
  for (final d in devices) {
    if (printerDeviceKey(d) == selectedId) return d;
  }
  return null;
}

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
  /// Already-paired devices matching [choice]'s transport, no active scan —
  /// used by the Settings screen's "select printer" picker as its default,
  /// instant list (empty for [PrinterChoice.usb], which has no "paired"
  /// concept; the picker's explicit "Scan" action covers that case, and a
  /// printer that was never paired at the OS level either).
  Future<List<PrinterDevice>> pairedDevices(PrinterChoice choice) async {
    final manager = PrinterManager();
    try {
      return await manager.pairedPrinters(types: _typesFor(choice));
    } finally {
      await manager.dispose();
    }
  }

  /// Scans for devices matching [choice]'s transport — used by the Settings
  /// screen's "select printer" picker's explicit "Scan" action.
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
      final types = _typesFor(choice);
      final selectedId = await settings.getSelectedPrinterId();

      // Fast path: the phone's already-paired device list, no active scan —
      // this is what was actually flaky before (a live Bluetooth discovery
      // scan on every single print). Only Bluetooth/BLE have a "paired"
      // concept; USB always falls straight through to scanPrinters below.
      PrinterDevice? target;
      if (choice == PrinterChoice.bluetooth) {
        final paired = await manager.pairedPrinters(types: types);
        target = _findMatch(paired, selectedId) ?? paired.firstOrNull;
      }

      // Fall back to a live scan if the paired lookup found nothing usable —
      // covers USB, and a printer that's paired at the OS level but wasn't
      // returned by the bonded-device query, or one never paired at all.
      if (target == null) {
        final scanned = await manager.scanPrinters(
          timeout: const Duration(seconds: 5),
          types: types,
        );
        if (scanned.isEmpty) {
          return const PrintResult(PrintOutcome.noPrinterFound);
        }
        target = _findMatch(scanned, selectedId) ?? scanned.first;
      }

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

  // Labels follow the app's language setting (Settings > Language), not just
  // the printer's fixed English text as before. Since Thai labels aren't
  // Latin-1, every line — including "Order"/"Date"/"Total" — now goes
  // through rowRaster()/textRaster() (bitmap via Flutter's text engine)
  // rather than the cheap native-codec row()/text() path used previously;
  // that's the same path item names (which may always be Thai) already used.
  Future<void> _buildReceipt(Ticket ticket, Order order) async {
    // ฿ printed via raster rather than the native-codec path — that path
    // can't encode the Baht sign and printed it as garbage on real hardware.
    // Kept concatenated into one "฿65" string, not a separate column: a
    // separate column left a gap between the symbol and the amount since
    // flex-sized columns don't shrink to fit short content.
    final locale = LocaleController.instance.locale;
    final l10n = lookupAppLocalizations(locale);
    final shop = ShopConfigService.instance;

    await ticket.textRaster(
      shop.shopName,
      align: PrintAlign.center,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
    );
    if (shop.address != null && shop.address!.isNotEmpty) {
      await ticket.textRaster(shop.address!, align: PrintAlign.center);
    }
    if (shop.taxId != null && shop.taxId!.isNotEmpty) {
      await ticket.textRaster(
        '${l10n.taxIdFieldLabel}: ${shop.taxId}',
        align: PrintAlign.center,
      );
    }
    await ticket.textRaster(
      l10n.receiptThankYouMessage,
      align: PrintAlign.center,
      linesAfter: 1,
    );

    // Reprints of a voided bill (Order History) must be unmistakable as not a
    // valid sale — a fresh sale is never cancelled, so this only ever shows
    // on a reprint.
    if (order.kitchenStatus == 'cancelled') {
      ticket.separator();
      await ticket.textRaster(
        '*** ${l10n.cancelledOrderBadge.toUpperCase()} ***',
        align: PrintAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 36),
      );
      if (order.cancelReason != null && order.cancelReason!.isNotEmpty) {
        await ticket.textRaster(order.cancelReason!, align: PrintAlign.center);
      }
      ticket.separator();
    }

    await ticket.rowRaster([
      PrintRasterColumn(text: l10n.receiptOrderLabel, flex: 1),
      PrintRasterColumn(
        text: order.formattedNumber,
        flex: 1,
        align: PrintAlign.right,
        // A bit bigger than the rest of the header so the order number is
        // the one thing a customer can spot at a glance when comparing
        // their receipt to what's called out at pickup.
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      ),
    ]);
    await ticket.rowRaster([
      PrintRasterColumn(text: l10n.receiptDateLabel, flex: 1),
      PrintRasterColumn(text: order.formattedDate, flex: 1, align: PrintAlign.right),
    ]);
    await ticket.rowRaster([
      PrintRasterColumn(text: l10n.receiptPaymentLabel, flex: 1),
      PrintRasterColumn(
        text: order.paymentMethod == PaymentMethod.cash ? l10n.cash : l10n.promptpay,
        flex: 1,
        align: PrintAlign.right,
      ),
    ]);
    ticket.separator();

    for (final item in order.items) {
      final name = item.menuItem.displayName(locale);
      final sweetness =
          item.sweetness == null ? '' : ' (${item.sweetness!.label(l10n)})';
      await ticket.rowRaster([
        PrintRasterColumn(
          text: '${item.quantity}x $name$sweetness',
          flex: 3,
        ),
        PrintRasterColumn(
          text: baht(item.subtotal),
          flex: 1,
          align: PrintAlign.right,
        ),
      ]);
    }
    ticket.separator();

    if (order.appliedPromotions.isNotEmpty) {
      await ticket.rowRaster([
        PrintRasterColumn(text: l10n.subtotalLabel, flex: 1),
        PrintRasterColumn(text: baht(order.subtotal), flex: 1, align: PrintAlign.right),
      ]);
      for (final promo in order.appliedPromotions) {
        await ticket.rowRaster([
          PrintRasterColumn(text: promo.name, flex: 3),
          PrintRasterColumn(text: '-${baht(promo.discountAmount)}', flex: 1, align: PrintAlign.right),
        ]);
      }
    }

    await ticket.rowRaster([
      PrintRasterColumn(
        text: l10n.total,
        flex: 1,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      PrintRasterColumn(
        text: baht(order.total),
        flex: 1,
        align: PrintAlign.right,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ]);
    if (order.paymentMethod == PaymentMethod.cash) {
      await ticket.rowRaster([
        PrintRasterColumn(text: l10n.cash, flex: 1),
        PrintRasterColumn(
          text: baht(order.amountPaid ?? 0),
          flex: 1,
          align: PrintAlign.right,
        ),
      ]);
      await ticket.rowRaster([
        PrintRasterColumn(text: l10n.change, flex: 1),
        PrintRasterColumn(
          text: baht(order.change),
          flex: 1,
          align: PrintAlign.right,
        ),
      ]);
    }

    if (shop.receiptFooter != null && shop.receiptFooter!.isNotEmpty) {
      await ticket.textRaster(
        shop.receiptFooter!,
        align: PrintAlign.center,
        linesAfter: 1,
      );
    }
    await ticket.textRaster(
      l10n.receiptClosingMessage,
      align: PrintAlign.center,
      linesAfter: 1,
    );
    // Feed past the tear bar before cutting — the last printed lines sit under
    // the blade otherwise and get lost on the tear-off. Bump if a specific
    // printer's blade is further from the head.
    ticket.cut(linesBefore: 4);
  }
}
