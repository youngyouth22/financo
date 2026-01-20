import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/entities/global_wealth.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for retrieving the user's complete financial portfolio
///
/// Returns a GlobalWealth object containing all assets and calculated metrics.
class GetGlobalWealthUseCase implements UseCase<GlobalWealth, NoParams> {
  final FinanceRepository repository;

  GetGlobalWealthUseCase(this.repository);

  @override
  Future<Either<Failure, GlobalWealth>> call(NoParams params) async {
    return await repository.getGlobalWealth();
  }
}
