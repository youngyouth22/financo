import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/features/finance/presentation/pages/add_bank_account_page.dart';
import 'package:financo/features/finance/presentation/pages/add_crypto_wallet_page.dart';
import 'package:financo/features/finance/presentation/pages/add_manual_asset_page.dart';
import 'package:financo/features/finance/presentation/pages/add_stock_page.dart';
import 'package:flutter/material.dart';

/// Page for choosing what type of asset to add
class AddAssetChoicePage extends StatelessWidget {
  const AddAssetChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: AppColors.white),
        ),
        title: Text(
          'Add Asset',
          style: AppTypography.headline4Bold.copyWith(color: AppColors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Asset Type',
                style: AppTypography.headline3SemiBold.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select how you want to add your asset',
                style: AppTypography.headline2Regular.copyWith(
                  color: AppColors.gray50,
                ),
              ),
              const SizedBox(height: 32),
              _buildAssetTypeCard(
                context,
                icon: Icons.account_balance_wallet_outlined,
                title: 'Crypto Wallet',
                description: 'Add a cryptocurrency wallet via Moralis',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddCryptoWalletPage(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildAssetTypeCard(
                context,
                icon: Icons.trending_up,
                title: 'Stock',
                description: 'Add stocks and ETFs via Financial Modeling Prep',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AddStockPage()),
                ),
              ),
              const SizedBox(height: 16),
              _buildAssetTypeCard(
                context,
                icon: Icons.account_balance,
                title: 'Bank Account',
                description: 'Connect your bank account via Plaid',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddBankAccountPage(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildAssetTypeCard(
                context,
                icon: Icons.edit,
                title: 'Manual Asset',
                description: 'Add real estate, commodities, liabilities, etc.',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddManualAssetPage(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetTypeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray70),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
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
                  Text(
                    description,
                    style: AppTypography.headline2Regular.copyWith(
                      color: AppColors.gray50,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppColors.gray50, size: 16),
          ],
        ),
      ),
    );
  }
}
