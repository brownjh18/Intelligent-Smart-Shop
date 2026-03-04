import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ismart_shop/models/transaction.dart' as app;

class TransactionProvider with ChangeNotifier {
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  List<app.Transaction> _transactions = [];
  bool _isLoading = false;
  String _error = '';
  bool _firebaseInitialized = false;
  bool _demoMode = false;
  DateTime? _lastFetchTime;

  // Pagination
  static const int _pageSize = 20; // Smaller page size for faster initial load
  DocumentSnapshot? _lastDocument; // Cursor for pagination
  bool _hasMore = true;
  bool _isLoadingMore = false;

  List<app.Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String get error => _error;

  void _ensureFirebaseInitialized() {
    if (!_firebaseInitialized) {
      try {
        _firestore = FirebaseFirestore.instance;
        _auth = FirebaseAuth.instance;
        _firebaseInitialized = true;
        _demoMode = false;
        debugPrint('Firebase initialized successfully in TransactionProvider');
      } catch (e) {
        debugPrint('Firebase initialization error: $e - running in demo mode');
        _demoMode = true;
      }
    }
  }

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

    // Demo mode - return empty list
    if (_demoMode || _auth == null || _firestore == null) {
      _transactions = [];
      _isLoading = false;
      notifyListeners();
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
    _lastDocument = null; // Reset pagination cursor
    notifyListeners();

    try {
      // Fetch transactions - simple query without orderBy to avoid index requirement
      // Using select() to only fetch necessary fields for list view
      QuerySnapshot snapshot = await _firestore!
          .collection('transactions')
          .where('userId', isEqualTo: _auth!.currentUser!.uid)
          .limit(_pageSize)
          .get();

      _transactions = snapshot.docs
          .map((doc) => app.Transaction.fromFirestore(doc))
          .toList();

      // Sort locally by createdAt descending
      _transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Store last document for pagination
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      // Check if there are more items
      _hasMore = snapshot.docs.length >= _pageSize;

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

  /// Load more transactions (pagination)
  Future<void> loadMoreTransactions() async {
    // Prevent multiple simultaneous load more requests
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

    // Don't load if we don't have a cursor
    if (_lastDocument == null) {
      _hasMore = false;
      notifyListeners();
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      // Fetch next page - simple query without orderBy to avoid index requirement
      QuerySnapshot snapshot = await _firestore!
          .collection('transactions')
          .where('userId', isEqualTo: _auth!.currentUser!.uid)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize)
          .get();

      List<app.Transaction> newTransactions = snapshot.docs
          .map((doc) => app.Transaction.fromFirestore(doc))
          .toList();

      // Add new transactions to existing list
      _transactions.addAll(newTransactions);

      // Sort locally by createdAt descending
      _transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Update cursor
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      // Check if there are more items
      _hasMore = snapshot.docs.length >= _pageSize;

      // Update cache timestamp
      _lastFetchTime = DateTime.now();
    } catch (e) {
      _error = 'Failed to load more transactions';
      debugPrint('Error loading more transactions: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Refresh transactions (reset pagination and reload)
  Future<void> refreshTransactions() async {
    await loadTransactions(forceRefresh: true);
  }

  Future<void> addTransaction(app.Transaction transaction) async {
    _ensureFirebaseInitialized();

    // Demo mode - add locally
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

    // Optimistic update - add to local list immediately
    app.Transaction newTransaction = transaction.copyWith(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
    );
    _transactions.insert(0, newTransaction);
    _error = '';
    notifyListeners();

    // Save to Firestore in background without blocking UI
    try {
      DocumentReference docRef = await _firestore!
          .collection('transactions')
          .add(transaction.toFirestore());

      // Update with real ID
      int index = _transactions.indexWhere((t) => t.id == newTransaction.id);
      if (index != -1) {
        _transactions[index] = newTransaction.copyWith(id: docRef.id);
        notifyListeners();
      }
    } catch (e) {
      // Remove from list if save failed
      _transactions.removeWhere((t) => t.id == newTransaction.id);
      _error = 'Failed to save transaction';
      notifyListeners();
      debugPrint('Error adding transaction: $e');
    }
  }

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

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore!
          .collection('transactions')
          .doc(transaction.id)
          .update(transaction.toFirestore());

      int index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
      }
      _error = '';
    } catch (e) {
      _error = 'Failed to update transaction';
      debugPrint('Error updating transaction: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore!.collection('transactions').doc(transactionId).delete();

      _transactions.removeWhere((t) => t.id == transactionId);
      _error = '';
    } catch (e) {
      _error = 'Failed to delete transaction';
      debugPrint('Error deleting transaction: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
}
