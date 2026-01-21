import 'package:financo/common/common_widgets/custom_arc_180_painter.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' show radians;

class NetWorthGauge extends StatefulWidget {
  final List<ArcValueModel> segments;
  final double width;
  final double bgWidth;
  final double blurWidth;
  final double space;
  final Duration duration;
  final bool isSequential;

  const NetWorthGauge({
    super.key,
    required this.segments,
    this.width = 15,
    this.bgWidth = 10,
    this.blurWidth = 6,
    this.space = 4,
    this.duration = const Duration(milliseconds: 1500),
    this.isSequential = true,
  });

  @override
  State<NetWorthGauge> createState() => _NetWorthGaugeState();
}

class _NetWorthGaugeState extends State<NetWorthGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _setupAnimations();
    _controller.forward();
  }

  @override
  void didUpdateWidget(NetWorthGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If segments change, update animations and restart
    _setupAnimations();
    _controller.forward(from: 0);
  }

  void _setupAnimations() {
    double startInterval = 0.0;
    final int count = widget.segments.length;

    _animations = widget.segments.map((segment) {
      // Determine the interval based on sequential flag
      final endInterval = widget.isSequential
          ? (startInterval + (1.0 / count)).clamp(0.0, 1.0)
          : 1.0;

      final animation = Tween<double>(begin: 0, end: segment.value).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            widget.isSequential ? startInterval : 0.0,
            endInterval,
            curve: Curves.easeOutCubic,
          ),
        ),
      );

      startInterval = endInterval;
      return animation;
    }).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: NetWorthArcPainter(
            values: _animations.map((a) => a.value).toList(),
            colors: widget.segments.map((e) => e.color).toList(),
            width: widget.width,
            bgWidth: widget.bgWidth,
            blurWidth: widget.blurWidth,
            space: widget.space,
          ),
        );
      },
    );
  }
}

class NetWorthArcPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double width;
  final double bgWidth;
  final double blurWidth;
  final double space;

  NetWorthArcPainter({
    required this.values,
    required this.colors,
    required this.width,
    required this.bgWidth,
    required this.blurWidth,
    required this.space,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final Offset center = Offset(centerX, centerY);
    final double radius = size.width / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    const double totalArcDegrees = 270.0;
    const double startAngleOffset = 135.0;

    // 1. Draw Background Track
    final Paint backgroundPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = bgWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      radians(startAngleOffset),
      radians(totalArcDegrees),
      false,
      backgroundPaint,
    );

    // 2. Draw Active Segments
    double currentStartAngle = startAngleOffset;

    for (int i = 0; i < values.length; i++) {
      final double segmentValue = values[i];
      if (segmentValue <= 0) continue;

      final double sweepAngle = segmentValue * totalArcDegrees;

      // LOGIC: Only apply space if this is NOT the last segment
      // This ensures the last arc reaches the very end of the gauge
      bool isLastSegment = i == values.length - 1;
      final double adjustedSweep = isLastSegment
          ? sweepAngle
          : math.max(0.0, sweepAngle - space);

      final Paint activePaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;

      final Paint shadowPaint = Paint()
        ..color = colors[i].withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width + blurWidth
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      // Draw Shadow
      canvas.drawArc(
        rect,
        radians(currentStartAngle),
        radians(adjustedSweep),
        false,
        shadowPaint,
      );

      // Draw Segment
      canvas.drawArc(
        rect,
        radians(currentStartAngle),
        radians(adjustedSweep),
        false,
        activePaint,
      );

      // Increment start angle for next segment
      currentStartAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant NetWorthArcPainter oldDelegate) => true;
}

// import 'package:financo/common/app_colors.dart';
// import 'package:flutter/material.dart';
// import 'package:vector_math/vector_math.dart';

// class CustomArcPainter extends CustomPainter {
//   final double start;
//   final double end;
//   final double width;
//   final double blurWidth;

//   CustomArcPainter(
//       {this.start = 0, this.end = 270, this.width = 15, this.blurWidth = 6});

//   @override
//   void paint(Canvas canvas, Size size) {
//     var rect = Rect.fromCircle(
//         center: Offset(size.width / 2, size.height / 2),
//         radius: size.width / 2);

//     var gradienAppColors = LinearGradient(
//         colors: [AppColors.accent, AppColors.accent],
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter);

//     Paint activePaint = Paint()..shader = gradienAppColors.createShader(rect);

//     activePaint.style = PaintingStyle.stroke;
//     activePaint.strokeWidth = width;
//     activePaint.strokeCap = StrokeCap.round;

//     Paint backgroundPaint = Paint();
//     backgroundPaint.color = AppColors.gray60.withValues(alpha: 0.5);
//     backgroundPaint.style = PaintingStyle.stroke;
//     backgroundPaint.strokeWidth = width;
//     backgroundPaint.strokeCap = StrokeCap.round;

//     Paint shadowPaint = Paint()
//       ..color = AppColors.accent.withValues(alpha: 0.3)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = width + blurWidth
//       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

//     var startVal = 135.0 + start;

//     canvas.drawArc(
//         rect, radians(startVal), radians(270), false, backgroundPaint);

//     //Draw Shadow Arc
//     Path path = Path();
//     path.addArc(rect, radians(startVal), radians(end));
//     canvas.drawPath(path, shadowPaint);

//     canvas.drawArc(rect, radians(startVal), radians(end), false, activePaint);
//   }

//   @override
//   bool shouldRepaint(CustomArcPainter oldDelegate) => false;

//   @override
//   bool shouldRebuildSemantics(CustomArcPainter oldDelegate) => false;
// }
