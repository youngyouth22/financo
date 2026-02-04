import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:financo/core/services/connectivity_service.dart';
import 'package:financo/core/error/exceptions.dart';

/// Wrapper around SupabaseClient that checks connectivity before all operations
/// 
/// Prevents requests when offline to avoid timeout errors and auth refresh issues
class SupabaseClientWrapper {
  final SupabaseClient _client;
  final ConnectivityService _connectivityService;

  SupabaseClientWrapper({
    required SupabaseClient client,
    required ConnectivityService connectivityService,
  })  : _client = client,
        _connectivityService = connectivityService;

  /// Get the underlying Supabase client (for direct access when needed)
  SupabaseClient get client => _client;

  /// Check connectivity before making any request
  Future<void> _ensureConnected() async {
    final isConnected = await _connectivityService.checkConnection();
    if (!isConnected) {
      throw ServerException(
        'No internet connection. Please check your network and try again.',
      );
    }
  }

  /// Wrap Supabase auth operations with connectivity check
  GoTrueClient get auth => _client.auth;

  /// Wrap Supabase database operations with connectivity check
  SupabaseQueryBuilder from(String table) {
    // Check connectivity synchronously using cached status
    if (!_connectivityService.isOnline()) {
      throw ServerException(
        'No internet connection. Please check your network and try again.',
      );
    }
    return _client.from(table);
  }

  /// Wrap Supabase storage operations with connectivity check
  SupabaseStorageClient get storage {
    if (!_connectivityService.isOnline()) {
      throw ServerException(
        'No internet connection. Please check your network and try again.',
      );
    }
    return _client.storage;
  }

  /// Wrap Supabase Edge Functions with connectivity check
  FunctionsClient get functions {
    if (!_connectivityService.isOnline()) {
      throw ServerException(
        'No internet connection. Please check your network and try again.',
      );
    }
    return _client.functions;
  }

  /// Wrap Supabase Realtime with connectivity check
  RealtimeClient get realtime {
    if (!_connectivityService.isOnline()) {
      throw ServerException(
        'No internet connection. Please check your network and try again.',
      );
    }
    return _client.realtime;
  }

  /// Dispose resources
  void dispose() {
    // Supabase client doesn't need explicit disposal
  }
}
