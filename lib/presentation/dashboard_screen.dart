import 'package:flutter/material.dart';

import '../barrel_export.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Medicine>>(
      stream: InventoryService.instance.watchMedicines(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const EmptyState(
            icon: Icons.cloud_off,
            title: 'Inventory unavailable',
            message: 'The inventory could not be loaded. Check your '
                'connection and pull down to retry.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final medicines = snapshot.data!;
        NotificationService.instance.evaluate(medicines);

        if (medicines.isEmpty) {
          return EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No medicines yet',
            message:
                'Add your first medicine to start tracking stock levels and '
                'expiry dates.',
            actionLabel: 'Add medicine',
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MedicineFormScreen()),
            ),
          );
        }

        final summary = InventorySummary.from(medicines);
        final attention = medicines
            .where((m) =>
                m.stockStatus != StockStatus.healthy ||
                m.isExpiringSoon ||
                m.isExpired)
            .toList()
          ..sort((a, b) => a.quantity.compareTo(b.quantity));

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                StatTile(
                  label: 'Medicines tracked',
                  value: '${summary.totalMedicines}',
                  icon: Icons.medication_outlined,
                ),
                StatTile(
                  label: 'Stock value',
                  value: currency.format(summary.stockValue),
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.primaryLight,
                ),
                StatTile(
                  label: 'Low on stock',
                  value: '${summary.lowStockCount}',
                  icon: Icons.trending_down,
                  color: AppColors.warning,
                ),
                StatTile(
                  label: 'Out of stock',
                  value: '${summary.outOfStockCount}',
                  icon: Icons.remove_shopping_cart_outlined,
                  color: AppColors.danger,
                ),
                StatTile(
                  label: 'Expiring in 90 days',
                  value: '${summary.expiringSoonCount}',
                  icon: Icons.event_outlined,
                  color: AppColors.warning,
                ),
                StatTile(
                  label: 'Already expired',
                  value: '${summary.expiredCount}',
                  icon: Icons.dangerous_outlined,
                  color: AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 26),
            const Text(
              'Needs attention',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              attention.isEmpty
                  ? 'Every medicine is above its minimum level and in date.'
                  : '${attention.length} item(s) are low, out of stock or '
                      'close to expiry.',
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13.5),
            ),
            const SizedBox(height: 10),
            ...attention.take(10).map(
                  (m) => MedicineTile(
                    medicine: m,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MedicineDetailScreen(medicineId: m.id),
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
