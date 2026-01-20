import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for manually syncing all assets
///
/// Triggers a manual refresh of asset data and records a wealth snapshot.
/// Useful for pull-to-refresh functionality.
class SyncAssetsUseCase implements UseCase<void, NoParams> {
  final FinanceRepository repository;

  SyncAssetsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.syncAssets();
  }
}
