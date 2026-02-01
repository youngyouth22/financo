
import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_spacing.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/common/image_resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomFormFieldTile extends StatelessWidget {
  final String title;
  final String? trailingImage;
  final Widget? child;
  final String? value;
  final String? placeHolder;
  final TextStyle? titleStyle;
  final Widget? leading;
  final bool showArrowRight;
  final CrossAxisAlignment? crossAxisAlignment;
  const CustomFormFieldTile(
      {super.key,
      required this.title,
      this.titleStyle,
      this.value,
      this.leading,
      this.child,
      this.placeHolder,
      this.trailingImage,
      this.crossAxisAlignment,
      this.showArrowRight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: titleStyle ??
              AppTypography.headline2Medium.copyWith(color: AppColors.gray10),
        ),
        Expanded(
            child: child ??
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: AppSpacing.five,
                  children: [
                    Expanded(
                      child: Text(
                        textAlign: TextAlign.right,
                        value ?? placeHolder ?? '',
                        style: AppTypography.headline3SemiBold.copyWith(
                            color: value == null && placeHolder != null
                                ? AppColors.gray10.withValues(alpha: 0.3)
                                : AppColors.white,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    if (trailingImage != null)
                      Image.asset(
                        trailingImage!,
                        height: 25,
                      ),
                  ],
                )),
        leading ??
            Visibility(
              visible: showArrowRight,
              child: SvgPicture.asset(
                ImageResources.arrowRight,
                height: 20,
                colorFilter:
                    ColorFilter.mode(AppColors.gray10, BlendMode.srcIn),
              ),
            )
      ],
    );
  }
}
