import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_spacing.dart';
import 'package:financo/common/image_resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomFloatingButton extends StatelessWidget {
  final bool isMenuOpen;
  final VoidCallback onPressed;
  const CustomFloatingButton({
    super.key,
    this.isMenuOpen = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.fifty),
      ),
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.accent,
                const Color.fromARGB(255, 249, 132, 116),
                AppColors.accent,
              ],
              transform: const GradientRotation(2),
              begin: Alignment.bottomCenter,
            ),
            border: Border(
              top: BorderSide(color: AppColors.accentP0.withAlpha(100)),
              left: BorderSide(color: AppColors.accentP0.withAlpha(100)),
              right: BorderSide(color: AppColors.accentP0.withAlpha(100)),
            )),
        child: Center(
          child: AnimatedRotation(
            turns: isMenuOpen ? 0.125 : 0.0, // 45 degrés
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
            child: SvgPicture.asset(
              ImageResources.addIcon,
              height: 18,
              colorFilter: ColorFilter.mode(AppColors.white, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}
