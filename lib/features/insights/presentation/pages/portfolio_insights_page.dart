import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/common/widgets/shimmer/insights_shimmer.dart';
import 'package:financo/common/widgets/empty_states/error_state.dart';
import 'package:financo/common/widgets/empty_states/no_connection_state.dart';
import 'package:financo/features/insights/presentation/bloc/insights_bloc.dart';
import 'package:financo/features/insights/presentation/bloc/insights_event.dart';
import 'package:financo/features/insights/presentation/bloc/insights_state.dart';
import 'package:financo/features/insights/presentation/widgets/asset_allocation_tab.dart';
import 'package:financo/features/insights/presentation/widgets/diversification_tab.dart';
import 'package:financo/features/insights/presentation/widgets/risk_strategy_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PortfolioInsightsPage extends StatefulWidget {
  const PortfolioInsightsPage({super.key});

  @override
  State<PortfolioInsightsPage> createState() => _PortfolioInsightsPageState();
}

class _PortfolioInsightsPageState extends State<PortfolioInsightsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // CRITICAL FIX: Trigger the data load when entering the page
    // This ensures the Bloc starts fetching the networth and insights.
    context.read<InsightsBloc>().add(const LoadInsightsEvent());

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- UI COMPONENTS ---

  List<Tab> get tabs => [
    _buildTab(0, 'Allocation', Icons.pie_chart_rounded),
    _buildTab(1, 'Exposure', Icons.public_rounded),
    _buildTab(2, 'Strategy', Icons.psychology_rounded),
  ];

  Tab _buildTab(int index, String label, IconData iconData) {
    bool selected = _tabController.index == index;
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            color: selected ? AppColors.accent : AppColors.gray20,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.headline2Regular.copyWith(
              color: selected ? AppColors.accent : AppColors.gray20,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('Portfolio Insights'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.accent,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              tabs: tabs,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<InsightsBloc, InsightsState>(
          builder: (context, state) {
            // If data is loaded, show the tabs
            if (state is InsightsLoaded) {
              // Use networth data which includes insights
              final networth = state.networth;
              return TabBarView(
                controller: _tabController,
                children: [
                  AssetAllocationTab(networth: networth),
                  DiversificationTab(networth: networth),
                  const RiskStrategyTab(),
                ],
              );
            }

            // If an error occurs, show the error message
            if (state is InsightsError) {
              // Check if it's a connectivity error
              final message = state.message.toLowerCase();
              if (message.contains('connection') ||
                  message.contains('network') ||
                  message.contains('offline')) {
                return NoConnectionState(
                  onRetry: () => context.read<InsightsBloc>().add(
                    const LoadInsightsEvent(),
                  ),
                );
              }

              return ErrorState(
                title: 'Unable to Load Insights',
                message: state.message,
                onRetry: () =>
                    context.read<InsightsBloc>().add(const LoadInsightsEvent()),
              );
            }

            // Show the shimmer while waiting for data
            return const InsightsShimmer();
          },
        ),
      ),
    );
  }
}
