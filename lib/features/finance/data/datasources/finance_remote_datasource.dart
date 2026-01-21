import 'dart:async';
import 'package:financo/core/error/exceptions.dart';
import 'package:financo/features/finance/data/models/asset_model.dart';
import 'package:financo/features/finance/data/models/wealth_snapshot_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract interface for finance remote data source
///
/// Defines methods for interacting with Supabase backend,
/// including real-time subscriptions and CRUD operations.
abstract class FinanceRemoteDataSource {
  /// Get all assets for the current user
  Future<List<AssetModel>> getAssets();

  /// Get a specific asset by ID
  Future<AssetModel> getAssetById(String assetId);

  /// Add a new asset
  Future<AssetModel> addAsset(AssetModel asset);

  /// Update an existing asset
  Future<AssetModel> updateAsset(AssetModel asset);

  /// Delete an asset
  Future<void> deleteAsset(String assetId);

  /// Get wealth history for the current user
  Future<List<WealthSnapshotModel>> getWealthHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });

  /// Calculate current net worth
  Future<double> calculateNetWorth();

  /// Record a wealth snapshot
  Future<void> recordWealthSnapshot();

  /// Stream of real-time asset updates
  Stream<List<AssetModel>> watchAssets();

  /// Add wallet address to Moralis stream
  Future<void> addWalletToStream(String walletAddress);

  /// Remove wallet address from Moralis stream
  Future<void> removeWalletFromStream(String walletAddress);

  /// Setup Moralis stream (idempotent)
  Future<void> setupMoralisStream();

  /// Cleanup user's crypto assets on account deletion
  Future<void> cleanupUserCryptoAssets();
}

/// Implementation of FinanceRemoteDataSource using Supabase
class FinanceRemoteDataSourceImpl implements FinanceRemoteDataSource {
  final SupabaseClient supabaseClient;

  FinanceRemoteDataSourceImpl({required this.supabaseClient});

  /// Get current user ID
  String get _currentUserId {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw ServerException( 'User not authenticated');
    }
    return userId;
  }

  @override
  Future<List<AssetModel>> getAssets() async {
    try {
      final response = await supabaseClient
          .from('assets')
          .select()
          .eq('user_id', _currentUserId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AssetModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException( 'Failed to fetch assets: $e');
    }
  }

  @override
  Future<AssetModel> getAssetById(String assetId) async {
    try {
      final response = await supabaseClient
          .from('assets')
          .select()
          .eq('id', assetId)
          .eq('user_id', _currentUserId)
          .single();

      return AssetModel.fromJson(response);
    } catch (e) {
      throw ServerException( 'Failed to fetch asset: $e');
    }
  }

  @override
  Future<AssetModel> addAsset(AssetModel asset) async {
    try {
      final response = await supabaseClient
          .from('assets')
          .insert(asset.toJson())
          .select()
          .single();

      return AssetModel.fromJson(response);
    } catch (e) {
      throw ServerException( 'Failed to add asset: $e');
    }
  }

  @override
  Future<AssetModel> updateAsset(AssetModel asset) async {
    try {
      final response = await supabaseClient
          .from('assets')
          .update(asset.toJson())
          .eq('id', asset.id)
          .eq('user_id', _currentUserId)
          .select()
          .single();

      return AssetModel.fromJson(response);
    } catch (e) {
      throw ServerException( 'Failed to update asset: $e');
    }
  }

  @override
  Future<void> deleteAsset(String assetId) async {
    try {
      await supabaseClient
          .from('assets')
          .delete()
          .eq('id', assetId)
          .eq('user_id', _currentUserId);
    } catch (e) {
      throw ServerException( 'Failed to delete asset: $e');
    }
  }

  @override
  Future<List<WealthSnapshotModel>> getWealthHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      var query = supabaseClient
          .from('wealth_history')
          .select()
          .eq('user_id', _currentUserId)
          .order('timestamp', ascending: false);

      // if (startDate != null) {
      //   query = query.gte('timestamp', startDate.toIso8601String());
      // }

      // if (endDate != null) {
      //   query = query.lte('timestamp', endDate.toIso8601String());
      // }

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      return (response as List)
          .map((json) =>
              WealthSnapshotModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException( 'Failed to fetch wealth history: $e');
    }
  }

  @override
  Future<double> calculateNetWorth() async {
    try {
      final response = await supabaseClient.rpc(
        'calculate_user_net_worth',
        params: {'p_user_id': _currentUserId},
      );

      if (response is num) {
        return response.toDouble();
      }

      return 0.0;
    } catch (e) {
      throw ServerException( 'Failed to calculate net worth: $e');
    }
  }

  @override
  Future<void> recordWealthSnapshot() async {
    try {
      await supabaseClient.rpc(
        'record_wealth_snapshot',
        params: {'p_user_id': _currentUserId},
      );
    } catch (e) {
      throw ServerException( 'Failed to record wealth snapshot: $e');
    }
  }

  @override
  Stream<List<AssetModel>> watchAssets() {
    try {
      // Create a stream controller to manage the asset stream
      final controller = StreamController<List<AssetModel>>();

      // Initial fetch
      getAssets().then((assets) {
        if (!controller.isClosed) {
          controller.add(assets);
        }
      }).catchError((error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      });

      // Subscribe to real-time updates
      final subscription = supabaseClient
          .from('assets')
          .stream(primaryKey: ['id'])
          .eq('user_id', _currentUserId)
          .order('created_at', ascending: false)
          .listen(
            (data) {
              if (!controller.isClosed) {
                final assets = data
                    .map((json) => AssetModel.fromJson(json))
                    .toList();
                controller.add(assets);
              }
            },
            onError: (error) {
              if (!controller.isClosed) {
                controller.addError(
                  ServerException( 'Real-time update error: $error'),
                );
              }
            },
          );

      // Clean up when stream is cancelled
      controller.onCancel = () {
        subscription.cancel();
      };

      return controller.stream;
    } catch (e) {
      throw ServerException( 'Failed to watch assets: $e');
    }
  }

  @override
  Future<void> addWalletToStream(String walletAddress) async {
    try {
      await supabaseClient.functions.invoke(
        'moralis-stream-manager',
        body: {
          'action': 'add_address',
          'address': walletAddress,
        },
      );
    } catch (e) {
      throw ServerException(
           'Failed to add wallet to stream: $e');
    }
  }

  @override
  Future<void> removeWalletFromStream(String walletAddress) async {
    try {
      await supabaseClient.functions.invoke(
        'moralis-stream-manager',
        body: {
          'action': 'remove_address',
          'address': walletAddress,
        },
      );
    } catch (e) {
      throw ServerException(
           'Failed to remove wallet from stream: $e');
    }
  }

  @override
  Future<void> setupMoralisStream() async {
    try {
      await supabaseClient.functions.invoke(
        'moralis-stream-manager',
        body: {
          'action': 'setup',
        },
      );
    } catch (e) {
      throw ServerException( 'Failed to setup Moralis stream: $e');
    }
  }

  @override
  Future<void> cleanupUserCryptoAssets() async {
    try {
      await supabaseClient.functions.invoke(
        'moralis-stream-manager',
        body: {
          'action': 'cleanup_user',
          'userId': _currentUserId,
        },
      );
    } catch (e) {
      throw ServerException(
           'Failed to cleanup user crypto assets: $e');
    }
  }
}
