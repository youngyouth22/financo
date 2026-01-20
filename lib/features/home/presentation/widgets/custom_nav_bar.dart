import 'dart:ui';

import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_spacing.dart';
import 'package:financo/common/image_resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: AppSpacing.twenty,
        right: AppSpacing.twenty,
        bottom: AppSpacing.twenty,
      ),
     
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.fifteen),
        child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: DecoratedBox(
             decoration: BoxDecoration(
            color: AppColors.gray60.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(AppSpacing.fifteen),
            border: Border(
              top: BorderSide(color: AppColors.gray60.withAlpha(100)),
              left: BorderSide(color: AppColors.gray60.withAlpha(100)),
            ),
          ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: ImageResources.home,
                  isFirst: true,
                ),
                _buildNavItem(
                  index: 1,
                  icon: ImageResources.budgetIcon,
                ),
                const SizedBox(width: 30), // Spacer
                _buildNavItem(
                  index: 2,
                  icon: ImageResources.barIcon,
                  size: 20,
                ),
                _buildNavItem(
                  index: 3,
                  icon: ImageResources.setting,
                  size: 20,
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      {required int index,
      required String icon,
      double? size,
      bool isFirst = false,
      bool isLast = false}) {
    final isSelected = widget.currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            widget.onItemSelected(index);
          },
          radius: 50,
          borderRadius: BorderRadius.only(
            topLeft: isFirst ? Radius.circular(AppSpacing.fifteen) : Radius.zero,
            bottomLeft:
                isFirst ? Radius.circular(AppSpacing.fifteen) : Radius.zero,
            topRight: isLast ? Radius.circular(AppSpacing.fifteen) : Radius.zero,
            bottomRight:
                isLast ? Radius.circular(AppSpacing.fifteen) : Radius.zero,
          ),
          // padding: EdgeInsets.symmetric(horizontal: AppSpacing.ten),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Center(
              child: SvgPicture.asset(
                icon,
                height: size ?? 18,
                width: size ?? 18,
                colorFilter: ColorFilter.mode(
                    isSelected ? AppColors.white : AppColors.gray40,
                    BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
