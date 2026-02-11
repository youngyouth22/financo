import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:flutter/material.dart';

class IconItemSwitchRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool value;
  final Function(bool) didChange;
  final bool isLoading;

  const IconItemSwitchRow({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.didChange,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.gray30),
          const SizedBox(width: 15),
          Text(
            title,
            style: AppTypography.headline1Medium.copyWith(
              color: AppColors.white,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          isLoading
              ?  SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Switch(
                  value: value,
                  onChanged: didChange,
                  activeColor: AppColors.primary,
                ),
        ],
      ),
    );
  }
}
