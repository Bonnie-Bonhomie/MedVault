import 'package:flutter/material.dart';

import '../barrel_export.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _categoryId;
  StockStatus? _status;
  bool _expiringOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = InventoryService.instance;

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MedicineFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add medicine'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by name, brand or batch',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: StreamBuilder<List<Category>>(
              stream: service.watchCategories(),
              builder: (context, catSnap) {
                final categories = catSnap.data ?? const <Category>[];
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _chip('Low stock', _status == StockStatus.low, () {
                      setState(() => _status =
                          _status == StockStatus.low ? null : StockStatus.low);
                    }),
                    _chip('Out of stock', _status == StockStatus.out, () {
                      setState(() => _status =
                          _status == StockStatus.out ? null : StockStatus.out);
                    }),
                    _chip('Expiring', _expiringOnly, () {
                      setState(() => _expiringOnly = !_expiringOnly);
                    }),
                    for (final c in categories)
                      _chip(c.name, _categoryId == c.id, () {
                        setState(() =>
                            _categoryId = _categoryId == c.id ? null : c.id);
                      }),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: StreamBuilder<List<Medicine>>(
              stream: service.watchMedicines(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final results = service.filter(
                  snapshot.data!,
                  query: _query,
                  categoryId: _categoryId,
                  status: _status,
                  expiringOnly: _expiringOnly,
                );

                if (results.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'Nothing matches',
                    message:
                        'No medicine matches this search and filter set. '
                        'Clear a filter or try another spelling.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  itemCount: results.length,
                  itemBuilder: (context, i) => MedicineTile(
                    medicine: results[i],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            MedicineDetailScreen(medicineId: results[i].id),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
