import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:financo/core/services/connectivity_service.dart';

/// Global error handler for Supabase operations
/// 
/// Catches and handles auth refresh errors when offline
class SupabaseErrorHandler {
  final ConnectivityService _connectivityService;
  StreamSubscription<AuthState>? _authSubscription;

  SupabaseErrorHandler({
    required ConnectivityService connectivityService,
  }) : _connectivityService = connectivityService;

  /// Initialize error handling for Supabase auth
  void initialize(SupabaseClient client) {
    // Listen to auth state changes
    _authSubscription = client.auth.onAuthStateChange.listen(
      (AuthState data) {
        final event = data.event;
        
        // Handle token refresh errors
        if (event == AuthChangeEvent.tokenRefreshed) {
          // Token refreshed successfully
        }
      },
      onError: (error) {
        // Catch auth errors silently when offline
        if (!_connectivityService.isOnline()) {
          // Offline - suppress error
          print('[SupabaseErrorHandler] Auth error suppressed (offline): $error');
        } else {
          // Online - log error for debugging
          print('[SupabaseErrorHandler] Auth error: $error');
        }
      },
    );
  }

  /// Wrap async operations with connectivity check and error handling
  Future<T> safeExecute<T>({
    required Future<T> Function() operation,
    required T Function() fallback,
  }) async {
    // Check connectivity first
    if (!_connectivityService.isOnline()) {
      print('[SupabaseErrorHandler] Operation blocked: No internet connection');
      return fallback();
    }

    try {
      return await operation();
    } catch (error) {
      // Handle specific Supabase errors
      if (error.toString().contains('AuthRetryableFetchException') ||
          error.toString().contains('Connection closed') ||
          error.toString().contains('SocketException')) {
        print('[SupabaseErrorHandler] Network error caught: $error');
        return fallback();
      }
      
      // Re-throw other errors
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _authSubscription?.cancel();
  }
}

/// Extension to add safe execution to SupabaseClient
extension SupabaseClientExtension on SupabaseClient {
  /// Execute operation only if online
  Future<T?> executeIfOnline<T>(
    Future<T> Function() operation,
    ConnectivityService connectivityService,
  ) async {
    if (!connectivityService.isOnline()) {
      return null;
    }

    try {
      return await operation();
    } catch (error) {
      if (error.toString().contains('AuthRetryableFetchException') ||
          error.toString().contains('Connection closed')) {
        // Suppress network errors when offline
        return null;
      }
      rethrow;
    }
  }
}
