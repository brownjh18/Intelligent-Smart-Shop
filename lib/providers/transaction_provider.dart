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

  List<app.Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
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

  Future<void> loadTransactions() async {
    _ensureFirebaseInitialized();

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
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore!
          .collection('transactions')
          .where('userId', isEqualTo: _auth!.currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .get();

      _transactions = snapshot.docs
          .map((doc) => app.Transaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      _error = 'Failed to load transactions';
      debugPrint('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  double get todaySales {
    final today = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == app.TransactionType.sale &&
            t.createdAt.day == today.day &&
            t.createdAt.month == today.month &&
            t.createdAt.year == today.year)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
  }

  double get todayExpenses {
    final today = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == app.TransactionType.expense &&
            t.createdAt.day == today.day &&
            t.createdAt.month == today.month &&
            t.createdAt.year == today.year)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
  }

  List<app.Transaction> getTodayTransactions() {
    final today = DateTime.now();
    return _transactions
        .where((t) =>
            t.createdAt.day == today.day &&
            t.createdAt.month == today.month &&
            t.createdAt.year == today.year)
        .toList();
  }

  List<app.Transaction> getTransactionsByDate(DateTime date) {
    return _transactions
        .where((t) =>
            t.createdAt.day == date.day &&
            t.createdAt.month == date.month &&
            t.createdAt.year == date.year)
        .toList();
  }

  List<app.Transaction> getWeeklyTransactions() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return _transactions
        .where((t) => t.createdAt.isAfter(startOfWeek))
        .toList();
  }

  List<app.Transaction> getMonthlyTransactions() {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.createdAt.month == now.month && t.createdAt.year == now.year)
        .toList();
  }
}
