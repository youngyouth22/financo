import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for watching real-time asset updates
///
/// Returns a stream that emits asset lists whenever changes occur in Supabase.
/// This enables automatic UI updates without manual refresh.
class WatchAssetsUseCase {
  final FinanceRepository repository;

  WatchAssetsUseCase(this.repository);

  /// Execute the use case
  ///
  /// Returns a stream of Either<Failure, List<Asset>>
  Stream<Either<Failure, List<Asset>>> call() {
    return repository.watchAssets();
  }
}
