import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for getting Plaid Link token
class GetPlaidLinkTokenUseCase implements UseCase<Map<String, dynamic>, NoParams> {
  final FinanceRepository repository;

  GetPlaidLinkTokenUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(NoParams params) {
    return repository.getPlaidLinkToken();
  }
}
