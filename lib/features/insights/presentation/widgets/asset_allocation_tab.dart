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
      'color': const Color(0xFF3861FB),
      'icon': Icons.currency_bitcoin_rounded,
      'label': 'Crypto',
      'liquid': true,
    },
    'stock': {
      'color': const Color(0xFF00D16C),
      'icon': Icons.trending_up_rounded,
      'label': 'Stocks',
      'liquid': true,
    },
    'cash': {
      'color': const Color(0xFFFFAA00),
      'icon': Icons.payments_rounded,
      'label': 'Cash',
      'liquid': true,
    },
    'real_estate': {
      'color': const Color(0xFFFF4D4D),
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
      'color': const Color(0xFF6B7280),
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
          _buildTotalValueCard(),
          const SizedBox(height: 32),
          Text(
            'Portfolio Composition',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          _buildPieChart(),
          const SizedBox(height: 32),
          Text(
            'Asset Class Breakdown',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          ...allocations.asMap().entries.map(
            (entry) => _buildLegendItem(entry.key, entry.value),
          ),
          const SizedBox(height: 32),
          _buildLiquidityCard(),
        ],
      ),
    );
  }

  Widget _buildTotalValueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3861FB).withOpacity(0.2),
            const Color(0xFF3861FB).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3861FB).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net Worth (Total Wealth)',
            style: AppTypography.headline3Regular.copyWith(
              color: AppColors.gray30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_formatNumber(totalNetWorth)}',
            style: AppTypography.headline3Bold.copyWith(
              color: AppColors.white,
              fontSize: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    return SizedBox(
      height: 240,
      child: PieChart(
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
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: _buildPieSections(),
        ),
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
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: isTouched ? 65.0 : 55.0,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.gray80 : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? allocation.color : AppColors.gray70,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(allocation.icon, color: allocation.color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allocation.type,
                  style: AppTypography.headline3Medium.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${_formatNumber(allocation.amount)}',
                  style: AppTypography.headline2Regular.copyWith(
                    color: allocation.amount < 0
                        ? const Color(0xFFFF4D4D)
                        : AppColors.gray30,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: AppTypography.headline3Bold.copyWith(
              color: allocation.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray70),
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
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: liquidityRatio / 100,
              minHeight: 12,
              backgroundColor: const Color(0xFFFF4D4D).withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00D16C),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${liquidityRatio.toStringAsFixed(1)}% of your assets are liquid (Cash/Crypto)',
            style: AppTypography.headline2Regular.copyWith(
              color: AppColors.gray40,
            ),
          ),
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
    if (absNum >= 1000000)
      return '$sign${(absNum / 1000000).toStringAsFixed(2)}M';
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
