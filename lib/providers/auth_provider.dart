import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ismart_shop/models/user.dart';

class AuthProvider with ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  UserModel? _userModel;
  bool _isLoading = false;
  String _error = '';
  bool _firebaseInitialized = false;
  bool _demoMode = false;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isAuthenticated =>
      _userModel != null || _demoMode || _auth?.currentUser != null;

  bool get isSignedIn => _auth?.currentUser != null || _demoMode;

  AuthProvider() {
    debugPrint('AuthProvider constructor called');
    _initializeAuth();
  }

  void _initializeAuth() {
    debugPrint('_initializeAuth called');
    _ensureFirebaseInitialized();
  }

  void _listenToAuthState() {
    // Auth state listener is now set up in _ensureFirebaseInitialized
  }

  void _ensureFirebaseInitialized() {
    debugPrint('_ensureFirebaseInitialized called');

    if (_firebaseInitialized) {
      debugPrint('Firebase already initialized, demoMode: $_demoMode');
      return;
    }

    try {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;

      // Check if user is already signed in (persists across app restarts)
      final currentUser = _auth!.currentUser;
      if (currentUser != null) {
        debugPrint('User already signed in: ${currentUser.uid}');
        _loadUserData(currentUser.uid);
      }

      // Set up auth state listener for future changes
      _auth!.authStateChanges().listen((User? user) {
        debugPrint('Auth state changed: ${user?.uid ?? 'null'}');
        if (user != null && !_demoMode) {
          _loadUserData(user.uid);
        }
      });

      _firebaseInitialized = true;
      _demoMode = false;
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint(
          'Firebase initialization error: $e - falling back to demo mode');
      _demoMode = true;
      _firebaseInitialized = true;
    }
  }

  Future<void> login(String email, String password) async {
    debugPrint('login() called with email: $email');
    _ensureFirebaseInitialized();
    debugPrint('After ensureFirebaseInitialized: demoMode=$_demoMode');

    // Demo mode - accept any login for testing
    if (_demoMode) {
      debugPrint('Running in demo mode - creating demo user');
      _isLoading = true;
      _error = '';
      notifyListeners();

      // No delay for faster sign-in
      _userModel = UserModel(
        id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: email.split('@')[0],
        language: 'en',
        createdAt: DateTime.now(),
      );
      _isLoading = false;
      notifyListeners();
      debugPrint('Demo login complete - isAuthenticated: $isAuthenticated');
      return;
    }

    if (_auth == null || _firestore == null) {
      debugPrint('Firebase not initialized properly');
      _error = 'Firebase not configured';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      debugPrint('Attempting Firebase login...');
      UserCredential result = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Firebase login successful: ${result.user?.uid}');

      // Load user data (will create user model immediately, then try Firestore)
      await _loadUserData(result.user!.uid);
      _error = '';
    } catch (e) {
      debugPrint('Firebase login error: $e');
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> register(
      String email, String password, String displayName) async {
    debugPrint(
        'register() called with email: $email, displayName: $displayName');
    _ensureFirebaseInitialized();
    debugPrint('After ensureFirebaseInitialized: demoMode=$_demoMode');

    // Demo mode - accept any registration for testing
    if (_demoMode) {
      debugPrint('Running in demo mode - creating demo user');
      _isLoading = true;
      _error = '';
      notifyListeners();

      // No delay for faster account creation
      _userModel = UserModel(
        id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: displayName,
        language: 'en',
        createdAt: DateTime.now(),
      );
      _isLoading = false;
      notifyListeners();
      debugPrint(
          'Demo registration complete - isAuthenticated: $isAuthenticated');
      return;
    }

    if (_auth == null || _firestore == null) {
      debugPrint('Firebase not initialized properly');
      _error = 'Firebase not configured';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      debugPrint('Attempting Firebase registration...');
      UserCredential result = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Firebase registration successful: ${result.user?.uid}');

      await result.user!.updateDisplayName(displayName);

      _userModel = UserModel(
        id: result.user!.uid,
        email: email,
        displayName: displayName,
        language: 'en',
        createdAt: DateTime.now(),
      );

      debugPrint('Saving user to Firestore...');
      await _firestore!
          .collection('users')
          .doc(result.user!.uid)
          .set(_userModel!.toFirestore());
      debugPrint('User saved to Firestore');

      _error = '';
    } catch (e) {
      debugPrint('Firebase registration error: $e');
      _error = _getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _ensureFirebaseInitialized();
    if (_auth != null && !_demoMode) {
      await _auth!.signOut();
    }
    _userModel = null;
    _demoMode = false;
    notifyListeners();
  }

  Future<void> _loadUserData(String userId) async {
    _ensureFirebaseInitialized();

    // Always create a user model immediately when user is authenticated
    // This ensures isAuthenticated is true even if Firestore is unavailable
    _userModel = UserModel(
      id: userId,
      email: _auth?.currentUser?.email ?? '',
      displayName: _auth?.currentUser?.displayName ?? 'User',
      profileImageUrl: _auth?.currentUser?.photoURL,
      language: 'en',
      createdAt: DateTime.now(),
    );
    notifyListeners();
    debugPrint('User model created immediately: ${_userModel?.email}');

    // Try to enhance user data from Firestore (optional)
    if (_firestore == null) {
      debugPrint('Firestore not available, using auth user data only');
      return;
    }

    try {
      DocumentSnapshot doc =
          await _firestore!.collection('users').doc(userId).get();
      if (doc.exists) {
        _userModel =
            UserModel.fromFirestore(doc.data() as Map<String, dynamic>, userId);
        notifyListeners();
        debugPrint('User data enhanced from Firestore: ${_userModel?.email}');
      }
    } catch (e) {
      debugPrint('Error loading user data from Firestore (non-critical): $e');
      // User model already set from auth, so we can continue
    }
  }

  String _getErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      debugPrint('FirebaseAuthException code: ${e.code}');
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Wrong password provided';
        case 'email-already-in-use':
          return 'Email is already registered';
        case 'invalid-email':
          return 'Invalid email address';
        case 'weak-password':
          return 'Password is too weak';
        case 'user-disabled':
          return 'This account has been disabled';
        default:
          return 'An error occurred: ${e.message}';
      }
    }
    return 'An error occurred';
  }

  Future<void> updateProfile(
      {String? displayName, String? profileImageUrl}) async {
    _ensureFirebaseInitialized();

    // Demo mode - update local user model only
    if (_demoMode) {
      _isLoading = true;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 300));

      _userModel = _userModel?.copyWith(
        displayName: displayName,
        profileImageUrl: profileImageUrl,
      );
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (_auth == null || _auth!.currentUser == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Update display name in Firebase Auth
      if (displayName != null && displayName != _userModel?.displayName) {
        await _auth!.currentUser!.updateDisplayName(displayName);
      }

      // Update profile image in Firebase Auth
      if (profileImageUrl != null &&
          profileImageUrl != _userModel?.profileImageUrl) {
        await _auth!.currentUser!.updatePhotoURL(profileImageUrl);
      }

      // Update in Firestore
      if (_firestore != null && _userModel != null) {
        final updates = <String, dynamic>{};
        if (displayName != null) {
          updates['displayName'] = displayName;
        }
        if (profileImageUrl != null) {
          updates['profileImageUrl'] = profileImageUrl;
        }

        if (updates.isNotEmpty) {
          await _firestore!
              .collection('users')
              .doc(_userModel!.id)
              .update(updates);
        }
      }

      // Update local user model
      _userModel = _userModel?.copyWith(
        displayName: displayName,
        profileImageUrl: profileImageUrl,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      _error = 'Failed to update profile';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
