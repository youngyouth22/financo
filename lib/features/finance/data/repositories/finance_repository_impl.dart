import 'package:dartz/dartz.dart';
import 'package:financo/core/error/exceptions.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/services/connectivity_service.dart';
import 'package:financo/features/finance/data/datasources/finance_remote_datasource.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';
import 'package:financo/features/finance/domain/entities/networth_response.dart';
import 'package:financo/features/finance/domain/entities/wealth_snapshot.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';
import 'package:financo/features/finance/domain/entities/crypto_wallet_detail.dart';
import 'package:financo/features/finance/domain/entities/stock_detail.dart';
import 'package:financo/features/finance/domain/entities/bank_account_detail.dart';
import 'package:financo/features/finance/domain/entities/manual_asset_detail.dart';
import 'package:financo/features/finance/domain/entities/asset_payout.dart';
import 'package:financo/features/finance/data/models/asset_payout_model.dart';

/// Implementation of FinanceRepository
///
/// Handles error conversion from Exceptions to Failures
/// Maps data models to domain entities
class FinanceRepositoryImpl implements FinanceRepository {
  final FinanceRemoteDataSource remoteDataSource;
  final ConnectivityService connectivityService;

  FinanceRepositoryImpl({
    required this.remoteDataSource,
    required this.connectivityService,
  });

  /// Check if device is online before making API calls
  Future<bool> _isOnline() async {
    return await connectivityService.checkConnection();
  }

  // ===========================================================================
  // ASSETS CRUD
  // ===========================================================================

  @override
  Future<Either<Failure, List<Asset>>> getAssets() async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final assets = await remoteDataSource.getAssets();
      return Right(assets.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Stream<Either<Failure, List<Asset>>> watchAssets() async* {
    try {
      await for (final assets in remoteDataSource.watchAssets()) {
        yield Right(assets.map((model) => model.toEntity()).toList());
      }
    } on ServerException catch (e) {
      yield Left(ServerFailure(e.message));
    } catch (e) {
      yield Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAsset(String assetId) async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      await remoteDataSource.deleteAsset(assetId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateAssetQuantity(
      String assetId, double newQuantity) async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      await remoteDataSource.updateAssetQuantity(assetId, newQuantity);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  // ===========================================================================
  // CRYPTO (MORALIS)
  // ===========================================================================

  @override
  Future<Either<Failure, void>> addCryptoWallet(String walletAddress) async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      await remoteDataSource.addCryptoWallet(walletAddress);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> removeCryptoWallet(String walletAddress) async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      await remoteDataSource.removeCryptoWallet(walletAddress);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> setupMoralisStream() async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final result = await remoteDataSource.setupMoralisStream();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> cleanupUserCrypto() async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      await remoteDataSource.cleanupUserCrypto();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  // ===========================================================================
  // STOCKS (FMP)
  // ===========================================================================

  @override
  Future<Either<Failure, List<dynamic>>> searchStocks(String query) async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final results = await remoteDataSource.searchStocks(query);
      return Right(results);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> addStock(
      String symbol, double quantity) async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final result = await remoteDataSource.addStock(symbol, quantity);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateStockPrices() async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final result = await remoteDataSource.updateStockPrices();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> removeStock(String assetId) async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      await remoteDataSource.removeStock(assetId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  // ===========================================================================
  // BANKING (PLAID)
  // ===========================================================================

  @override
  Future<Either<Failure, Map<String, dynamic>>> getPlaidLinkToken() async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final result = await remoteDataSource.getPlaidLinkToken();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> exchangePlaidToken(
      String publicToken) async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final result = await remoteDataSource.exchangePlaidToken(publicToken);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> syncBankAccounts() async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final result = await remoteDataSource.syncBankAccounts();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getBankAccounts(
      String itemId) async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final result = await remoteDataSource.getBankAccounts(itemId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> removeBankConnection(String itemId) async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      await remoteDataSource.removeBankConnection(itemId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  // ===========================================================================
  // UNIFIED NETWORTH & INSIGHTS
  // ===========================================================================

  @override
  Future<Either<Failure, NetworthResponse>> getNetworth(
      {bool forceRefresh = false}) async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final result = await remoteDataSource.getNetworth(forceRefresh: forceRefresh);
      return Right(result.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDailyChange() async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final result = await remoteDataSource.getDailyChange();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> recordWealthSnapshot() async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final result = await remoteDataSource.recordWealthSnapshot();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  // ===========================================================================
  // WEALTH HISTORY
  // ===========================================================================

  @override
  Future<Either<Failure, List<WealthSnapshot>>> getWealthHistory(
      {int? limit}) async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final snapshots = await remoteDataSource.getWealthHistory(limit: limit);
      return Right(snapshots.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOldSnapshots() async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      await remoteDataSource.deleteOldSnapshots();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  // ===========================================================================
  // PORTFOLIO INSIGHTS
  // ===========================================================================

  @override
  Future<Either<Failure, Map<String, dynamic>>> getPortfolioInsights() async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final result = await remoteDataSource.getPortfolioInsights();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  // ===========================================================================
  // MANUAL ASSETS
  // ===========================================================================

  @override
  Future<Either<Failure, String>> addManualAsset({
    required String name,
    required AssetType type,
    required double amount,
    String? currency,
    String? sector,
    String? country,
  }) async {
    try {
      final assetId = await remoteDataSource.addManualAsset(
        name: name,
        type: type,
        amount: amount,
        currency: currency,
        sector: sector,
        country: country,
      );
      return Right(assetId);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  // ===========================================================================
  // ASSET REMINDERS
  // ===========================================================================

  @override
  Future<Either<Failure, void>> addAssetReminder({
    required String assetId,
    required String title,
    required String rruleExpression,
    required DateTime nextEventDate,
    double? amountExpected,
  }) async {
    try {
      await remoteDataSource.addAssetReminder(
        assetId: assetId,
        title: title,
        rruleExpression: rruleExpression,
        nextEventDate: nextEventDate,
        amountExpected: amountExpected,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  // ===========================================================================
  // ASSET PAYOUTS
  // ===========================================================================

  @override
  Future<Either<Failure, AssetPayoutSummary>> getAssetPayoutSummary(String assetId) async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final summary = await remoteDataSource.getAssetPayoutSummary(assetId);
      return Right(summary);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch payout summary: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<AssetPayout>>> getAssetPayouts(String assetId) async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final payouts = await remoteDataSource.getAssetPayouts(assetId);
      return Right(payouts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch payouts: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> markReminderAsReceived({
    required String reminderId,
    required String assetId,
    required double amount,
    required DateTime payoutDate,
    String? notes,
  }) async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      await remoteDataSource.markReminderAsReceived(
        reminderId: reminderId,
        assetId: assetId,
        amount: amount,
        payoutDate: payoutDate,
        notes: notes,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to mark reminder as received: ${e.toString()}'));
    }
  }

  // ===========================================================================
  // ASSET DETAILS (Edge Functions)
  // ===========================================================================

  @override
  Future<Either<Failure, CryptoWalletDetail>> getCryptoWalletDetails({
    required String address,
    String chain = 'eth',
  }) async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final detail = await remoteDataSource.getCryptoWalletDetails(
        address: address,
        chain: chain,
      );
      return Right(detail);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch crypto wallet details: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, StockDetail>> getStockDetails({
    required String symbol,
    required String userId,
    String timeframe = '1hour',
  }) async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final detail = await remoteDataSource.getStockDetails(
        symbol: symbol,
        userId: userId,
        timeframe: timeframe,
      );
      return Right(detail);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch stock details: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BankAccountDetail>> getBankAccountDetails({
    required String itemId,
    required String accountId,
    required String userId,
  }) async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final detail = await remoteDataSource.getBankAccountDetails(
        itemId: itemId,
        accountId: accountId,
        userId: userId,
      );
      return Right(detail);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch bank account details: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ManualAssetDetail>> getManualAssetDetails({
    required String assetId,
    required String userId,
  }) async {
    if (!await _isOnline()) {
      return const Left(OfflineFailure('No internet connection. Please check your network.'));
    }
    try {
      final detail = await remoteDataSource.getManualAssetDetails(
        assetId: assetId,
        userId: userId,
      );
      return Right(detail);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch manual asset details: ${e.toString()}'));
    }
  }
}
