import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ismart_shop/models/transaction.dart' as app;
import 'package:ismart_shop/models/transaction_item.dart' as app;
import 'package:ismart_shop/models/transaction_item.dart';

/// Sync status for records
enum SyncStatus {
  pending, // Created locally, not yet synced
  synced, // Successfully synced to Firebase
  failed, // Sync failed, needs retry
  deleted, // Marked for deletion, will delete from Firebase on sync
}

/// Transaction model with sync status for local storage
class LocalTransaction {
  final String id;
  final app.TransactionType type;
  final List<app.TransactionItem> items;
  final double totalAmount;
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String userId;
  final String? category;
  final String? customerName;
  final String? notes;
  final SyncStatus syncStatus;
  final String? firebaseId; // The Firebase document ID after sync

  LocalTransaction({
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
    this.syncStatus = SyncStatus.pending,
    this.firebaseId,
  });

  /// Create from app Transaction
  factory LocalTransaction.fromTransaction(app.Transaction transaction,
      {String? firebaseId, SyncStatus? syncStatus}) {
    return LocalTransaction(
      id: transaction.id,
      type: transaction.type,
      items: transaction.items,
      totalAmount: transaction.totalAmount,
      description: transaction.description,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
      userId: transaction.userId,
      category: transaction.category,
      customerName: transaction.customerName,
      notes: transaction.notes,
      syncStatus: syncStatus ?? SyncStatus.pending,
      firebaseId: firebaseId,
    );
  }

  /// Convert to app Transaction
  app.Transaction toTransaction() {
    return app.Transaction(
      id: firebaseId ?? id,
      type: type,
      items: items,
      totalAmount: totalAmount,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt,
      userId: userId,
      category: category,
      customerName: customerName,
      notes: notes,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'items': jsonEncode(items.map((item) => item.toFirestore()).toList()),
      'totalAmount': totalAmount,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'userId': userId,
      'category': category,
      'customerName': customerName,
      'notes': notes,
      'syncStatus': syncStatus.name,
      'firebaseId': firebaseId,
    };
  }

  /// Create from JSON map
  factory LocalTransaction.fromJson(Map<String, dynamic> json) {
    // Parse items
    List<app.TransactionItem> items = [];
    if (json['items'] != null) {
      final itemsData = jsonDecode(json['items'] as String) as List<dynamic>;
      items = itemsData.map((itemData) {
        return app.TransactionItem(
          id: itemData['id'] ?? '',
          itemName: itemData['itemName'] ?? '',
          quantity: (itemData['quantity'] ?? 0).toDouble(),
          unit: app.QuantityUnit.values.firstWhere(
            (e) => e.name == itemData['unit'],
            orElse: () => app.QuantityUnit.pcs,
          ),
          pricePerUnit: (itemData['pricePerUnit'] ?? 0).toDouble(),
          amount: (itemData['amount'] ?? 0).toDouble(),
          description: itemData['description'],
        );
      }).toList();
    }

    return LocalTransaction(
      id: json['id'],
      type: app.TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => app.TransactionType.sale,
      ),
      items: items,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      userId: json['userId'],
      category: json['category'],
      customerName: json['customerName'],
      notes: json['notes'],
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.pending,
      ),
      firebaseId: json['firebaseId'],
    );
  }

  LocalTransaction copyWith({
    String? id,
    app.TransactionType? type,
    List<app.TransactionItem>? items,
    double? totalAmount,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? category,
    String? customerName,
    String? notes,
    SyncStatus? syncStatus,
    String? firebaseId,
  }) {
    return LocalTransaction(
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
      syncStatus: syncStatus ?? this.syncStatus,
      firebaseId: firebaseId ?? this.firebaseId,
    );
  }
}

/// Local customer model with sync status
class LocalCustomer {
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
  final SyncStatus syncStatus;
  final String? firebaseId;

  LocalCustomer({
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
    this.syncStatus = SyncStatus.pending,
    this.firebaseId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'totalPurchases': totalPurchases,
      'creditBalance': creditBalance,
      'notes': notes,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'syncStatus': syncStatus.name,
      'firebaseId': firebaseId,
    };
  }

  factory LocalCustomer.fromJson(Map<String, dynamic> json) {
    return LocalCustomer(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      totalPurchases: (json['totalPurchases'] ?? 0).toDouble(),
      creditBalance: (json['creditBalance'] ?? 0).toDouble(),
      notes: json['notes'],
      userId: json['userId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isActive: json['isActive'] == 1,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.pending,
      ),
      firebaseId: json['firebaseId'],
    );
  }

  LocalCustomer copyWith({
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
    SyncStatus? syncStatus,
    String? firebaseId,
  }) {
    return LocalCustomer(
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
      syncStatus: syncStatus ?? this.syncStatus,
      firebaseId: firebaseId ?? this.firebaseId,
    );
  }
}

/// Local category model with sync status
class LocalCategory {
  final String id;
  final String name;
  final String? description;
  final String? iconName;
  final int colorValue;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final SyncStatus syncStatus;
  final String? firebaseId;

  LocalCategory({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    required this.colorValue,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.syncStatus = SyncStatus.pending,
    this.firebaseId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'colorValue': colorValue,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'syncStatus': syncStatus.name,
      'firebaseId': firebaseId,
    };
  }

  factory LocalCategory.fromJson(Map<String, dynamic> json) {
    return LocalCategory(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      iconName: json['iconName'],
      colorValue: json['colorValue'] ?? 0xFF007AFF,
      userId: json['userId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isActive: json['isActive'] == 1,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.pending,
      ),
      firebaseId: json['firebaseId'],
    );
  }

  LocalCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    int? colorValue,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    SyncStatus? syncStatus,
    String? firebaseId,
  }) {
    return LocalCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      firebaseId: firebaseId ?? this.firebaseId,
    );
  }
}

/// Local supplier model with sync status
class LocalSupplier {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String products; // Comma-separated
  final double totalPurchases;
  final String? notes;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final SyncStatus syncStatus;
  final String? firebaseId;

  LocalSupplier({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.products = '',
    this.totalPurchases = 0,
    this.notes,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.syncStatus = SyncStatus.pending,
    this.firebaseId,
  });

  List<String> get productsList =>
      products.isEmpty ? [] : products.split(',').map((p) => p.trim()).toList();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'products': products,
      'totalPurchases': totalPurchases,
      'notes': notes,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'syncStatus': syncStatus.name,
      'firebaseId': firebaseId,
    };
  }

  factory LocalSupplier.fromJson(Map<String, dynamic> json) {
    return LocalSupplier(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      products: json['products'] ?? '',
      totalPurchases: (json['totalPurchases'] ?? 0).toDouble(),
      notes: json['notes'],
      userId: json['userId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isActive: json['isActive'] == 1,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.pending,
      ),
      firebaseId: json['firebaseId'],
    );
  }

  LocalSupplier copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? products,
    double? totalPurchases,
    String? notes,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    SyncStatus? syncStatus,
    String? firebaseId,
  }) {
    return LocalSupplier(
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
      syncStatus: syncStatus ?? this.syncStatus,
      firebaseId: firebaseId ?? this.firebaseId,
    );
  }
}

/// Local product model with sync status
class LocalProduct {
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
  final SyncStatus syncStatus;
  final String? firebaseId;

  LocalProduct({
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
    this.syncStatus = SyncStatus.pending,
    this.firebaseId,
  });

  bool get isLowStock => stockQuantity <= lowStockThreshold;
  double get profitMargin => sellingPrice - costPrice;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'syncStatus': syncStatus.name,
      'firebaseId': firebaseId,
    };
  }

  factory LocalProduct.fromJson(Map<String, dynamic> json) {
    return LocalProduct(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      unit: QuantityUnit.values.firstWhere(
        (e) => e.name == json['unit'],
        orElse: () => QuantityUnit.pcs,
      ),
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      stockQuantity: (json['stockQuantity'] ?? 0).toInt(),
      lowStockThreshold: (json['lowStockThreshold'] ?? 10).toInt(),
      imageUrl: json['imageUrl'],
      userId: json['userId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isActive: json['isActive'] == 1,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.pending,
      ),
      firebaseId: json['firebaseId'],
    );
  }

  LocalProduct copyWith({
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
    SyncStatus? syncStatus,
    String? firebaseId,
  }) {
    return LocalProduct(
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
      syncStatus: syncStatus ?? this.syncStatus,
      firebaseId: firebaseId ?? this.firebaseId,
    );
  }
}

/// Local database service for offline storage with sync capability
class LocalDatabaseService {
  static Database? _database;
  static const String _transactionsTable = 'transactions';
  static const String _customersTable = 'customers';
  static const String _categoriesTable = 'categories';
  static const String _suppliersTable = 'suppliers';
  static const String _productsTable = 'products';
  static const String _notesTable = 'notes';

  /// Get database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'ismart_shop.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Create database tables
  static Future<void> _onCreate(Database db, int version) async {
    // Transactions table
    await db.execute('''
      CREATE TABLE $_transactionsTable (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        items TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        description TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        userId TEXT NOT NULL,
        category TEXT,
        customerName TEXT,
        notes TEXT,
        syncStatus TEXT NOT NULL DEFAULT 'pending',
        firebaseId TEXT
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_trans_userId ON $_transactionsTable (userId)');
    await db.execute(
        'CREATE INDEX idx_trans_syncStatus ON $_transactionsTable (syncStatus)');
    await db.execute(
        'CREATE INDEX idx_trans_createdAt ON $_transactionsTable (createdAt)');

    // Customers table
    await db.execute('''
      CREATE TABLE $_customersTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        totalPurchases REAL DEFAULT 0,
        creditBalance REAL DEFAULT 0,
        notes TEXT,
        userId TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        isActive INTEGER DEFAULT 1,
        syncStatus TEXT NOT NULL DEFAULT 'pending',
        firebaseId TEXT
      )
    ''');

    await db
        .execute('CREATE INDEX idx_cust_userId ON $_customersTable (userId)');
    await db.execute(
        'CREATE INDEX idx_cust_syncStatus ON $_customersTable (syncStatus)');
    await db.execute('CREATE INDEX idx_cust_name ON $_customersTable (name)');

    // Categories table
    await db.execute('''
      CREATE TABLE $_categoriesTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        iconName TEXT,
        colorValue INTEGER,
        userId TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        isActive INTEGER DEFAULT 1,
        syncStatus TEXT NOT NULL DEFAULT 'pending',
        firebaseId TEXT
      )
    ''');

    await db
        .execute('CREATE INDEX idx_cat_userId ON $_categoriesTable (userId)');
    await db.execute(
        'CREATE INDEX idx_cat_syncStatus ON $_categoriesTable (syncStatus)');
    await db.execute('CREATE INDEX idx_cat_name ON $_categoriesTable (name)');

    // Suppliers table
    await db.execute('''
      CREATE TABLE $_suppliersTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        products TEXT,
        totalPurchases REAL DEFAULT 0,
        notes TEXT,
        userId TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        isActive INTEGER DEFAULT 1,
        syncStatus TEXT NOT NULL DEFAULT 'pending',
        firebaseId TEXT
      )
    ''');

    await db
        .execute('CREATE INDEX idx_supp_userId ON $_suppliersTable (userId)');
    await db.execute(
        'CREATE INDEX idx_supp_syncStatus ON $_suppliersTable (syncStatus)');
    await db.execute('CREATE INDEX idx_supp_name ON $_suppliersTable (name)');

    // Products table
    await db.execute('''
      CREATE TABLE $_productsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        categoryId TEXT NOT NULL,
        categoryName TEXT NOT NULL,
        unit TEXT NOT NULL,
        sellingPrice REAL NOT NULL,
        costPrice REAL NOT NULL,
        stockQuantity INTEGER NOT NULL DEFAULT 0,
        lowStockThreshold INTEGER DEFAULT 10,
        imageUrl TEXT,
        userId TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        isActive INTEGER DEFAULT 1,
        syncStatus TEXT NOT NULL DEFAULT 'pending',
        firebaseId TEXT
      )
    ''');

    await db
        .execute('CREATE INDEX idx_prod_userId ON $_productsTable (userId)');
    await db.execute(
        'CREATE INDEX idx_prod_syncStatus ON $_productsTable (syncStatus)');
    await db.execute('CREATE INDEX idx_prod_name ON $_productsTable (name)');
    await db.execute(
        'CREATE INDEX idx_prod_category ON $_productsTable (categoryId)');

    // Notes table
    await db.execute('''
      CREATE TABLE $_notesTable (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'chat_note'
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_notes_timestamp ON $_notesTable (timestamp)');
  }

  // ==================== TRANSACTIONS ====================

  /// Insert a new transaction
  static Future<void> insertTransaction(LocalTransaction transaction) async {
    final db = await database;
    await db.insert(
      _transactionsTable,
      transaction.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing transaction
  static Future<void> updateTransaction(LocalTransaction transaction) async {
    final db = await database;
    await db.update(
      _transactionsTable,
      transaction.toJson(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  /// Delete a transaction
  static Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      _transactionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all transactions for a user
  static Future<List<LocalTransaction>> getTransactions(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _transactionsTable,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return LocalTransaction.fromJson(maps[i]);
    });
  }

  /// Get a single transaction by ID
  static Future<LocalTransaction?> getTransaction(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _transactionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return LocalTransaction.fromJson(maps.first);
  }

  /// Get transactions that need syncing (pending or failed)
  static Future<List<LocalTransaction>> getUnsyncedTransactions(
      String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _transactionsTable,
      where: "userId = ? AND (syncStatus = 'pending' OR syncStatus = 'failed')",
      whereArgs: [userId],
      orderBy: 'createdAt ASC',
    );

    return List.generate(maps.length, (i) {
      return LocalTransaction.fromJson(maps[i]);
    });
  }

  /// Mark transaction as synced
  static Future<void> markTransactionSynced(
      String id, String firebaseId) async {
    final db = await database;
    await db.update(
      _transactionsTable,
      {
        'syncStatus': SyncStatus.synced.name,
        'firebaseId': firebaseId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark transaction as failed
  static Future<void> markTransactionFailed(String id) async {
    final db = await database;
    await db.update(
      _transactionsTable,
      {'syncStatus': SyncStatus.failed.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get count of unsynced transactions
  static Future<int> getUnsyncedTransactionsCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM $_transactionsTable WHERE userId = ? AND (syncStatus = 'pending' OR syncStatus = 'failed')",
      [userId],
    );
    return result.first['count'] as int;
  }

  /// Clear all transactions for a user (use with caution)
  static Future<void> clearAllTransactions(String userId) async {
    final db = await database;
    await db.delete(
      _transactionsTable,
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // ==================== CUSTOMERS ====================

  /// Insert a new customer
  static Future<void> insertCustomer(LocalCustomer customer) async {
    final db = await database;
    await db.insert(
      _customersTable,
      customer.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing customer
  static Future<void> updateCustomer(LocalCustomer customer) async {
    final db = await database;
    await db.update(
      _customersTable,
      customer.toJson(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  /// Delete a customer (soft delete)
  static Future<void> deleteCustomer(String id) async {
    final db = await database;
    await db.update(
      _customersTable,
      {'isActive': 0, 'syncStatus': SyncStatus.pending.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all active customers for a user
  static Future<List<LocalCustomer>> getCustomers(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _customersTable,
      where: 'userId = ? AND isActive = 1',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return LocalCustomer.fromJson(maps[i]);
    });
  }

  /// Get a single customer by ID
  static Future<LocalCustomer?> getCustomer(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _customersTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return LocalCustomer.fromJson(maps.first);
  }

  /// Get a single customer by Firebase ID
  static Future<LocalCustomer?> getCustomerByFirebaseId(
      String firebaseId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _customersTable,
      where: 'firebaseId = ?',
      whereArgs: [firebaseId],
    );

    if (maps.isEmpty) return null;
    return LocalCustomer.fromJson(maps.first);
  }

  /// Get customers that need syncing
  static Future<List<LocalCustomer>> getUnsyncedCustomers(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _customersTable,
      where:
          "userId = ? AND (syncStatus = 'pending' OR syncStatus = 'failed' OR syncStatus = 'deleted')",
      whereArgs: [userId],
      orderBy: 'createdAt ASC',
    );

    return List.generate(maps.length, (i) {
      return LocalCustomer.fromJson(maps[i]);
    });
  }

  /// Mark customer as synced
  static Future<void> markCustomerSynced(String id, String firebaseId) async {
    final db = await database;
    await db.update(
      _customersTable,
      {
        'syncStatus': SyncStatus.synced.name,
        'firebaseId': firebaseId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark customer as failed
  static Future<void> markCustomerFailed(String id) async {
    final db = await database;
    await db.update(
      _customersTable,
      {'syncStatus': SyncStatus.failed.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== CATEGORIES ====================

  /// Insert a new category
  static Future<void> insertCategory(LocalCategory category) async {
    final db = await database;
    await db.insert(
      _categoriesTable,
      category.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing category
  static Future<void> updateCategory(LocalCategory category) async {
    final db = await database;
    await db.update(
      _categoriesTable,
      category.toJson(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Delete a category (soft delete)
  static Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.update(
      _categoriesTable,
      {'isActive': 0, 'syncStatus': SyncStatus.pending.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all active categories for a user
  static Future<List<LocalCategory>> getCategories(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _categoriesTable,
      where: 'userId = ? AND isActive = 1',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return LocalCategory.fromJson(maps[i]);
    });
  }

  /// Get a single category by ID
  static Future<LocalCategory?> getCategory(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _categoriesTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return LocalCategory.fromJson(maps.first);
  }

  /// Get a single category by Firebase ID
  static Future<LocalCategory?> getCategoryByFirebaseId(
      String firebaseId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _categoriesTable,
      where: 'firebaseId = ?',
      whereArgs: [firebaseId],
    );

    if (maps.isEmpty) return null;
    return LocalCategory.fromJson(maps.first);
  }

  /// Get categories that need syncing
  static Future<List<LocalCategory>> getUnsyncedCategories(
      String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _categoriesTable,
      where:
          "userId = ? AND (syncStatus = 'pending' OR syncStatus = 'failed' OR syncStatus = 'deleted')",
      whereArgs: [userId],
      orderBy: 'createdAt ASC',
    );

    return List.generate(maps.length, (i) {
      return LocalCategory.fromJson(maps[i]);
    });
  }

  /// Mark category as synced
  static Future<void> markCategorySynced(String id, String firebaseId) async {
    final db = await database;
    await db.update(
      _categoriesTable,
      {
        'syncStatus': SyncStatus.synced.name,
        'firebaseId': firebaseId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark category as failed
  static Future<void> markCategoryFailed(String id) async {
    final db = await database;
    await db.update(
      _categoriesTable,
      {'syncStatus': SyncStatus.failed.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== SUPPLIERS ====================

  /// Insert a new supplier
  static Future<void> insertSupplier(LocalSupplier supplier) async {
    final db = await database;
    await db.insert(
      _suppliersTable,
      supplier.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing supplier
  static Future<void> updateSupplier(LocalSupplier supplier) async {
    final db = await database;
    await db.update(
      _suppliersTable,
      supplier.toJson(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  /// Delete a supplier (soft delete)
  static Future<void> deleteSupplier(String id) async {
    final db = await database;
    await db.update(
      _suppliersTable,
      {'isActive': 0, 'syncStatus': SyncStatus.pending.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all active suppliers for a user
  static Future<List<LocalSupplier>> getSuppliers(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _suppliersTable,
      where: 'userId = ? AND isActive = 1',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return LocalSupplier.fromJson(maps[i]);
    });
  }

  /// Get a single supplier by ID
  static Future<LocalSupplier?> getSupplier(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _suppliersTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return LocalSupplier.fromJson(maps.first);
  }

  /// Get a single supplier by Firebase ID
  static Future<LocalSupplier?> getSupplierByFirebaseId(
      String firebaseId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _suppliersTable,
      where: 'firebaseId = ?',
      whereArgs: [firebaseId],
    );

    if (maps.isEmpty) return null;
    return LocalSupplier.fromJson(maps.first);
  }

  /// Get suppliers that need syncing
  static Future<List<LocalSupplier>> getUnsyncedSuppliers(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _suppliersTable,
      where:
          "userId = ? AND (syncStatus = 'pending' OR syncStatus = 'failed' OR syncStatus = 'deleted')",
      whereArgs: [userId],
      orderBy: 'createdAt ASC',
    );

    return List.generate(maps.length, (i) {
      return LocalSupplier.fromJson(maps[i]);
    });
  }

  /// Mark supplier as synced
  static Future<void> markSupplierSynced(String id, String firebaseId) async {
    final db = await database;
    await db.update(
      _suppliersTable,
      {
        'syncStatus': SyncStatus.synced.name,
        'firebaseId': firebaseId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark supplier as failed
  static Future<void> markSupplierFailed(String id) async {
    final db = await database;
    await db.update(
      _suppliersTable,
      {'syncStatus': SyncStatus.failed.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== PRODUCTS ====================

  /// Insert a new product
  static Future<void> insertProduct(LocalProduct product) async {
    final db = await database;
    await db.insert(
      _productsTable,
      product.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing product
  static Future<void> updateProduct(LocalProduct product) async {
    final db = await database;
    await db.update(
      _productsTable,
      product.toJson(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  /// Delete a product (soft delete)
  static Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.update(
      _productsTable,
      {'isActive': 0, 'syncStatus': SyncStatus.pending.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all active products for a user
  static Future<List<LocalProduct>> getProducts(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _productsTable,
      where: 'userId = ? AND isActive = 1',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return LocalProduct.fromJson(maps[i]);
    });
  }

  /// Get a single product by ID
  static Future<LocalProduct?> getProduct(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return LocalProduct.fromJson(maps.first);
  }

  /// Get a single product by Firebase ID
  static Future<LocalProduct?> getProductByFirebaseId(String firebaseId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _productsTable,
      where: 'firebaseId = ?',
      whereArgs: [firebaseId],
    );

    if (maps.isEmpty) return null;
    return LocalProduct.fromJson(maps.first);
  }

  /// Get products by category
  static Future<List<LocalProduct>> getProductsByCategory(
      String userId, String categoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _productsTable,
      where: 'userId = ? AND categoryId = ? AND isActive = 1',
      whereArgs: [userId, categoryId],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return LocalProduct.fromJson(maps[i]);
    });
  }

  /// Get low stock products
  static Future<List<LocalProduct>> getLowStockProducts(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _productsTable,
      where:
          'userId = ? AND isActive = 1 AND stockQuantity <= lowStockThreshold',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) {
      return LocalProduct.fromJson(maps[i]);
    });
  }

  /// Get products that need syncing
  static Future<List<LocalProduct>> getUnsyncedProducts(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _productsTable,
      where:
          "userId = ? AND (syncStatus = 'pending' OR syncStatus = 'failed' OR syncStatus = 'deleted')",
      whereArgs: [userId],
      orderBy: 'createdAt ASC',
    );

    return List.generate(maps.length, (i) {
      return LocalProduct.fromJson(maps[i]);
    });
  }

  /// Mark product as synced
  static Future<void> markProductSynced(String id, String firebaseId) async {
    final db = await database;
    await db.update(
      _productsTable,
      {
        'syncStatus': SyncStatus.synced.name,
        'firebaseId': firebaseId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark product as failed
  static Future<void> markProductFailed(String id) async {
    final db = await database;
    await db.update(
      _productsTable,
      {'syncStatus': SyncStatus.failed.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Close database
  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // ==================== NOTES ====================

  /// Save a note
  static Future<void> saveNote(Map<String, dynamic> note) async {
    final db = await database;
    await db.insert(
      _notesTable,
      note,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all notes
  static Future<List<Map<String, dynamic>>> getNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _notesTable,
      orderBy: 'timestamp DESC',
    );
    return maps;
  }

  /// Delete a note
  static Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete(
      _notesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
