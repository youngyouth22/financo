import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for getting portfolio insights
/// 
/// Returns insights including sector exposure, geographic distribution,
/// risk analysis, and AI-generated recommendations
class GetPortfolioInsightsUseCase implements UseCase<Map<String, dynamic>, NoParams> {
  final FinanceRepository repository;

  GetPortfolioInsightsUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(NoParams params) {
    return repository.getPortfolioInsights();
  }
}
