import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for calculating the user's current net worth
///
/// Returns the total net worth across all assets in USD.
class GetNetWorthUseCase implements UseCase<double, NoParams> {
  final FinanceRepository repository;

  GetNetWorthUseCase(this.repository);

  @override
  Future<Either<Failure, double>> call(NoParams params) async {
    return await repository.calculateNetWorth();
  }
}
