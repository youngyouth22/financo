import 'package:flutter/material.dart';
import 'dart:math' as math; // Import for math.pi

/// A circular loading indicator that looks like a "snake" or a segment
/// that sweeps around a full circle, with a gradient that fades
/// from solid at its head to a smoky, transparent tail.
class CustomCircularLoadingIndicator extends StatefulWidget {
  /// The size of the indicator (width and height).
  final double size;

  /// The width of the indicator line (stroke).
  final double strokeWidth;

  /// The main color of the loading arc.
  final Color color;

  /// The duration of one full rotation cycle.
  final Duration duration;

  /// The length of the visible arc, in radians. Close to 2*pi for almost full circle.
  /// Default is 350 degrees.
  final double sweepRadians;

  const CustomCircularLoadingIndicator({
    super.key,
    this.size = 60.0,
    this.strokeWidth = 5.0,
    this.color = Colors.blue,
    this.duration = const Duration(milliseconds: 1200),
    this.sweepRadians = (350 / 360) * 2 * math.pi, // Default to 350 degrees
  });

  @override
  State<CustomCircularLoadingIndicator> createState() => _CustomCircularLoadingIndicatorState();
}

class _CustomCircularLoadingIndicatorState extends State<CustomCircularLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
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
        final double rotationValue = _controller.value;
        final double currentStartAngle = 2 * math.pi * rotationValue;

        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _SmokyPainter(
            strokeWidth: widget.strokeWidth,
            color: widget.color,
            startAngle: currentStartAngle,
            sweepRadians: widget.sweepRadians,
          ),
        );
      },
    );
  }
}

/// Custom Painter to draw the circular "snake" arc with a smoky, fading head and tail.
class _SmokyPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final double startAngle;
  final double sweepRadians;

  _SmokyPainter({
    required this.strokeWidth,
    required this.color,
    required this.startAngle,
    required this.sweepRadians,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    // Prepare the gradient for the active arc with a "smoky" fade.
    final Paint progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round // Round caps often look better for this effect
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: sweepRadians,
        // Define colors and stops for the "smoky" effect.
        // This configuration creates a solid head, a gradual fade in the middle,
        // and a very transparent tail.
        colors: [
          color.withValues(alpha: 0.0), // Far end of the tail (fully transparent)
          color.withValues(alpha: 0.1), // Slight hint of color
          color.withValues(alpha: 0.3), // More visible
          color.withValues(alpha: 0.6), // Building up
          color.withValues(alpha: 0.9), // Near solid
          color, // The head of the "snake" (fully solid)
          color.withValues(alpha: 0.9), // Fades slightly right after the head
          color.withValues(alpha: 0.6), // More fade
          color.withValues(alpha: 0.3), // More transparent
          color.withValues(alpha: 0.1), // Very transparent
          color.withValues(alpha: 0.0), // Start of the tail (fully transparent)
        ],
        stops: const [
          0.0,  // Tail far end (transparent)
          0.1,  // Start to appear
          0.2,  // More visible
          0.35, // Building up
          0.45, // Close to solid
          0.5,  // Solid "head" of the snake (peak of the light)
          0.55, // Fades after the head
          0.7,  // More fade
          0.8,  // Very transparent
          0.9,  // Almost gone
          1.0,  // Tail start (transparent, connects to 0.0)
        ],
        transform: GradientRotation(startAngle),
      ).createShader(rect.deflate(strokeWidth / 2));

    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      startAngle,
      sweepRadians,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SmokyPainter oldDelegate) {
    return oldDelegate.startAngle != startAngle ||
        oldDelegate.sweepRadians != sweepRadians ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}