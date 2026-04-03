import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ismart_shop/models/transaction.dart' as app;

/// Represents a receipt for a transaction
class Receipt {
  final String id;
  final String transactionId;
  final String receiptNumber;
  final app.TransactionType transactionType;
  final List<ReceiptItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double totalAmount;
  final String? customerName;
  final String? customerPhone;
  final String? paymentMethod;
  final String? notes;
  final String userId;
  final DateTime createdAt;

  Receipt({
    required this.id,
    required this.transactionId,
    required this.receiptNumber,
    required this.transactionType,
    required this.items,
    required this.subtotal,
    this.tax = 0,
    this.discount = 0,
    required this.totalAmount,
    this.customerName,
    this.customerPhone,
    this.paymentMethod,
    this.notes,
    required this.userId,
    required this.createdAt,
  });

  /// Create a receipt from a transaction
  factory Receipt.fromTransaction({
    required String transactionId,
    required String receiptNumber,
    required app.Transaction transaction,
    double tax = 0,
    double discount = 0,
    String? customerName,
    String? customerPhone,
    String? paymentMethod,
    String? notes,
  }) {
    final receiptItems = transaction.items.map((item) {
      return ReceiptItem(
        id: '',
        itemName: item.itemName,
        quantity: item.quantity,
        unit: item.unit.name,
        pricePerUnit: item.pricePerUnit,
        amount: item.amount,
      );
    }).toList();

    return Receipt(
      id: '',
      transactionId: transactionId,
      receiptNumber: receiptNumber,
      transactionType: transaction.type,
      items: receiptItems,
      subtotal: transaction.totalAmount,
      tax: tax,
      discount: discount,
      totalAmount: transaction.totalAmount + tax - discount,
      customerName: customerName ?? transaction.customerName,
      customerPhone: null,
      paymentMethod: paymentMethod,
      notes: notes ?? transaction.notes,
      userId: transaction.userId,
      createdAt: transaction.createdAt,
    );
  }

  factory Receipt.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse items
    List<ReceiptItem> itemsList = [];
    if (data['items'] != null) {
      itemsList = (data['items'] as List<dynamic>).map((itemData) {
        return ReceiptItem(
          id: itemData['id'] ?? '',
          itemName: itemData['itemName'] ?? '',
          quantity: (itemData['quantity'] ?? 0).toDouble(),
          unit: itemData['unit'] ?? 'pcs',
          pricePerUnit: (itemData['pricePerUnit'] ?? 0).toDouble(),
          amount: (itemData['amount'] ?? 0).toDouble(),
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

    // Parse transaction type - check both 'transactionType' and 'type'
    app.TransactionType transactionType;
    if (data['transactionType'] != null) {
      transactionType = app.TransactionType.values.firstWhere(
        (e) => e.name == data['transactionType'],
        orElse: () => app.TransactionType.sale,
      );
    } else if (data['type'] != null) {
      transactionType = app.TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => app.TransactionType.sale,
      );
    } else {
      transactionType = app.TransactionType.sale;
    }

    return Receipt(
      id: doc.id,
      transactionId: data['transactionId'] ?? doc.id,
      receiptNumber:
          data['receiptNumber'] ?? doc.id.substring(0, 8).toUpperCase(),
      transactionType: transactionType,
      items: itemsList,
      subtotal: (data['subtotal'] ?? data['totalAmount'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      customerName: data['customerName'],
      customerPhone: data['customerPhone'],
      paymentMethod: data['paymentMethod'],
      notes: data['notes'],
      userId: data['userId'] ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    final itemsData = items.map((item) => item.toFirestore()).toList();

    return {
      'transactionId': transactionId,
      'receiptNumber': receiptNumber,
      'transactionType': transactionType.name,
      'items': itemsData,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'totalAmount': totalAmount,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Get formatted total
  String get formattedTotal => 'UGX ${totalAmount.toStringAsFixed(0)}';

  /// Get formatted date
  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} at ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// Get transaction type display
  String get transactionTypeDisplay {
    switch (transactionType) {
      case app.TransactionType.sale:
        return 'Sale';
      case app.TransactionType.expense:
        return 'Expense';
      case app.TransactionType.purchase:
        return 'Purchase';
      case app.TransactionType.cashReceipt:
        return 'Cash Receipt';
    }
  }
}

/// Individual item in a receipt
class ReceiptItem {
  final String id;
  final String itemName;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final double amount;

  ReceiptItem({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.amount,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'pricePerUnit': pricePerUnit,
      'amount': amount,
    };
  }

  /// Get formatted amount
  String get formattedAmount => 'UGX ${amount.toStringAsFixed(0)}';

  /// Get formatted price
  String get formattedPrice => 'UGX ${pricePerUnit.toStringAsFixed(0)}';

  /// Get quantity display
  String get quantityDisplay => '${quantity.toStringAsFixed(0)} $unit';
}
