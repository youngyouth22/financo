import 'dart:math' as math;
import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:flutter/material.dart';

/// Tab 3: Risk & Strategy (The Premium Brain)
///
/// Features:
/// - Three circular score gauges (Diversification, Risk, Volatility)
/// - AI Strategic Insights with warning and action cards
/// - Professional fintech design
class RiskStrategyTab extends StatelessWidget {
  const RiskStrategyTab({super.key});

  // Mock data - will be replaced with real data from BLoC
  static const double diversificationScore = 7.5;
  static const double riskLevel = 6.2;
  static const double volatilityScore = 8.1;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health Indicators Section
          Text(
            'Portfolio Health',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          
          // Three Circular Gauges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScoreGauge(
                context,
                score: diversificationScore,
                maxScore: 10,
                title: 'Diversification',
                icon: Icons.pie_chart_rounded,
                color: const Color(0xFF00D16C),
              ),
              _buildScoreGauge(
                context,
                score: riskLevel,
                maxScore: 10,
                title: 'Risk Level',
                icon: Icons.warning_rounded,
                color: const Color(0xFFFFAA00),
              ),
              _buildScoreGauge(
                context,
                score: volatilityScore,
                maxScore: 10,
                title: 'Volatility',
                icon: Icons.show_chart_rounded,
                color: const Color(0xFFFF4D4D),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // AI Strategic Insights
          Row(
            children: [
              Icon(Icons.psychology_rounded, color: const Color(0xFF3861FB), size: 24),
              const SizedBox(width: 8),
              Text(
                'AI Strategic Insights',
                style: AppTypography.headline3SemiBold.copyWith(
                  color: AppColors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Warning Cards
          _buildInsightCard(
            type: InsightType.warning,
            icon: Icons.flag_rounded,
            title: 'High US Exposure Detected',
            description: 'Your portfolio has 65% exposure to US markets. Consider diversifying into European and Asian markets to reduce geographic concentration risk.',
            actionLabel: 'View Recommendations',
          ),
          const SizedBox(height: 12),
          
          _buildInsightCard(
            type: InsightType.action,
            icon: Icons.lightbulb_rounded,
            title: 'Crypto Volatility Impact',
            description: 'Crypto represents 75% of your daily volatility. Adding Commodities (Gold, Silver) could stabilize your balance and reduce overall portfolio risk.',
            actionLabel: 'Explore Commodities',
          ),
          const SizedBox(height: 12),
          
          _buildInsightCard(
            type: InsightType.success,
            icon: Icons.check_circle_rounded,
            title: 'Strong Sector Diversification',
            description: 'Your portfolio is well-balanced across Technology (35%), Finance (25%), and Healthcare (20%). This provides good protection against sector-specific downturns.',
            actionLabel: null,
          ),
          const SizedBox(height: 12),
          
          _buildInsightCard(
            type: InsightType.action,
            icon: Icons.trending_up_rounded,
            title: 'Liquidity Optimization',
            description: 'Only 32% of your portfolio is liquid. Consider increasing cash or liquid assets to 40-50% for better flexibility and emergency coverage.',
            actionLabel: 'Rebalance Portfolio',
          ),
          const SizedBox(height: 12),
          
          _buildInsightCard(
            type: InsightType.warning,
            icon: Icons.security_rounded,
            title: 'Real Estate Concentration',
            description: 'Real Estate accounts for 62% of your net worth. While stable, this creates illiquidity risk. Consider gradual diversification into REITs or other liquid alternatives.',
            actionLabel: 'Learn About REITs',
          ),
        ],
      ),
    );
  }

  Widget _buildScoreGauge(
    BuildContext context, {
    required double score,
    required double maxScore,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final percentage = score / maxScore;
    final displayScore = score.toStringAsFixed(1);

    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              CustomPaint(
                size: const Size(100, 100),
                painter: CircularGaugePainter(
                  percentage: 1.0,
                  color: AppColors.gray80,
                  strokeWidth: 10,
                ),
              ),
              // Progress circle
              CustomPaint(
                size: const Size(100, 100),
                painter: CircularGaugePainter(
                  percentage: percentage,
                  color: color,
                  strokeWidth: 10,
                ),
              ),
              // Center content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    displayScore,
                    style: AppTypography.headline3Bold.copyWith(
                      color: AppColors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: AppTypography.headline2Regular.copyWith(
            color: AppColors.gray30,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required InsightType type,
    required IconData icon,
    required String title,
    required String description,
    String? actionLabel,
  }) {
    Color getColor() {
      switch (type) {
        case InsightType.warning:
          return const Color(0xFFFF4D4D);
        case InsightType.action:
          return const Color(0xFF3861FB);
        case InsightType.success:
          return const Color(0xFF00D16C);
      }
    }

    final color = getColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headline3SemiBold.copyWith(
                    color: AppColors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: AppTypography.headline2Regular.copyWith(
              color: AppColors.gray30,
              height: 1.5,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                // TODO: Implement action
              },
              child: Row(
                children: [
                  Text(
                    actionLabel,
                    style: AppTypography.headline3Medium.copyWith(
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, color: color, size: 16),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum InsightType {
  warning,
  action,
  success,
}

/// Custom painter for circular gauge
class CircularGaugePainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double strokeWidth;

  CircularGaugePainter({
    required this.percentage,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * percentage;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(CircularGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
