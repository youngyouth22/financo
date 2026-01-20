import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/entities/wealth_snapshot.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for retrieving wealth history for charts and analytics
///
/// Returns time-series data of wealth snapshots for visualization.
class GetWealthHistoryUseCase
    implements UseCase<List<WealthSnapshot>, GetWealthHistoryParams> {
  final FinanceRepository repository;

  GetWealthHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<WealthSnapshot>>> call(
    GetWealthHistoryParams params,
  ) async {
    return await repository.getWealthHistory(
      startDate: params.startDate,
      endDate: params.endDate,
      limit: params.limit,
    );
  }
}

/// Parameters for GetWealthHistoryUseCase
class GetWealthHistoryParams extends Equatable {
  /// Start date for history range (optional)
  final DateTime? startDate;

  /// End date for history range (optional)
  final DateTime? endDate;

  /// Maximum number of snapshots to return (optional)
  final int? limit;

  const GetWealthHistoryParams({
    this.startDate,
    this.endDate,
    this.limit,
  });

  /// Get history for the last 7 days
  factory GetWealthHistoryParams.last7Days() {
    return GetWealthHistoryParams(
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now(),
    );
  }

  /// Get history for the last 30 days
  factory GetWealthHistoryParams.last30Days() {
    return GetWealthHistoryParams(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );
  }

  /// Get history for the last 90 days
  factory GetWealthHistoryParams.last90Days() {
    return GetWealthHistoryParams(
      startDate: DateTime.now().subtract(const Duration(days: 90)),
      endDate: DateTime.now(),
    );
  }

  /// Get history for the last year
  factory GetWealthHistoryParams.lastYear() {
    return GetWealthHistoryParams(
      startDate: DateTime.now().subtract(const Duration(days: 365)),
      endDate: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [startDate, endDate, limit];
}
