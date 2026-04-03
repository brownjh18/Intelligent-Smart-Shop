import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a supplier/vendor
class Supplier {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final List<String> products;
  final double totalPurchases;
  final String? notes;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.products = const [],
    this.totalPurchases = 0,
    this.notes,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  /// Create a new supplier with auto-generated timestamp
  factory Supplier.create({
    required String name,
    String? phone,
    String? email,
    String? address,
    List<String>? products,
    double totalPurchases = 0,
    String? notes,
    required String userId,
  }) {
    return Supplier(
      id: '',
      name: name,
      phone: phone,
      email: email,
      address: address,
      products: products ?? [],
      totalPurchases: totalPurchases,
      notes: notes,
      userId: userId,
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  factory Supplier.fromFirestore(DocumentSnapshot doc) {
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

    // Parse products list
    List<String> productsList = [];
    if (data['products'] != null) {
      productsList =
          (data['products'] as List<dynamic>).map((e) => e.toString()).toList();
    }

    return Supplier(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'],
      email: data['email'],
      address: data['address'],
      products: productsList,
      totalPurchases: (data['totalPurchases'] ?? 0).toDouble(),
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
      'products': products,
      'totalPurchases': totalPurchases,
      'notes': notes,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
    };
  }

  Supplier copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    List<String>? products,
    double? totalPurchases,
    String? notes,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      products: products ?? this.products,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Get formatted total purchases
  String get formattedTotalPurchases =>
      'UGX ${totalPurchases.toStringAsFixed(0)}';

  /// Get products as comma-separated string
  String get productsString => products.join(', ');

  /// Get initials for avatar
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
