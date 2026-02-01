import 'package:equatable/equatable.dart';

/// Events for DashboardBloc
/// 
/// Handles total networth and global portfolio overview
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Load global networth and portfolio overview
class LoadDashboardEvent extends DashboardEvent {
  const LoadDashboardEvent();
}

/// Refresh dashboard data
class RefreshDashboardEvent extends DashboardEvent {
  const RefreshDashboardEvent();
}

/// Get daily change in networth
class GetDailyChangeEvent extends DashboardEvent {
  const GetDailyChangeEvent();
}
