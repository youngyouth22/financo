import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';
import 'package:financo/features/finance/domain/entities/global_wealth.dart';
import 'package:financo/features/finance/domain/entities/wealth_snapshot.dart';

/// Abstract repository interface for finance operations
///
/// Defines the contract for finance-related operations in the domain layer.
/// Returns Either<Failure, Success> for proper error handling using Dartz.
abstract class FinanceRepository {
  /// Get all assets for the current user
  ///
  /// Returns [Right(List<Asset>)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, List<Asset>>> getAssets();

  /// Get a specific asset by ID
  ///
  /// Returns [Right(Asset)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, Asset>> getAssetById(String assetId);

  /// Add a new asset
  ///
  /// Returns [Right(Asset)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, Asset>> addAsset({
    required String name,
    required AssetType type,
    required AssetGroup assetGroup,
    required AssetProvider provider,
    required String assetAddressOrId,
    double initialBalance = 0.0,
  });

  /// Update an existing asset
  ///
  /// Returns [Right(Asset)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, Asset>> updateAsset(Asset asset);

  /// Delete an asset
  ///
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> deleteAsset(String assetId);

  /// Get global wealth (all assets aggregated)
  ///
  /// Returns [Right(GlobalWealth)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, GlobalWealth>> getGlobalWealth();

  /// Get wealth history for charts
  ///
  /// Returns [Right(List<WealthSnapshot>)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, List<WealthSnapshot>>> getWealthHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });

  /// Calculate current net worth
  ///
  /// Returns [Right(double)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, double>> calculateNetWorth();

  /// Record a wealth snapshot
  ///
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> recordWealthSnapshot();

  /// Stream of real-time asset updates
  ///
  /// Returns a stream that emits [Right(List<Asset>)] on updates
  /// or [Left(Failure)] on errors
  Stream<Either<Failure, List<Asset>>> watchAssets();

  /// Add wallet address to Moralis stream
  ///
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> addWalletToStream(String walletAddress);

  /// Remove wallet address from Moralis stream
  ///
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> removeWalletFromStream(String walletAddress);

  /// Setup Moralis stream (idempotent)
  ///
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> setupMoralisStream();

  /// Cleanup user's crypto assets on account deletion
  ///
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> cleanupUserCryptoAssets();

  /// Sync all assets (trigger manual refresh)
  ///
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> syncAssets();
}
