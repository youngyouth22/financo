import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:flutter/material.dart';

class OnboadingStepPageWidget extends StatelessWidget {
  final Widget graphic;
  final String title;
  final String subTitle;
  final dynamic theme;

  const OnboadingStepPageWidget({
    super.key,
    required this.graphic,
    required this.title,
    required this.subTitle,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          // Graphic Area
          Expanded(flex: 5, child: Center(child: graphic)),
          const SizedBox(height: 20),
          // Text Area
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headline5Bold.copyWith(
                    color: AppColors.white,
                    fontSize: 34,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  subTitle,
                  style: AppTypography.headline3Medium.copyWith(
                    color: AppColors.white.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
