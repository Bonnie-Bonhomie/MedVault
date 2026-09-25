import 'package:flutter/material.dart';

import 'barrel_export.dart';

Future<void> showStockMovementSheet(
  BuildContext context, {
  required Medicine medicine,
  required TxnType type,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _StockMovementSheet(medicine: medicine, type: type),
  );
}

class _StockMovementSheet extends StatefulWidget {
  final Medicine medicine;
  final TxnType type;

  const _StockMovementSheet({required this.medicine, required this.type});

  @override
  State<_StockMovementSheet> createState() => _StockMovementSheetState();
}

class _StockMovementSheetState extends State<_StockMovementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  late final TextEditingController _price;
  late final TextEditingController _party;
  final _note = TextEditingController();
  bool _busy = false;

  bool get _isIn => widget.type == TxnType.stockIn;

  @override
  void initState() {
    super.initState();
    _price = TextEditingController(
      text: (_isIn ? widget.medicine.costPrice : widget.medicine.sellingPrice)
          .toStringAsFixed(2),
    );
    _party = TextEditingController(
      text: _isIn ? widget.medicine.supplierName : '',
    );
  }

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    _party.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await InventoryService.instance.recordMovement(
        medicine: widget.medicine,
        type: widget.type,
        quantity: int.parse(_quantity.text),
        unitPrice: double.tryParse(_price.text) ?? 0,
        party: _party.text.trim(),
        performedBy: AuthService.instance.currentUser?.email ?? 'unknown',
        note: _note.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        showMessage(
          context,
          _isIn ? 'Stock added.' : 'Sale recorded.',
        );
      }
    } on StateError catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } catch (_) {
      if (mounted) {
        showMessage(context, 'The movement was not saved. Try again.',
            error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isIn ? 'Record stock in' : 'Record stock out',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.medicine.name} · ${widget.medicine.quantity} '
              '${widget.medicine.unit}(s) on hand',
              style: const TextStyle(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _quantity,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity (${widget.medicine.unit}s)',
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a quantity above zero';
                if (!_isIn && n > widget.medicine.quantity) {
                  return 'Only ${widget.medicine.quantity} left in stock';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _isIn ? 'Cost per unit' : 'Selling price per unit',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _party,
              decoration: InputDecoration(
                labelText: _isIn ? 'Supplier' : 'Customer or reference',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: Text(_isIn ? 'Add to stock' : 'Remove from stock'),
            ),
          ],
        ),
      ),
    );
  }
}
