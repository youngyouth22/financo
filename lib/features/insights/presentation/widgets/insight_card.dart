import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:flutter/material.dart';

enum InsightType { warning, action, success }

/// A premium card used by GenUI to display financial insights.
///
/// Parameters:
/// - [type]: Determines the color scheme (warning, action, success).
/// - [icon]: The Material icon to display.
/// - [title]: The headline of the insight.
/// - [description]: The detailed financial advice.
/// - [actionLabel]: Optional text for the button.
/// - [onActionPressed]: Callback for GenUI to trigger next steps/modals.

class InsightCard extends StatelessWidget {
  final InsightType type;
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  const InsightCard({
    super.key,
    required this.type,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    Color getColor() {
      switch (type) {
        case InsightType.warning:
          return const Color(0xFFFF4D4D); // Red
        case InsightType.action:
          return const Color(0xFF3861FB); // Blue
        case InsightType.success:
          return const Color(0xFF00D16C); // Green
      }
    }

    final color = getColor();
    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ), // Added margin for list spacing
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(
          16,
        ), // Increased radius for premium look
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
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
            const SizedBox(height: 16),
            InkWell(
              // Changed to InkWell for better touch feedback
              onTap: onActionPressed,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: AppTypography.headline3Medium.copyWith(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
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
