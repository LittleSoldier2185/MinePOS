import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../cashier/models/order.dart';
import 'services/csv_export.dart';
import 'services/reports_service.dart';

enum _QuickRange { today, yesterday, last7, last30, all, custom }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<List<Order>> _future;
  _QuickRange _range = _QuickRange.today;
  DateTimeRange? _customRange;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _future = ReportsService.instance.fetchAllOrders();
  }

  void _reload() => setState(() => _future = ReportsService.instance.fetchAllOrders());

  DateTimeRange _resolveRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_range) {
      case _QuickRange.today:
        return DateTimeRange(start: today, end: today.add(const Duration(days: 1)));
      case _QuickRange.yesterday:
        final y = today.subtract(const Duration(days: 1));
        return DateTimeRange(start: y, end: today);
      case _QuickRange.last7:
        return DateTimeRange(
            start: today.subtract(const Duration(days: 6)),
            end: today.add(const Duration(days: 1)));
      case _QuickRange.last30:
        return DateTimeRange(
            start: today.subtract(const Duration(days: 29)),
            end: today.add(const Duration(days: 1)));
      case _QuickRange.all:
        return DateTimeRange(start: DateTime(2000), end: today.add(const Duration(days: 1)));
      case _QuickRange.custom:
        return _customRange ??
            DateTimeRange(start: today, end: today.add(const Duration(days: 1)));
    }
  }

  List<Order> _filter(List<Order> all) {
    final range = _resolveRange();
    return all
        .where((o) => !o.createdAt.isBefore(range.start) && o.createdAt.isBefore(range.end))
        .toList();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now),
    );
    if (picked == null) return;
    setState(() {
      _range = _QuickRange.custom;
      _customRange = DateTimeRange(
        start: DateTime(picked.start.year, picked.start.month, picked.start.day),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day)
            .add(const Duration(days: 1)),
      );
    });
  }

  String _baht(double v) => '฿${v.toStringAsFixed(0)}';

  Future<void> _export(List<Order> orders) async {
    setState(() => _exporting = true);
    try {
      final buffer = StringBuffer()
        ..writeln('Order,Date,Time,Item,Quantity,Unit Price,Subtotal,Payment Method,Order Total');
      for (final o in orders) {
        final method = o.paymentMethod == PaymentMethod.cash ? 'Cash' : 'PromptPay';
        for (final item in o.items) {
          buffer.writeln([
            o.formattedNumber,
            o.formattedDate.split(' ').first,
            o.formattedDate.split(' ').last,
            '"${item.menuItem.name.replaceAll('"', '""')}"',
            item.quantity,
            item.menuItem.price.toStringAsFixed(2),
            item.subtotal.toStringAsFixed(2),
            method,
            o.total.toStringAsFixed(2),
          ].join(','));
        }
      }
      final range = _resolveRange();
      final fileName =
          'minepos-report-${_isoDate(range.start)}_to_${_isoDate(range.end.subtract(const Duration(days: 1)))}.csv';
      final path = await saveCsv(fileName, buffer.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(path == null ? 'Export cancelled' : 'Saved to $path')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.terracottaDark),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
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
                    const Icon(Icons.error_outline, size: 32, color: AppColors.muted),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _reload, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }
          final orders = _filter(snapshot.data!);
          final revenue = orders.fold(0.0, (s, o) => s + o.total);
          final avg = orders.isNotEmpty ? revenue / orders.length : 0.0;
          final cashCount = orders.where((o) => o.paymentMethod == PaymentMethod.cash).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RangeChips(
                selected: _range,
                onSelect: (r) {
                  if (r == _QuickRange.custom) {
                    _pickCustomRange();
                  } else {
                    setState(() => _range = r);
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
                          _StatCard(label: 'Orders', value: '${orders.length}'),
                          const SizedBox(width: 10),
                          _StatCard(label: 'Revenue', value: _baht(revenue)),
                          const SizedBox(width: 10),
                          _StatCard(
                              label: 'Avg Order', value: orders.isEmpty ? '—' : _baht(avg)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _StatCard(label: 'Cash', value: '$cashCount'),
                          const SizedBox(width: 10),
                          _StatCard(label: 'PromptPay', value: '${orders.length - cashCount}'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ORDERS',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: AppColors.muted)),
                          TextButton.icon(
                            onPressed:
                                (orders.isEmpty || _exporting) ? null : () => _export(orders),
                            icon: _exporting
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.file_download_outlined, size: 15),
                            label: const Text('Export CSV', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (orders.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text('No orders in this range',
                                style: TextStyle(color: AppColors.muted)),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.terracottaLight),
                          ),
                          child: Column(
                            children: orders.asMap().entries.map((e) {
                              final isLast = e.key == orders.length - 1;
                              final o = e.value;
                              final method =
                                  o.paymentMethod == PaymentMethod.cash ? 'Cash' : 'PromptPay';
                              return Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  border: isLast
                                      ? null
                                      : const Border(
                                          bottom: BorderSide(
                                              color: AppColors.terracottaLight, width: 0.5)),
                                ),
                                child: Row(
                                  children: [
                                    Text(o.formattedNumber,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(o.formattedDate,
                                          style: const TextStyle(
                                              fontSize: 12, color: AppColors.muted)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(method,
                                          style: const TextStyle(
                                              fontSize: 9,
                                              color: AppColors.muted,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(_baht(o.total),
                                        style: const TextStyle(
                                            fontSize: 13, fontWeight: FontWeight.w700)),
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
  const _RangeChips({required this.selected, required this.onSelect});
  final _QuickRange selected;
  final ValueChanged<_QuickRange> onSelect;

  static const _labels = {
    _QuickRange.today: 'Today',
    _QuickRange.yesterday: 'Yesterday',
    _QuickRange.last7: 'Last 7 Days',
    _QuickRange.last30: 'Last 30 Days',
    _QuickRange.all: 'All Time',
    _QuickRange.custom: 'Custom…',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: _labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final range = _labels.keys.elementAt(i);
          final sel = range == selected;
          return GestureDetector(
            onTap: () => onSelect(range),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? AppColors.primary : AppColors.terracottaLight),
              ),
              child: Center(
                child: Text(
                  _labels[range]!,
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
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }
}
