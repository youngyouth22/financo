import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for adding a stock to portfolio
class AddStockUseCase implements UseCase<Map<String, dynamic>, AddStockParams> {
  final FinanceRepository repository;

  AddStockUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(AddStockParams params) {
    return repository.addStock(params.symbol, params.quantity);
  }
}

class AddStockParams extends Equatable {
  final String symbol;
  final double quantity;

  const AddStockParams({
    required this.symbol,
    required this.quantity,
  });

  @override
  List<Object?> get props => [symbol, quantity];
}
