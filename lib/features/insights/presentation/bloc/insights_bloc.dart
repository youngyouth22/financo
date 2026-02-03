import 'package:bloc/bloc.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/insights/presentation/bloc/insights_event.dart';
import 'package:financo/features/insights/presentation/bloc/insights_state.dart';
import 'package:financo/features/finance/domain/usecases/get_portfolio_insights_usecase.dart';

/// BLoC for Insights
/// 
/// Handles GenUI strategy generation and risk analysis
/// (Geographic/Sector exposure)
class InsightsBloc extends Bloc<InsightsEvent, InsightsState> {
  final GetPortfolioInsightsUseCase getPortfolioInsightsUseCase;

  InsightsBloc({
    required this.getPortfolioInsightsUseCase,
  }) : super(const InsightsInitial()) {
    on<LoadInsightsEvent>(_onLoadInsights);
    on<RefreshInsightsEvent>(_onRefreshInsights);
    on<GenerateStrategyEvent>(_onGenerateStrategy);
  }

  /// Load portfolio insights
  Future<void> _onLoadInsights(
    LoadInsightsEvent event,
    Emitter<InsightsState> emit,
  ) async {
    emit(const InsightsLoading());

    final result = await getPortfolioInsightsUseCase.call(const NoParams());

    result.fold(
      (failure) {
        final isOffline = failure is OfflineFailure;
        emit(InsightsError(failure.message, isOffline: isOffline));
      },
      (insights) => emit(InsightsLoaded(insights)),
    );
  }

  /// Refresh insights
  Future<void> _onRefreshInsights(
    RefreshInsightsEvent event,
    Emitter<InsightsState> emit,
  ) async {
    // Don't show loading for refresh
    final result = await getPortfolioInsightsUseCase.call(const NoParams());

    result.fold(
      (failure) {
        final isOffline = failure is OfflineFailure;
        emit(InsightsError(failure.message, isOffline: isOffline));
      },
      (insights) => emit(InsightsLoaded(insights)),
    );
  }

  /// Generate AI strategy recommendations
  Future<void> _onGenerateStrategy(
    GenerateStrategyEvent event,
    Emitter<InsightsState> emit,
  ) async {
    emit(const InsightsLoading());

    // TODO: Implement GenUI strategy generation
    // This will call a use case that uses GenUI to analyze the portfolio
    // and generate personalized recommendations

    // For now, return mock data
    emit(const StrategyGenerated(
      strategy: 'Diversification Strategy',
      recommendations: [
        'Consider reducing US exposure to below 50%',
        'Add emerging market exposure for growth',
        'Increase commodity allocation for inflation hedge',
      ],
    ));
  }
}
