import 'package:flutter/material.dart';

import '../barrel_export.dart';

class MedicineFormScreen extends StatefulWidget {
  final Medicine? existing;
  const MedicineFormScreen({super.key, this.existing});

  @override
  State<MedicineFormScreen> createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends State<MedicineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = InventoryService.instance;

  late final TextEditingController _name;
  late final TextEditingController _generic;
  late final TextEditingController _brand;
  late final TextEditingController _batch;
  late final TextEditingController _unit;
  late final TextEditingController _costPrice;
  late final TextEditingController _sellingPrice;
  late final TextEditingController _quantity;
  late final TextEditingController _minLevel;
  late final TextEditingController _notes;

  Category? _category;
  Supplier? _supplier;
  DateTime _expiry = DateTime.now().add(const Duration(days: 365));
  bool _busy = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _name = TextEditingController(text: m?.name ?? '');
    _generic = TextEditingController(text: m?.genericName ?? '');
    _brand = TextEditingController(text: m?.brand ?? '');
    _batch = TextEditingController(text: m?.batchNumber ?? '');
    _unit = TextEditingController(text: m?.unit ?? 'tablet');
    _costPrice = TextEditingController(text: m?.costPrice.toString() ?? '');
    _sellingPrice =
        TextEditingController(text: m?.sellingPrice.toString() ?? '');
    _quantity = TextEditingController(text: m?.quantity.toString() ?? '0');
    _minLevel = TextEditingController(text: m?.minStockLevel.toString() ?? '10');
    _notes = TextEditingController(text: m?.notes ?? '');
    if (m != null) _expiry = m.expiryDate;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _generic,
      _brand,
      _batch,
      _unit,
      _costPrice,
      _sellingPrice,
      _quantity,
      _minLevel,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      helpText: 'Select expiry date',
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);

    final medicine = Medicine(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      genericName: _generic.text.trim(),
      brand: _brand.text.trim(),
      categoryId: _category?.id ?? widget.existing?.categoryId ?? '',
      categoryName:
          _category?.name ?? widget.existing?.categoryName ?? 'Uncategorised',
      supplierId: _supplier?.id ?? widget.existing?.supplierId ?? '',
      supplierName: _supplier?.name ?? widget.existing?.supplierName ?? '',
      batchNumber: _batch.text.trim(),
      unit: _unit.text.trim().isEmpty ? 'unit' : _unit.text.trim(),
      costPrice: double.tryParse(_costPrice.text) ?? 0,
      sellingPrice: double.tryParse(_sellingPrice.text) ?? 0,
      quantity: int.tryParse(_quantity.text) ?? 0,
      minStockLevel: int.tryParse(_minLevel.text) ?? 0,
      expiryDate: _expiry,
      notes: _notes.text.trim(),
    );

    try {
      if (_isEdit) {
        await _service.updateMedicine(widget.existing!.id, medicine);
      } else {
        await _service.addMedicine(medicine);
      }
      if (mounted) {
        Navigator.of(context).pop();
        showMessage(
          context,
          _isEdit ? 'Medicine updated.' : 'Medicine added to inventory.',
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, 'Could not save. Try again.', error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Matches a saved id back to the live dropdown option.
  T? _lookup<T>(List<T> items, String? id, String Function(T) idOf) {
    if (id == null || id.isEmpty) return null;
    for (final item in items) {
      if (idOf(item) == id) return item;
    }
    return null;
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit medicine' : 'Add medicine'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Medicine name'),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _generic,
              decoration: const InputDecoration(
                labelText: 'Generic name',
                helperText: 'Active ingredient, e.g. paracetamol',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _brand,
              decoration: const InputDecoration(labelText: 'Brand'),
            ),
            const SizedBox(height: 14),
            StreamBuilder<List<Category>>(
              stream: _service.watchCategories(),
              builder: (context, snap) {
                final items = snap.data ?? const <Category>[];
                print(items);
                _category ??= _lookup(items, widget.existing?.categoryId,
                    (c) => c.id);
                print(_category?.id);
                return DropdownButtonFormField<String>(
                  value: _category?.id,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: items
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _category?.id = v!),
                  validator: (v) => (v == null && !_isEdit)
                      ? 'Choose a category'
                      : null,
                );
              },
            ),
            const SizedBox(height: 14),
            StreamBuilder<List<Supplier>>(
              stream: _service.watchSuppliers(),
              builder: (context, snap) {
                final items = snap.data ?? const <Supplier>[];
                _supplier ??= _lookup(items, widget.existing?.supplierId,
                    (s) => s.id);
                return DropdownButtonFormField<String>(
                  value: _supplier?.id,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Supplier'),
                  items: items
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _supplier?.id = v!),
                );
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _batch,
                    decoration:
                        const InputDecoration(labelText: 'Batch number'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      hintText: 'tablet, bottle',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costPrice,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cost price'),
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sellingPrice,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Selling price'),
                    validator: _required,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    enabled: !_isEdit,
                    decoration: InputDecoration(
                      labelText: 'Quantity in stock',
                      helperText: _isEdit
                          ? 'Change this from stock in or stock out'
                          : null,
                    ),
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _minLevel,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minimum level',
                      helperText: 'Alert below this',
                    ),
                    validator: _required,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickExpiry,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Expiry date'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateFormat.format(_expiry)),
                    const Icon(Icons.calendar_today_outlined, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Storage or handling notes',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 26),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              child: Text(_isEdit ? 'Save changes' : 'Add to inventory'),
            ),
          ],
        ),
      ),
    );
  }
}
