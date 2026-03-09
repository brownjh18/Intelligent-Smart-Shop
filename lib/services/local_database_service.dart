import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ismart_shop/models/transaction.dart' as app;
import 'package:ismart_shop/models/transaction_item.dart' as app;

/// Sync status for transactions
enum SyncStatus {
  pending, // Created locally, not yet synced
  synced, // Successfully synced to Firebase
  failed, // Sync failed, needs retry
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

/// Local database service for offline transaction storage
class LocalDatabaseService {
  static Database? _database;
  static const String _tableName = 'transactions';

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
    await db.execute('''
      CREATE TABLE $_tableName (
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

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_userId ON $_tableName (userId)
    ''');

    await db.execute('''
      CREATE INDEX idx_syncStatus ON $_tableName (syncStatus)
    ''');

    await db.execute('''
      CREATE INDEX idx_createdAt ON $_tableName (createdAt)
    ''');
  }

  /// Insert a new transaction
  static Future<void> insertTransaction(LocalTransaction transaction) async {
    final db = await database;
    await db.insert(
      _tableName,
      transaction.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing transaction
  static Future<void> updateTransaction(LocalTransaction transaction) async {
    final db = await database;
    await db.update(
      _tableName,
      transaction.toJson(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  /// Delete a transaction
  static Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all transactions for a user
  static Future<List<LocalTransaction>> getTransactions(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
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
      _tableName,
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
      _tableName,
      where: "userId = ? AND (syncStatus = 'pending' OR syncStatus = 'failed')",
      whereArgs: [userId],
      orderBy: 'createdAt ASC',
    );

    return List.generate(maps.length, (i) {
      return LocalTransaction.fromJson(maps[i]);
    });
  }

  /// Mark transaction as synced
  static Future<void> markAsSynced(String id, String firebaseId) async {
    final db = await database;
    await db.update(
      _tableName,
      {
        'syncStatus': SyncStatus.synced.name,
        'firebaseId': firebaseId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark transaction as failed
  static Future<void> markAsFailed(String id) async {
    final db = await database;
    await db.update(
      _tableName,
      {'syncStatus': SyncStatus.failed.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get count of unsynced transactions
  static Future<int> getUnsyncedCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM $_tableName WHERE userId = ? AND (syncStatus = 'pending' OR syncStatus = 'failed')",
      [userId],
    );
    return result.first['count'] as int;
  }

  /// Clear all transactions for a user (use with caution)
  static Future<void> clearAllTransactions(String userId) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  /// Close database
  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
