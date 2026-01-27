import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/features/finance/domain/entities/networth_response.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for getting unified networth
class GetNetworthUseCase {
  final FinanceRepository repository;

  GetNetworthUseCase(this.repository);

  Future<Either<Failure, NetworthResponse>> call({bool forceRefresh = false}) {
    return repository.getNetworth(forceRefresh: forceRefresh);
  }
}
