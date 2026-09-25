import 'package:flutter/material.dart';

import '../barrel_export.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = InventoryService.instance;

    return StreamBuilder<List<Medicine>>(
      stream: service.watchMedicines(),
      builder: (context, medSnap) {
        if (!medSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final medicines = medSnap.data!;
        if (medicines.isEmpty) {
          return const EmptyState(
            icon: Icons.insert_chart_outlined,
            title: 'Nothing to report yet',
            message: 'Reports build themselves once medicines and stock '
                'movements are in the system.',
          );
        }

        final summary = InventorySummary.from(medicines);
        final byCategory = <String, double>{};
        for (final m in medicines) {
          byCategory.update(
            m.categoryName,
            (v) => v + m.stockValue,
            ifAbsent: () => m.stockValue,
          );
        }
        final categoryRows = byCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return StreamBuilder<List<InventoryTransaction>>(
          stream: service.watchTransactions(limit: 500),
          builder: (context, txnSnap) {
            final txns = txnSnap.data ?? const <InventoryTransaction>[];
            final monthStart =
                DateTime(DateTime.now().year, DateTime.now().month, 1);
            final monthTxns =
                txns.where((t) => t.timestamp.isAfter(monthStart)).toList();
            final salesValue = monthTxns
                .where((t) => t.type == TxnType.stockOut)
                .fold<double>(0, (s, t) => s + t.totalValue);
            final purchaseValue = monthTxns
                .where((t) => t.type == TxnType.stockIn)
                .fold<double>(0, (s, t) => s + t.totalValue);

            final topMoving = <String, int>{};
            for (final t in monthTxns.where((t) => t.type == TxnType.stockOut)) {
              topMoving.update(t.medicineName, (v) => v + t.quantity,
                  ifAbsent: () => t.quantity);
            }
            final topRows = topMoving.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
              children: [
                _section('Inventory valuation'),
                _row('Medicines tracked', '${summary.totalMedicines}'),
                _row('Total stock value', currency.format(summary.stockValue)),
                _row('Low stock items', '${summary.lowStockCount}'),
                _row('Out of stock items', '${summary.outOfStockCount}'),
                _row('Expiring within 90 days',
                    '${summary.expiringSoonCount}'),
                _row('Expired items', '${summary.expiredCount}'),

                _section('This month'),
                _row('Sales value', currency.format(salesValue)),
                _row('Purchases value', currency.format(purchaseValue)),
                _row('Movements recorded', '${monthTxns.length}'),

                _section('Stock value by category'),
                ...categoryRows.take(8).map(
                      (e) => _bar(
                        e.key,
                        e.value,
                        categoryRows.first.value,
                      ),
                    ),

                _section('Fastest moving this month'),
                if (topRows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No sales recorded this month.',
                      style: TextStyle(color: AppColors.inkSoft),
                    ),
                  )
                else
                  ...topRows.take(8).map(
                        (e) => _row(e.key, '${e.value} issued'),
                      ),

                _section('Reorder list'),
                ...medicines
                    .where((m) => m.stockStatus != StockStatus.healthy)
                    .map((m) => _row(
                          '${m.name} (${m.supplierName})',
                          '${m.quantity}/${m.minStockLevel}',
                        )),
              ],
            );
          },
        );
      },
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: AppColors.inkSoft)),
            ),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _bar(String label, double value, double max) {
    final fraction = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                currency.format(value),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AppColors.mist,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
