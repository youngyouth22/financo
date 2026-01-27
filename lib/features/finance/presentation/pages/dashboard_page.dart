import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/di/injection_container.dart';
import 'package:financo/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:financo/features/finance/presentation/bloc/finance_event.dart';
import 'package:financo/features/finance/presentation/bloc/finance_state.dart';
import 'package:financo/features/finance/presentation/widgets/asset_group_card.dart';
import 'package:financo/features/finance/presentation/widgets/breakdown_tab.dart';
import 'package:financo/features/finance/presentation/widgets/circular_wealth_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Dashboard page displaying user's financial portfolio
///
/// Features:
/// - Circular arcs showing asset group allocation
/// - Animated net worth display
/// - Three cards for Crypto, Stocks & ETFs, Cash & Banks
/// - Tab switcher: Assets overview | Breakdown
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<FinanceBloc>()
        ..add(const LoadGlobalWealthEvent())
        ..add(const WatchAssetsEvent()),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Tab Bar
              _buildTabBar(),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAssetsOverviewTab(),
                    const BreakdownTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build header with title
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            'Dashboard',
            style: AppTypography.headline5Bold.copyWith(
              color: AppColors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // Refresh data
              // context.read<FinanceBloc>().add(const SyncAssetsEvent());
            },
            icon: Icon(
              Icons.refresh,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Build tab bar
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.gray80,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.gray40,
        labelStyle: AppTypography.headline2SemiBold,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Assets overview'),
          Tab(text: 'Breakdown'),
        ],
      ),
    );
  }

  /// Build assets overview tab
  Widget _buildAssetsOverviewTab() {
    return BlocBuilder<FinanceBloc, FinanceState>(
      builder: (context, state) {
        if (state is FinanceLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        if (state is FinanceError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading data',
                  style: AppTypography.headline4Bold.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: AppTypography.headline2Regular.copyWith(
                    color: AppColors.gray40,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (state is GlobalWealthLoaded) {
          final wealth = state.globalWealth;
          
          if (!wealth.hasAssets) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Circular wealth indicator
                CircularWealthIndicator(
                  netWorth: wealth.netWorth,
                  cryptoPercentage: wealth.cryptoPercentage,
                  stocksPercentage: wealth.stocksPercentage,
                  cashPercentage: wealth.cashPercentage,
                ),
                
                const SizedBox(height: 32),
                
                // Asset group cards
                AssetGroupCard(
                  title: 'Crypto',
                  amount: wealth.totalCryptoBalance,
                  percentage: wealth.cryptoPercentage,
                  assetCount: wealth.cryptoAssetCount,
                  color: AppColors.primary,
                  icon: Icons.currency_bitcoin,
                ),
                
                const SizedBox(height: 16),
                
                AssetGroupCard(
                  title: 'Stocks & ETFs',
                  amount: wealth.totalStocksBalance,
                  percentage: wealth.stocksPercentage,
                  assetCount: wealth.stocksAssetCount,
                  color: AppColors.accent,
                  icon: Icons.trending_up,
                ),
                
                const SizedBox(height: 16),
                
                AssetGroupCard(
                  title: 'Cash & Banks',
                  amount: wealth.totalCashBalance,
                  percentage: wealth.cashPercentage,
                  assetCount: wealth.cashAssetCount,
                  color: AppColors.accentS,
                  icon: Icons.account_balance,
                ),
              ],
            ),
          );
        }

        return _buildEmptyState();
      },
    );
  }

  /// Build empty state when no assets
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: AppColors.gray60,
          ),
          const SizedBox(height: 24),
          Text(
            'No assets yet',
            style: AppTypography.headline4Bold.copyWith(
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first crypto wallet or bank account',
            style: AppTypography.headline2Regular.copyWith(
              color: AppColors.gray40,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
