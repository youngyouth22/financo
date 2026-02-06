import 'package:financo/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Premium Shimmer loading effect for Portfolio Insights page
/// Mimics the tabs and insight content
class InsightsShimmer extends StatelessWidget {
  const InsightsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Chart Section
          _buildShimmerBox(
            width: double.infinity,
            height: 250,
            borderRadius: 16,
          ),
          const SizedBox(height: 24),

          // Section Title
          _buildShimmerBox(width: 150, height: 18, borderRadius: 6),
          const SizedBox(height: 16),

          // Grid of Stats Cards (2x2)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: List.generate(4, (index) => _buildStatCardShimmer()),
          ),
          const SizedBox(height: 24),

          // Another Section Title
          _buildShimmerBox(width: 120, height: 18, borderRadius: 6),
          const SizedBox(height: 16),

          // List Items (Holdings/Allocations)
          ...List.generate(
            6,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildListItemShimmer(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required double borderRadius,
  }) {
    return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.gray80,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white10);
  }

  Widget _buildStatCardShimmer() {
    return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.gray80,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gray70, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildShimmerBox(width: 60, height: 11, borderRadius: 4),
              const SizedBox(height: 6),
              _buildShimmerBox(width: 80, height: 14, borderRadius: 4),
            ],
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white10);
  }

  Widget _buildListItemShimmer() {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gray80,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray70, width: 1),
          ),
          child: Row(
            children: [
              // Icon/Logo
              Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.gray70,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 1200.ms, color: Colors.white10),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(width: 120, height: 14, borderRadius: 4),
                    const SizedBox(height: 6),
                    _buildShimmerBox(width: 80, height: 11, borderRadius: 4),
                  ],
                ),
              ),

              // Percentage/Value
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildShimmerBox(width: 60, height: 14, borderRadius: 4),
                  const SizedBox(height: 6),
                  _buildShimmerBox(width: 40, height: 11, borderRadius: 4),
                ],
              ),
            ],
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white10);
  }
}
