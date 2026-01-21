import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/features/finance/presentation/pages/add_bank_account_page.dart';
import 'package:financo/features/finance/presentation/pages/add_crypto_wallet_page.dart';
import 'package:flutter/material.dart';

/// Modal for choosing asset type to add
///
/// Options:
/// - Add Crypto Wallet (Moralis)
/// - Add Bank Account (Plaid)
class AddAssetModal extends StatelessWidget {
  const AddAssetModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Add Asset',
                style: AppTypography.headline4Bold.copyWith(
                  color: AppColors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  color: AppColors.gray50,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Choose the type of asset you want to add',
            style: AppTypography.headline2Regular.copyWith(
              color: AppColors.gray40,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Crypto wallet option
          _buildAssetOption(
            context: context,
            icon: Icons.currency_bitcoin,
            title: 'Crypto Wallet',
            description: 'Add your crypto wallet via Moralis',
            color: AppColors.primary,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddCryptoWalletPage(),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Bank account option
          _buildAssetOption(
            context: context,
            icon: Icons.account_balance,
            title: 'Bank Account',
            description: 'Connect your bank via Plaid',
            color: AppColors.accentS,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddBankAccountPage(),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Stocks option (coming soon)
          _buildAssetOption(
            context: context,
            icon: Icons.trending_up,
            title: 'Stocks & ETFs',
            description: 'Coming soon',
            color: AppColors.accent,
            onTap: null,
            isDisabled: true,
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Build asset option card
  Widget _buildAssetOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDisabled ? AppColors.gray80 : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDisabled ? AppColors.gray70 : color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDisabled
                    ? AppColors.gray70
                    : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isDisabled ? AppColors.gray50 : color,
                size: 28,
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
                    style: AppTypography.headline3Bold.copyWith(
                      color: isDisabled ? AppColors.gray50 : AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTypography.headline2Regular.copyWith(
                      color: AppColors.gray50,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow
            if (!isDisabled)
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.gray60,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

/// Show add asset modal
void showAddAssetModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const AddAssetModal(),
  );
}
