import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a customer
class Customer {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final double totalPurchases;
  final double creditBalance;
  final String? notes;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.totalPurchases = 0,
    this.creditBalance = 0,
    this.notes,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  /// Create a new customer with auto-generated timestamp
  factory Customer.create({
    required String name,
    String? phone,
    String? email,
    String? address,
    double totalPurchases = 0,
    double creditBalance = 0,
    String? notes,
    required String userId,
  }) {
    return Customer(
      id: '',
      name: name,
      phone: phone,
      email: email,
      address: address,
      totalPurchases: totalPurchases,
      creditBalance: creditBalance,
      notes: notes,
      userId: userId,
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

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

    return Customer(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'],
      email: data['email'],
      address: data['address'],
      totalPurchases: (data['totalPurchases'] ?? 0).toDouble(),
      creditBalance: (data['creditBalance'] ?? 0).toDouble(),
      notes: data['notes'],
      userId: data['userId'] ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'totalPurchases': totalPurchases,
      'creditBalance': creditBalance,
      'notes': notes,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? totalPurchases,
    double? creditBalance,
    String? notes,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      creditBalance: creditBalance ?? this.creditBalance,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Check if customer has credit
  bool get hasCredit => creditBalance > 0;

  /// Get formatted total purchases
  String get formattedTotalPurchases =>
      'UGX ${totalPurchases.toStringAsFixed(0)}';

  /// Get formatted credit balance
  String get formattedCreditBalance =>
      'UGX ${creditBalance.toStringAsFixed(0)}';

  /// Get initials for avatar
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
