import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecases/usecase.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for updating asset quantity
class UpdateAssetQuantityUseCase implements UseCase<void, UpdateAssetQuantityParams> {
  final FinanceRepository repository;

  UpdateAssetQuantityUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateAssetQuantityParams params) {
    return repository.updateAssetQuantity(params.assetId, params.newQuantity);
  }
}

class UpdateAssetQuantityParams extends Equatable {
  final String assetId;
  final double newQuantity;

  const UpdateAssetQuantityParams({
    required this.assetId,
    required this.newQuantity,
  });

  @override
  List<Object?> get props => [assetId, newQuantity];
}
