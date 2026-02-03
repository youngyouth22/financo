import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/entities/networth_response.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for getting portfolio insights
/// 
/// Returns NetworthResponse which includes insights such as sector exposure,
/// geographic distribution, risk analysis, and AI-generated recommendations
class GetPortfolioInsightsUseCase implements UseCase<NetworthResponse, NoParams> {
  final FinanceRepository repository;

  GetPortfolioInsightsUseCase(this.repository);

  @override
  Future<Either<Failure, NetworthResponse>> call(NoParams params) {
    // Use getNetworth which returns complete portfolio data including insights
    return repository.getNetworth(forceRefresh: false);
  }
}
