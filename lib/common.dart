import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';
import 'data/models.dart';


final currency = NumberFormat.currency(symbol: '₦', decimalDigits: 2);
final dateFormat = DateFormat('d MMM yyyy');
final dateTimeFormat = DateFormat('d MMM yyyy, h:mm a');

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCE7E1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
                backgroundColor: AppColors.primaryLight.withOpacity(0.5),
                child: Icon(icon, color: color, size: 28,)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const StatusPill(this.text, this.color, {super.key});

  factory StatusPill.forMedicine(Medicine m) {
    switch (m.stockStatus) {
      case StockStatus.out:
        return const StatusPill('Out of stock', AppColors.danger);
      case StockStatus.low:
        return const StatusPill('Low stock', AppColors.warning);
      case StockStatus.healthy:
        return const StatusPill('In stock', AppColors.accent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.mist,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft, height: 1.4),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MedicineTile extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback? onTap;

  const MedicineTile({super.key, required this.medicine, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.mist,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            medicine.name.isEmpty ? '?' : medicine.name[0].toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          medicine.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${medicine.categoryName} · ${medicine.quantity} ${medicine.unit}(s) · '
            'expires ${dateFormat.format(medicine.expiryDate)}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
          ),
        ),
        trailing: StatusPill.forMedicine(medicine),
      ),
    );
  }
}

void showMessage(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? AppColors.danger : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
}
