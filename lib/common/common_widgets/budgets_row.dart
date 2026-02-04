import 'package:financo/common/app_colors.dart';
import 'package:flutter/material.dart';

class BudgetsRow extends StatelessWidget {
  final Widget? icon;
  final String? iconString;
  final String title;
  final String subtitle;
  final String value;
  final String? subValue;
  final double percent;
  final Color color;

  const BudgetsRow({
    super.key,
    this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.percent,
    required this.color,
    this.iconString,
     this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border.withValues(alpha: 0.05)),
          color: AppColors.gray60.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child:
                      icon ??
                      Image.asset(
                        iconString!,
                        width: 30,
                        height: 30,
                        color: AppColors.gray40,
                      ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                       subtitle,
                        style: TextStyle(
                          color: AppColors.gray30,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                     value,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if(subValue != null)
                    Text(
                      subValue!,
                      style: TextStyle(
                        color: AppColors.gray30,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),
            LinearProgressIndicator(
              backgroundColor: AppColors.gray60,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 3,
              value: percent,
            ),
          ],
        ),
      ),
    );
  }
}
