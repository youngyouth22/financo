import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/features/insights/presentation/widgets/asset_allocation_tab.dart';
import 'package:financo/features/insights/presentation/widgets/diversification_tab.dart';
import 'package:financo/features/insights/presentation/widgets/risk_strategy_tab.dart';
import 'package:flutter/material.dart';

/// Premium Portfolio Insights Page with 3 tabs
///
/// Tab 1: Asset Allocation (The Big Picture)
/// Tab 2: Diversification & Exposure
/// Tab 3: Risk & Strategy (The Premium Brain)
///
/// Features:
/// - Interactive charts (Pie, Bar)
/// - Geographic exposure map
/// - Risk indicators and gauges
/// - AI Strategic Insights
/// - Professional fintech design
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
    _tabController.addListener(() {
      setState(() {}); // Refresh tab indicator
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget customTabBar({
    required String text,
    IconData? iconData,
    String? icon,
    required bool selected,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (iconData != null)
          Icon(
            iconData,
            color: selected ? AppColors.accent : AppColors.gray20,
            size: 18,
          ),
        if (iconData != null) const SizedBox(width: 6),
        Text(
          text,
          style: AppTypography.headline2Regular.copyWith(
            color: selected ? AppColors.accent : AppColors.gray20,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  List<Tab> get tabs => [
        _buildTab(0, 'Allocation', Icons.pie_chart_rounded),
        _buildTab(1, 'Exposure', Icons.public_rounded),
        _buildTab(2, 'Strategy', Icons.psychology_rounded),
      ];

  Tab _buildTab(int index, String label, IconData iconData) {
    return Tab(
      child: customTabBar(
        text: label,
        iconData: iconData,
        selected: _tabController.index == index,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfolio Insights',
              style: AppTypography.headline3Bold.copyWith(
                color: AppColors.white,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '360° Vision of Your Wealth',
              style: AppTypography.headline2Regular.copyWith(
                color: AppColors.gray40,
                fontSize: 13,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                  indicatorColor: AppColors.accent,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: Colors.transparent,
                  tabs: tabs,
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AssetAllocationTab(),
          DiversificationTab(),
          RiskStrategyTab(),
        ],
      ),
    );
  }
}
