import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a quantity unit for items
enum QuantityUnit {
  pcs,
  kgs,
  grams,
  liters,
  ml,
  dozens,
  boxes,
  bags,
  sacks,
  pieces,
}

/// Individual item within a transaction
class TransactionItem {
  final String id;
  final String itemName;
  final double quantity;
  final QuantityUnit unit;
  final double pricePerUnit;
  final double amount; // Auto-calculated: pricePerUnit * quantity
  final String? description;

  TransactionItem({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.amount,
    this.description,
  });

  /// Create a new item with auto-calculated amount
  factory TransactionItem.create({
    required String itemName,
    required double quantity,
    required QuantityUnit unit,
    required double pricePerUnit,
    String? description,
  }) {
    final amount = pricePerUnit * quantity;
    return TransactionItem(
      id: '',
      itemName: itemName,
      quantity: quantity,
      unit: unit,
      pricePerUnit: pricePerUnit,
      amount: amount,
      description: description,
    );
  }

  /// Create from Firestore document
  factory TransactionItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionItem(
      id: doc.id,
      itemName: data['itemName'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: QuantityUnit.values.firstWhere(
        (e) => e.name == data['unit'],
        orElse: () => QuantityUnit.pcs,
      ),
      pricePerUnit: (data['pricePerUnit'] ?? 0).toDouble(),
      amount: (data['amount'] ?? 0).toDouble(),
      description: data['description'],
    );
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit.name,
      'pricePerUnit': pricePerUnit,
      'amount': amount,
      'description': description,
    };
  }

  /// Create a copy with updated values
  TransactionItem copyWith({
    String? id,
    String? itemName,
    double? quantity,
    QuantityUnit? unit,
    double? pricePerUnit,
    double? amount,
    String? description,
  }) {
    final newAmount =
        (pricePerUnit ?? this.pricePerUnit) * (quantity ?? this.quantity);
    return TransactionItem(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      amount: amount ?? newAmount,
      description: description ?? this.description,
    );
  }

  /// Get display string for the unit
  String get unitDisplay {
    switch (unit) {
      case QuantityUnit.pcs:
        return 'pcs';
      case QuantityUnit.kgs:
        return 'kgs';
      case QuantityUnit.grams:
        return 'grams';
      case QuantityUnit.liters:
        return 'liters';
      case QuantityUnit.ml:
        return 'ml';
      case QuantityUnit.dozens:
        return 'dozens';
      case QuantityUnit.boxes:
        return 'boxes';
      case QuantityUnit.bags:
        return 'bags';
      case QuantityUnit.sacks:
        return 'sacks';
      case QuantityUnit.pieces:
        return 'pieces';
    }
  }

  /// Get full display string for quantity
  String get quantityDisplay =>
      '${quantity.toStringAsFixed(unit == QuantityUnit.grams || unit == QuantityUnit.ml ? 0 : 2)} $unitDisplay';
}
