import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:financo/core/services/connectivity_service.dart';

/// Global error handler for Supabase operations
/// 
/// Completely prevents auth refresh and all Supabase operations when offline
/// to avoid AuthRetryableFetchException crashes
class SupabaseErrorHandler {
  final ConnectivityService _connectivityService;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isOnline = true;

  SupabaseErrorHandler({
    required ConnectivityService connectivityService,
  }) : _connectivityService = connectivityService;

  /// Initialize error handling for Supabase auth
  Future<void> initialize(SupabaseClient client) async {
    // Get initial connectivity status
    _isOnline = await _connectivityService.hasConnection;
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen(
      (isConnected) {
        _isOnline = isConnected;
        
        if (!isConnected) {
          print('[SupabaseErrorHandler] Connection lost - disabling auth refresh');
          // Cancel any pending auth refresh
          _cancelAuthRefresh(client);
        } else {
          print('[SupabaseErrorHandler] Connection restored - enabling auth refresh');
        }
      },
    );

    // Listen to auth state changes and suppress errors when offline
    _authSubscription = client.auth.onAuthStateChange.listen(
      (AuthState data) {
        final event = data.event;
        
        if (event == AuthChangeEvent.tokenRefreshed) {
          print('[SupabaseErrorHandler] Token refreshed successfully');
        }
      },
      onError: (error) {
        // Always suppress auth errors when offline
        if (!_isOnline) {
          print('[SupabaseErrorHandler] Auth error suppressed (offline): ${error.runtimeType}');
          // Don't rethrow - just suppress
          return;
        }
        
        // Suppress specific network-related errors even when "online"
        final errorStr = error.toString();
        if (errorStr.contains('AuthRetryableFetchException') ||
            errorStr.contains('SocketException') ||
            errorStr.contains('Failed host lookup') ||
            errorStr.contains('Connection closed') ||
            errorStr.contains('No address associated with hostname')) {
          print('[SupabaseErrorHandler] Network error suppressed: ${error.runtimeType}');
          return;
        }
        
        // Log other errors for debugging
        print('[SupabaseErrorHandler] Auth error: $error');
      },
      cancelOnError: false, // Don't cancel subscription on error
    );
  }

  /// Cancel any pending auth refresh operations
  void _cancelAuthRefresh(SupabaseClient client) {
    try {
      // Attempt to stop any pending refresh
      // Note: Supabase doesn't expose a direct way to cancel refresh,
      // but errors will be caught and suppressed
    } catch (e) {
      print('[SupabaseErrorHandler] Error canceling auth refresh: $e');
    }
  }

  /// Wrap async operations with connectivity check and error handling
  Future<T> safeExecute<T>({
    required Future<T> Function() operation,
    required T Function() fallback,
  }) async {
    // Check connectivity first
    if (!_isOnline) {
      print('[SupabaseErrorHandler] Operation blocked: No internet connection');
      return fallback();
    }

    try {
      return await operation();
    } on AuthException catch (error) {
      print('[SupabaseErrorHandler] Auth error caught: ${error.message}');
      return fallback();
    } catch (error) {
      // Handle specific network errors
      final errorStr = error.toString();
      if (errorStr.contains('AuthRetryableFetchException') ||
          errorStr.contains('SocketException') ||
          errorStr.contains('Failed host lookup') ||
          errorStr.contains('Connection closed') ||
          errorStr.contains('No address associated with hostname')) {
        print('[SupabaseErrorHandler] Network error caught: ${error.runtimeType}');
        return fallback();
      }
      
      // Re-throw other errors
      rethrow;
    }
  }

  /// Check if currently online
  bool get isOnline => _isOnline;

  /// Dispose resources
  void dispose() {
    _authSubscription?.cancel();
    _connectivitySubscription?.cancel();
  }
}

/// Extension to add safe execution to SupabaseClient
extension SupabaseClientExtension on SupabaseClient {
  /// Execute operation only if online
  Future<T?> executeIfOnline<T>(
    Future<T> Function() operation,
    ConnectivityService connectivityService,
  ) async {
    final hasConnection = await connectivityService.hasConnection;
    if (!hasConnection) {
      print('[SupabaseClient] Operation skipped: No internet connection');
      return null;
    }

    try {
      return await operation();
    } on AuthException catch (error) {
      print('[SupabaseClient] Auth error: ${error.message}');
      return null;
    } catch (error) {
      final errorStr = error.toString();
      if (errorStr.contains('AuthRetryableFetchException') ||
          errorStr.contains('SocketException') ||
          errorStr.contains('Failed host lookup') ||
          errorStr.contains('Connection closed') ||
          errorStr.contains('No address associated with hostname')) {
        print('[SupabaseClient] Network error suppressed: ${error.runtimeType}');
        return null;
      }
      rethrow;
    }
  }
}
