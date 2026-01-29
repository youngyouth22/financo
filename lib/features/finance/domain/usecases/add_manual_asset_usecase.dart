import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for adding a manual asset
///
/// Manual assets include:
/// - Real estate
/// - Commodities (gold, silver, etc.)
/// - Liabilities (loans, mortgages)
/// - Other assets not tracked via APIs
class AddManualAssetUseCase implements UseCase<void, AddManualAssetParams> {
  final FinanceRepository repository;

  AddManualAssetUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddManualAssetParams params) async {
    return await repository.addManualAsset(
      name: params.name,
      type: params.type,
      amount: params.amount,
      currency: params.currency,
      sector: params.sector,
      country: params.country,
    );
  }
}

/// Parameters for AddManualAssetUseCase
class AddManualAssetParams {
  final String name;
  final AssetType type;
  final double amount;
  final String? currency;
  final String? sector;
  final String? country;

  const AddManualAssetParams({
    required this.name,
    required this.type,
    required this.amount,
    this.currency,
    this.sector,
    this.country,
  });
}
