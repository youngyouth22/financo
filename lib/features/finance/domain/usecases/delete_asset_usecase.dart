import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for deleting an asset from the user's portfolio
///
/// Automatically removes crypto wallets from Moralis stream.
class DeleteAssetUseCase implements UseCase<void, DeleteAssetParams> {
  final FinanceRepository repository;

  DeleteAssetUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteAssetParams params) async {
    return await repository.deleteAsset(params.assetId);
  }
}

/// Parameters for DeleteAssetUseCase
class DeleteAssetParams extends Equatable {
  /// ID of the asset to delete
  final String assetId;

  const DeleteAssetParams({required this.assetId});

  @override
  List<Object?> get props => [assetId];
}
