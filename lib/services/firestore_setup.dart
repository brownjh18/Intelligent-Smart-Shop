import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// This service initializes Firestore collections and sample data
/// Run this once to set up your database structure
class FirestoreSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize Firestore with proper collection structure
  /// Call this once when setting up the app
  static Future<void> initializeCollections() async {
    try {
      // Check if user is authenticated
      if (_auth.currentUser == null) {
        debugPrint('Please sign in first before initializing collections');
        return;
      }

      final userId = _auth.currentUser!.uid;

      debugPrint('Initializing Firestore collections for user: $userId');

      // Create a sample transaction to establish the collection
      final sampleTransaction = {
        'type': 'sale',
        'items': [],
        'totalAmount': 0.0,
        'description': 'Sample transaction - can be deleted',
        'createdAt': DateTime.now(),
        'updatedAt': null,
        'userId': userId,
        'category': null,
        'customerName': null,
        'notes': 'This is a sample transaction to initialize the collection',
      };

      // Add sample transaction to create 'transactions' collection
      await _firestore.collection('transactions').add(sampleTransaction);

      debugPrint('✓ Transactions collection created');

      // Create sample user data to establish 'users' collection
      await _firestore.collection('users').doc(userId).set({
        'id': userId,
        'email': _auth.currentUser!.email,
        'displayName': _auth.currentUser!.displayName ?? 'User',
        'language': 'en',
        'createdAt': DateTime.now(),
        'initialized': true,
      }, SetOptions(merge: true));

      debugPrint('✓ Users collection created');

      // Delete the sample transaction we just created
      final snapshot = await _firestore
          .collection('transactions')
          .where('description',
              isEqualTo: 'Sample transaction - can be deleted')
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('✓ Sample data cleaned up');
      debugPrint('Firestore collections initialized successfully!');
      debugPrint('Collections available:');
      debugPrint('  - transactions (your sales/expenses)');
      debugPrint('  - users (user profiles)');
    } catch (e) {
      debugPrint('Error initializing collections: $e');
    }
  }

  /// Check if Firestore is properly connected
  static Future<bool> checkConnection() async {
    try {
      // Try to access Firestore to check connection
      await _firestore.collection('_health_check').doc('test').get();
      return true;
    } catch (e) {
      debugPrint('Firestore connection check failed: $e');
      return false;
    }
  }

  /// Get all transactions (for debugging)
  static Future<void> listAllTransactions() async {
    if (_auth.currentUser == null) {
      debugPrint('Please sign in first');
      return;
    }

    final snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _auth.currentUser!.uid)
        .get();

    debugPrint('Total transactions: ${snapshot.docs.length}');
    for (final doc in snapshot.docs) {
      debugPrint('  - ${doc.id}: ${doc.data()}');
    }
  }
}
