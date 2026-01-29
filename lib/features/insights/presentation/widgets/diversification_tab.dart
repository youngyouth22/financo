import 'package:fl_chart/fl_chart.dart';
import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

/// Tab 2: Diversification & Exposure
///
/// Features:
/// - Sector exposure bar chart with overexposure warnings
/// - Geographic exposure world map
/// - Country list with risk levels
class DiversificationTab extends StatefulWidget {
  const DiversificationTab({super.key});

  @override
  State<DiversificationTab> createState() => _DiversificationTabState();
}

class _DiversificationTabState extends State<DiversificationTab> {
  late MapShapeSource _mapSource;

  // Mock data - will be replaced with real data from BLoC
  final List<SectorExposure> sectors = [
    SectorExposure(name: 'Technology', percentage: 45, color: const Color(0xFF3861FB)),
    SectorExposure(name: 'Finance', percentage: 25, color: const Color(0xFF00D16C)),
    SectorExposure(name: 'Healthcare', percentage: 15, color: const Color(0xFFFFAA00)),
    SectorExposure(name: 'Energy', percentage: 10, color: const Color(0xFFFF4D4D)),
    SectorExposure(name: 'Real Estate', percentage: 5, color: const Color(0xFFAD7BFF)),
  ];

  final List<GeographicExposure> countries = [
    GeographicExposure(
      name: 'United States',
      code: 'US',
      flag: '🇺🇸',
      percentage: 65,
      amount: 260000,
      riskLevel: 'High Concentration',
      riskColor: const Color(0xFFFF4D4D),
    ),
    GeographicExposure(
      name: 'United Kingdom',
      code: 'GB',
      flag: '🇬🇧',
      percentage: 15,
      amount: 60000,
      riskLevel: 'Moderate',
      riskColor: const Color(0xFFFFAA00),
    ),
    GeographicExposure(
      name: 'Germany',
      code: 'DE',
      flag: '🇩🇪',
      percentage: 10,
      amount: 40000,
      riskLevel: 'Low',
      riskColor: const Color(0xFF00D16C),
    ),
    GeographicExposure(
      name: 'Japan',
      code: 'JP',
      flag: '🇯🇵',
      percentage: 7,
      amount: 28000,
      riskLevel: 'Low',
      riskColor: const Color(0xFF00D16C),
    ),
    GeographicExposure(
      name: 'Switzerland',
      code: 'CH',
      flag: '🇨🇭',
      percentage: 3,
      amount: 12000,
      riskLevel: 'Low',
      riskColor: const Color(0xFF00D16C),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _mapSource = MapShapeSource.asset(
      'assets/world_map.json',
      shapeDataField: 'name',
      dataCount: countries.length,
      primaryValueMapper: (int index) => countries[index].name,
      shapeColorValueMapper: (int index) => countries[index].percentage,
      shapeColorMappers: const [
        MapColorMapper(from: 0, to: 20, color: Color(0xFF3861FB), minOpacity: 0.3, maxOpacity: 0.5),
        MapColorMapper(from: 20, to: 40, color: Color(0xFF3861FB), minOpacity: 0.5, maxOpacity: 0.7),
        MapColorMapper(from: 40, to: 100, color: Color(0xFF3861FB), minOpacity: 0.7, maxOpacity: 1.0),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sector Exposure Section
          Text(
            'Sector Exposure',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          
          // Bar Chart
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray70),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 50,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => AppColors.gray80,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${sectors[group.x.toInt()].name}\n${rod.toY.toStringAsFixed(0)}%',
                        TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < sectors.length) {
                          final sector = sectors[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              sector.name.split(' ').first,
                              style: AppTypography.headline1Regular.copyWith(
                                color: AppColors.gray40,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: AppTypography.headline1Regular.copyWith(
                            color: AppColors.gray40,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.gray70,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: sectors.asMap().entries.map((entry) {
                  final index = entry.key;
                  final sector = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: sector.percentage,
                        color: sector.color,
                        width: 32,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Sector List with Overexposure Warnings
          ...sectors.map((sector) {
            final isOverexposed = sector.percentage > 40;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOverexposed
                    ? const Color(0xFFFF4D4D).withOpacity(0.1)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOverexposed
                      ? const Color(0xFFFF4D4D).withOpacity(0.3)
                      : AppColors.gray70,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: sector.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sector.name,
                      style: AppTypography.headline3Medium.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  if (isOverexposed) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4D4D).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_rounded, color: Color(0xFFFF4D4D), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Overexposed',
                            style: AppTypography.headline1Regular.copyWith(
                              color: const Color(0xFFFF4D4D),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '${sector.percentage.toStringAsFixed(0)}%',
                    style: AppTypography.headline3Bold.copyWith(
                      color: sector.color,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 32),

          // Geographic Exposure Section
          Text(
            'Geographic Exposure',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          
          // World Map (Placeholder - Syncfusion requires asset file)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray70),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Map placeholder with gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF3861FB).withOpacity(0.1),
                          AppColors.card,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.public_rounded, size: 48, color: AppColors.gray50),
                          const SizedBox(height: 8),
                          Text(
                            'World Map Visualization',
                            style: AppTypography.headline3Medium.copyWith(
                              color: AppColors.gray40,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Showing ${countries.length} countries',
                            style: AppTypography.headline2Regular.copyWith(
                              color: AppColors.gray50,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Country List
          Text(
            'Country Breakdown',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...countries.asMap().entries.map((entry) {
            final index = entry.key;
            final country = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray70),
              ),
              child: Row(
                children: [
                  // Rank
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.gray80,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: AppTypography.headline3Bold.copyWith(
                          color: AppColors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Flag
                  Text(
                    country.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  // Country Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          country.name,
                          style: AppTypography.headline3Medium.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '\$${_formatNumber(country.amount)}',
                              style: AppTypography.headline2Regular.copyWith(
                                color: AppColors.gray30,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: country.riskColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                country.riskLevel,
                                style: AppTypography.headline1Regular.copyWith(
                                  color: country.riskColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Percentage
                  Text(
                    '${country.percentage}%',
                    style: AppTypography.headline3Bold.copyWith(
                      color: const Color(0xFF3861FB),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
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

class SectorExposure {
  final String name;
  final double percentage;
  final Color color;

  SectorExposure({
    required this.name,
    required this.percentage,
    required this.color,
  });
}

class GeographicExposure {
  final String name;
  final String code;
  final String flag;
  final double percentage;
  final double amount;
  final String riskLevel;
  final Color riskColor;

  GeographicExposure({
    required this.name,
    required this.code,
    required this.flag,
    required this.percentage,
    required this.amount,
    required this.riskLevel,
    required this.riskColor,
  });
}
