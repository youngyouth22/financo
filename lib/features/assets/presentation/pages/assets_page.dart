import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/common/image_resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

// Modèle pour un asset
class Asset {
  final String symbol;
  final String name;
  final double value;
  final double change;
  final bool isPositive;
  final IconData icon;
  final String category;

  Asset({
    required this.symbol,
    required this.name,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.category,
  });
}

class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key});

  @override
  createState() => _AssetsPage();
}

class _AssetsPage extends State<AssetsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Données factices
  late final List<Asset> allAssets;
  late final List<Asset> stocksAssets;
  late final List<Asset> cryptoAssets;
  late final List<Asset> fixedAssets;
  late final List<Asset> vaultAssets;

  @override
  void initState() {
    super.initState();

    // Initialiser les données factices
    _initializeAssets();

    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(
        () {},
      ); // Pour rafraîchir la couleur à chaque changement d'onglet
    });
  }

  void _initializeAssets() {
    stocksAssets = [
      Asset(
        symbol: 'AAPL',
        name: 'Apple Inc.',
        value: 15250.50,
        change: 2.45,
        isPositive: true,
        icon: Icons.trending_up_rounded,
        category: 'Technology',
      ),
      Asset(
        symbol: 'MSFT',
        name: 'Microsoft Corp.',
        value: 12000.00,
        change: 1.82,
        isPositive: true,
        icon: Icons.trending_up_rounded,
        category: 'Technology',
      ),
      Asset(
        symbol: 'GOOGL',
        name: 'Alphabet Inc.',
        value: 8500.75,
        change: -0.95,
        isPositive: false,
        icon: Icons.trending_down_rounded,
        category: 'Technology',
      ),
      Asset(
        symbol: 'TSLA',
        name: 'Tesla Inc.',
        value: 6200.30,
        change: 3.50,
        isPositive: true,
        icon: Icons.trending_up_rounded,
        category: 'Automotive',
      ),
    ];

    cryptoAssets = [
      Asset(
        symbol: 'BTC',
        name: 'Bitcoin',
        value: 25000.00,
        change: 5.23,
        isPositive: true,
        icon: Icons.currency_bitcoin_rounded,
        category: 'Cryptocurrency',
      ),
      Asset(
        symbol: 'ETH',
        name: 'Ethereum',
        value: 8750.50,
        change: 3.12,
        isPositive: true,
        icon: Icons.currency_bitcoin_rounded,
        category: 'Cryptocurrency',
      ),
      Asset(
        symbol: 'XRP',
        name: 'Ripple',
        value: 3200.00,
        change: -2.15,
        isPositive: false,
        icon: Icons.trending_down_rounded,
        category: 'Cryptocurrency',
      ),
    ];

    fixedAssets = [
      Asset(
        symbol: 'BOND-01',
        name: 'Government Bonds 5Y',
        value: 20000.00,
        change: 0.45,
        isPositive: true,
        icon: Icons.event_repeat_rounded,
        category: 'Fixed Income',
      ),
      Asset(
        symbol: 'CD-02',
        name: 'Certificate of Deposit',
        value: 10000.00,
        change: 0.25,
        isPositive: true,
        icon: Icons.event_repeat_rounded,
        category: 'Fixed Income',
      ),
    ];

    vaultAssets = [
      Asset(
        symbol: 'GOLD',
        name: 'Gold Reserve',
        value: 15500.00,
        change: 1.75,
        isPositive: true,
        icon: Icons.shelves,
        category: 'Precious Metals',
      ),
      Asset(
        symbol: 'SILVER',
        name: 'Silver Vault',
        value: 5200.50,
        change: -0.65,
        isPositive: false,
        icon: Icons.trending_down_rounded,
        category: 'Precious Metals',
      ),
    ];

    allAssets = [
      ...stocksAssets,
      ...cryptoAssets,
      ...fixedAssets,
      ...vaultAssets,
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget customTabBar({
    required String text,
    String? icon,
    IconData? iconData,
    required bool selected,
  }) {
    return Row(
      spacing: 8,
      children: [
        if (iconData != null)
          Icon(
            iconData,
            size: 18,
            color: selected ? AppColors.accent : AppColors.gray20,
          ),
        if (icon != null)
          SvgPicture.asset(
            icon,
            height: 15,
            colorFilter: ColorFilter.mode(
              selected ? AppColors.accent : AppColors.gray20,
              BlendMode.srcIn,
            ),
          ),
        Text(text),
      ],
    );
  }

  List<Tab> get tabs => [
    _buildTab(0, 'All', Icons.grid_view_rounded),
    _buildTab(1, 'Stocks', Icons.trending_up_rounded),
    _buildTab(2, 'Crypto', Icons.currency_bitcoin_rounded),
    _buildTab(3, 'Fixed', Icons.event_repeat_rounded),
    _buildTab(4, 'Vault', Icons.shelves),
  ];

  Tab _buildTab(int index, String label, IconData iconData) {
    return Tab(
      child: customTabBar(
        text: label,
        iconData: iconData,
        selected: _tabController.index == index,
      ),
    );
  }

  // Widget pour afficher un asset dans la liste
  Widget _buildAssetCard(Asset asset) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray80,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray70, width: 0.5),
      ),
      child: Row(
        children: [
          // Icône à gauche
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(asset.icon, color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 12),

          // Nom et symbole au centre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  style: AppTypography.headline4Medium.copyWith(
                    color: AppColors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  asset.symbol,
                  style: AppTypography.headline1Regular.copyWith(
                    color: AppColors.gray20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Valeur et changement à droite
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${asset.value.toStringAsFixed(2)}',
                style: AppTypography.headline4Medium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: asset.isPositive
                      ? Colors.green.withAlpha(25)
                      : Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      asset.isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: asset.isPositive ? Colors.green : Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${asset.change.abs().toStringAsFixed(2)}%',
                      style: AppTypography.headline1Regular.copyWith(
                        color: asset.isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget pour l'en-tête de groupe
  Widget _buildGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: AppTypography.headline3Medium.copyWith(color: AppColors.white),
      ),
    );
  }

  // Vue groupée pour l'onglet "All"
  Widget _buildGroupedListView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stocksAssets.isNotEmpty) ...[
            _buildGroupHeader('📈 Stocks'),
            ...stocksAssets.map((asset) => _buildAssetCard(asset)),
          ],
          if (cryptoAssets.isNotEmpty) ...[
            _buildGroupHeader('₿ Cryptocurrency'),
            ...cryptoAssets.map((asset) => _buildAssetCard(asset)),
          ],
          if (fixedAssets.isNotEmpty) ...[
            _buildGroupHeader('📋 Fixed Income'),
            ...fixedAssets.map((asset) => _buildAssetCard(asset)),
          ],
          if (vaultAssets.isNotEmpty) ...[
            _buildGroupHeader('🔒 Vault'),
            ...vaultAssets.map((asset) => _buildAssetCard(asset)),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Vue simple pour un onglet spécifique
  Widget _buildCategoryView(List<Asset> assets) {
    if (assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: AppColors.gray20),
            const SizedBox(height: 16),
            Text(
              'No assets in this category',
              style: AppTypography.headline4Medium.copyWith(
                color: AppColors.gray20,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: assets.map((asset) => _buildAssetCard(asset)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: SvgPicture.asset(
            ImageResources.financoLogo,
            colorFilter: ColorFilter.mode(AppColors.white, BlendMode.srcIn),
            height: 40,
          ),
        ),
        title: Text(
          'Your Assets',
          style: AppTypography.headline5Bold.copyWith(color: AppColors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: tabs,
          dividerColor: AppColors.gray70,
          indicatorColor: AppColors.accent,
          labelStyle: AppTypography.headline3Medium.copyWith(
            color: AppColors.accent,
          ),
          unselectedLabelStyle: AppTypography.headline3Medium.copyWith(
            color: AppColors.gray20,
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildGroupedListView(), // All - Grouped view
            _buildCategoryView(stocksAssets), // Stocks
            _buildCategoryView(cryptoAssets), // Crypto
            _buildCategoryView(fixedAssets), // Fixed
            _buildCategoryView(vaultAssets), // Vault
          ],
        ),
      ),
    );
  }
}
