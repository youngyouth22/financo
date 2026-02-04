import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/entities/asset_payout.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for getting payout summary of a manual asset
///
/// Returns summary including:
/// - Total expected value
/// - Total received amount
/// - Remaining balance
/// - Payout count
/// - Last payout date
class GetAssetPayoutSummaryUseCase implements UseCase<AssetPayoutSummary, String> {
  final FinanceRepository repository;

  GetAssetPayoutSummaryUseCase(this.repository);

  @override
  Future<Either<Failure, AssetPayoutSummary>> call(String assetId) async {
    return await repository.getAssetPayoutSummary(assetId);
  }
}
