import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/features/assets/presentation/widgets/asset_card.dart';
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
    context.read<AssetsBloc>().add(const WatchAssetsEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- LOGIQUE DE FILTRAGE ET GROUPAGE ---

  Map<String, List<Asset>> _groupCryptoByAddress(List<Asset> assets) {
    final Map<String, List<Asset>> grouped = {};
    for (var asset in assets.where((a) => a.type == AssetType.crypto)) {
      // On extrait l'adresse (on enlève le suffixe :symbol si présent)
      final address = asset.assetAddressOrId.split(':').first;
      if (!grouped.containsKey(address)) grouped[address] = [];
      grouped[address]!.add(asset);
    }
    return grouped;
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
            return Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          if (allAssets.isEmpty) return _buildEmptyState();

          // Filtrage par catégorie
          final stocks = allAssets
              .where((a) => a.type == AssetType.stock)
              .toList();
          final cryptoGrouped = _groupCryptoByAddress(allAssets);
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
                _buildAllTab(stocks, cryptoGrouped, fixed, vault),
                _buildGenericGrid(stocks),
                _buildCryptoTab(cryptoGrouped),
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
    Map<String, List<Asset>> cryptoGrouped,
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
          if (cryptoGrouped.isNotEmpty) ...[
            _buildHeader('₿ Cryptocurrency'),
            ...cryptoGrouped.entries.map(
              (e) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildSubHeader(e.key), _buildAssetGrid(e.value)],
              ),
            ),
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

  Widget _buildCryptoTab(Map<String, List<Asset>> cryptoGrouped) {
    return SingleChildScrollView(
      child: Column(
        children: cryptoGrouped.entries
            .map(
              (e) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildSubHeader(e.key), _buildAssetGrid(e.value)],
              ),
            )
            .toList(),
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1 / 1,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) => AssetCard( asset:assets[index]),
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

  Widget _buildSubHeader(String address) {
    final shortAddr =
        "${address.substring(0, 6)}...${address.substring(address.length - 4)}";
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Text(
        "Wallet $shortAddr",
        style: AppTypography.headline1Bold.copyWith(color: AppColors.accent),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text("No assets found", style: TextStyle(color: AppColors.gray40)),
    );
  }


}
