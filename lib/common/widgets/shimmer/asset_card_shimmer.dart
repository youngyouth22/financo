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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray40,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gray70.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.gray70.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
          ).animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 1200.ms, color: Colors.white10),
          
          const SizedBox(width: 16),
          
          // Text placeholders
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name placeholder
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.gray70.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 1200.ms, color: Colors.white10),
                
                const SizedBox(height: 8),
                
                // Symbol placeholder
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.gray70.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 1200.ms, color: Colors.white10),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Value placeholders
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Value placeholder
              Container(
                width: 100,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.gray70.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 1200.ms, color: Colors.white10),
              
              const SizedBox(height: 8),
              
              // Change placeholder
              Container(
                width: 60,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.gray70.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 1200.ms, color: Colors.white10),
            ],
          ),
        ],
      ),
    );
  }
}
