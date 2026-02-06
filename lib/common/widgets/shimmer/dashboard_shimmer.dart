import 'package:financo/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Premium Shimmer loading effect for Dashboard page
/// Mimics the header, allocation bar, and top assets list
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.gray70.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: SafeArea(
              top: true,
              bottom: false,
              child: Column(
                children: [
                  // App Bar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Row(
                      children: [
                        _buildShimmerBox(
                          width: 40,
                          height: 40,
                          borderRadius: 8,
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // "Total networth" label
                  _buildShimmerBox(width: 120, height: 12, borderRadius: 4),
                  const SizedBox(height: 12),

                  // Net worth value
                  _buildShimmerBox(width: 200, height: 48, borderRadius: 8),
                  const SizedBox(height: 20),

                  // Allocation label + percentage
                  Row(
                    children: [
                      _buildShimmerBox(width: 80, height: 12, borderRadius: 4),
                      const Spacer(),
                      _buildShimmerBox(width: 40, height: 12, borderRadius: 4),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Allocation bar
                  _buildShimmerBox(
                    width: double.infinity,
                    height: 8,
                    borderRadius: 2,
                  ),
                  const SizedBox(height: 20),

                  // 3 Status Buttons (Crypto, Stocks, Other)
                  Row(
                    children: [
                      Expanded(child: _buildStatusButtonShimmer()),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatusButtonShimmer()),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatusButtonShimmer()),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Filter Toggle
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            padding: const EdgeInsets.all(8),
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildShimmerBox(
                    width: double.infinity,
                    height: 34,
                    borderRadius: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildShimmerBox(
                    width: double.infinity,
                    height: 34,
                    borderRadius: 12,
                  ),
                ),
              ],
            ),
          ),

          // Top 5 Assets List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAssetRowShimmer(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
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

  Widget _buildStatusButtonShimmer() {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.gray80,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBox(width: 50, height: 10, borderRadius: 4),
              const SizedBox(height: 4),
              _buildShimmerBox(width: 70, height: 14, borderRadius: 4),
            ],
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white10);
  }

  Widget _buildAssetRowShimmer() {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gray80,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Icon
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

              // Name
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

              // Value
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildShimmerBox(width: 70, height: 14, borderRadius: 4),
                  const SizedBox(height: 6),
                  _buildShimmerBox(width: 50, height: 11, borderRadius: 4),
                ],
              ),
            ],
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white10);
  }
}
