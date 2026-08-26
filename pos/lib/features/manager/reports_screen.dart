import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/access_restricted.dart';
import '../../core/widgets/app_message.dart';
import '../../l10n/app_localizations.dart';
import '../cashier/models/order.dart';
import 'services/csv_export.dart';
import 'services/reports_service.dart';

enum _QuickRange { today, yesterday, last7, last30, all, month, custom }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<List<Order>> _future;
  _QuickRange _range = _QuickRange.today;
  DateTimeRange? _customRange;
  DateTime? _selectedMonth;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _future = _fetchForCurrentRange();
  }

  Future<List<Order>> _fetchForCurrentRange() {
    final range = _resolveRange();
    return ReportsService.instance.fetchOrders(
      from: range.start,
      to: range.end,
    );
  }

  void _reload() => setState(() {
    _future = _fetchForCurrentRange();
  });

  DateTimeRange _resolveRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_range) {
      case _QuickRange.today:
        return DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 1)),
        );
      case _QuickRange.yesterday:
        final y = today.subtract(const Duration(days: 1));
        return DateTimeRange(start: y, end: today);
      case _QuickRange.last7:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today.add(const Duration(days: 1)),
        );
      case _QuickRange.last30:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: today.add(const Duration(days: 1)),
        );
      case _QuickRange.all:
        return DateTimeRange(
          start: DateTime(2000),
          end: today.add(const Duration(days: 1)),
        );
      case _QuickRange.month:
        final m = _selectedMonth ?? DateTime(now.year, now.month);
        return DateTimeRange(
          start: DateTime(m.year, m.month, 1),
          end: DateTime(m.year, m.month + 1, 1),
        );
      case _QuickRange.custom:
        return _customRange ??
            DateTimeRange(
              start: today,
              end: today.add(const Duration(days: 1)),
            );
    }
  }

  List<Order> _filter(List<Order> all) {
    final range = _resolveRange();
    return all
        .where(
          (o) =>
              o.kitchenStatus != 'cancelled' &&
              !o.createdAt.isBefore(range.start) &&
              o.createdAt.isBefore(range.end),
        )
        .toList();
  }

  Future<void> _pickCustomRange() async {
    final result = await showDialog<DateTimeRange>(
      context: context,
      builder: (_) => _CustomRangeDialog(existing: _customRange),
    );
    if (result == null) return;
    setState(() {
      _range = _QuickRange.custom;
      _customRange = result;
      _future = _fetchForCurrentRange();
    });
  }

  // Flutter's built-in date picker has no dedicated "month only" mode, so
  // this reuses it as-is and just ignores whatever day the user lands
  // on — the year+month is all `_resolveRange`'s `month` case reads.
  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) return;
    setState(() {
      _range = _QuickRange.month;
      _selectedMonth = DateTime(picked.year, picked.month);
      _future = _fetchForCurrentRange();
    });
  }

  String _formatMonth(DateTime m) => DateFormat.yMMMM().format(m);

  String _formatCustomRange(DateTimeRange r) {
    String fmt(DateTime d) =>
        '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final end = r.end.subtract(const Duration(minutes: 1));
    return '${fmt(r.start)}–${fmt(end)}';
  }

  Future<void> _export(List<Order> orders) async {
    setState(() => _exporting = true);
    try {
      final buffer = StringBuffer()
        ..writeln(
          'Order,Date,Time,Item,Quantity,Unit Price,Subtotal,Payment Method,Discount,Order Total',
        );
      for (final o in orders) {
        final method = o.paymentMethod == PaymentMethod.cash
            ? 'Cash'
            : 'PromptPay';
        for (final item in o.items) {
          buffer.writeln(
            [
              o.formattedNumber,
              o.formattedDate.split(' ').first,
              o.formattedDate.split(' ').last,
              '"${item.menuItem.name.replaceAll('"', '""')}"',
              item.quantity,
              item.menuItem.price.toStringAsFixed(2),
              item.subtotal.toStringAsFixed(2),
              method,
              o.discountTotal.toStringAsFixed(2),
              o.total.toStringAsFixed(2),
            ].join(','),
          );
        }
      }
      final range = _resolveRange();
      final fileName =
          'minepos-report-${_isoDate(range.start)}_to_${_isoDate(range.end.subtract(const Duration(days: 1)))}.csv';
      final path = await saveCsv(fileName, buffer.toString());
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      showAppMessage(
        context,
        path == null
            ? l10n.exportCancelledSnackbar
            : l10n.exportSuccessSnackbar(path),
      );
    } catch (e) {
      if (mounted) {
        showAppMessage(
          context,
          AppLocalizations.of(context)!.exportFailedSnackbar('$e'),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _isoDate(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!ServerClient.instance.canManageShop) {
      return AccessRestrictedScreen(feature: l10n.reportsLabel);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportsLabel),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<Order>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 32,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _reload, child: Text(l10n.retry)),
                  ],
                ),
              ),
            );
          }
          final orders = _filter(snapshot.data!);
          final revenue = orders.fold(0.0, (s, o) => s + o.total);
          final avg = orders.isNotEmpty ? revenue / orders.length : 0.0;
          final cashCount = orders
              .where((o) => o.paymentMethod == PaymentMethod.cash)
              .length;
          final totalDiscounted = orders.fold(
            0.0,
            (s, o) => s + o.discountTotal,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RangeChips(
                selected: _range,
                customLabel: _customRange == null
                    ? null
                    : _formatCustomRange(_customRange!),
                monthLabel: _selectedMonth == null
                    ? null
                    : _formatMonth(_selectedMonth!),
                onSelect: (r) {
                  if (r == _QuickRange.custom) {
                    _pickCustomRange();
                  } else if (r == _QuickRange.month) {
                    _pickMonth();
                  } else {
                    setState(() {
                      _range = r;
                      _future = _fetchForCurrentRange();
                    });
                  }
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatCard(
                            label: l10n.reportsOrdersLabel,
                            value: '${orders.length}',
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: l10n.revenueLabel,
                            value: baht(revenue),
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: l10n.avgOrderLabel,
                            value: orders.isEmpty ? l10n.emDash : baht(avg),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _StatCard(label: l10n.cash, value: '$cashCount'),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: l10n.promptpay,
                            value: '${orders.length - cashCount}',
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: l10n.totalDiscountedLabel,
                            value: baht(totalDiscounted),
                          ),
                        ],
                      ),
                      if (orders.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _SalesTrendChart(
                          orders: orders,
                          range: _resolveRange(),
                          l10n: l10n,
                          baht: baht,
                        ),
                        const SizedBox(height: 16),
                        _TopItemsCard(orders: orders, l10n: l10n, baht: baht),
                        const SizedBox(height: 16),
                        _StaffSalesCard(orders: orders, l10n: l10n, baht: baht),
                        if (totalDiscounted > 0) ...[
                          const SizedBox(height: 16),
                          _PromotionBreakdownCard(
                            orders: orders,
                            l10n: l10n,
                            baht: baht,
                          ),
                        ],
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.ordersColumnHeader,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: AppColors.muted,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: (orders.isEmpty || _exporting)
                                ? null
                                : () => _export(orders),
                            icon: _exporting
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.file_download_outlined,
                                    size: 15,
                                  ),
                            label: Text(
                              l10n.exportCSVButton,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (orders.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              l10n.reportsNoOrdersEmpty,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.terracottaLight,
                            ),
                          ),
                          child: Column(
                            children: orders.asMap().entries.map((e) {
                              final isLast = e.key == orders.length - 1;
                              final o = e.value;
                              final method =
                                  o.paymentMethod == PaymentMethod.cash
                                  ? l10n.cash
                                  : l10n.promptpay;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: isLast
                                      ? null
                                      : const Border(
                                          bottom: BorderSide(
                                            color: AppColors.terracottaLight,
                                            width: 0.5,
                                          ),
                                        ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      o.formattedNumber,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        o.formattedDate,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        method,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: AppColors.muted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      baht(o.total),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RangeChips extends StatelessWidget {
  const _RangeChips({
    required this.selected,
    required this.onSelect,
    this.customLabel,
    this.monthLabel,
  });
  final _QuickRange selected;
  final ValueChanged<_QuickRange> onSelect;
  final String? customLabel;
  final String? monthLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      _QuickRange.today: l10n.todayRange,
      _QuickRange.yesterday: l10n.yesterdayRange,
      _QuickRange.last7: l10n.last7Range,
      _QuickRange.last30: l10n.last30Range,
      _QuickRange.all: l10n.allTimeRange,
      _QuickRange.month: l10n.monthRange,
      _QuickRange.custom: l10n.customRange,
    };
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final range = labels.keys.elementAt(i);
          final sel = range == selected;
          final label =
              (range == _QuickRange.custom && sel && customLabel != null)
              ? customLabel!
              : (range == _QuickRange.month && sel && monthLabel != null)
              ? monthLabel!
              : labels[range]!;
          return GestureDetector(
            onTap: () => onSelect(range),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? AppColors.primary : AppColors.terracottaLight,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: sel ? AppColors.accent : AppColors.ink,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _Editing { start, end }

/// One dialog: a calendar to pick the date and a digital HH:MM field for the
/// time, both visible together — a [_Editing] toggle switches which end of
/// the range (start/end) they're currently editing.
class _CustomRangeDialog extends StatefulWidget {
  const _CustomRangeDialog({this.existing});
  final DateTimeRange? existing;

  @override
  State<_CustomRangeDialog> createState() => _CustomRangeDialogState();
}

class _CustomRangeDialogState extends State<_CustomRangeDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  _Editing _editing = _Editing.start;
  late final TextEditingController _hourCtrl;
  late final TextEditingController _minuteCtrl;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final existing = widget.existing;
    _startDate = existing == null
        ? DateTime(now.year, now.month, now.day)
        : DateTime(
            existing.start.year,
            existing.start.month,
            existing.start.day,
          );
    _startTime = existing == null
        ? const TimeOfDay(hour: 0, minute: 0)
        : TimeOfDay.fromDateTime(existing.start);
    final endInclusive =
        existing?.end.subtract(const Duration(minutes: 1)) ?? now;
    _endDate = DateTime(
      endInclusive.year,
      endInclusive.month,
      endInclusive.day,
    );
    _endTime = existing == null
        ? const TimeOfDay(hour: 23, minute: 59)
        : TimeOfDay.fromDateTime(endInclusive);
    _hourCtrl = TextEditingController(
      text: _startTime.hour.toString().padLeft(2, '0'),
    );
    _minuteCtrl = TextEditingController(
      text: _startTime.minute.toString().padLeft(2, '0'),
    );
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  DateTime get _selectedDate =>
      _editing == _Editing.start ? _startDate : _endDate;
  TimeOfDay get _selectedTime =>
      _editing == _Editing.start ? _startTime : _endTime;

  void _switchTo(_Editing editing) {
    setState(() {
      _editing = editing;
      final t = editing == _Editing.start ? _startTime : _endTime;
      _hourCtrl.text = t.hour.toString().padLeft(2, '0');
      _minuteCtrl.text = t.minute.toString().padLeft(2, '0');
    });
  }

  void _onDateChanged(DateTime d) {
    setState(() {
      if (_editing == _Editing.start) {
        _startDate = d;
      } else {
        _endDate = d;
      }
    });
  }

  void _onTimeFieldChanged() {
    final hour =
        int.tryParse(_hourCtrl.text)?.clamp(0, 23) ?? _selectedTime.hour;
    final minute =
        int.tryParse(_minuteCtrl.text)?.clamp(0, 59) ?? _selectedTime.minute;
    setState(() {
      if (_editing == _Editing.start) {
        _startTime = TimeOfDay(hour: hour, minute: minute);
      } else {
        _endTime = TimeOfDay(hour: hour, minute: minute);
      }
    });
  }

  String _fmt(DateTime date, TimeOfDay time) =>
      '${date.month}/${date.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final start = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );
    final valid = !end.isBefore(start);

    return AlertDialog(
      title: Text(l10n.customRangeDialogTitle),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _EndpointChip(
                        label: l10n.startTimeLabel,
                        value: _fmt(_startDate, _startTime),
                        selected: _editing == _Editing.start,
                        onTap: () => _switchTo(_Editing.start),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _EndpointChip(
                        label: l10n.endTimeLabel,
                        value: _fmt(_endDate, _endTime),
                        selected: _editing == _Editing.end,
                        onTap: () => _switchTo(_Editing.end),
                      ),
                    ),
                  ],
                ),
              ),
              CalendarDatePicker(
                key: ValueKey(_editing),
                initialDate: _selectedDate,
                firstDate: DateTime(now.year - 2),
                lastDate: now,
                onDateChanged: _onDateChanged,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DigitField(
                      controller: _hourCtrl,
                      onChanged: _onTimeFieldChanged,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        ':',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _DigitField(
                      controller: _minuteCtrl,
                      onChanged: _onTimeFieldChanged,
                    ),
                    if (!valid) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.endBeforeStartError,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.terracottaDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: !valid
              ? null
              : () => Navigator.pop(
                  context,
                  DateTimeRange(
                    start: start,
                    end: end.add(const Duration(minutes: 1)),
                  ),
                ),
          child: Text(l10n.applyButton),
        ),
      ],
    );
  }
}

class _EndpointChip extends StatelessWidget {
  const _EndpointChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.terracottaLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.accent : AppColors.muted,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.accent : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DigitField extends StatelessWidget {
  const _DigitField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 64,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 2,
        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
        decoration: const InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => onChanged(),
      ),
    );
  }
}

class _TopItemsCard extends StatelessWidget {
  const _TopItemsCard({
    required this.orders,
    required this.l10n,
    required this.baht,
  });
  final List<Order> orders;
  final AppLocalizations l10n;
  final String Function(double) baht;

  @override
  Widget build(BuildContext context) {
    final totals = <String, (int qty, double revenue)>{};
    for (final o in orders) {
      for (final item in o.items) {
        final prev = totals[item.menuItem.name] ?? (0, 0.0);
        totals[item.menuItem.name] = (
          prev.$1 + item.quantity,
          prev.$2 + item.subtotal,
        );
      }
    }
    final top = totals.entries.toList()
      ..sort((a, b) => b.value.$2.compareTo(a.value.$2));
    final top5 = top.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.topSellingItemsHeader,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.terracottaLight),
          ),
          child: Column(
            children: top5.asMap().entries.map((e) {
              final isLast = e.key == top5.length - 1;
              final name = e.value.key;
              final (qty, revenue) = e.value.value;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(
                            color: AppColors.terracottaLight,
                            width: 0.5,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$qty ${l10n.soldSuffix}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      baht(revenue),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _StaffSalesCard extends StatelessWidget {
  const _StaffSalesCard({
    required this.orders,
    required this.l10n,
    required this.baht,
  });
  final List<Order> orders;
  final AppLocalizations l10n;
  final String Function(double) baht;

  @override
  Widget build(BuildContext context) {
    final totals = <String, (int count, double revenue)>{};
    for (final o in orders) {
      final name = o.createdByName ?? l10n.staffSalesUnknownLabel;
      final prev = totals[name] ?? (0, 0.0);
      totals[name] = (prev.$1 + 1, prev.$2 + o.total);
    }
    final ranked = totals.entries.toList()
      ..sort((a, b) => b.value.$2.compareTo(a.value.$2));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.staffSalesHeader,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.terracottaLight),
          ),
          child: Column(
            children: ranked.asMap().entries.map((e) {
              final isLast = e.key == ranked.length - 1;
              final name = e.value.key;
              final (count, revenue) = e.value.value;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(
                            color: AppColors.terracottaLight,
                            width: 0.5,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$count ${l10n.ordersSuffix}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      baht(revenue),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PromotionBreakdownCard extends StatelessWidget {
  const _PromotionBreakdownCard({
    required this.orders,
    required this.l10n,
    required this.baht,
  });
  final List<Order> orders;
  final AppLocalizations l10n;
  final String Function(double) baht;

  @override
  Widget build(BuildContext context) {
    final totals = <String, (int uses, double discounted)>{};
    for (final o in orders) {
      for (final promo in o.appliedPromotions) {
        final prev = totals[promo.name] ?? (0, 0.0);
        totals[promo.name] = (prev.$1 + 1, prev.$2 + promo.discountAmount);
      }
    }
    final ranked = totals.entries.toList()
      ..sort((a, b) => b.value.$2.compareTo(a.value.$2));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.promotionBreakdownHeader,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.terracottaLight),
          ),
          child: Column(
            children: ranked.asMap().entries.map((e) {
              final isLast = e.key == ranked.length - 1;
              final name = e.value.key;
              final (uses, discounted) = e.value.value;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(
                            color: AppColors.terracottaLight,
                            width: 0.5,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$uses ${l10n.usedSuffix}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '-${baht(discounted)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

enum _Granularity { minute, hour, day, month }

class _SalesTrendChart extends StatefulWidget {
  const _SalesTrendChart({
    required this.orders,
    required this.range,
    required this.l10n,
    required this.baht,
  });
  final List<Order> orders;
  final DateTimeRange range;
  final AppLocalizations l10n;
  final String Function(double) baht;

  @override
  State<_SalesTrendChart> createState() => _SalesTrendChartState();
}

class _SalesTrendChartState extends State<_SalesTrendChart> {
  int? _selectedIndex;
  double _zoom = 1.0;
  static const double _maxZoom = 8.0;
  final _hScrollController = ScrollController();

  @override
  void dispose() {
    _hScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = widget.orders;
    final range = widget.range;
    final l10n = widget.l10n;
    final baht = widget.baht;
    // The narrower the range, the finer the buckets: minutes for a short
    // custom window, then hour/day/month as the span widens.
    final spanMinutes = range.end.difference(range.start).inMinutes;
    final _Granularity granularity;
    final int minuteStep;
    if (spanMinutes <= 60) {
      granularity = _Granularity.minute;
      minuteStep = 5;
    } else if (spanMinutes <= 180) {
      granularity = _Granularity.minute;
      minuteStep = 15;
    } else if (spanMinutes <= 1440) {
      granularity = _Granularity.hour;
      minuteStep = 60;
    } else if (range.end.difference(range.start).inDays <= 31) {
      granularity = _Granularity.day;
      minuteStep = 0;
    } else {
      granularity = _Granularity.month;
      minuteStep = 0;
    }

    DateTime bucketOf(DateTime d) => switch (granularity) {
      _Granularity.minute => DateTime(
        d.year,
        d.month,
        d.day,
        d.hour,
        (d.minute ~/ minuteStep) * minuteStep,
      ),
      _Granularity.hour => DateTime(d.year, d.month, d.day, d.hour),
      _Granularity.day => DateTime(d.year, d.month, d.day),
      _Granularity.month => DateTime(d.year, d.month),
    };
    DateTime step(DateTime d) => switch (granularity) {
      _Granularity.minute => d.add(Duration(minutes: minuteStep)),
      _Granularity.hour => d.add(const Duration(hours: 1)),
      _Granularity.day => DateTime(d.year, d.month, d.day + 1),
      _Granularity.month => DateTime(d.year, d.month + 1),
    };

    final totals = <DateTime, double>{};
    for (final o in orders) {
      final key = bucketOf(o.createdAt);
      totals[key] = (totals[key] ?? 0) + o.total;
    }

    // ponytail: for month buckets, start the timeline at the earliest real
    // order instead of the filter's year-2000 floor, so "All Time" doesn't
    // plot a quarter-century of empty months.
    final startFrom = granularity == _Granularity.month && orders.isNotEmpty
        ? orders.map((o) => o.createdAt).reduce((a, b) => a.isBefore(b) ? a : b)
        : range.start;
    final buckets = <DateTime>[];
    for (
      var cursor = bucketOf(startFrom);
      cursor.isBefore(range.end);
      cursor = step(cursor)
    ) {
      buckets.add(cursor);
    }
    final values = buckets.map((d) => totals[d] ?? 0.0).toList();
    final maxValue = values.fold(0.0, (m, v) => v > m ? v : m);

    String label(DateTime d) => switch (granularity) {
      _Granularity.minute =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
      _Granularity.hour => '${d.hour.toString().padLeft(2, '0')}:00',
      _Granularity.day => '${d.day}',
      _Granularity.month => '${d.month}/${d.year % 100}',
    };
    // Show at most ~6 labels so they don't collide on narrow ranges.
    final labelEvery = (buckets.length / 6).ceil().clamp(
      1,
      buckets.isEmpty ? 1 : buckets.length,
    );
    // Guard against a selection left over from a range/filter change that shrank the bucket count.
    final selected = (_selectedIndex != null && _selectedIndex! < values.length)
        ? _selectedIndex
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.salesTrendHeader,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: AppColors.muted,
              ),
            ),
            Row(
              children: [
                _ZoomButton(
                  icon: Icons.remove,
                  onTap: _zoom <= 1.0
                      ? null
                      : () => setState(() {
                          _zoom = (_zoom / 2).clamp(1.0, _maxZoom);
                          _selectedIndex = null;
                        }),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${_zoom.round()}x',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                _ZoomButton(
                  icon: Icons.add,
                  onTap: _zoom >= _maxZoom
                      ? null
                      : () => setState(() {
                          _zoom = (_zoom * 2).clamp(1.0, _maxZoom);
                          _selectedIndex = null;
                        }),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.terracottaLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 14,
                child: selected == null
                    ? null
                    : Text(
                        '${label(buckets[selected])}  ·  ${baht(values[selected])}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 100,
                    width: 38,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          baht(maxValue),
                          style: const TextStyle(
                            fontSize: 8,
                            color: AppColors.muted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        const Text(
                          '฿0',
                          style: TextStyle(fontSize: 8, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, outerConstraints) {
                        // Zooming widens the plotted content rather than
                        // narrowing the time window shown — the Scrollbar
                        // below is how the now off-screen left/right side
                        // stays reachable instead of only ever seeing
                        // whatever's centered.
                        final contentWidth = outerConstraints.maxWidth * _zoom;
                        return Scrollbar(
                          controller: _hScrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _hScrollController,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: contentWidth,
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 100,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTapDown: (details) {
                                        if (values.isEmpty) return;
                                        final slot =
                                            contentWidth / values.length;
                                        final idx =
                                            (details.localPosition.dx / slot)
                                                .floor()
                                                .clamp(0, values.length - 1);
                                        setState(() => _selectedIndex = idx);
                                      },
                                      child: CustomPaint(
                                        size: Size.infinite,
                                        painter: _LineChartPainter(
                                          values: values,
                                          maxValue: maxValue,
                                          color: AppColors.primary,
                                          highlightIndex: selected,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: List.generate(buckets.length, (
                                      i,
                                    ) {
                                      return Expanded(
                                        child: Text(
                                          i % labelEvery == 0
                                              ? label(buckets[i])
                                              : '',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 8,
                                            color: AppColors.muted,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 14),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      color: AppColors.muted,
      disabledColor: AppColors.terracottaLight,
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.maxValue,
    required this.color,
    this.highlightIndex,
  });
  final List<double> values;
  final double maxValue;
  final Color color;
  final int? highlightIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const topInset = 6.0;
    const bottomInset = 4.0;
    final h = size.height - topInset - bottomInset;
    final slot = size.width / values.length;

    Offset pointAt(int i) {
      final ratio = maxValue == 0 ? 0.0 : values[i] / maxValue;
      return Offset(slot * (i + 0.5), topInset + h - ratio * h);
    }

    final points = List.generate(values.length, pointAt);
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(fillPath, Paint()..color = color.withValues(alpha: 0.12));

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dotPaint = Paint()..color = color;
    for (final p in points) {
      canvas.drawCircle(p, 2.5, dotPaint);
    }

    final hi = highlightIndex;
    if (hi != null && hi >= 0 && hi < points.length) {
      final p = points[hi];
      final guidePaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(p.dx, topInset),
        Offset(p.dx, size.height),
        guidePaint,
      );
      canvas.drawCircle(p, 5, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        5,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.maxValue != maxValue ||
      oldDelegate.color != color ||
      oldDelegate.highlightIndex != highlightIndex;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.terracottaLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.muted,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
