import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction_item.dart';

enum TransactionType {
  sale,
  expense,
  purchase,
}

class Transaction {
  final String id;
  final TransactionType type;
  final List<TransactionItem> items;
  final double totalAmount;
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String userId;
  final String? category;
  final String? customerName;
  final String? notes;

  Transaction({
    required this.id,
    required this.type,
    required this.items,
    required this.totalAmount,
    required this.description,
    required this.createdAt,
    this.updatedAt,
    required this.userId,
    this.category,
    this.customerName,
    this.notes,
  });

  /// Create a new transaction with auto-generated timestamp
  factory Transaction.create({
    required TransactionType type,
    required List<TransactionItem> items,
    required String userId,
    String? description,
    String? category,
    String? customerName,
    String? notes,
  }) {
    final totalAmount = items.fold(0.0, (sum, item) => sum + item.amount);
    return Transaction(
      id: '',
      type: type,
      items: items,
      totalAmount: totalAmount,
      description: description ?? '',
      createdAt: DateTime.now(),
      updatedAt: null,
      userId: userId,
      category: category,
      customerName: customerName,
      notes: notes,
    );
  }

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse items from Firestore
    List<TransactionItem> items = [];
    if (data['items'] != null) {
      final itemsList = data['items'] as List<dynamic>;
      items = itemsList.map((itemData) {
        return TransactionItem(
          id: itemData['id'] ?? '',
          itemName: itemData['itemName'] ?? '',
          quantity: (itemData['quantity'] ?? 0).toDouble(),
          unit: QuantityUnit.values.firstWhere(
            (e) => e.name == itemData['unit'],
            orElse: () => QuantityUnit.pcs,
          ),
          pricePerUnit: (itemData['pricePerUnit'] ?? 0).toDouble(),
          amount: (itemData['amount'] ?? 0).toDouble(),
          description: itemData['description'],
        );
      }).toList();
    }

    // Handle timestamp
    DateTime createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAt = DateTime.parse(data['createdAt']);
    } else {
      createdAt = DateTime.now();
    }

    DateTime? updatedAt;
    if (data['updatedAt'] != null) {
      if (data['updatedAt'] is Timestamp) {
        updatedAt = (data['updatedAt'] as Timestamp).toDate();
      } else if (data['updatedAt'] is String) {
        updatedAt = DateTime.parse(data['updatedAt']);
      }
    }

    return Transaction(
      id: doc.id,
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.sale,
      ),
      items: items,
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      userId: data['userId'] ?? '',
      category: data['category'],
      customerName: data['customerName'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    final itemsData = items.map((item) => item.toFirestore()).toList();

    return {
      'type': type.name,
      'items': itemsData,
      'totalAmount': totalAmount,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'userId': userId,
      'category': category,
      'customerName': customerName,
      'notes': notes,
    };
  }

  Transaction copyWith({
    String? id,
    TransactionType? type,
    List<TransactionItem>? items,
    double? totalAmount,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? category,
    String? customerName,
    String? notes,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
    );
  }

  /// Get item names (up to 3) for display purposes
  String get itemNames {
    if (items.isEmpty) return 'No items';
    final validItems = items.where((item) => item.itemName.isNotEmpty).toList();
    if (validItems.isEmpty) return 'No items';

    final maxItems = validItems.take(3).map((item) => item.itemName).toList();
    if (maxItems.length == 1) return maxItems[0];
    if (maxItems.length == 2) return '${maxItems[0]}, ${maxItems[1]}';
    return '${maxItems[0]}, ${maxItems[1]}, +${validItems.length - 2} more';
  }

  /// Get the first item name for display purposes
  String get primaryItemName {
    if (items.isEmpty) return 'No items';
    return items.first.itemName;
  }

  /// Get item count
  int get itemCount => items.length;

  /// Get formatted date string
  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} at ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// Get item names for display (up to 3 items)
  String get itemName => itemNames;
  double get amount => totalAmount;
}
