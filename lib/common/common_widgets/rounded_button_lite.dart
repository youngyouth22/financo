import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:flutter/material.dart';

class RoundedButtonLite extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const RoundedButtonLite({
    super.key,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.white.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      child: Text(
        label,
        style: AppTypography.headline3SemiBold.copyWith(
          color: AppColors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
