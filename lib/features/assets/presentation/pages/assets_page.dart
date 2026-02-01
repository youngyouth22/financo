import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/core/utils/extract_two_first_letter.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';
import 'package:financo/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:financo/features/finance/presentation/bloc/finance_event.dart';
import 'package:financo/features/finance/presentation/bloc/finance_state.dart';
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
    context.read<FinanceBloc>().add(const WatchAssetsEvent());
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
      body: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          List<Asset> allAssets = [];

          if (state is AssetsWatching) {
            allAssets = state.assets;
          } else if (state is FinanceLoading) {
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
      itemBuilder: (context, index) => _buildAssetCard(assets[index]),
    );
  }

  Widget _buildAssetCard(Asset asset) {
    final bool isPos = asset.change24h >= 0;

    return Container(
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
                onPressed: () => _showAssetActions(asset),
              ),
            ],
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
    );
  }

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
            ? Image.network(
                asset.iconUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.account_balance_wallet, color: AppColors.accent),
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

  void _showAssetActions(Asset asset) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              'Remove Asset',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              context.read<FinanceBloc>().add(DeleteAssetEvent(asset.id));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
