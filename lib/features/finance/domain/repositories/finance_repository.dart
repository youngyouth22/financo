import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';
import 'package:financo/features/finance/domain/entities/wealth_snapshot.dart';
import 'package:financo/features/finance/domain/entities/networth_response.dart';

/// Repository interface for finance operations
///
/// Follows Clean Architecture principles with Either<Failure, Success> pattern
/// Updated to match the new FinanceRemoteDataSource interface
abstract class FinanceRepository {
  // --- ASSETS CRUD ---
  
  /// Get all assets for the current user
  Future<Either<Failure, List<Asset>>> getAssets();
  
  /// Watch assets in real-time via Supabase Realtime
  Stream<Either<Failure, List<Asset>>> watchAssets();
  
  /// Delete an asset (soft delete)
  Future<Either<Failure, void>> deleteAsset(String assetId);
  
  /// Update asset quantity and recalculate balance
  Future<Either<Failure, void>> updateAssetQuantity(String assetId, double newQuantity);

  // --- CRYPTO (MORALIS) ---
  
  /// Add crypto wallet to Moralis stream monitoring
  Future<Either<Failure, void>> addCryptoWallet(String walletAddress);
  
  /// Remove crypto wallet from Moralis stream
  Future<Either<Failure, void>> removeCryptoWallet(String walletAddress);
  
  /// Setup Moralis stream for the first time
  Future<Either<Failure, Map<String, dynamic>>> setupMoralisStream();
  
  /// Cleanup all crypto assets for current user
  Future<Either<Failure, void>> cleanupUserCrypto();

  // --- STOCKS (FMP) ---
  
  /// Search stocks by query via Financial Modeling Prep API
  Future<Either<Failure, List<dynamic>>> searchStocks(String query);
  
  /// Add stock to portfolio with quantity
  Future<Either<Failure, Map<String, dynamic>>> addStock(String symbol, double quantity);
  
  /// Update all stock prices for current user
  Future<Either<Failure, Map<String, dynamic>>> updateStockPrices();
  
  /// Remove stock from portfolio
  Future<Either<Failure, void>> removeStock(String assetId);

  // --- BANKING (PLAID) ---
  
  /// Get Plaid Link token for bank connection flow
  Future<Either<Failure, Map<String, dynamic>>> getPlaidLinkToken();
  
  /// Exchange Plaid public token for access token
  Future<Either<Failure, Map<String, dynamic>>> exchangePlaidToken(String publicToken);
  
  /// Sync bank accounts and balances
  Future<Either<Failure, Map<String, dynamic>>> syncBankAccounts();
  
  /// Get bank accounts for a specific Plaid item
  Future<Either<Failure, Map<String, dynamic>>> getBankAccounts(String itemId);
  
  /// Remove bank connection (Plaid item)
  Future<Either<Failure, void>> removeBankConnection(String itemId);

  // --- UNIFIED NETWORTH & INSIGHTS ---
  
  /// Get unified networth across all asset types
  Future<Either<Failure, NetworthResponse>> getNetworth({bool forceRefresh = false});
  
  /// Get daily change in networth
  Future<Either<Failure, Map<String, dynamic>>> getDailyChange();
  
  /// Record wealth snapshot for historical tracking
  Future<Either<Failure, Map<String, dynamic>>> recordWealthSnapshot();

  // --- WEALTH HISTORY ---
  
  /// Get wealth history snapshots
  Future<Either<Failure, List<WealthSnapshot>>> getWealthHistory({int? limit});
  
  /// Delete old snapshots (older than 90 days)
  Future<Either<Failure, void>> deleteOldSnapshots();

  // --- PORTFOLIO INSIGHTS ---
  
  /// Get portfolio insights (diversification, risk, recommendations)
  Future<Either<Failure, Map<String, dynamic>>> getPortfolioInsights();
}
