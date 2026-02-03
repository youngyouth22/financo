import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecases/usecase.dart';
import 'package:financo/features/finance/domain/entities/manual_asset_detail.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for fetching detailed manual asset information
class GetManualAssetDetailsUseCase
    implements UseCase<ManualAssetDetail, ManualAssetDetailsParams> {
  final FinanceRepository repository;

  GetManualAssetDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, ManualAssetDetail>> call(
    ManualAssetDetailsParams params,
  ) async {
    return await repository.getManualAssetDetails(
      assetId: params.assetId,
      userId: params.userId,
    );
  }
}

/// Parameters for GetManualAssetDetailsUseCase
class ManualAssetDetailsParams extends Equatable {
  final String assetId;
  final String userId;

  const ManualAssetDetailsParams({
    required this.assetId,
    required this.userId,
  });

  @override
  List<Object?> get props => [assetId, userId];
}
