import 'package:financo/common/app_colors.dart';
import 'package:flutter/material.dart';

class SegmentButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final bool isActive;
  const SegmentButton(
      {super.key,
      required this.title,
      required this.isActive,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPressed,
      child: Container(
        decoration: isActive
            ? BoxDecoration(
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.15),
                ),
                color: AppColors.gray60.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
              color: isActive ? AppColors.white : AppColors.gray30,
              fontSize: 12,
              
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
