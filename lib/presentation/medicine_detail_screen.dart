import 'package:flutter/material.dart';

import '../barrel_export.dart';


class MedicineDetailScreen extends StatelessWidget {
  final String medicineId;
  const MedicineDetailScreen({super.key, required this.medicineId});

  @override
  Widget build(BuildContext context) {
    final service = InventoryService.instance;

    return StreamBuilder<Medicine>(
      stream: service.watchMedicine(medicineId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final m = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(m.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MedicineFormScreen(existing: m),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context, m),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.deepGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${m.quantity}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${m.unit}(s) in stock · minimum ${m.minStockLevel}',
                      style: const TextStyle(color: Color(0xFFBFD8CC)),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusPill.forMedicine(m),
                        if (m.isExpired)
                          const StatusPill('Expired', AppColors.danger)
                        else if (m.isExpiringSoon)
                          StatusPill(
                            'Expires in ${m.daysToExpiry} days',
                            AppColors.warning,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _detail('Generic name', m.genericName),
              _detail('Brand', m.brand),
              _detail('Category', m.categoryName),
              _detail('Supplier', m.supplierName),
              _detail('Batch number', m.batchNumber),
              _detail('Expiry date', dateFormat.format(m.expiryDate)),
              _detail('Cost price', currency.format(m.costPrice)),
              _detail('Selling price', currency.format(m.sellingPrice)),
              _detail('Value held', currency.format(m.stockValue)),
              if (m.notes.isNotEmpty) _detail('Notes', m.notes),
              const SizedBox(height: 22),
              const Text(
                'Movement history',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<InventoryTransaction>>(
                stream: service.watchTransactionsFor(m.id),
                builder: (context, txnSnap) {
                  final txns = txnSnap.data ?? const <InventoryTransaction>[];
                  if (txns.isEmpty) {
                    return const Text(
                      'No stock has moved for this medicine yet.',
                      style: TextStyle(color: AppColors.inkSoft),
                    );
                  }
                  return Column(
                    children: txns.map(_txnTile).toList(),
                  );
                },
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showStockMovementSheet(
                        context,
                        medicine: m,
                        type: TxnType.stockOut,
                      ),
                      icon: const Icon(Icons.remove_circle_outline),
                      label: const Text('Stock out'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => showStockMovementSheet(
                        context,
                        medicine: m,
                        type: TxnType.stockIn,
                      ),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Stock in'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detail(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _txnTile(InventoryTransaction t) {
    final isIn = t.type == TxnType.stockIn;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (isIn ? AppColors.accent : AppColors.warning).withOpacity(0.15),
          child: Icon(
            isIn ? Icons.south_west : Icons.north_east,
            color: isIn ? AppColors.accent : AppColors.warning,
            size: 20,
          ),
        ),
        title: Text(
          '${isIn ? '+' : '-'}${t.quantity} · ${currency.format(t.totalValue)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${dateTimeFormat.format(t.timestamp)}'
          '${t.party.isEmpty ? '' : ' · ${t.party}'}',
          style: const TextStyle(fontSize: 12.5),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Medicine m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this medicine?'),
        content: Text(
          '${m.name} and its current stock record will be removed from the '
          'inventory. Past transactions stay in the history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await InventoryService.instance.deleteMedicine(m.id);
      if (context.mounted) {
        Navigator.of(context).pop();
        showMessage(context, '${m.name} deleted.');
      }
    }
  }
}
