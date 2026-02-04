import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/entities/asset_payout.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for getting all payouts for a specific asset
///
/// Returns list of payouts ordered by date (most recent first)
class GetAssetPayoutsUseCase implements UseCase<List<AssetPayout>, String> {
  final FinanceRepository repository;

  GetAssetPayoutsUseCase(this.repository);

  @override
  Future<Either<Failure, List<AssetPayout>>> call(String assetId) async {
    return await repository.getAssetPayouts(assetId);
  }
}
