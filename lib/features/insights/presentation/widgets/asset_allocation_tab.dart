import 'package:fl_chart/fl_chart.dart';
import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/features/finance/domain/entities/networth_response.dart';
import 'package:flutter/material.dart';

class AssetAllocationTab extends StatefulWidget {
  final NetworthResponse networth;

  const AssetAllocationTab({super.key, required this.networth});

  @override
  State<AssetAllocationTab> createState() => _AssetAllocationTabState();
}

class _AssetAllocationTabState extends State<AssetAllocationTab> {
  int touchedIndex = -1;

  final Map<String, dynamic> _typeConfig = {
    'crypto': {
      'color': AppColors.primary,
      'icon': Icons.currency_bitcoin_rounded,
      'label': 'Crypto',
      'liquid': true,
    },
    'stock': {
      'color': AppColors.primary500,
      'icon': Icons.trending_up_rounded,
      'label': 'Stocks',
      'liquid': true,
    },
    'cash': {
      'color': AppColors.accentS,
      'icon': Icons.payments_rounded,
      'label': 'Cash',
      'liquid': true,
    },
    'real_estate': {
      'color': AppColors.primary5,
      'icon': Icons.home_rounded,
      'label': 'Real Estate',
      'liquid': false,
    },
    'commodity': {
      'color': const Color(0xFFAD7BFF),
      'icon': Icons.diamond_rounded,
      'label': 'Commodities',
      'liquid': false,
    },
    'investment': {
      'color': const Color(0xFF00B8D9),
      'icon': Icons.account_balance_wallet_rounded,
      'label': 'Investments',
      'liquid': false,
    },
    'liability': {
      'color': AppColors.warning,
      'icon': Icons.credit_card_rounded,
      'label': 'Liabilities',
      'liquid': true,
    },
  };

  List<AssetAllocation> get allocations {
    return widget.networth.breakdown.byType.entries.map((entry) {
      final config =
          _typeConfig[entry.key.toLowerCase()] ?? _typeConfig['other'];
      return AssetAllocation(
        type: config['label'],
        amount: entry.value,
        color: config['color'],
        icon: config['icon'],
        isLiquid: config['liquid'],
      );
    }).toList();
  }

  double get totalGrossWeight =>
      allocations.fold(0, (sum, item) => sum + item.amount.abs());

  double get totalNetWorth => widget.networth.total.value;

  double get liquidAssetsOnly => allocations
      .where((a) => a.isLiquid && a.amount > 0)
      .fold(0, (sum, item) => sum + item.amount);

  double get illiquidAssetsOnly => allocations
      .where((a) => !a.isLiquid && a.amount > 0)
      .fold(0, (sum, item) => sum + item.amount);

  double get liquidityRatio {
    double totalAssets = liquidAssetsOnly + illiquidAssetsOnly;
    return totalAssets > 0 ? (liquidAssetsOnly / totalAssets) * 100 : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (allocations.isEmpty) return _buildEmptyState();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildOverallChartCard(),
          const SizedBox(height: 24),
          Text(
            'Asset Breakdown',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          ...allocations.asMap().entries.map(
            (entry) => _buildSoftRowItem(entry.key, entry.value),
          ),
          const SizedBox(height: 32),
          Text(
            'Liquidity Analysis',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          _buildLiquidityCard(),
          const SizedBox(height: 80), // Padding for scrolling
        ],
      ),
    );
  }

  Widget _buildOverallChartCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.gray80.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.white.withOpacity(0.05),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(children: [_buildPieChart()]),
    );
  }

  Widget _buildPieChart() {
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              centerSpaceColor: Colors.transparent,
              sectionsSpace: 2,
              centerSpaceRadius: 100,
              sections: _buildPieSections(),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Net Worth',
                  style: AppTypography.headline2Regular.copyWith(
                    color: AppColors.gray40,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${_formatNumber(totalNetWorth)}',
                  style: AppTypography.headline5Bold.copyWith(
                    color: AppColors.white,
                    fontSize: 28,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    return allocations.asMap().entries.map((entry) {
      final index = entry.key;
      final allocation = entry.value;
      final isTouched = index == touchedIndex;

      final absValue = allocation.amount.abs();
      final percentage = totalGrossWeight > 0
          ? (absValue / totalGrossWeight) * 100
          : 0;

      return PieChartSectionData(
        color: allocation.color,
        value: absValue,
        showTitle: false,
        radius: isTouched ? 25 : 18,
        badgeWidget: isTouched
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.gray80,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

  Widget _buildSoftRowItem(int index, AssetAllocation allocation) {
    final absValue = allocation.amount.abs();
    final percentage = totalGrossWeight > 0
        ? (absValue / totalGrossWeight) * 100
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gray80.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.white.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: allocation.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(allocation.icon, size: 20, color: allocation.color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allocation.type,
                      style: AppTypography.headline3SemiBold.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${percentage.toStringAsFixed(1)}% portfolio',
                      style: AppTypography.headline1Regular.copyWith(
                        color: AppColors.gray40,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${_formatNumber(allocation.amount)}',
                style: AppTypography.headline3Bold.copyWith(
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: AppColors.gray60.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(allocation.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.gray80.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.white.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLiquidityInfo(
                'Liquid Assets',
                liquidAssetsOnly,
                const Color(0xFF00D16C),
              ),
              Container(
                height: 40,
                width: 1,
                color: AppColors.gray60.withOpacity(0.2),
              ),
              _buildLiquidityInfo(
                'Fixed Assets',
                illiquidAssetsOnly,
                const Color(0xFFFF4D4D),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D4D).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (liquidityRatio / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D16C),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D16C).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${liquidityRatio.toStringAsFixed(0)}% Liquid',
                style: AppTypography.headline1Medium.copyWith(
                  color: AppColors.success,
                ),
              ),
              Text(
                '${(100 - liquidityRatio).toStringAsFixed(0)}% Fixed',
                style: AppTypography.headline1Medium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidityInfo(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.headline2Regular.copyWith(
                color: AppColors.gray40,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '\$${_formatNumber(amount)}',
          style: AppTypography.headline3Bold.copyWith(
            color: AppColors.white,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "No investments found.",
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  String _formatNumber(double number) {
    String sign = number < 0 ? '-' : '';
    double absNum = number.abs();
    if (absNum >= 1000000) {
      return '$sign${(absNum / 1000000).toStringAsFixed(2)}M';
    }
    if (absNum >= 1000) return '$sign${(absNum / 1000).toStringAsFixed(1)}K';
    return '$sign${absNum.toStringAsFixed(0)}';
  }
}

class AssetAllocation {
  final String type;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isLiquid;

  AssetAllocation({
    required this.type,
    required this.amount,
    required this.color,
    required this.icon,
    required this.isLiquid,
  });
}
