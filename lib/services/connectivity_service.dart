import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service to monitor network connectivity status
class ConnectivityService with ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  bool _isOnline = true;
  bool _isInitialized = false;

  StreamSubscription<ConnectivityResult>? _subscription;

  /// Whether the device is currently online
  bool get isOnline => _isOnline;

  /// Whether the service has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the connectivity service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // Listen for changes
    _subscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    _isInitialized = true;
    notifyListeners();
  }

  /// Update connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    if (wasOnline != _isOnline) {
      debugPrint('Connectivity changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
      notifyListeners();
    }
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    notifyListeners();
    return _isOnline;
  }

  /// Manually trigger a sync attempt (when coming back online)
  Future<void> syncNow() async {
    if (_isOnline) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
