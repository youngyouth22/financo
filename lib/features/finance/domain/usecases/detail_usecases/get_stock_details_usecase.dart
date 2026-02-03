import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/entities/stock_detail.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for fetching detailed stock information
class GetStockDetailsUseCase
    implements UseCase<StockDetail, StockDetailsParams> {
  final FinanceRepository repository;

  GetStockDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, StockDetail>> call(
    StockDetailsParams params,
  ) async {
    return await repository.getStockDetails(
      symbol: params.symbol,
      userId: params.userId,
      timeframe: params.timeframe,
    );
  }
}

/// Parameters for GetStockDetailsUseCase
class StockDetailsParams extends Equatable {
  final String symbol;
  final String userId;
  final String timeframe;

  const StockDetailsParams({
    required this.symbol,
    required this.userId,
    this.timeframe = '1hour',
  });

  @override
  List<Object?> get props => [symbol, userId, timeframe];
}
