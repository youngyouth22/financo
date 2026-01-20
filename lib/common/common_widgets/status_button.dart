import 'package:financo/common/app_colors.dart';
import 'package:flutter/material.dart';

class StatusButton extends StatelessWidget {
  final String title;
  final String value;
  final Color statusColor;

  final VoidCallback onPressed;
  const StatusButton(
      {super.key,
      required this.title,
      required this.value,
      required this.statusColor,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: 68,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.15),
              ),
              color: AppColors.gray60.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: AppColors.gray40,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 1,
            color: statusColor,
          ),
        ],
      ),
    );
  }
}
