import 'package:flutter/material.dart';

import '../barrel_export.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TxnType? _filter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: SegmentedButton<TxnType?>(
            segments: const [
              ButtonSegment(value: null, label: Text('All')),
              ButtonSegment(value: TxnType.stockIn, label: Text('Stock in')),
              ButtonSegment(value: TxnType.stockOut, label: Text('Stock out')),
            ],
            selected: {_filter},
            onSelectionChanged: (s) => setState(() => _filter = s.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primary,
              selectedForegroundColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<InventoryTransaction>>(
            stream: InventoryService.instance.watchTransactions(limit: 200),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snapshot.data!;
              final items = _filter == null
                  ? all
                  : all.where((t) => t.type == _filter).toList();

              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No movements recorded',
                  message: 'Stock-in and stock-out entries will appear here '
                      'as soon as staff record them.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final t = items[i];
                  final isIn = t.type == TxnType.stockIn;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (isIn
                                ? AppColors.accent
                                : AppColors.warning)
                            .withOpacity(0.15),
                        child: Icon(
                          isIn ? Icons.south_west : Icons.north_east,
                          color: isIn ? AppColors.accent : AppColors.warning,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        t.medicineName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${isIn ? 'Received' : 'Issued'} ${t.quantity} · '
                        '${dateTimeFormat.format(t.timestamp)}\n'
                        'By ${t.performedBy}'
                        '${t.party.isEmpty ? '' : ' · ${t.party}'}',
                        style: const TextStyle(fontSize: 12.5, height: 1.4),
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        currency.format(t.totalValue),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
