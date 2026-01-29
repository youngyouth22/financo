import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for exchanging Plaid public token for access token
class ExchangePlaidTokenUseCase implements UseCase<Map<String, dynamic>, ExchangePlaidTokenParams> {
  final FinanceRepository repository;

  ExchangePlaidTokenUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(ExchangePlaidTokenParams params) {
    return repository.exchangePlaidToken(params.publicToken);
  }
}

class ExchangePlaidTokenParams extends Equatable {
  final String publicToken;

  const ExchangePlaidTokenParams({required this.publicToken});

  @override
  List<Object?> get props => [publicToken];
}
