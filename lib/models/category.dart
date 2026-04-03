import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a product category
class Category {
  final String id;
  final String name;
  final String? description;
  final String? iconName;
  final int colorValue;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    required this.colorValue,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  /// Create a new category with auto-generated timestamp
  factory Category.create({
    required String name,
    String? description,
    String? iconName,
    required int colorValue,
    required String userId,
  }) {
    return Category(
      id: '',
      name: name,
      description: description,
      iconName: iconName,
      colorValue: colorValue,
      userId: userId,
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  factory Category.fromFirestore(DocumentSnapshot doc) {
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

    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      iconName: data['iconName'],
      colorValue: data['colorValue'] ?? 0xFF007AFF,
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
      'iconName': iconName,
      'colorValue': colorValue,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    int? colorValue,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Default categories for new users
  static List<Map<String, dynamic>> getDefaultCategories(String userId) {
    return [
      {
        'name': 'Groceries',
        'description': 'General grocery items',
        'iconName': 'shopping_cart',
        'colorValue': 0xFF34C759,
        'userId': userId,
      },
      {
        'name': 'Bakery',
        'description': 'Bread and bakery products',
        'iconName': 'bakery_dining',
        'colorValue': 0xFFFF9500,
        'userId': userId,
      },
      {
        'name': 'Meat',
        'description': 'Fresh meat and poultry',
        'iconName': 'restaurant',
        'colorValue': 0xFFFF3B30,
        'userId': userId,
      },
      {
        'name': 'Drinks',
        'description': 'Beverages and drinks',
        'iconName': 'local_cafe',
        'colorValue': 0xFF007AFF,
        'userId': userId,
      },
      {
        'name': 'Dairy',
        'description': 'Milk and dairy products',
        'iconName': 'egg',
        'colorValue': 0xFFAF52DE,
        'userId': userId,
      },
      {
        'name': 'Snacks',
        'description': 'Snacks and treats',
        'iconName': 'cookie',
        'colorValue': 0xFFFFCC00,
        'userId': userId,
      },
    ];
  }
}
