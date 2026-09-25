import 'package:cloud_firestore/cloud_firestore.dart';
import '../barrel_export.dart';

class InventorySummary {
  final int totalMedicines;
  final int lowStockCount;
  final int outOfStockCount;
  final int expiringSoonCount;
  final int expiredCount;
  final double stockValue;

  InventorySummary({
    required this.totalMedicines,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.expiringSoonCount,
    required this.expiredCount,
    required this.stockValue,
  });

  factory InventorySummary.from(List<Medicine> medicines) {
    return InventorySummary(
      totalMedicines: medicines.length,
      lowStockCount:
          medicines.where((m) => m.stockStatus == StockStatus.low).length,
      outOfStockCount:
          medicines.where((m) => m.stockStatus == StockStatus.out).length,
      expiringSoonCount: medicines.where((m) => m.isExpiringSoon).length,
      expiredCount: medicines.where((m) => m.isExpired).length,
      stockValue: medicines.fold<double>(0, (sum, m) => sum + m.stockValue),
    );
  }
}

class InventoryService {
  InventoryService._();
  static final InventoryService instance = InventoryService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _medicines =>
      _db.collection('medicines');
  CollectionReference<Map<String, dynamic>> get _categories =>
      _db.collection('categories');
  CollectionReference<Map<String, dynamic>> get _suppliers =>
      _db.collection('suppliers');
  CollectionReference<Map<String, dynamic>> get _transactions =>
      _db.collection('transactions');

  // ---------------------------------------------------------------- medicines

  Stream<List<Medicine>> watchMedicines() => _medicines
      .orderBy('nameLower')
      .snapshots()
      .map((s) => s.docs.map(Medicine.fromDoc).toList());

  Stream<Medicine> watchMedicine(String id) =>
      _medicines.doc(id).snapshots().map(Medicine.fromDoc);

  Future<String> addMedicine(Medicine medicine) async {
    final data = medicine.toMap()..['createdAt'] = FieldValue.serverTimestamp();
    final ref = await _medicines.add(data);
    if (medicine.quantity > 0) {
      await _transactions.add(InventoryTransaction(
        id: '',
        medicineId: ref.id,
        medicineName: medicine.name,
        type: TxnType.stockIn,
        quantity: medicine.quantity,
        unitPrice: medicine.costPrice,
        party: medicine.supplierName,
        performedBy: 'system',
        note: 'Opening stock',
        timestamp: DateTime.now(),
      ).toMap());
    }
    return ref.id;
  }

  Future<void> updateMedicine(String id, Medicine medicine) =>
      _medicines.doc(id).update(medicine.toMap());

  Future<void> deleteMedicine(String id) => _medicines.doc(id).delete();

  /// Text search runs on the cached list so partial matches work without
  /// a third-party search index.
  List<Medicine> filter(
    List<Medicine> source, {
    String query = '',
    String? categoryId,
    StockStatus? status,
    bool expiringOnly = false,
  }) {
    final q = query.trim().toLowerCase();
    return source.where((m) {
      final matchesQuery = q.isEmpty ||
          m.name.toLowerCase().contains(q) ||
          m.genericName.toLowerCase().contains(q) ||
          m.brand.toLowerCase().contains(q) ||
          m.batchNumber.toLowerCase().contains(q);
      final matchesCategory =
          categoryId == null || categoryId.isEmpty || m.categoryId == categoryId;
      final matchesStatus = status == null || m.stockStatus == status;
      final matchesExpiry = !expiringOnly || m.isExpiringSoon || m.isExpired;
      return matchesQuery && matchesCategory && matchesStatus && matchesExpiry;
    }).toList();
  }

  // ------------------------------------------------------------ stock movement

  /// Records a movement and adjusts the quantity atomically so two staff
  /// members selling at once cannot overwrite each other.
  Future<void> recordMovement({
    required Medicine medicine,
    required TxnType type,
    required int quantity,
    required double unitPrice,
    required String party,
    required String performedBy,
    String note = '',
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Enter a quantity greater than zero.');
    }
    final medicineRef = _medicines.doc(medicine.id);
    final txnRef = _transactions.doc();

    await _db.runTransaction((txn) async {
      final snap = await txn.get(medicineRef);
      final current = (snap.data()?['quantity'] ?? 0) as int;
      final updated =
          type == TxnType.stockIn ? current + quantity : current - quantity;

      if (updated < 0) {
        throw StateError(
          'Only $current ${medicine.unit}(s) of ${medicine.name} are in stock.',
        );
      }

      txn.update(medicineRef, {
        'quantity': updated,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      txn.set(
        txnRef,
        InventoryTransaction(
          id: txnRef.id,
          medicineId: medicine.id,
          medicineName: medicine.name,
          type: type,
          quantity: quantity,
          unitPrice: unitPrice,
          party: party,
          performedBy: performedBy,
          note: note,
          timestamp: DateTime.now(),
        ).toMap(),
      );
    });
  }

  Stream<List<InventoryTransaction>> watchTransactions({int limit = 100}) =>
      _transactions
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs.map(InventoryTransaction.fromDoc).toList());

  Stream<List<InventoryTransaction>> watchTransactionsFor(String medicineId) =>
      _transactions
          .where('medicineId', isEqualTo: medicineId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((s) => s.docs.map(InventoryTransaction.fromDoc).toList());

  // --------------------------------------------------------------- categories

  Stream<List<Category>> watchCategories() => _categories
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(Category.fromDoc).toList());

  Future<void> saveCategory(Category category) => category.id.isEmpty
      ? _categories.add(category.toMap())
      : _categories.doc(category.id).update(category.toMap());

  Future<void> deleteCategory(String id) => _categories.doc(id).delete();

  // ---------------------------------------------------------------- suppliers

  Stream<List<Supplier>> watchSuppliers() => _suppliers
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(Supplier.fromDoc).toList());

  Future<void> saveSupplier(Supplier supplier) => supplier.id.isEmpty
      ? _suppliers.add(supplier.toMap())
      : _suppliers.doc(supplier.id).update(supplier.toMap());

  Future<void> deleteSupplier(String id) => _suppliers.doc(id).delete();
}
