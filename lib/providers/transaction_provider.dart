import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:ismart_shop/models/transaction.dart' as app;
import 'package:ismart_shop/services/local_database_service.dart';
import 'package:ismart_shop/services/connectivity_service.dart';

class TransactionProvider with ChangeNotifier {
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  ConnectivityService? _connectivityService;

  List<app.Transaction> _transactions = [];
  bool _isLoading = false;
  String _error = '';
  bool _firebaseInitialized = false;
  bool _demoMode = false;
  DateTime? _lastFetchTime;

  // Offline sync
  bool _isOnline = true;
  int _pendingSyncCount = 0;
  bool _isSyncing = false;

  // Pagination
  static const int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // UUID generator
  final _uuid = const Uuid();

  List<app.Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String get error => _error;
  bool get isOnline => _isOnline;
  int get pendingSyncCount => _pendingSyncCount;
  bool get isSyncing => _isSyncing;

  void _ensureFirebaseInitialized() {
    if (!_firebaseInitialized) {
      try {
        _firestore = FirebaseFirestore.instance;
        _auth = FirebaseAuth.instance;
        _connectivityService = ConnectivityService();
        _firebaseInitialized = true;
        _demoMode = false;
        debugPrint('Firebase initialized successfully in TransactionProvider');
      } catch (e) {
        debugPrint('Firebase initialization error: $e - running in demo mode');
        _demoMode = true;
      }
    }
  }

  /// Initialize the provider - must be called after Firebase is ready
  Future<void> initialize() async {
    _ensureFirebaseInitialized();

    // Initialize connectivity service
    if (_connectivityService != null) {
      await _connectivityService!.initialize();
      _isOnline = _connectivityService!.isOnline;

      // Listen for connectivity changes
      _connectivityService!.addListener(_onConnectivityChanged);
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged() {
    if (_connectivityService != null) {
      final wasOnline = _isOnline;
      _isOnline = _connectivityService!.isOnline;

      // Trigger sync when coming back online
      if (!wasOnline && _isOnline) {
        debugPrint('Back online - triggering sync');
        _syncPendingTransactions();
      }
      notifyListeners();
    }
  }

  /// Load transactions from local database first, then sync with Firebase
  Future<void> loadTransactions({bool forceRefresh = false}) async {
    _ensureFirebaseInitialized();

    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _transactions.isNotEmpty && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!) <
          const Duration(seconds: 30)) {
        debugPrint('Returning cached transactions');
        return;
      }
    }

    // Demo mode - return from local database
    if (_demoMode || _firestore == null || _auth == null) {
      await _loadFromLocalDatabase();
      return;
    }

    if (_auth!.currentUser == null) {
      _transactions = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _hasMore = true;
    _lastDocument = null;
    notifyListeners();

    try {
      // First load from local database for offline support
      await _loadFromLocalDatabase();

      // Then try to sync with Firebase if online
      if (_isOnline) {
        await _syncWithFirebase();
      }

      // Update pending sync count
      await _updatePendingSyncCount();

      // Update cache timestamp
      _lastFetchTime = DateTime.now();
    } catch (e) {
      _error = 'Failed to load transactions';
      debugPrint('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load transactions from local database
  Future<void> _loadFromLocalDatabase() async {
    if (_auth?.currentUser == null) return;

    try {
      final localTransactions = await LocalDatabaseService.getTransactions(
        _auth!.currentUser!.uid,
      );

      _transactions =
          localTransactions.map((local) => local.toTransaction()).toList();

      // Sort by createdAt descending
      _transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint(
          'Loaded ${_transactions.length} transactions from local database');
    } catch (e) {
      debugPrint('Error loading from local database: $e');
    }
  }

  /// Sync with Firebase and update local database
  Future<void> _syncWithFirebase() async {
    if (_firestore == null || _auth?.currentUser == null) return;

    try {
      // Fetch from Firebase
      QuerySnapshot snapshot = await _firestore!
          .collection('transactions')
          .where('userId', isEqualTo: _auth!.currentUser!.uid)
          .limit(_pageSize)
          .get();

      final firebaseTransactions = snapshot.docs
          .map((doc) => app.Transaction.fromFirestore(doc))
          .toList();

      // Update local database with Firebase data
      for (final transaction in firebaseTransactions) {
        final localTransaction = LocalTransaction.fromTransaction(
          transaction,
          firebaseId: transaction.id,
          syncStatus: SyncStatus.synced,
        );
        await LocalDatabaseService.insertTransaction(localTransaction);
      }

      // Reload from local database to get merged data
      await _loadFromLocalDatabase();

      // Store last document for pagination
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      _hasMore = snapshot.docs.length >= _pageSize;
    } catch (e) {
      debugPrint('Error syncing with Firebase: $e');
      // Continue with local data if sync fails
    }
  }

  /// Update pending sync count
  Future<void> _updatePendingSyncCount() async {
    if (_auth?.currentUser == null) return;

    try {
      _pendingSyncCount = await LocalDatabaseService.getUnsyncedCount(
        _auth!.currentUser!.uid,
      );
    } catch (e) {
      debugPrint('Error updating pending sync count: $e');
    }
  }

  /// Load more transactions (pagination)
  Future<void> loadMoreTransactions() async {
    if (_isLoadingMore || !_hasMore) return;

    // Demo mode - nothing more to load
    if (_demoMode || _firestore == null) {
      _hasMore = false;
      notifyListeners();
      return;
    }

    if (_auth!.currentUser == null) {
      _hasMore = false;
      notifyListeners();
      return;
    }

    if (_lastDocument == null) {
      _hasMore = false;
      notifyListeners();
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore!
          .collection('transactions')
          .where('userId', isEqualTo: _auth!.currentUser!.uid)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize)
          .get();

      List<app.Transaction> newTransactions = snapshot.docs
          .map((doc) => app.Transaction.fromFirestore(doc))
          .toList();

      _transactions.addAll(newTransactions);
      _transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      _hasMore = snapshot.docs.length >= _pageSize;
      _lastFetchTime = DateTime.now();
    } catch (e) {
      _error = 'Failed to load more transactions';
      debugPrint('Error loading more transactions: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Refresh transactions
  Future<void> refreshTransactions() async {
    await loadTransactions(forceRefresh: true);
  }

  /// Add a new transaction - saves locally first, then syncs to Firebase
  Future<void> addTransaction(app.Transaction transaction) async {
    _ensureFirebaseInitialized();

    // Generate a unique ID for local storage
    final localId = _uuid.v4();

    // Demo mode - add locally only
    if (_demoMode || _firestore == null) {
      _isLoading = true;
      notifyListeners();

      app.Transaction newTransaction = transaction.copyWith(
        id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
      );
      _transactions.insert(0, newTransaction);
      _error = '';
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Create local transaction with pending sync status
    final localTransaction = LocalTransaction.fromTransaction(
      transaction.copyWith(id: localId),
      syncStatus: SyncStatus.pending,
    );

    // Save to local database first (offline-first)
    try {
      await LocalDatabaseService.insertTransaction(localTransaction);
      _transactions.insert(0, localTransaction.toTransaction());
      _pendingSyncCount++;
      _error = '';
      notifyListeners();
      debugPrint('Transaction saved locally with ID: $localId');
    } catch (e) {
      _error = 'Failed to save transaction locally';
      debugPrint('Error saving transaction locally: $e');
      notifyListeners();
      return;
    }

    // Try to sync to Firebase if online
    if (_isOnline) {
      await _syncTransactionToFirebase(localTransaction);
    } else {
      debugPrint('Offline - transaction will be synced when online');
    }
  }

  /// Sync a single transaction to Firebase
  Future<void> _syncTransactionToFirebase(
      LocalTransaction localTransaction) async {
    if (_firestore == null || _auth?.currentUser == null) return;

    try {
      // Add to Firebase
      final docRef = await _firestore!
          .collection('transactions')
          .add(localTransaction.toTransaction().toFirestore());

      // Mark as synced in local database
      await LocalDatabaseService.markAsSynced(localTransaction.id, docRef.id);

      // Update the transaction in the list with the Firebase ID
      final index =
          _transactions.indexWhere((t) => t.id == localTransaction.id);
      if (index != -1) {
        _transactions[index] = localTransaction
            .copyWith(
              firebaseId: docRef.id,
              syncStatus: SyncStatus.synced,
            )
            .toTransaction();
      }

      _pendingSyncCount--;
      debugPrint('Transaction synced to Firebase: ${docRef.id}');
      notifyListeners();
    } catch (e) {
      // Mark as failed
      await LocalDatabaseService.markAsFailed(localTransaction.id);
      debugPrint('Failed to sync transaction: $e');
    }
  }

  /// Sync all pending transactions to Firebase
  Future<void> _syncPendingTransactions() async {
    if (_isSyncing || !_isOnline || _auth?.currentUser == null) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final unsyncedTransactions =
          await LocalDatabaseService.getUnsyncedTransactions(
        _auth!.currentUser!.uid,
      );

      debugPrint('Syncing ${unsyncedTransactions.length} pending transactions');

      for (final localTransaction in unsyncedTransactions) {
        await _syncTransactionToFirebase(localTransaction);
      }

      await _updatePendingSyncCount();
    } catch (e) {
      debugPrint('Error syncing pending transactions: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Update an existing transaction
  Future<void> updateTransaction(app.Transaction transaction) async {
    _ensureFirebaseInitialized();

    // Demo mode - update locally
    if (_demoMode || _firestore == null) {
      _isLoading = true;
      notifyListeners();

      int index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
      }
      _error = '';
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Update locally first
    final localTransaction = LocalTransaction.fromTransaction(
      transaction,
      syncStatus: _isOnline ? SyncStatus.pending : SyncStatus.pending,
    );

    try {
      await LocalDatabaseService.updateTransaction(localTransaction);

      int index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
      }
      _error = '';
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update transaction locally';
      debugPrint('Error updating transaction locally: $e');
    }

    // Try to sync to Firebase if online
    if (_isOnline) {
      try {
        await _firestore!
            .collection('transactions')
            .doc(transaction.id)
            .update(transaction.toFirestore());

        // Mark as synced
        await LocalDatabaseService.markAsSynced(transaction.id, transaction.id);
        _pendingSyncCount = await LocalDatabaseService.getUnsyncedCount(
            _auth!.currentUser!.uid);
      } catch (e) {
        debugPrint('Error updating transaction in Firebase: $e');
      }
    }
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    _ensureFirebaseInitialized();

    // Demo mode - delete locally
    if (_demoMode || _firestore == null) {
      _isLoading = true;
      notifyListeners();

      _transactions.removeWhere((t) => t.id == transactionId);
      _error = '';
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Delete from local database first
    try {
      await LocalDatabaseService.deleteTransaction(transactionId);
      _transactions.removeWhere((t) => t.id == transactionId);
      _error = '';
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete transaction locally';
      debugPrint('Error deleting transaction locally: $e');
    }

    // Try to delete from Firebase if online
    if (_isOnline) {
      try {
        await _firestore!
            .collection('transactions')
            .doc(transactionId)
            .delete();
      } catch (e) {
        debugPrint('Error deleting transaction from Firebase: $e');
      }
    }

    await _updatePendingSyncCount();
  }

  /// Force sync all pending transactions
  Future<void> syncNow() async {
    if (_isOnline && _pendingSyncCount > 0) {
      await _syncPendingTransactions();
    }
  }

  // Calculate totals efficiently using cached data
  double get todaySales {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _transactions
        .where((t) =>
            t.type == app.TransactionType.sale &&
            t.createdAt.isAfter(todayStart))
        .fold(0.0, (sum, t) => sum + t.totalAmount);
  }

  double get todayExpenses {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _transactions
        .where((t) =>
            t.type == app.TransactionType.expense &&
            t.createdAt.isAfter(todayStart))
        .fold(0.0, (sum, t) => sum + t.totalAmount);
  }

  List<app.Transaction> getTodayTransactions() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _transactions.where((t) => t.createdAt.isAfter(todayStart)).toList();
  }

  List<app.Transaction> getTransactionsByDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return _transactions
        .where((t) =>
            t.createdAt.isAfter(dayStart) && t.createdAt.isBefore(dayEnd))
        .toList();
  }

  List<app.Transaction> getWeeklyTransactions() {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return _transactions
        .where((t) => t.createdAt.isAfter(startOfWeek))
        .toList();
  }

  List<app.Transaction> getMonthlyTransactions() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _transactions
        .where((t) => t.createdAt.isAfter(startOfMonth))
        .toList();
  }

  @override
  void dispose() {
    _connectivityService?.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
