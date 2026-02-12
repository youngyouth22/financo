import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:financo/common/app_colors.dart';

/// Shimmer loading widget for asset cards
///
/// Mimics the layout of AssetCard with shimmer animation
class AssetCardShimmer extends StatelessWidget {
  const AssetCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.gray80,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray70),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon placeholder
              Container(
                    width: 36,
                    height: 36,
                    decoration:  BoxDecoration(
                      color: AppColors.gray70,
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 1200.ms, color: Colors.white10),

              // Menu icon placeholder
              Container(
                    width: 18,
                    height: 18,
                    decoration:  BoxDecoration(
                      color: AppColors.gray70,
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 1200.ms, color: Colors.white10),
            ],
          ),
          const Spacer(),
          // Name placeholder
          Container(
                width: double.infinity,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.gray70,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1200.ms, color: Colors.white10),
          const SizedBox(height: 8),

          Row(
            children: [
              // Symbol placeholder
              Expanded(
                child:
                    Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.gray70,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(duration: 1200.ms, color: Colors.white10),
              ),
              const SizedBox(width: 8),
              // Badge placeholder
              Container(
                    width: 40,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.gray70,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 1200.ms, color: Colors.white10),
            ],
          ),
          const SizedBox(height: 8),
          // Value placeholder
          Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.gray70,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1200.ms, color: Colors.white10),
        ],
      ),
    );
  }
}
