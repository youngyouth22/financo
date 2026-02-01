import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_spacing.dart';
import 'package:flutter/material.dart';

class CustomContainer extends StatelessWidget {
  final Widget child;
  final double borderRadiusValue;
  final bool roundedRadiusTopLeft;
  final bool roundedRadiusTopRight;
  final bool roundedRadiusbottomLeft;
  final bool roundedRadiusbottomRight;
  final bool roundedRadiusAll;
  final VoidCallback? onTap;

  final bool showBorderTop;
  final bool showBorderRight;
  final bool showBorderLeft;
  final bool showBorderBottom;
  final bool showBorderAll;
  final double verticalPaddingValue;
  final double horizontalPaddingValue;

  const CustomContainer({
    super.key,
    required this.child,
    this.borderRadiusValue = 10,
    this.roundedRadiusAll = false,
    this.roundedRadiusTopLeft = false,
    this.roundedRadiusTopRight = false,
    this.roundedRadiusbottomLeft = false,
    this.roundedRadiusbottomRight = false,
    this.showBorderTop = false,
    this.showBorderBottom = false,
    this.showBorderLeft = false,
    this.showBorderRight = false,
    this.showBorderAll = false,
    this.verticalPaddingValue = 2,
    this.horizontalPaddingValue = 10,
    this.onTap,
  });

  BorderRadius borderRadius() => roundedRadiusAll
      ? BorderRadius.circular(borderRadiusValue)
      : BorderRadius.only(
          topLeft: Radius.circular(
            roundedRadiusTopLeft ? borderRadiusValue : 0,
          ),
          topRight: Radius.circular(
            roundedRadiusTopRight ? borderRadiusValue : 0,
          ),
          bottomLeft: Radius.circular(
            roundedRadiusbottomLeft ? borderRadiusValue : 0,
          ),
          bottomRight: Radius.circular(
            roundedRadiusbottomRight ? borderRadiusValue : 0,
          ),
        );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius(),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.ten),
        decoration: BoxDecoration(
          border: showBorderAll
              ? Border(
                  top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.1),
                  ),
                  left: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.1),
                  ))
              : Border(
                  top: showBorderTop
                      ? BorderSide(
                          color: AppColors.border.withValues(alpha: 0.1),
                        )
                      : BorderSide.none,
                  left: showBorderLeft
                      ? BorderSide(
                          color: AppColors.border.withValues(alpha: 0.1),
                        )
                      : BorderSide.none,
                  right: showBorderRight
                      ? BorderSide(
                          color: AppColors.border.withValues(alpha: 0.1),
                        )
                      : BorderSide.none,
                  bottom: showBorderBottom
                      ? BorderSide(
                          color: AppColors.border.withValues(alpha: 0.1),
                        )
                      : BorderSide.none),
          color: AppColors.white.withValues(alpha: 0.06),
          borderRadius: borderRadius(),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: horizontalPaddingValue,
              vertical: verticalPaddingValue),
          child: child,
        ),
      ),
    );
  }
}
