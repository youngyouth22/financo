import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/common/common_widgets/price_line_chart.dart';
import 'package:financo/features/finance/domain/entities/crypto_wallet_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Premium Crypto Wallet Detail Page with Assets and Activity tabs
class CryptoWalletDetailPage extends StatefulWidget {
  final CryptoWalletDetail walletDetail;

  const CryptoWalletDetailPage({
    super.key,
    required this.walletDetail,
  });

  @override
  State<CryptoWalletDetailPage> createState() => _CryptoWalletDetailPageState();
}

class _CryptoWalletDetailPageState extends State<CryptoWalletDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.walletDetail.change24h >= 0;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: AppColors.white),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          _buildHeader(isPositive),
          
          // Chart Section
          _buildChartSection(isPositive),
          
          // Tab Bar
          _buildTabBar(),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAssetsTab(),
                _buildActivityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isPositive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wallet Name
          Text(
            widget.walletDetail.name,
            style: AppTypography.headline3Bold.copyWith(
              color: AppColors.white,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          
          // Wallet Address
          GestureDetector(
            onTap: () {
              Clipboard.setData(
                ClipboardData(text: widget.walletDetail.walletAddress),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Address copied to clipboard')),
              );
            },
            child: Row(
              children: [
                Text(
                  _formatAddress(widget.walletDetail.walletAddress),
                  style: AppTypography.headline2Regular.copyWith(
                    color: AppColors.gray40,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.copy, size: 12, color: AppColors.gray40),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Total Value
          Text(
            '\$${NumberFormat('#,##0.00').format(widget.walletDetail.totalValueUsd)}',
            style: AppTypography.headline3Bold.copyWith(
              color: AppColors.white,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 8),
          
          // 24h Change
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? AppColors.success : AppColors.error,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive ? '+' : ''}${widget.walletDetail.change24h.toStringAsFixed(2)}%',
                style: AppTypography.headline2SemiBold.copyWith(
                  color: isPositive ? AppColors.success : AppColors.error,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '24h',
                style: AppTypography.headline2Regular.copyWith(
                  color: AppColors.gray40,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(bool isPositive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: PriceLineChart(
        priceHistory: widget.walletDetail.priceHistory,
        isPositive: isPositive,
        height: 200,
        showTimeframeSelector: true,
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.accent,
        indicatorWeight: 3,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.gray40,
        labelStyle: AppTypography.headline2SemiBold,
        unselectedLabelStyle: AppTypography.headline2Regular,
        tabs: const [
          Tab(text: 'Assets'),
          Tab(text: 'Activity'),
        ],
      ),
    );
  }

  Widget _buildAssetsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: widget.walletDetail.tokens.length,
      itemBuilder: (context, index) {
        final token = widget.walletDetail.tokens[index];
        return _buildTokenCard(token);
      },
    );
  }

  Widget _buildTokenCard(CryptoToken token) {
    final isPositive = token.change24h >= 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray80,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray80, width: 1),
      ),
      child: Row(
        children: [
          // Token Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gray80,
              borderRadius: BorderRadius.circular(20),
            ),
            child: token.iconUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      token.iconUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.currency_bitcoin,
                        color: AppColors.accent,
                      ),
                    ),
                  )
                : Icon(Icons.currency_bitcoin, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          
          // Token Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  token.symbol,
                  style: AppTypography.headline2SemiBold.copyWith(
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${token.balance.toStringAsFixed(4)} ${token.symbol}',
                  style: AppTypography.headline1Regular.copyWith(
                    color: AppColors.gray40,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Value & Change
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${NumberFormat('#,##0.00').format(token.valueUsd)}',
                style: AppTypography.headline2SemiBold.copyWith(
                  color: AppColors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPositive ? AppColors.success : AppColors.error,
                    size: 10,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${isPositive ? '+' : ''}${token.change24h.toStringAsFixed(2)}%',
                    style: AppTypography.headline1Regular.copyWith(
                      color: isPositive ? AppColors.success : AppColors.error,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    if (widget.walletDetail.transactions.isEmpty) {
      return Center(
        child: Text(
          'No transactions yet',
          style: AppTypography.headline2Regular.copyWith(
            color: AppColors.gray40,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: widget.walletDetail.transactions.length,
      itemBuilder: (context, index) {
        final tx = widget.walletDetail.transactions[index];
        return _buildTransactionCard(tx);
      },
    );
  }

  Widget _buildTransactionCard(CryptoTransaction tx) {
    final IconData icon;
    final Color iconColor;
    final String typeLabel;

    switch (tx.type) {
      case CryptoTransactionType.sent:
        icon = Icons.arrow_upward;
        iconColor = AppColors.error;
        typeLabel = 'Sent';
        break;
      case CryptoTransactionType.received:
        icon = Icons.arrow_downward;
        iconColor = AppColors.success;
        typeLabel = 'Received';
        break;
      case CryptoTransactionType.swap:
        icon = Icons.swap_horiz;
        iconColor = AppColors.accent;
        typeLabel = 'Swap';
        break;
      case CryptoTransactionType.stake:
        icon = Icons.lock;
        iconColor = AppColors.primary;
        typeLabel = 'Stake';
        break;
      case CryptoTransactionType.unstake:
        icon = Icons.lock_open;
        iconColor = AppColors.warning;
        typeLabel = 'Unstake';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray80,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray80, width: 1),
      ),
      child: Row(
        children: [
          // Transaction Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          
          // Transaction Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: AppTypography.headline2SemiBold.copyWith(
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tx.entityName ?? _formatAddress(tx.toAddress),
                  style: AppTypography.headline1Regular.copyWith(
                    color: AppColors.gray40,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy • HH:mm').format(tx.timestamp),
                  style: AppTypography.headline1Regular.copyWith(
                    color: AppColors.gray50,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tx.tokenAmount.toStringAsFixed(4)} ${tx.tokenSymbol}',
                style: AppTypography.headline2SemiBold.copyWith(
                  color: AppColors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '\$${NumberFormat('#,##0.00').format(tx.amountUsd)}',
                style: AppTypography.headline1Regular.copyWith(
                  color: AppColors.gray40,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}
