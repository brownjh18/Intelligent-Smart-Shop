import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ismart_shop/models/transaction_item.dart';

/// Represents a product in the inventory
class Product {
  final String id;
  final String name;
  final String? description;
  final String categoryId;
  final String categoryName;
  final QuantityUnit unit;
  final double sellingPrice;
  final double costPrice;
  final int stockQuantity;
  final int lowStockThreshold;
  final String? imageUrl;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
    required this.categoryName,
    required this.unit,
    required this.sellingPrice,
    required this.costPrice,
    required this.stockQuantity,
    this.lowStockThreshold = 10,
    this.imageUrl,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  /// Create a new product with auto-generated timestamp
  factory Product.create({
    required String name,
    String? description,
    required String categoryId,
    required String categoryName,
    required QuantityUnit unit,
    required double sellingPrice,
    required double costPrice,
    int stockQuantity = 0,
    int lowStockThreshold = 10,
    String? imageUrl,
    required String userId,
  }) {
    return Product(
      id: '',
      name: name,
      description: description,
      categoryId: categoryId,
      categoryName: categoryName,
      unit: unit,
      sellingPrice: sellingPrice,
      costPrice: costPrice,
      stockQuantity: stockQuantity,
      lowStockThreshold: lowStockThreshold,
      imageUrl: imageUrl,
      userId: userId,
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle timestamps
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

    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      unit: QuantityUnit.values.firstWhere(
        (e) => e.name == data['unit'],
        orElse: () => QuantityUnit.pcs,
      ),
      sellingPrice: (data['sellingPrice'] ?? 0).toDouble(),
      costPrice: (data['costPrice'] ?? 0).toDouble(),
      stockQuantity: (data['stockQuantity'] ?? 0).toInt(),
      lowStockThreshold: (data['lowStockThreshold'] ?? 10).toInt(),
      imageUrl: data['imageUrl'],
      userId: data['userId'] ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'unit': unit.name,
      'sellingPrice': sellingPrice,
      'costPrice': costPrice,
      'stockQuantity': stockQuantity,
      'lowStockThreshold': lowStockThreshold,
      'imageUrl': imageUrl,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    String? categoryName,
    QuantityUnit? unit,
    double? sellingPrice,
    double? costPrice,
    int? stockQuantity,
    int? lowStockThreshold,
    String? imageUrl,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      unit: unit ?? this.unit,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Check if product is low on stock
  bool get isLowStock => stockQuantity <= lowStockThreshold;

  /// Calculate profit margin
  double get profitMargin => sellingPrice - costPrice;

  /// Calculate profit percentage
  double get profitPercentage =>
      costPrice > 0 ? ((sellingPrice - costPrice) / costPrice) * 100 : 0;

  /// Get formatted price
  String get formattedPrice => 'UGX ${sellingPrice.toStringAsFixed(0)}';

  /// Get formatted cost
  String get formattedCost => 'UGX ${costPrice.toStringAsFixed(0)}';

  /// Get unit display name
  String get unitDisplay => unit.name;
}
