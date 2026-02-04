import 'package:financo/common/common_widgets/budgets_row.dart';
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

  // --- LOGIQUE MATHÉMATIQUE CORRIGÉE ---

  List<AssetAllocation> get allocations {
    return widget.networth.breakdown.byType.entries.map((entry) {
      final config =
          _typeConfig[entry.key.toLowerCase()] ?? _typeConfig['other'];
      return AssetAllocation(
        type: config['label'],
        amount: entry.value, // Valeur réelle (peut être négative)
        color: config['color'],
        icon: config['icon'],
        isLiquid: config['liquid'],
      );
    }).toList();
  }

  // Somme de la valeur absolue de tout ce qu'on gère (pour le camembert)
  double get totalGrossWeight =>
      allocations.fold(0, (sum, item) => sum + item.amount.abs());

  // Valeur réelle (Net Worth)
  double get totalNetWorth => widget.networth.total.value;

  // Analyse de liquidité : Cash + Crypto (Positifs uniquement)
  double get liquidAssetsOnly => allocations
      .where((a) => a.isLiquid && a.amount > 0)
      .fold(0, (sum, item) => sum + item.amount);

  // Actifs Immobilisés (Immo, etc)
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
          const SizedBox(height: 20),
          _buildPieChart(),
          const SizedBox(height: 32),
          ...allocations.asMap().entries.map(
            (entry) => _buildLegendItem(entry.key, entry.value),
          ),
          const SizedBox(height: 32),
          _buildLiquidityCard(),
        ],
      ),
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
              centerSpaceColor: AppColors.gray80,
              sectionsSpace: 1,
              centerSpaceRadius: 120,
              sections: _buildPieSections(),
            ),
          ),
          Align(
            alignment: AlignmentGeometry.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Value',
                  style: AppTypography.headline2Regular.copyWith(
                    color: AppColors.gray30,
                  ),
                ),
                Text(
                  '\$${_formatNumber(totalGrossWeight)}',
                  style: AppTypography.headline3Bold.copyWith(
                    color: AppColors.white,
                    fontSize: 32,
                  ),
                ),
                Text(
                  '+ 33.4%',
                  style: AppTypography.headline1Regular.copyWith(
                    color: AppColors.success,
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

      // On utilise la valeur ABSOLUE pour le dessin, car un camembert ne peut pas être négatif
      final absValue = allocation.amount.abs();
      final percentage = totalGrossWeight > 0
          ? (absValue / totalGrossWeight) * 100
          : 0;

      return PieChartSectionData(
        color: allocation.color,
        value: absValue,
        showTitle: false,
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: isTouched ? 30 : 20,

        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegendItem(int index, AssetAllocation allocation) {
    final absValue = allocation.amount.abs();
    final percentage = totalGrossWeight > 0
        ? (absValue / totalGrossWeight) * 100
        : 0;
    final isSelected = touchedIndex == index;

    return Transform.scale(
      scale: isSelected ? 1.1 : 1.0,
      child: BudgetsRow(
        icon: Icon(allocation.icon, size: 30, color: AppColors.gray40),
        title: allocation.type,
        subtitle: '\$${_formatNumber(allocation.amount)}',
        value: '${percentage.toStringAsFixed(1)}%',
        percent: percentage / 100,
        color: allocation.color,
      ),
    );
  }

  Widget _buildLiquidityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gray60.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.05)),
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
              _buildLiquidityInfo(
                'Fixed Assets',
                illiquidAssetsOnly,
                const Color(0xFFFF4D4D),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: liquidityRatio / 100,
              borderRadius: BorderRadius.circular(4),
              minHeight: 12,
              backgroundColor: const Color(0xFFFF4D4D).withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00D16C),
              ),
            ),
          ),
          // const SizedBox(height: 12),
          // Text(
          //   '${liquidityRatio.toStringAsFixed(1)}% of your assets are liquid (Cash/Crypto)',
          //   style: AppTypography.headline2Regular.copyWith(
          //     color: AppColors.gray40,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildLiquidityInfo(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: label.startsWith('L')
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.headline2Regular.copyWith(
                color: AppColors.gray30,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '\$${_formatNumber(amount)}',
          style: AppTypography.headline3SemiBold.copyWith(
            color: AppColors.white,
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
