import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to monitor internet connectivity status
/// 
/// Provides real-time connectivity updates and checks for offline state
class ConnectivityService {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  // Current connectivity status
  bool _isConnected = true;
  bool get isConnected => _isConnected;
  
  // Stream controller for connectivity changes
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity status
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _updateConnectionStatus(results);
      },
    );
  }

  /// Update connection status based on connectivity result
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Check if any result indicates connection
    final hasConnection = results.any((result) =>
        result != ConnectivityResult.none);

    if (_isConnected != hasConnection) {
      _isConnected = hasConnection;
      _connectivityController.add(_isConnected);
    }
  }

  /// Check if device is currently online
  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
