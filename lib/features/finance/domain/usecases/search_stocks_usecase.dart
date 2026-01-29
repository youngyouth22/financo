import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for searching stocks via FMP API
class SearchStocksUseCase implements UseCase<List<dynamic>, SearchStocksParams> {
  final FinanceRepository repository;

  SearchStocksUseCase(this.repository);

  @override
  Future<Either<Failure, List<dynamic>>> call(SearchStocksParams params) {
    return repository.searchStocks(params.query);
  }
}

class SearchStocksParams extends Equatable {
  final String query;

  const SearchStocksParams({required this.query});

  @override
  List<Object?> get props => [query];
}
