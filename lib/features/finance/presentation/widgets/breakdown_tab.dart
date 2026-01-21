import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:financo/features/finance/presentation/bloc/finance_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Breakdown tab showing textual breakdown by asset group
///
/// Displays for each group:
/// - Group name
/// - Total value
/// - Percentage of Net Worth
/// - Number of assets
class BreakdownTab extends StatelessWidget {
  const BreakdownTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinanceBloc, FinanceState>(
      builder: (context, state) {
        if (state is GlobalWealthLoaded) {
          final wealth = state.globalWealth;

          if (!wealth.hasAssets) {
            return _buildEmptyState();
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Text(
                'Asset Breakdown',
                style: AppTypography.headline4Bold.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Detailed view of your portfolio allocation',
                style: AppTypography.headline2Regular.copyWith(
                  color: AppColors.gray40,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Crypto breakdown
              _buildBreakdownItem(
                title: 'Crypto',
                amount: wealth.totalCryptoBalance,
                percentage: wealth.cryptoPercentage,
                assetCount: wealth.cryptoAssetCount,
                color: AppColors.primary,
                icon: Icons.currency_bitcoin,
              ),
              
              const SizedBox(height: 16),
              
              // Stocks breakdown
              _buildBreakdownItem(
                title: 'Stocks & ETFs',
                amount: wealth.totalStocksBalance,
                percentage: wealth.stocksPercentage,
                assetCount: wealth.stocksAssetCount,
                color: AppColors.accent,
                icon: Icons.trending_up,
              ),
              
              const SizedBox(height: 16),
              
              // Cash breakdown
              _buildBreakdownItem(
                title: 'Cash & Banks',
                amount: wealth.totalCashBalance,
                percentage: wealth.cashPercentage,
                assetCount: wealth.cashAssetCount,
                color: AppColors.accentS,
                icon: Icons.account_balance,
              ),
              
              const SizedBox(height: 32),
              
              // Total summary
              _buildTotalSummary(wealth.netWorth, wealth.totalAssetCount),
            ],
          );
        }

        return _buildEmptyState();
      },
    );
  }

  /// Build breakdown item
  Widget _buildBreakdownItem({
    required String title,
    required double amount,
    required double percentage,
    required int assetCount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gray70,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTypography.headline3Bold.copyWith(
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Amount
          Text(
            _formatCurrency(amount),
            style: AppTypography.headline5Bold.copyWith(
              color: color,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Percentage and asset count
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: AppTypography.headline1SemiBold.copyWith(
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$assetCount ${assetCount == 1 ? 'asset' : 'assets'}',
                style: AppTypography.headline2Regular.copyWith(
                  color: AppColors.gray40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build total summary
  Widget _buildTotalSummary(double totalAmount, int totalAssets) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Net Worth',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(totalAmount),
            style: AppTypography.headline5Bold.copyWith(
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Across $totalAssets ${totalAssets == 1 ? 'asset' : 'assets'}',
            style: AppTypography.headline2Regular.copyWith(
              color: AppColors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 80,
            color: AppColors.gray60,
          ),
          const SizedBox(height: 24),
          Text(
            'No breakdown available',
            style: AppTypography.headline4Bold.copyWith(
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add assets to see your portfolio breakdown',
            style: AppTypography.headline2Regular.copyWith(
              color: AppColors.gray40,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Format currency
  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(2)}K';
    } else {
      return '\$${value.toStringAsFixed(2)}';
    }
  }
}
