import 'package:financo/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Premium Shimmer loading effect for asset detail pages
/// Mimics the layout of detail pages while data is being fetched
class DetailShimmer extends StatelessWidget {
  const DetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  _buildShimmerBox(
                    width: 200,
                    height: 24,
                    borderRadius: 8,
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  _buildShimmerBox(
                    width: 150,
                    height: 14,
                    borderRadius: 6,
                  ),
                  const SizedBox(height: 16),
                  
                  // Main Value
                  _buildShimmerBox(
                    width: 180,
                    height: 36,
                    borderRadius: 10,
                  ),
                  const SizedBox(height: 8),
                  
                  // Change Indicator
                  _buildShimmerBox(
                    width: 100,
                    height: 16,
                    borderRadius: 6,
                  ),
                ],
              ),
            ),
            
            // Chart Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildShimmerBox(
                width: double.infinity,
                height: 200,
                borderRadius: 12,
              ),
            ),
            
            // Timeframe Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => _buildShimmerBox(
                    width: 50,
                    height: 32,
                    borderRadius: 8,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Stats Grid / Info Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(
                    width: 150,
                    height: 18,
                    borderRadius: 6,
                  ),
                  const SizedBox(height: 16),
                  
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: List.generate(
                      4,
                      (index) => _buildShimmerCard(),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // List Items (Transactions/Tokens)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(
                    width: 120,
                    height: 18,
                    borderRadius: 6,
                  ),
                  const SizedBox(height: 16),
                  
                  ...List.generate(
                    5,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildShimmerListItem(),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
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
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1200.ms,
          color: Colors.white10,
        );
  }

  Widget _buildShimmerCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray80, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildShimmerBox(
            width: 60,
            height: 11,
            borderRadius: 4,
          ),
          const SizedBox(height: 6),
          _buildShimmerBox(
            width: 80,
            height: 14,
            borderRadius: 4,
          ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1200.ms,
          color: Colors.white10,
        );
  }

  Widget _buildShimmerListItem() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray80, width: 1),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gray80,
              borderRadius: BorderRadius.circular(20),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 1200.ms,
                color: Colors.white10,
              ),
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(
                  width: 120,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: 6),
                _buildShimmerBox(
                  width: 80,
                  height: 12,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
          
          // Value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildShimmerBox(
                width: 70,
                height: 14,
                borderRadius: 4,
              ),
              const SizedBox(height: 6),
              _buildShimmerBox(
                width: 50,
                height: 11,
                borderRadius: 4,
              ),
            ],
          ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1200.ms,
          color: Colors.white10,
        );
  }
}
