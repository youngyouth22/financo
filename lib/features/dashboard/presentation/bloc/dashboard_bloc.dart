import 'package:bloc/bloc.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:financo/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:financo/features/finance/domain/usecases/get_daily_change_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_networth_usecase.dart';

/// BLoC for Dashboard
/// 
/// Handles total networth and global portfolio overview
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetNetworthUseCase getNetworthUseCase;
  final GetDailyChangeUseCase getDailyChangeUseCase;

  DashboardBloc({
    required this.getNetworthUseCase,
    required this.getDailyChangeUseCase,
  }) : super(const DashboardInitial()) {
    on<LoadDashboardEvent>(_onLoadDashboard);
    on<RefreshDashboardEvent>(_onRefreshDashboard);
    on<GetDailyChangeEvent>(_onGetDailyChange);
  }

  /// Load dashboard data
  Future<void> _onLoadDashboard(
    LoadDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());

    final result = await getNetworthUseCase.call();

    result.fold(
      (failure) {
        final isOffline = failure is OfflineFailure;
        emit(DashboardError(failure.message, isOffline: isOffline));
      },
      (networth) => emit(NetworthLoaded(networth)),
    );
  }

  /// Refresh dashboard data
  Future<void> _onRefreshDashboard(
    RefreshDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    // Don't show loading for refresh
    final result = await getNetworthUseCase.call();

    result.fold(
      (failure) {
        final isOffline = failure is OfflineFailure;
        emit(DashboardError(failure.message, isOffline: isOffline));
      },
      (networth) => emit(NetworthLoaded(networth)),
    );
  }

  /// Get daily change
  Future<void> _onGetDailyChange(
    GetDailyChangeEvent event,
    Emitter<DashboardState> emit,
  ) async {
    final result = await getDailyChangeUseCase.call(const NoParams());

    result.fold(
      (failure) {
        final isOffline = failure is OfflineFailure;
        emit(DashboardError(failure.message, isOffline: isOffline));
      },
      (change) => emit(DailyChangeLoaded(
        changeAmount: change['amount'] as double,
        changePercentage: change['percentage'] as double,
      )),
    );
  }
}
