import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { owner, pharmacist, staff }

UserRole roleFromString(String value) => UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.staff,
    );

class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String pharmacyName;
  final UserRole role;

  AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.pharmacyName,
    required this.role,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      fullName: d['fullName'] ?? '',
      email: d['email'] ?? '',
      pharmacyName: d['pharmacyName'] ?? '',
      role: roleFromString(d['role'] ?? 'staff'),
    );
  }

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'email': email,
        'pharmacyName': pharmacyName,
        'role': role.name,
        'createdAt': FieldValue.serverTimestamp(),
      };

  bool get canManageUsers => role == UserRole.owner;
  bool get canDeleteRecords => role != UserRole.staff;
}

class Category {
  String id;
  final String name;
  final String description;

  Category({required this.id, required this.name, this.description = ''});

  factory Category.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Category(
      id: doc.id,
      name: d['name'] ?? '',
      description: d['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'description': description};
}

class Supplier {
  String id;
  final String name;
  final String phone;
  final String email;
  final String address;

  Supplier({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
  });

  factory Supplier.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Supplier(
      id: doc.id,
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      email: d['email'] ?? '',
      address: d['address'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
      };
}

enum StockStatus { healthy, low, out }

class Medicine {
  final String id;
  final String name;
  final String genericName;
  final String brand;
  final String categoryId;
  final String categoryName;
  final String supplierId;
  final String supplierName;
  final String batchNumber;
  final String unit; // tablet, bottle, sachet...
  final double costPrice;
  final double sellingPrice;
  final int quantity;
  final int minStockLevel;
  final DateTime expiryDate;
  final String notes;

  Medicine({
    required this.id,
    required this.name,
    required this.genericName,
    required this.brand,
    required this.categoryId,
    required this.categoryName,
    required this.supplierId,
    required this.supplierName,
    required this.batchNumber,
    required this.unit,
    required this.costPrice,
    required this.sellingPrice,
    required this.quantity,
    required this.minStockLevel,
    required this.expiryDate,
    this.notes = '',
  });

  factory Medicine.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Medicine(
      id: doc.id,
      name: d['name'] ?? '',
      genericName: d['genericName'] ?? '',
      brand: d['brand'] ?? '',
      categoryId: d['categoryId'] ?? '',
      categoryName: d['categoryName'] ?? 'Uncategorised',
      supplierId: d['supplierId'] ?? '',
      supplierName: d['supplierName'] ?? '',
      batchNumber: d['batchNumber'] ?? '',
      unit: d['unit'] ?? 'unit',
      costPrice: (d['costPrice'] ?? 0).toDouble(),
      sellingPrice: (d['sellingPrice'] ?? 0).toDouble(),
      quantity: (d['quantity'] ?? 0).toInt(),
      minStockLevel: (d['minStockLevel'] ?? 0).toInt(),
      expiryDate:
          (d['expiryDate'] as Timestamp?)?.toDate() ?? DateTime(2100, 1, 1),
      notes: d['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'nameLower': name.toLowerCase(),
        'genericName': genericName,
        'brand': brand,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'batchNumber': batchNumber,
        'unit': unit,
        'costPrice': costPrice,
        'sellingPrice': sellingPrice,
        'quantity': quantity,
        'minStockLevel': minStockLevel,
        'expiryDate': Timestamp.fromDate(expiryDate),
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  StockStatus get stockStatus {
    if (quantity <= 0) return StockStatus.out;
    if (quantity <= minStockLevel) return StockStatus.low;
    return StockStatus.healthy;
  }

  int get daysToExpiry => expiryDate.difference(DateTime.now()).inDays;
  bool get isExpired => daysToExpiry < 0;
  bool get isExpiringSoon => !isExpired && daysToExpiry <= 90;
  double get stockValue => quantity * costPrice;
}

enum TxnType { stockIn, stockOut }

class InventoryTransaction {
  final String id;
  final String medicineId;
  final String medicineName;
  final TxnType type;
  final int quantity;
  final double unitPrice;
  final String party; // supplier for stock-in, customer for stock-out
  final String performedBy;
  final String note;
  final DateTime timestamp;

  InventoryTransaction({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.type,
    required this.quantity,
    required this.unitPrice,
    required this.party,
    required this.performedBy,
    required this.timestamp,
    this.note = '',
  });

  factory InventoryTransaction.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return InventoryTransaction(
      id: doc.id,
      medicineId: d['medicineId'] ?? '',
      medicineName: d['medicineName'] ?? '',
      type: d['type'] == 'stockIn' ? TxnType.stockIn : TxnType.stockOut,
      quantity: (d['quantity'] ?? 0).toInt(),
      unitPrice: (d['unitPrice'] ?? 0).toDouble(),
      party: d['party'] ?? '',
      performedBy: d['performedBy'] ?? '',
      note: d['note'] ?? '',
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'medicineId': medicineId,
        'medicineName': medicineName,
        'type': type.name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalValue': quantity * unitPrice,
        'party': party,
        'performedBy': performedBy,
        'note': note,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  double get totalValue => quantity * unitPrice;
}
