import 'package:equatable/equatable.dart';
import 'package:financo/features/finance/domain/entities/networth_response.dart';

/// States for DashboardBloc
abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// Loading state
class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// Networth loaded successfully
class NetworthLoaded extends DashboardState {
  final NetworthResponse networth;

  const NetworthLoaded(this.networth);

  @override
  List<Object?> get props => [networth];
}

/// Daily change loaded
class DailyChangeLoaded extends DashboardState {
  final double changeAmount;
  final double changePercentage;

  const DailyChangeLoaded({
    required this.changeAmount,
    required this.changePercentage,
  });

  @override
  List<Object?> get props => [changeAmount, changePercentage];
}

/// Error state
class DashboardError extends DashboardState {
  final String message;
  final bool isOffline;

  const DashboardError(this.message, {this.isOffline = false});

  @override
  List<Object?> get props => [message, isOffline];
}
