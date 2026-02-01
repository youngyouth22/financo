import 'package:equatable/equatable.dart';

/// States for InsightsBloc
abstract class InsightsState extends Equatable {
  const InsightsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class InsightsInitial extends InsightsState {
  const InsightsInitial();
}

/// Loading state
class InsightsLoading extends InsightsState {
  const InsightsLoading();
}

/// Insights loaded successfully
class InsightsLoaded extends InsightsState {
  final Map<String, dynamic> insights;

  const InsightsLoaded(this.insights);

  @override
  List<Object?> get props => [insights];
}

/// Strategy generated successfully
class StrategyGenerated extends InsightsState {
  final String strategy;
  final List<String> recommendations;

  const StrategyGenerated({
    required this.strategy,
    required this.recommendations,
  });

  @override
  List<Object?> get props => [strategy, recommendations];
}

/// Error state
class InsightsError extends InsightsState {
  final String message;
  final bool isOffline;

  const InsightsError(this.message, {this.isOffline = false});

  @override
  List<Object?> get props => [message, isOffline];
}
