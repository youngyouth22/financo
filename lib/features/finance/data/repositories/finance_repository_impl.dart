import 'package:dartz/dartz.dart';
import 'package:financo/core/error/exceptions.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/features/finance/data/datasources/finance_remote_datasource.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';
import 'package:financo/features/finance/domain/entities/global_wealth.dart';
import 'package:financo/features/finance/domain/entities/wealth_snapshot.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Implementation of FinanceRepository
///
/// Handles data operations and error mapping from data layer to domain layer.
class FinanceRepositoryImpl implements FinanceRepository {
  final FinanceRemoteDataSource remoteDataSource;

  FinanceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Asset>>> getAssets() async {
    try {
      final assetModels = await remoteDataSource.getAssets();
      final assets = assetModels.map((model) => model.toEntity()).toList();
      return Right(assets);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAsset(String assetId) async {
    try {
      await remoteDataSource.deleteAsset(assetId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, GlobalWealth>> getGlobalWealth() async {
    try {
      final assetModels = await remoteDataSource.getAssets();
      final assets = assetModels.map((model) => model.toEntity()).toList();

      final globalWealth = GlobalWealth(
        assets: assets,
        lastUpdated: DateTime.now(),
      );

      return Right(globalWealth);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<WealthSnapshot>>> getWealthHistory({
    int? limit,
  }) async {
    try {
      final snapshotModels = await remoteDataSource.getWealthHistory(
        limit: limit,
      );

      final snapshots = snapshotModels
          .map((model) => model.toEntity())
          .toList();

      return Right(snapshots);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> calculateNetWorth() async {
    try {
      final netWorth = await remoteDataSource.calculateNetWorth();
      return Right(netWorth);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Stream<Either<Failure, List<Asset>>> watchAssets() {
    try {
      return remoteDataSource
          .watchAssets()
          .map((assetModels) {
            final assets = assetModels
                .map((model) => model.toEntity())
                .toList();
            return Right<Failure, List<Asset>>(assets);
          })
          .handleError((error) {
            if (error is ServerException) {
              return Left<Failure, List<Asset>>(ServerFailure(error.message));
            }
            return Left<Failure, List<Asset>>(
              ServerFailure('Unexpected error: $error'),
            );
          });
    } catch (e) {
      return Stream.value(Left(ServerFailure('Failed to watch assets: $e')));
    }
  }

  @override
  Future<Either<Failure, void>> addCryptoWallet(String walletAddress) async {
    try {
      await remoteDataSource.addCryptoWallet(walletAddress);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> removeCryptoWallet(String walletAddress) async {
    try {
      await remoteDataSource.removeCryptoWallet(walletAddress);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> getPlaidLinkToken() async {
    try {
      final linkToken = await remoteDataSource.getPlaidLinkToken();
      return Right(linkToken);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> exchangePlaidToken(
    String publicToken,
    Map<String, dynamic> metadata,
  ) async {
    try {
      await remoteDataSource.exchangePlaidToken(publicToken, metadata);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
