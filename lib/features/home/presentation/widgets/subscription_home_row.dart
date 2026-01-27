import 'package:financo/common/app_colors.dart';
import 'package:financo/common/image_resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SubScriptionHomeRow extends StatelessWidget {
  final Map sObj;
  final VoidCallback onPressed;

  const SubScriptionHomeRow({
    super.key,
    required this.sObj,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Image.asset(ImageResources.placeHolderPng),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        border: Border.all(color: AppColors.gray, width: 2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: SvgPicture.asset(ImageResources.incomeIcon),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sObj["name"],
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '2 January 2022, 9:00',
                      style: TextStyle(
                        color: AppColors.gray50,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "+ \$${sObj["price"]}",
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
