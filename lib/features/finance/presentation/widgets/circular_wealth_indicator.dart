import 'dart:math' as math;
import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:flutter/material.dart';

/// Circular wealth indicator with animated net worth display
///
/// Features:
/// - Three arc segments for asset groups
/// - Animated net worth value in center
/// - Proportional arc sizes based on percentages
class CircularWealthIndicator extends StatefulWidget {
  final double netWorth;
  final double cryptoPercentage;
  final double stocksPercentage;
  final double cashPercentage;

  const CircularWealthIndicator({
    super.key,
    required this.netWorth,
    required this.cryptoPercentage,
    required this.stocksPercentage,
    required this.cashPercentage,
  });

  @override
  State<CircularWealthIndicator> createState() =>
      _CircularWealthIndicatorState();
}

class _CircularWealthIndicatorState extends State<CircularWealthIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _displayedValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.netWorth,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _animation.addListener(() {
      setState(() {
        _displayedValue = _animation.value;
      });
    });

    _controller.forward();
  }

  @override
  void didUpdateWidget(CircularWealthIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.netWorth != widget.netWorth) {
      _animation = Tween<double>(
        begin: _displayedValue,
        end: widget.netWorth,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arc segments
          CustomPaint(
            size: const Size(280, 280),
            painter: _WealthArcPainter(
              cryptoPercentage: widget.cryptoPercentage,
              stocksPercentage: widget.stocksPercentage,
              cashPercentage: widget.cashPercentage,
            ),
          ),
          
          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Net Worth',
                style: AppTypography.headline2Regular.copyWith(
                  color: AppColors.gray40,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatCurrency(_displayedValue),
                style: AppTypography.headline6Bold.copyWith(
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Format currency with abbreviation (K, M, B)
  String _formatCurrency(double value) {
    if (value >= 1000000000) {
      return '\$${(value / 1000000000).toStringAsFixed(2)}B';
    } else if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(2)}K';
    } else {
      return '\$${value.toStringAsFixed(2)}';
    }
  }
}

/// Custom painter for wealth arc segments
class _WealthArcPainter extends CustomPainter {
  final double cryptoPercentage;
  final double stocksPercentage;
  final double cashPercentage;

  _WealthArcPainter({
    required this.cryptoPercentage,
    required this.stocksPercentage,
    required this.cashPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    const strokeWidth = 24.0;

    // Background circle
    final bgPaint = Paint()
      ..color = AppColors.gray80
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Calculate angles (leave small gaps between arcs)
    const gapAngle = 0.05; // Small gap in radians
    double startAngle = -math.pi / 2; // Start from top

    // Draw crypto arc
    if (cryptoPercentage > 0) {
      final cryptoSweepAngle =
          (cryptoPercentage / 100) * 2 * math.pi - gapAngle;
      final cryptoPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary500,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        cryptoSweepAngle,
        false,
        cryptoPaint,
      );

      startAngle += cryptoSweepAngle + gapAngle;
    }

    // Draw stocks arc
    if (stocksPercentage > 0) {
      final stocksSweepAngle =
          (stocksPercentage / 100) * 2 * math.pi - gapAngle;
      final stocksPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.accent,
            AppColors.accentP50,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        stocksSweepAngle,
        false,
        stocksPaint,
      );

      startAngle += stocksSweepAngle + gapAngle;
    }

    // Draw cash arc
    if (cashPercentage > 0) {
      final cashSweepAngle = (cashPercentage / 100) * 2 * math.pi - gapAngle;
      final cashPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.accentS,
            AppColors.accentS50,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        cashSweepAngle,
        false,
        cashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_WealthArcPainter oldDelegate) {
    return oldDelegate.cryptoPercentage != cryptoPercentage ||
        oldDelegate.stocksPercentage != stocksPercentage ||
        oldDelegate.cashPercentage != cashPercentage;
  }
}
