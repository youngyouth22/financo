import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/common/common_widgets/mini_sparkline.dart';
import 'package:financo/core/utils/extract_two_first_letter.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:financo/features/asset_details/presentation/utils/asset_detail_navigator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssetCard extends StatelessWidget {
  final Asset asset;
  const AssetCard({super.key, required this.asset});

  bool get isPos => asset.change24h >= 0;

  Widget _buildAssetIcon(Asset asset) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.gray30.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(color: AppColors.gray40.withValues(alpha: 0.2)),
          left: BorderSide(color: AppColors.gray40.withValues(alpha: 0.2)),
        ),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: asset.iconUrl.isNotEmpty
            ? asset.type == AssetType.crypto
                  ? SvgPicture.network(
                      asset.iconUrl,
                      fit: BoxFit.cover,
                      height: 36,
                      width: 36,
                      errorBuilder: (_, _, _) =>
                          Icon(Icons.currency_bitcoin, color: AppColors.accent),
                    )
                  : Image.network(
                      asset.iconUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.accent,
                      ),
                    )
            : Text(
                extractTwoFirstLetter(asset.symbol),
                textAlign: TextAlign.center,
                style: AppTypography.headline2Bold.copyWith(
                  color: AppColors.gray60,
                ),
              ),
      ),
    );
  }

  Widget _buildChangeBadge(double change, bool isPos) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isPos ? Colors.green : Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${isPos ? '+' : ''}${change.toStringAsFixed(2)}%',
        style: TextStyle(
          color: isPos ? Colors.green : Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  //   void _showAssetActions(Asset asset) {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: AppColors.card,
  //     builder: (context) => Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         ListTile(
  //           leading: const Icon(Icons.delete_outline, color: Colors.red),
  //           title: const Text(
  //             'Remove Asset',
  //             style: TextStyle(color: Colors.white),
  //           ),
  //           onTap: () {
  //             context.read<AssetsBloc>().add(DeleteAssetEvent(asset.id));
  //             Navigator.pop(context);
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
        AssetDetailNavigator.navigateToAssetDetail(
          context,
          asset,
          userId,
        );
      },
      child: Container(
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
              _buildAssetIcon(asset),
              IconButton(
                icon: Icon(Icons.more_vert, color: AppColors.gray40, size: 18),
                onPressed: () {
                  // _showAssetActions(asset);
                },
              ),
            ],
          ),
          if (asset.sparkline != null && asset.sparkline!.isNotEmpty)
            Center(
              child: MiniSparkline(points: asset.sparkline!, isPositive: isPos),
            ),
          const Spacer(),
          Text(
            asset.name,
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  asset.symbol,
                  style: AppTypography.headline1Regular.copyWith(
                    color: AppColors.gray40,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (asset.change24h > 0)
                _buildChangeBadge(asset.change24h, isPos),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${asset.balanceUsd.toStringAsFixed(2)}',
            style: AppTypography.headline3Bold.copyWith(color: AppColors.white),
          ),
        ],
      ),
      ),
    );
  }
}
