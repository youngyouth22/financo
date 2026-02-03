import 'package:fl_chart/fl_chart.dart';
import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Timeframe options for price chart
enum ChartTimeframe {
  oneHour('1H'),
  oneDay('1D'),
  sevenDays('7D'),
  thirtyDays('30D'),
  oneYear('1Y'),
  all('ALL');

  final String label;
  const ChartTimeframe(this.label);
}

/// Premium fintech line chart with gradient fill and timeframe selector
class PriceLineChart extends StatefulWidget {
  final List<double> priceHistory;
  final bool isPositive;
  final double height;
  final bool showTimeframeSelector;

  const PriceLineChart({
    super.key,
    required this.priceHistory,
    required this.isPositive,
    this.height = 200,
    this.showTimeframeSelector = true,
  });

  @override
  State<PriceLineChart> createState() => _PriceLineChartState();
}

class _PriceLineChartState extends State<PriceLineChart> {
  ChartTimeframe _selectedTimeframe = ChartTimeframe.oneDay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chart
        SizedBox(
          height: widget.height,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 16),
            child: _buildChart(),
          ),
        ),
        
        // Timeframe Selector
        if (widget.showTimeframeSelector) ...[
          const SizedBox(height: 16),
          _buildTimeframeSelector(),
        ],
      ],
    );
  }

  Widget _buildChart() {
    if (widget.priceHistory.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: AppTypography.headline2Regular.copyWith(
            color: AppColors.gray40,
          ),
        ),
      );
    }

    final spots = widget.priceHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    final lineColor = widget.isPositive ? AppColors.success : AppColors.error;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.gray80.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (spots.length / 4).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _getTimeLabel(value.toInt(), spots.length),
                    style: AppTypography.headline1Regular.copyWith(
                      color: AppColors.gray40,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: null,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatPrice(value),
                  style: AppTypography.headline1Regular.copyWith(
                    color: AppColors.gray40,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.left,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: spots.length.toDouble() - 1,
        minY: spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) * 0.995,
        maxY: spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.005,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withOpacity(0.3),
                  lineColor.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppColors.gray80,
            // tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '\$${spot.y.toStringAsFixed(2)}',
                  AppTypography.headline2SemiBold.copyWith(
                    color: AppColors.white,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ChartTimeframe.values.map((timeframe) {
          final isSelected = _selectedTimeframe == timeframe;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTimeframe = timeframe;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.gray70,
                  width: 1,
                ),
              ),
              child: Text(
                timeframe.label,
                style: AppTypography.headline2Regular.copyWith(
                  color: isSelected ? AppColors.white : AppColors.gray40,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getTimeLabel(int index, int totalPoints) {
    // Generate time labels based on selected timeframe
    switch (_selectedTimeframe) {
      case ChartTimeframe.oneHour:
        return '${index * 5}m';
      case ChartTimeframe.oneDay:
        return '${index * 2}h';
      case ChartTimeframe.sevenDays:
        return DateFormat('E').format(
          DateTime.now().subtract(Duration(days: 7 - index)),
        );
      case ChartTimeframe.thirtyDays:
        return DateFormat('MMM d').format(
          DateTime.now().subtract(Duration(days: 30 - index)),
        );
      case ChartTimeframe.oneYear:
        return DateFormat('MMM').format(
          DateTime.now().subtract(Duration(days: 365 - (index * 30))),
        );
      case ChartTimeframe.all:
        return DateFormat('yy').format(
          DateTime.now().subtract(Duration(days: totalPoints - index)),
        );
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '\$${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '\$${(price / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${price.toStringAsFixed(0)}';
    }
  }
}
