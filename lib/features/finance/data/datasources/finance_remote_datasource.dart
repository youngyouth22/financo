import 'dart:async';
import 'package:financo/features/finance/domain/entities/asset.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:financo/core/error/exceptions.dart';
import 'package:financo/features/finance/data/models/asset_model.dart';
import 'package:financo/features/finance/data/models/wealth_snapshot_model.dart';
import 'package:financo/features/finance/data/models/networth_response_model.dart';
import 'package:financo/features/finance/domain/entities/crypto_wallet_detail.dart';
import 'package:financo/features/finance/domain/entities/stock_detail.dart';
import 'package:financo/features/finance/domain/entities/bank_account_detail.dart';
import 'package:financo/features/finance/domain/entities/manual_asset_detail.dart';
import 'package:financo/features/finance/domain/entities/asset_payout.dart';
import 'package:financo/features/finance/data/models/asset_payout_model.dart';
import 'package:financo/features/finance/data/models/detail_models/crypto_wallet_detail_model.dart';
import 'package:financo/features/finance/data/models/detail_models/stock_detail_model.dart';
import 'package:financo/features/finance/data/models/detail_models/bank_account_detail_model.dart';
import 'package:financo/features/finance/data/models/detail_models/manual_asset_detail_model.dart';

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

  // --- MANUAL ASSETS ---
  /// Returns the created asset ID
  Future<String> addManualAsset({
    required String name,
    required AssetType type,
    required double amount,
    String? currency,
    String? sector,
    String? country,
  });

  // --- REMINDERS (Amortization/Fixed Income) ---
  Future<void> addAssetReminder({
    required String assetId,
    required String title,
    required String rruleExpression,
    required DateTime nextEventDate,
    double? amountExpected,
  });
  
  // --- ASSET PAYOUTS (Payment History) ---
  Future<AssetPayoutSummary> getAssetPayoutSummary(String assetId);
  Future<List<AssetPayout>> getAssetPayouts(String assetId);
  Future<void> markReminderAsReceived({
    required String reminderId,
    required String assetId,
    required double amount,
    required DateTime payoutDate,
    String? notes,
  });

  // --- ASSET DETAILS (Edge Functions) ---
  Future<CryptoWalletDetail> getCryptoWalletDetails({
    required String address,
    String chain = 'eth',
  });
  
  Future<StockDetail> getStockDetails({
    required String symbol,
    required String userId,
    String timeframe = '1hour',
  });
  
  Future<BankAccountDetail> getBankAccountDetails({
    required String itemId,
    required String accountId,
    required String userId,
  });
  
  Future<ManualAssetDetail> getManualAssetDetails({
    required String assetId,
    required String userId,
  });
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
      await supabaseClient.rpc('generate_portfolio_insights', params: {'p_user_id': _currentUserId});
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

   // ===========================================================================
  // MANUAL ASSETS MANAGEMENT
  // ===========================================================================

  @override
  Future<String> addManualAsset({
    required String name,
    required AssetType type,
    required double amount,
    String? currency,
    String? sector,
    String? country,
  }) async {
    try {
      // 1. Create a unique identifier for the manual asset
      final String manualId = 'manual_${DateTime.now().millisecondsSinceEpoch}';

      // 2. Insert the asset into the 'assets' table and get the ID
      // We fill balance_usd directly since it's a manual entry
      final response = await supabaseClient.from('assets').insert({
        'user_id': _currentUserId,
        'asset_address_or_id': manualId,
        'provider': 'manual',
        'type': _assetTypeToString(type),
        'name': name,
        'symbol': currency ?? 'USD',
        'quantity': 1,
        'current_price': amount,
        'price_usd': amount,
        'balance_usd': amount,
        'sector': sector ?? 'Other',
        'country': country ?? 'Global',
        'last_sync': DateTime.now().toIso8601String(),
        'status': 'active',
      }).select('id').single();
      
      final String assetId = response['id'] as String;

      // 3. RE-CALCULATE ANALYTICS IMMEDIATELY (Production Requirement)
      // This ensures the diversification chart updates right away
      await recordWealthSnapshot();
      await supabaseClient.rpc('generate_portfolio_insights', params: {'p_user_id': _currentUserId});
      
      // 4. Return the asset ID for potential reminder creation
      return assetId;
    } catch (e) {
      throw ServerException('Failed to add manual asset: ${e.toString()}');
    }
  }

  // ===========================================================================
  // ASSET REMINDERS (Amortization Logic)
  // ===========================================================================

  @override
  Future<void> addAssetReminder({
    required String assetId,
    required String title,
    required String rruleExpression,
    required DateTime nextEventDate,
    double? amountExpected,
  }) async {
    try {
      await supabaseClient.from('asset_reminders').insert({
        'user_id': _currentUserId,
        'asset_id': assetId,
        'title': title,
        'rrule_expression': rruleExpression,
        'next_event_date': nextEventDate.toIso8601String(),
        'amount_expected': amountExpected,
        'is_completed': false,
      });
    } catch (e) {
      throw ServerException('Failed to create reminder: ${e.toString()}');
    }
  }

  // ===========================================================================
  // ASSET PAYOUTS (Payment History)
  // ===========================================================================

  @override
  Future<AssetPayoutSummary> getAssetPayoutSummary(String assetId) async {
    try {
      // Call the database function to get payout summary
      final response = await supabaseClient
          .rpc('get_asset_payout_summary', params: {'p_asset_id': assetId})
          .single();

      return AssetPayoutSummaryModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to fetch payout summary: ${e.toString()}');
    }
  }

  @override
  Future<List<AssetPayout>> getAssetPayouts(String assetId) async {
    try {
      final response = await supabaseClient
          .from('asset_payouts')
          .select()
          .eq('asset_id', assetId)
          .order('payout_date', ascending: false);

      return (response as List)
          .map((json) => AssetPayoutModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch payouts: ${e.toString()}');
    }
  }

  @override
  Future<void> markReminderAsReceived({
    required String reminderId,
    required String assetId,
    required double amount,
    required DateTime payoutDate,
    String? notes,
  }) async {
    try {
      // 1. Create payout record
      await supabaseClient.from('asset_payouts').insert({
        'user_id': _currentUserId,
        'asset_id': assetId,
        'amount': amount,
        'payout_date': payoutDate.toIso8601String(),
        'notes': notes,
      });

      // 2. Get reminder details to calculate next event date
      final reminder = await supabaseClient
          .from('asset_reminders')
          .select('rrule_expression, next_event_date')
          .eq('id', reminderId)
          .single();

      final rruleExpression = reminder['rrule_expression'] as String;
      
      // 3. Update next_event_date using database function
      await supabaseClient.rpc(
        'update_reminder_next_event_date',
        params: {
          'p_reminder_id': reminderId,
          'p_rrule_expression': rruleExpression,
        },
      );
    } catch (e) {
      throw ServerException('Failed to mark reminder as received: ${e.toString()}');
    }
  }

  // ===========================================================================
  // ASSET DETAILS (Edge Functions)
  // ===========================================================================

  @override
  Future<CryptoWalletDetail> getCryptoWalletDetails({
    required String address,
    String chain = 'eth',
  }) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'get-wallet-details',
        body: {
          'address': address,
          'chain': chain,
        },
      );

      if (response.status != 200) {
        throw ServerException(response.data['error'] ?? 'Failed to fetch wallet details');
      }

      return CryptoWalletDetailModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to fetch crypto wallet details: ${e.toString()}');
    }
  }

  @override
  Future<StockDetail> getStockDetails({
    required String symbol,
    required String userId,
    String timeframe = '1hour',
  }) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'get-stock-details',
        body: {
          'symbol': symbol,
          'userId': userId,
          'timeframe': timeframe,
        },
      );

      if (response.status != 200) {
        throw ServerException(response.data['error'] ?? 'Failed to fetch stock details');
      }

      return StockDetailModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to fetch stock details: ${e.toString()}');
    }
  }

  @override
  Future<BankAccountDetail> getBankAccountDetails({
    required String itemId,
    required String accountId,
    required String userId,
  }) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'get-bank-details',
        body: {
          'itemId': itemId,
          'accountId': accountId,
          'userId': userId,
        },
      );

      if (response.status != 200) {
        throw ServerException(response.data['error'] ?? 'Failed to fetch bank account details');
      }

      return BankAccountDetailModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to fetch bank account details: ${e.toString()}');
    }
  }

  @override
  Future<ManualAssetDetail> getManualAssetDetails({
    required String assetId,
    required String userId,
  }) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'get-manual-asset-details',
        body: {
          'assetId': assetId,
          'userId': userId,
        },
      );

      if (response.status != 200) {
        throw ServerException(response.data['error'] ?? 'Failed to fetch manual asset details');
      }

      return ManualAssetDetailModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to fetch manual asset details: ${e.toString()}');
    }
  }

  // ===========================================================================
  // PRIVATE HELPER METHODS
  // ===========================================================================

  /// Convert internal AssetType enum to Database String
  String _assetTypeToString(AssetType type) {
    switch (type) {
      case AssetType.crypto: return 'crypto';
      case AssetType.stock: return 'stock';
      case AssetType.cash: return 'cash';
      case AssetType.investment: return 'investment';
      case AssetType.realEstate: return 'real_estate';
      case AssetType.commodity: return 'commodity';
      case AssetType.liability: return 'liability';
      case AssetType.other: return 'other';
    }
  }
}