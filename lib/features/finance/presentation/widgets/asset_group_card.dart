import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:flutter/material.dart';

/// Card displaying asset group information
///
/// Shows:
/// - Group icon and name
/// - Total value
/// - Percentage of net worth
/// - Number of assets
class AssetGroupCard extends StatelessWidget {
  final String title;
  final double amount;
  final double percentage;
  final int assetCount;
  final Color color;
  final IconData icon;

  const AssetGroupCard({
    super.key,
    required this.title,
    required this.amount,
    required this.percentage,
    required this.assetCount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gray70,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headline3SemiBold.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatCurrency(amount),
                      style: AppTypography.headline4Bold.copyWith(
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '· ${percentage.toStringAsFixed(0)}%',
                      style: AppTypography.headline2Regular.copyWith(
                        color: AppColors.gray40,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$assetCount ${assetCount == 1 ? 'asset' : 'assets'}',
                  style: AppTypography.headline1Regular.copyWith(
                    color: AppColors.gray50,
                  ),
                ),
              ],
            ),
          ),
          
          // Arrow icon
          Icon(
            Icons.arrow_forward_ios,
            color: AppColors.gray60,
            size: 16,
          ),
        ],
      ),
    );
  }

  /// Format currency with abbreviation
  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(2)}K';
    } else {
      return '\$${value.toStringAsFixed(2)}';
    }
  }
}
