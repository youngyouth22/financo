import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MiniSparkline extends StatelessWidget {
  final List<double> points;
  final bool isPositive;

  const MiniSparkline({
    super.key,
    required this.points,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    // We need at least 2 points to draw a line
    if (points.isEmpty || points.length < 2) {
      return const SizedBox(width: 60, height: 30);
    }

    final color = isPositive ? Colors.green : Colors.red;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 40,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: points
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              curveSmoothness: 0.4,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              // --- THE GRADIENT LOGIC ---
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
