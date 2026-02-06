import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/common/widgets/empty_states/no_data_state.dart';
import 'package:financo/features/assets/presentation/widgets/asset_card.dart';
import 'package:financo/common/widgets/shimmer/asset_card_shimmer.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';
import 'package:financo/features/assets/presentation/bloc/assets_bloc.dart';
import 'package:financo/features/assets/presentation/bloc/assets_event.dart';
import 'package:financo/features/assets/presentation/bloc/assets_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key});

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    // Lance l'écoute en temps réel des changements d'actifs
    context.read<AssetsBloc>().add(const WatchAssetsEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Your Portfolio'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.white,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Stocks"),
            Tab(text: "Crypto"),
            Tab(text: "Fixed"),
            Tab(text: "Vault"),
          ],
        ),
      ),
      body: BlocBuilder<AssetsBloc, AssetsState>(
        builder: (context, state) {
          List<Asset> allAssets = [];

          if (state is AssetsRealTimeUpdated) {
            allAssets = state.assets;
          } else if (state is AssetsLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 6,
              itemBuilder: (context, index) => const AssetCardShimmer(),
            );
          }

          if (allAssets.isEmpty) return _buildEmptyState();

          // --- FILTRAGE SIMPLE PAR CATÉGORIE ---
          final stocks = allAssets
              .where((a) => a.type == AssetType.stock)
              .toList();
          final crypto = allAssets
              .where((a) => a.type == AssetType.crypto)
              .toList();
          final fixed = allAssets
              .where(
                (a) =>
                    a.type == AssetType.investment ||
                    a.type == AssetType.liability,
              )
              .toList();
          final vault = allAssets
              .where(
                (a) =>
                    a.type == AssetType.commodity ||
                    a.type == AssetType.realEstate,
              )
              .toList();

          return Padding(
            padding: const EdgeInsets.only(bottom: 50),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllTab(stocks, crypto, fixed, vault),
                _buildGenericGrid(stocks),
                _buildGenericGrid(crypto),
                _buildGenericGrid(fixed),
                _buildGenericGrid(vault),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- BUILDERS DE COMPOSANTS ---

  Widget _buildAllTab(
    List<Asset> stocks,
    List<Asset> crypto,
    List<Asset> fixed,
    List<Asset> vault,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stocks.isNotEmpty) ...[
            _buildHeader('📈 Stocks'),
            _buildAssetGrid(stocks),
          ],
          if (crypto.isNotEmpty) ...[
            _buildHeader('₿ Cryptocurrency'),
            _buildAssetGrid(
              crypto,
            ), // Affichage direct des wallets sans sous-titres
          ],
          if (fixed.isNotEmpty) ...[
            _buildHeader('📋 Fixed Income'),
            _buildAssetGrid(fixed),
          ],
          if (vault.isNotEmpty) ...[
            _buildHeader('🔒 Vault'),
            _buildAssetGrid(vault),
          ],
        ],
      ),
    );
  }

  Widget _buildGenericGrid(List<Asset> assets) {
    return assets.isEmpty ? _buildEmptyState() : _buildAssetGrid(assets);
  }

  Widget _buildAssetGrid(List<Asset> assets) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1 / 1,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) => AssetCard(asset: assets[index]),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: AppTypography.headline3Bold.copyWith(color: AppColors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const NoDataState(
      icon: Icons.account_balance_wallet_outlined,
      title: 'No Assets Found',
      message: 'Start building your portfolio by adding your first asset',
    );
  }
}
