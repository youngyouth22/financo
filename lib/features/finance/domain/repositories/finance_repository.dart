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
  Future<Either<Failure, List<WealthSnapshot>>> getWealthHistory({int? limit});

  /// Calculate current net worth
  ///
  /// Returns [Right(double)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, double>> calculateNetWorth();

  /// Stream of real-time asset updates
  ///
  /// Returns a stream that emits [Right(List<Asset>)] on updates
  /// or [Left(Failure)] on errors
  Stream<Either<Failure, List<Asset>>> watchAssets();

  /// Add crypto wallet to Moralis stream
  ///
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> addCryptoWallet(String walletAddress);

  /// Remove crypto wallet from Moralis stream
  ///
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> removeCryptoWallet(String walletAddress);

  /// Get Plaid link token for bank account connection
  ///
  /// Returns [Right(String)] link token on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, String>> getPlaidLinkToken();

  /// Exchange Plaid public token for access token
  ///
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> exchangePlaidToken(
    String publicToken,
    Map<String, dynamic> metadata,
  );
}
