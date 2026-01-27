import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:financo/core/error/exceptions.dart';
import 'package:financo/features/finance/data/models/asset_model.dart';
import 'package:financo/features/finance/data/models/wealth_snapshot_model.dart';
import 'package:financo/features/finance/data/models/networth_response_model.dart';

abstract class FinanceRemoteDataSource {
  // --- ASSETS CRUD ---
  Future<List<AssetModel>> getAssets();
  Stream<List<AssetModel>> watchAssets();
  Future<void> deleteAsset(String assetId);
  Future<void> updateAssetQuantity(String assetId, double newQuantity);

  // --- CRYPTO (MORALIS) ---
  Future<void> addCryptoWallet(String walletAddress);
  Future<void> removeCryptoWallet(String walletAddress);
  Future<Map<String, dynamic>> setupMoralisStream();
  Future<void> cleanupUserCrypto();

  // --- STOCKS (FMP) ---
  Future<List<dynamic>> searchStocks(String query);
  Future<Map<String, dynamic>> addStock(String symbol, double quantity);
  Future<Map<String, dynamic>> updateStockPrices();
  Future<void> removeStock(String assetId);

  // --- BANKING (PLAID) ---
  Future<Map<String, dynamic>> getPlaidLinkToken();
  Future<Map<String, dynamic>> exchangePlaidToken(String publicToken);
  Future<Map<String, dynamic>> syncBankAccounts();
  Future<Map<String, dynamic>> getBankAccounts(String itemId);
  Future<void> removeBankConnection(String itemId);

  // --- UNIFIED NETWORTH & INSIGHTS ---
  Future<NetworthResponseModel> getNetworth({bool forceRefresh = false});
  Future<Map<String, dynamic>> getDailyChange();
  Future<Map<String, dynamic>> recordWealthSnapshot();

  // --- WEALTH HISTORY ---
  Future<List<WealthSnapshotModel>> getWealthHistory({int? limit});
  Future<void> deleteOldSnapshots();

  // --- PORTFOLIO INSIGHTS ---
  Future<Map<String, dynamic>> getPortfolioInsights();
}

class FinanceRemoteDataSourceImpl implements FinanceRemoteDataSource {
  final SupabaseClient supabaseClient;

  FinanceRemoteDataSourceImpl({required this.supabaseClient});

  String get _currentUserId => supabaseClient.auth.currentUser!.id;

  // ===========================================================================
  // ASSETS CRUD
  // ===========================================================================

  @override
  Future<List<AssetModel>> getAssets() async {
    try {
      final response = await supabaseClient
          .from('assets')
          .select('''
            *,
            user_sync_status:crypto_assets_count,
            user_sync_status:stock_assets_count,
            user_sync_status:bank_assets_count
          ''')
          .eq('user_id', _currentUserId)
          .eq('status', 'active')
          .order('balance_usd', ascending: false);

      return (response as List)
          .map((json) => AssetModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch assets: ${e.toString()}');
    }
  }

  @override
  Stream<List<AssetModel>> watchAssets() {
    return supabaseClient
        .from('assets')
        .stream(primaryKey: ['id'])
        .eq('user_id', _currentUserId)
        // .eq('status', 'active')
        .order('balance_usd', ascending: false)
        .map((data) => data.map((json) => AssetModel.fromJson(json)).toList());
  }

  @override
  Future<void> deleteAsset(String assetId) async {
    try {
      // Soft delete - marquer comme inactif
      await supabaseClient
          .from('assets')
          .update({'status': 'inactive', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', assetId)
          .eq('user_id', _currentUserId);
    } catch (e) {
      throw ServerException('Delete failed: ${e.toString()}');
    }
  }

  @override
  Future<void> updateAssetQuantity(String assetId, double newQuantity) async {
    try {
      final response = await supabaseClient
          .from('assets')
          .select('current_price, price_usd')
          .eq('id', assetId)
          .eq('user_id', _currentUserId)
          .single();

      final price = response['current_price'] ?? response['price_usd'] ?? 0.0;
      final newBalance = price * newQuantity;

      await supabaseClient
          .from('assets')
          .update({
            'quantity': newQuantity,
            'balance_usd': newBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assetId)
          .eq('user_id', _currentUserId);
    } catch (e) {
      throw ServerException('Update quantity failed: ${e.toString()}');
    }
  }

  // ===========================================================================
  // CRYPTO - MORALIS INTEGRATION
  // ===========================================================================

  @override
  Future<void> addCryptoWallet(String walletAddress) async {
    try {
      final FunctionResponse response = await supabaseClient.functions.invoke(
        'moralis-stream-manager',
        body: {
          'action': 'add_address',
          'address': walletAddress,
          'userId': _currentUserId,
        },
      );

      if (response.status != 200) {
        throw ServerException('Failed to add wallet: ${response.status}');
      }
    } catch (e) {
      throw ServerException('Add crypto wallet failed: ${e.toString()}');
    }
  }

  @override
  Future<void> removeCryptoWallet(String walletAddress) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'moralis-stream-manager',
        body: {
          'action': 'remove_address',
          'address': walletAddress,
          'userId': _currentUserId,
        },
      );

      if (response.status != 200) {
        throw ServerException('Failed to remove wallet: ${response.status}');
      }
    } catch (e) {
      throw ServerException('Remove crypto wallet failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> setupMoralisStream() async {
    try {
      final response = await supabaseClient.functions.invoke(
        'moralis-stream-manager',
        body: {'action': 'setup'},
      );

      if (response.status != 200) {
        throw ServerException('Setup failed: ${response.status}');
      }

      return response.data;
    } catch (e) {
      throw ServerException('Moralis setup failed: ${e.toString()}');
    }
  }

  @override
  Future<void> cleanupUserCrypto() async {
    try {
      final response = await supabaseClient.functions.invoke(
        'moralis-stream-manager',
        body: {'action': 'cleanup_user', 'userId': _currentUserId},
      );

      if (response.status != 200) {
        throw ServerException('Cleanup failed: ${response.status}');
      }
    } catch (e) {
      throw ServerException('Crypto cleanup failed: ${e.toString()}');
    }
  }

  // ===========================================================================
  // STOCKS - FMP INTEGRATION
  // ===========================================================================

  @override
  Future<List<dynamic>> searchStocks(String query) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'fmp-manager',
        body: {'action': 'search', 'query': query},
      );

      if (response.status != 200) {
        throw ServerException('Search failed: ${response.status}');
      }

      return response.data as List;
    } catch (e) {
      throw ServerException('Stock search failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> addStock(String symbol, double quantity) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'fmp-manager',
        body: {
          'action': 'add_asset',
          'symbol': symbol,
          'quantity': quantity,
          'userId': _currentUserId,
        },
      );

      if (response.status != 200) {
        throw ServerException('Add stock failed: ${response.status}');
      }

      return response.data;
    } catch (e) {
      throw ServerException('Add stock failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> updateStockPrices() async {
    try {
      final response = await supabaseClient.functions.invoke(
        'fmp-manager',
        body: {
          'action': 'update_prices',
          'userId': _currentUserId,
        },
      );

      if (response.status != 200) {
        throw ServerException('Update prices failed: ${response.status}');
      }

      return response.data;
    } catch (e) {
      throw ServerException('Update stock prices failed: ${e.toString()}');
    }
  }

  @override
  Future<void> removeStock(String assetId) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'fmp-manager',
        body: {
          'action': 'remove_asset',
          'assetId': assetId,
          'userId': _currentUserId,
        },
      );

      if (response.status != 200) {
        throw ServerException('Remove stock failed: ${response.status}');
      }
    } catch (e) {
      throw ServerException('Remove stock failed: ${e.toString()}');
    }
  }

  // ===========================================================================
  // BANKING - PLAID INTEGRATION
  // ===========================================================================

  @override
  Future<Map<String, dynamic>> getPlaidLinkToken() async {
    try {
      final response = await supabaseClient.functions.invoke(
        'plaid-create-link-token',
        body: {'userId': _currentUserId},
      );

      if (response.status != 200) {
        throw ServerException('Get link token failed: ${response.status}');
      }

      return response.data;
    } catch (e) {
      throw ServerException('Get Plaid link token failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> exchangePlaidToken(String publicToken) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'plaid-manager',
        body: {
          'action': 'exchange_token',
          'public_token': publicToken,
          'userId': _currentUserId,
        },
      );

      if (response.status != 200) {
        throw ServerException('Exchange token failed: ${response.status}');
      }

      return response.data;
    } catch (e) {
      throw ServerException('Exchange Plaid token failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> syncBankAccounts() async {
    try {
      final response = await supabaseClient.functions.invoke(
        'plaid-manager',
        body: {
          'action': 'sync_accounts',
          'userId': _currentUserId,
        },
      );

      if (response.status != 200) {
        throw ServerException('Sync accounts failed: ${response.status}');
      }

      return response.data;
    } catch (e) {
      throw ServerException('Sync bank accounts failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getBankAccounts(String itemId) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'plaid-manager',
        body: {
          'action': 'get_accounts',
          'itemId': itemId,
          'userId': _currentUserId,
        },
      );

      if (response.status != 200) {
        throw ServerException('Get accounts failed: ${response.status}');
      }

      return response.data;
    } catch (e) {
      throw ServerException('Get bank accounts failed: ${e.toString()}');
    }
  }

  @override
  Future<void> removeBankConnection(String itemId) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'plaid-manager',
        body: {
          'action': 'remove_item',
          'itemId': itemId,
          'userId': _currentUserId,
        },
      );

      if (response.status != 200) {
        throw ServerException('Remove connection failed: ${response.status}');
      }
    } catch (e) {
      throw ServerException('Remove bank connection failed: ${e.toString()}');
    }
  }

  // ===========================================================================
  // UNIFIED NETWORTH & INSIGHTS
  // ===========================================================================

  @override
  Future<NetworthResponseModel> getNetworth({bool forceRefresh = false}) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'get-networth',
        body: {
          'userId': _currentUserId,
          'forceRefresh': forceRefresh,
        },
      );

      if (response.status != 200) {
        throw ServerException('Get networth failed: ${response.status}');
      }

      return NetworthResponseModel.fromJson(response.data);
    } catch (e) {
      throw ServerException('Get networth failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getDailyChange() async {
    try {
      final response = await supabaseClient.rpc(
        'get_daily_change',
        params: {'p_user_id': _currentUserId},
      );

      if (response.isEmpty) {
        return {
          'today_value': 0.0,
          'yesterday_value': 0.0,
          'change_amount': 0.0,
          'change_percentage': 0.0,
        };
      }

      return response[0];
    } catch (e) {
      throw ServerException('Get daily change failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> recordWealthSnapshot() async {
    try {
      final response = await supabaseClient.rpc(
        'record_wealth_snapshot',
        params: {'p_user_id': _currentUserId},
      );

      return {'success': true, 'message': 'Snapshot recorded successfully'};
    } catch (e) {
      throw ServerException('Record snapshot failed: ${e.toString()}');
    }
  }

  // ===========================================================================
  // WEALTH HISTORY
  // ===========================================================================

  @override
  Future<List<WealthSnapshotModel>> getWealthHistory({int? limit}) async {
    try {
      var query = supabaseClient
          .from('wealth_snapshots')
          .select()
          .eq('user_id', _currentUserId)
          .order('snapshot_date', ascending: false);

      if (limit != null) query = query.limit(limit);

      final response = await query;
      return (response as List)
          .map((json) => WealthSnapshotModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Get wealth history failed: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteOldSnapshots() async {
    try {
      // Garde seulement les 90 derniers jours
      final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
      
      await supabaseClient
          .from('wealth_snapshots')
          .delete()
          .lt('snapshot_date', ninetyDaysAgo.toIso8601String())
          .eq('user_id', _currentUserId);
    } catch (e) {
      throw ServerException('Delete old snapshots failed: ${e.toString()}');
    }
  }

  // ===========================================================================
  // PORTFOLIO INSIGHTS
  // ===========================================================================

  @override
  Future<Map<String, dynamic>> getPortfolioInsights() async {
    try {
      final response = await supabaseClient
          .from('portfolio_insights')
          .select()
          .eq('user_id', _currentUserId)
          .order('analysis_date', ascending: false)
          .limit(1)
          .single();

      return response;
    } catch (e) {
      // Si pas d'insights, retourner des valeurs par défaut
      return {
        'diversification_score': 0.0,
        'risk_score': 0.0,
        'volatility_score': 0.0,
        'exposure_warnings': [],
        'concentration_warnings': [],
        'recommendations': [],
        'analysis_date': DateTime.now().toIso8601String(),
      };
    }
  }
}