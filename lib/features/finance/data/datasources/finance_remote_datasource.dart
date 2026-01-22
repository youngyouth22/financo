import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:financo/core/error/exceptions.dart';
import 'package:financo/features/finance/data/models/asset_model.dart';
import 'package:financo/features/finance/data/models/wealth_snapshot_model.dart';

abstract class FinanceRemoteDataSource {
  // --- ASSETS CRUD ---
  Future<List<AssetModel>> getAssets();
  Stream<List<AssetModel>> watchAssets();
  Future<void> deleteAsset(String assetId);

  // --- CRYPTO (MORALIS) ---
  Future<void> addCryptoWallet(String walletAddress);
  Future<void> removeCryptoWallet(String walletAddress);

  // --- BANKING (PLAID) ---
  Future<String> getPlaidLinkToken();
  Future<void> exchangePlaidToken(
    String publicToken,
    Map<String, dynamic> metadata,
  );

  // --- WEALTH & HISTORY ---
  Future<double> calculateNetWorth();
  Future<List<WealthSnapshotModel>> getWealthHistory({int? limit});
}

class FinanceRemoteDataSourceImpl implements FinanceRemoteDataSource {
  final SupabaseClient supabaseClient;

  FinanceRemoteDataSourceImpl({required this.supabaseClient});

  String get _currentUserId => supabaseClient.auth.currentUser!.id;

  // ===========================================================================
  // ASSETS
  // ===========================================================================

  @override
  Future<List<AssetModel>> getAssets() async {
    try {
      final response = await supabaseClient
          .from('assets')
          .select()
          .eq('user_id', _currentUserId)
          .order('balance_usd', ascending: false);

      return (response as List)
          .map((json) => AssetModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch assets: $e');
    }
  }

  @override
  Stream<List<AssetModel>> watchAssets() {
    // Supabase .stream est déjà optimisé, pas besoin de StreamController complexe
    return supabaseClient
        .from('assets')
        .stream(primaryKey: ['id'])
        .eq('user_id', _currentUserId)
        .order('balance_usd', ascending: false)
        .map((data) => data.map((json) => AssetModel.fromJson(json)).toList());
  }

  @override
  Future<void> deleteAsset(String assetId) async {
    try {
      await supabaseClient.from('assets').delete().eq('id', assetId);
    } catch (e) {
      throw ServerException('Delete failed: $e');
    }
  }

  // ===========================================================================
  // CRYPTO (MORALIS EDGE FUNCTIONS)
  // ===========================================================================

  @override
  Future<void> addCryptoWallet(String walletAddress) async {
    try {
      await supabaseClient.functions.invoke(
        'moralis-stream-manager',
        body: {
          'action': 'add_address',
          'address': walletAddress,
          'userId': _currentUserId,
        },
      );
    } catch (e) {
      throw ServerException('Failed to add wallet: $e');
    }
  }

  @override
  Future<void> removeCryptoWallet(String walletAddress) async {
    try {
      await supabaseClient.functions.invoke(
        'moralis-stream-manager',
        body: {'action': 'remove_address', 'address': walletAddress},
      );
    } catch (e) {
      throw ServerException('Failed to remove wallet: $e');
    }
  }

  // ===========================================================================
  // BANKING (PLAID EDGE FUNCTIONS)
  // ===========================================================================

  @override
  Future<String> getPlaidLinkToken() async {
    try {
      final response = await supabaseClient.functions.invoke(
        'plaid-create-link-token',
        body: {'userId': _currentUserId},
      );
      return response.data['link_token'];
    } catch (e) {
      throw ServerException('Plaid Link failed: $e');
    }
  }

  @override
  Future<void> exchangePlaidToken(
    String publicToken,
    Map<String, dynamic> metadata,
  ) async {
    try {
      await supabaseClient.functions.invoke(
        'plaid-manager',
        body: {
          'action': 'exchange',
          'public_token': publicToken,
          'metadata': metadata,
          'userId': _currentUserId,
        },
      );
    } catch (e) {
      throw ServerException('Plaid Exchange failed: $e');
    }
  }

  // ===========================================================================
  // WEALTH & HISTORY
  // ===========================================================================

  @override
  Future<double> calculateNetWorth() async {
    try {
      // On utilise directement la table assets pour le Net Worth (temps réel)
      final response = await supabaseClient
          .from('assets')
          .select('balance_usd')
          .eq('user_id', _currentUserId);

      final assets = response as List;
      return assets.fold<double>(
        0.0,
        (sum, item) => sum + ((item['balance_usd'] as double?) ?? 0.0),
      );
    } catch (e) {
      throw ServerException('Calculation failed: $e');
    }
  }

  @override
  Future<List<WealthSnapshotModel>> getWealthHistory({int? limit}) async {
    try {
      var query = supabaseClient
          .from('wealth_history')
          .select()
          .eq('user_id', _currentUserId)
          .order('timestamp', ascending: false);

      if (limit != null) query = query.limit(limit);

      final response = await query;
      return (response as List)
          .map((json) => WealthSnapshotModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('History fetch failed: $e');
    }
  }
}
