import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:flutter/material.dart';

class IconItemRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? value;
  final VoidCallback? onTap;
  final Color? textColor;

  const IconItemRow({
    super.key,
    required this.title,
    required this.icon,
    this.value,
    this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.gray30),
            const SizedBox(width: 15),
            Text(
              title,
              style: AppTypography.headline1Medium.copyWith(
                color: textColor ?? AppColors.white,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            if (value != null)
              Text(
                value!,
                style: AppTypography.headline1Regular.copyWith(
                  color: AppColors.gray30,
                  fontSize: 12,
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppColors.gray30, size: 20),
          ],
        ),
      ),
    );
  }
}
