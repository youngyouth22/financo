import 'package:equatable/equatable.dart';
import 'package:financo/features/finance/domain/entities/networth_response.dart';

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
  final NetworthResponse networth;

  const InsightsLoaded(this.networth);

  @override
  List<Object?> get props => [networth];
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
