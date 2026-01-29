import 'package:fl_chart/fl_chart.dart';
import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:flutter/material.dart';

/// Tab 1: Asset Allocation (The Big Picture)
///
/// Features:
/// - Large interactive PieChart showing distribution by asset type
/// - Interactive legend with USD amounts
/// - Liquidity indicator showing liquid vs illiquid assets
class AssetAllocationTab extends StatefulWidget {
  const AssetAllocationTab({super.key});

  @override
  State<AssetAllocationTab> createState() => _AssetAllocationTabState();
}

class _AssetAllocationTabState extends State<AssetAllocationTab> {
  int touchedIndex = -1;

  // Mock data - will be replaced with real data from BLoC
  final List<AssetAllocation> allocations = [
    AssetAllocation(
      type: 'Crypto',
      amount: 43200,
      color: const Color(0xFF3861FB),
      icon: Icons.currency_bitcoin_rounded,
      isLiquid: true,
    ),
    AssetAllocation(
      type: 'Stocks',
      amount: 49800,
      color: const Color(0xFF00D16C),
      icon: Icons.trending_up_rounded,
      isLiquid: true,
    ),
    AssetAllocation(
      type: 'Cash',
      amount: 31520,
      color: const Color(0xFFFFAA00),
      icon: Icons.payments_rounded,
      isLiquid: true,
    ),
    AssetAllocation(
      type: 'Real Estate',
      amount: 250000,
      color: const Color(0xFFFF4D4D),
      icon: Icons.home_rounded,
      isLiquid: false,
    ),
    AssetAllocation(
      type: 'Commodities',
      amount: 15000,
      color: const Color(0xFFAD7BFF),
      icon: Icons.diamond_rounded,
      isLiquid: false,
    ),
  ];

  double get totalAmount => allocations.fold(0, (sum, item) => sum + item.amount);
  double get liquidAmount => allocations.where((a) => a.isLiquid).fold(0, (sum, item) => sum + item.amount);
  double get liquidPercentage => (liquidAmount / totalAmount) * 100;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Portfolio Value Card
          Container(
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
                  'Total Portfolio Value',
                  style: AppTypography.headline3Regular.copyWith(
                    color: AppColors.gray30,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${_formatNumber(totalAmount)}',
                  style: AppTypography.headline3Bold.copyWith(
                    color: AppColors.white,
                    fontSize: 32,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Pie Chart Section
          Text(
            'Asset Distribution',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          
          // Pie Chart
          SizedBox(
            height: 280,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: _buildPieSections(),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Interactive Legend
          Text(
            'Breakdown',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          ...allocations.asMap().entries.map((entry) {
            final index = entry.key;
            final allocation = entry.value;
            final percentage = (allocation.amount / totalAmount) * 100;
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: allocation.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(allocation.icon, color: allocation.color, size: 24),
                  ),
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
                            color: AppColors.gray30,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: AppTypography.headline3Bold.copyWith(
                      color: allocation.color,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 32),

          // Liquidity Indicator
          Text(
            'Liquidity Analysis',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Container(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D16C),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Liquid Assets',
                              style: AppTypography.headline2Regular.copyWith(
                                color: AppColors.gray30,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${_formatNumber(liquidAmount)}',
                          style: AppTypography.headline3SemiBold.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4D4D),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Illiquid Assets',
                              style: AppTypography.headline2Regular.copyWith(
                                color: AppColors.gray30,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${_formatNumber(totalAmount - liquidAmount)}',
                          style: AppTypography.headline3SemiBold.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: liquidPercentage / 100,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFFF4D4D).withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D16C)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${liquidPercentage.toStringAsFixed(1)}% of your portfolio is liquid',
                  style: AppTypography.headline2Regular.copyWith(
                    color: AppColors.gray40,
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
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 70.0 : 60.0;
      final percentage = (allocation.amount / totalAmount) * 100;

      return PieChartSectionData(
        color: allocation.color,
        value: allocation.amount,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: isTouched
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: allocation.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: allocation.color.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(allocation.icon, color: Colors.white, size: 20),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
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
