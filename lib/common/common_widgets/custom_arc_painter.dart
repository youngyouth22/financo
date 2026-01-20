
import 'package:financo/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart';

class CustomArcPainter extends CustomPainter {
  final double start;
  final double end;
  final double width;
  final double blurWidth;

  CustomArcPainter(
      {this.start = 0, this.end = 270, this.width = 15, this.blurWidth = 6});

  @override
  void paint(Canvas canvas, Size size) {
    var rect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2);

    var gradienAppColors = LinearGradient(
        colors: [AppColors.accent, AppColors.accent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter);

    Paint activePaint = Paint()..shader = gradienAppColors.createShader(rect);

    activePaint.style = PaintingStyle.stroke;
    activePaint.strokeWidth = width;
    activePaint.strokeCap = StrokeCap.round;

    Paint backgroundPaint = Paint();
    backgroundPaint.color = AppColors.gray60.withValues(alpha: 0.5);
    backgroundPaint.style = PaintingStyle.stroke;
    backgroundPaint.strokeWidth = width;
    backgroundPaint.strokeCap = StrokeCap.round;

    Paint shadowPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width + blurWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    var startVal = 135.0 + start;

    canvas.drawArc(
        rect, radians(startVal), radians(270), false, backgroundPaint);

    //Draw Shadow Arc
    Path path = Path();
    path.addArc(rect, radians(startVal), radians(end));
    canvas.drawPath(path, shadowPaint);

    canvas.drawArc(rect, radians(startVal), radians(end), false, activePaint);
  }

  @override
  bool shouldRepaint(CustomArcPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(CustomArcPainter oldDelegate) => false;
}
