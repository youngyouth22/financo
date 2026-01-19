import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_spacing.dart';
import 'package:financo/common/app_typography.dart';
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onClick;
  final Gradient? gradient;
  final Color? textColor;
  final Border? border;
  final double height;
  final double borderRadius;
  final bool disabled;
  final bool loading;
  final Widget? icon;
  final Color? color;
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onClick,
    this.gradient,
    this.textColor,
    this.border,
    this.borderRadius = 50,
    this.height = 50, //54
    this.disabled = false,
    this.icon,
    this.color,
    this.loading = false,
  });
  // TODO: Animation de shimmer pour faire briller le bouton surtout sur les bordures lorsque isDisable passe a true

  Border get primaryButtonBorder => Border(
    top: BorderSide(color: AppColors.accentP0.withAlpha(150), width: 2),
    left: BorderSide(color: AppColors.accentP0.withAlpha(150), width: 1),
    right: BorderSide(color: AppColors.accentP0.withAlpha(150), width: 1),
  );
  Border get disabledButtonBorder => Border(
    top: BorderSide(color: AppColors.gray10.withAlpha(100), width: 2),
    left: BorderSide(color: AppColors.gray10.withAlpha(100), width: 1),
    right: BorderSide(color: AppColors.gray10.withAlpha(100), width: 1),
  );
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(
        color: color,
        gradient: color != null ? null : disabled || loading
            ? AppColors.grayGradientDisabled
            : gradient ?? AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled || loading ? null : onClick,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border:
                  border ??
                  (disabled || loading
                      ? disabledButtonBorder
                      : primaryButtonBorder),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: icon != null
                    ? MainAxisAlignment.spaceEvenly
                    : MainAxisAlignment.center,
                spacing: icon != null ? AppSpacing.ten : 0,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icon != null) icon!,
                  Text(
                    text,
                    style: AppTypography.headline3Bold.copyWith(
                      color: textColor ?? Colors.white,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // .animate(
    //   onPlay: (controller) => controller.repeat(), // boucle infinie
    // )
    // .shimmer(duration: 2.seconds);
  }
}
