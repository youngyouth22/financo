import 'package:financo/common/app_colors.dart';
import 'package:financo/common/image_resources.dart';
import 'package:financo/core/utils/format_price.dart';
import 'package:financo/features/finance/data/models/networth_response_model.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SubScriptionHomeRow extends StatelessWidget {
  final AssetDetail asset;
  final VoidCallback onPressed;

  const SubScriptionHomeRow({
    super.key,
    required this.asset,
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: asset.type == AssetType.crypto.name
                          ? SvgPicture.network(
                              asset.iconUrl,
                              fit: BoxFit.cover,
                              height: 36,
                              width: 36,
                              errorBuilder: (_, _, _) =>
                                  Image.asset(ImageResources.placeHolderPng),
                            )
                          : Image.network(
                              asset.iconUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  Image.asset(ImageResources.placeHolderPng),
                            ),
                    ),
                  ),
                  // Positioned(
                  //   bottom: 0,
                  //   right: 0,
                  //   child: Container(
                  //     width: 16,
                  //     height: 16,
                  //     decoration: BoxDecoration(
                  //       color: AppColors.success,
                  //       border: Border.all(color: AppColors.gray, width: 2),
                  //       borderRadius: BorderRadius.circular(50),
                  //     ),
                  //     child: SvgPicture.asset(ImageResources.incomeIcon),
                  //   ),
                  // ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      maxLines: 1,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        overflow: TextOverflow.ellipsis,
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
                '\$${formatPrice(asset.value)}',
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
