import 'package:equatable/equatable.dart';

/// Events for InsightsBloc
/// 
/// Handles GenUI strategy generation and risk analysis
abstract class InsightsEvent extends Equatable {
  const InsightsEvent();

  @override
  List<Object?> get props => [];
}

/// Load portfolio insights
class LoadInsightsEvent extends InsightsEvent {
  const LoadInsightsEvent();
}

/// Refresh insights
class RefreshInsightsEvent extends InsightsEvent {
  const RefreshInsightsEvent();
}

/// Generate AI strategy recommendations
class GenerateStrategyEvent extends InsightsEvent {
  const GenerateStrategyEvent();
}
