import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:financo/features/asset_details/presentation/bloc/asset_detail_bloc.dart';
import 'package:financo/features/asset_details/presentation/bloc/asset_detail_event.dart';
import 'package:financo/features/asset_details/presentation/bloc/asset_detail_state.dart';
import 'package:financo/features/asset_details/presentation/widgets/detail_shimmer.dart';
import 'package:financo/features/asset_details/presentation/pages/crypto_wallet_detail_page.dart';
import 'package:financo/features/asset_details/presentation/pages/stock_detail_page.dart';
import 'package:financo/features/asset_details/presentation/pages/bank_account_detail_page.dart';
import 'package:financo/features/asset_details/presentation/pages/manual_asset_detail_page.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';
import 'package:financo/features/finance/presentation/bloc/manual_asset_detail/manual_asset_detail_bloc.dart';
import 'package:financo/di/injection_container.dart';

/// Helper class for navigating to asset detail pages
class AssetDetailNavigator {
  /// Navigate to the appropriate detail page based on asset provider and type
  static void navigateToAssetDetail(
    BuildContext context,
    Asset asset,
    String userId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => sl<AssetDetailBloc>(),
          child: _AssetDetailWrapper(asset: asset, userId: userId),
        ),
      ),
    );
  }
}

/// Wrapper widget that handles loading and displaying the correct detail page
class _AssetDetailWrapper extends StatefulWidget {
  final Asset asset;
  final String userId;

  const _AssetDetailWrapper({required this.asset, required this.userId});

  @override
  State<_AssetDetailWrapper> createState() => _AssetDetailWrapperState();
}

class _AssetDetailWrapperState extends State<_AssetDetailWrapper> {
  @override
  void initState() {
    super.initState();
    _loadAssetDetail();
  }

  void _loadAssetDetail() {
    final bloc = context.read<AssetDetailBloc>();
    final asset = widget.asset;
    final userId = widget.userId;

    // Determine which Edge Function to call based on provider
    if (asset.provider == AssetProvider.moralis) {
      bloc.add(LoadCryptoWalletDetailEvent(address: asset.assetAddressOrId));
    } else if (asset.provider == AssetProvider.fmp) {
      // Stock - use symbol
      bloc.add(LoadStockDetailEvent(symbol: asset.symbol, userId: userId));
    } else if (asset.provider == AssetProvider.plaid) {
      bloc.add(
        LoadBankAccountDetailEvent(
          itemId: asset.assetAddressOrId,
          accountId: asset.id,
          userId: userId,
        ),
      );
    } else if (asset.provider == AssetProvider.manual) {
      // Manual asset - use asset ID
      bloc.add(LoadManualAssetDetailEvent(assetId: asset.id, userId: userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssetDetailBloc, AssetDetailState>(
      builder: (context, state) {
        if (state is AssetDetailLoading) {
          return const DetailShimmer();
        } else if (state is CryptoWalletDetailLoaded) {
          return CryptoWalletDetailPage(walletDetail: state.detail);
        } else if (state is StockDetailLoaded) {
          return StockDetailPage(stockDetail: state.detail);
        } else if (state is BankAccountDetailLoaded) {
          return BankAccountDetailPage(accountDetail: state.detail);
        } else if (state is ManualAssetDetailLoaded) {
          // Provide ManualAssetDetailBloc for manual asset detail page
          return BlocProvider(
            create: (context) => sl<ManualAssetDetailBloc>(),
            child: ManualAssetDetailPage(assetDetail: state.detail),
          );
        } else if (state is AssetDetailError) {
          return _ErrorView(
            message: state.message,
            onRetry: () {
              context.read<AssetDetailBloc>().add(const RetryLoadDetailEvent());
            },
          );
        }

        return const DetailShimmer();
      },
    );
  }
}

/// Error view with retry button
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1116),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFFF4D4D),
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                'Failed to Load Details',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3861FB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Retry',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
