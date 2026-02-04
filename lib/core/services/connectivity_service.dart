import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to monitor internet connectivity status
/// 
/// Provides real-time connectivity updates and checks for REAL internet access
/// Not just WiFi/Data enabled, but actual internet reachability
class ConnectivityService {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  // Current connectivity status
  bool _isConnected = true;
  bool get isConnected => _isConnected;
  
  // Stream controller for connectivity changes
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  // List of reliable hosts to ping for internet check
  static const List<String> _testHosts = [
    'google.com',
    'cloudflare.com',
    '1.1.1.1',
  ];

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity status with real internet test
    final hasInternet = await checkConnection();
    _isConnected = hasInternet;
    _connectivityController.add(_isConnected);

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        // When connectivity changes, verify real internet access
        await _updateConnectionStatus(results);
      },
    );
  }

  /// Update connection status based on connectivity result
  /// Performs REAL internet check, not just WiFi/Data status
  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    // First check if WiFi/Data is enabled
    final hasNetworkInterface = results.any((result) =>
        result != ConnectivityResult.none);

    if (!hasNetworkInterface) {
      // No WiFi/Data at all
      if (_isConnected) {
        _isConnected = false;
        _connectivityController.add(_isConnected);
      }
      return;
    }

    // WiFi/Data is enabled, now check REAL internet access
    final hasRealInternet = await _hasInternetAccess();
    
    if (_isConnected != hasRealInternet) {
      _isConnected = hasRealInternet;
      _connectivityController.add(_isConnected);
    }
  }

  /// Check if device has REAL internet access by pinging reliable hosts
  /// Returns true only if we can actually reach the internet
  Future<bool> checkConnection() async {
    // First check if WiFi/Data is enabled
    final result = await _connectivity.checkConnectivity();
    final hasNetworkInterface = result.any((r) => r != ConnectivityResult.none);
    
    if (!hasNetworkInterface) {
      return false;
    }

    // WiFi/Data is enabled, now check REAL internet access
    return await _hasInternetAccess();
  }

  /// Perform actual internet reachability test
  /// Tries to connect to multiple reliable hosts
  Future<bool> _hasInternetAccess() async {
    // Try to reach at least one host
    for (final host in _testHosts) {
      try {
        final result = await InternetAddress.lookup(host).timeout(
          const Duration(seconds: 3),
        );
        
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          // Successfully resolved DNS and got IP address
          return true;
        }
      } catch (e) {
        // This host failed, try next one
        continue;
      }
    }
    
    // All hosts failed, no real internet access
    return false;
  }

  /// Quick check without timeout (for synchronous-like usage)
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
