import 'dart:async';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Service to monitor internet connectivity status
/// 
/// Uses internet_connection_checker_plus for REAL internet access detection
/// Not just WiFi/Data enabled, but actual internet reachability
class ConnectivityService {
  final InternetConnection _internetConnection;
  StreamSubscription<InternetStatus>? _subscription;
  
  // Current connectivity status
  bool _isConnected = true;
  bool get isConnected => _isConnected;
  
  // Stream controller for connectivity changes
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  ConnectivityService({InternetConnection? internetConnection})
      : _internetConnection = internetConnection ?? InternetConnection();

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity status with real internet test
    final hasInternet = await checkConnection();
    _isConnected = hasInternet;
    _connectivityController.add(_isConnected);

    // Listen to connectivity changes
    _subscription = _internetConnection.onStatusChange.listen(
      (InternetStatus status) {
        final isConnected = status == InternetStatus.connected;
        
        if (_isConnected != isConnected) {
          _isConnected = isConnected;
          _connectivityController.add(_isConnected);
          
          if (isConnected) {
            print('[ConnectivityService] ✅ Internet connection restored');
          } else {
            print('[ConnectivityService] ❌ Internet connection lost');
          }
        }
      },
    );
  }

  /// Check if device has REAL internet access
  /// Returns true only if we can actually reach the internet
  Future<bool> checkConnection() async {
    try {
      final status = await _internetConnection.internetStatus;
      return status == InternetStatus.connected;
    } catch (e) {
      print('[ConnectivityService] Error checking connection: $e');
      return false;
    }
  }

  /// Quick check without async (for synchronous-like usage)
  /// Returns cached status immediately
  bool isOnline() {
    return _isConnected;
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
