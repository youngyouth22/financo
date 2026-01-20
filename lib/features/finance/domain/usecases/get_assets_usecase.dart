import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for retrieving all user assets
///
/// Returns a list of all assets (crypto and bank accounts) for the current user.
class GetAssetsUseCase implements UseCase<List<Asset>, NoParams> {
  final FinanceRepository repository;

  GetAssetsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Asset>>> call(NoParams params) async {
    return await repository.getAssets();
  }
}
