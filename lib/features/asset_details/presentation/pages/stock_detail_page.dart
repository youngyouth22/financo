import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/common/common_widgets/price_line_chart.dart';
import 'package:financo/features/finance/domain/entities/stock_detail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:country_picker/country_picker.dart';

/// Premium Stock & Commodity Detail Page with market stats and diversification
class StockDetailPage extends StatefulWidget {
  final StockDetail stockDetail;

  const StockDetailPage({super.key, required this.stockDetail});

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.stockDetail.change24h >= 0;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.star_border, color: AppColors.white),
            onPressed: () {
              // Add to watchlist
            },
          ),
          IconButton(
            icon: Icon(Icons.share, color: AppColors.white),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(isPositive),

            // Chart Section
            _buildChartSection(isPositive),

            const SizedBox(height: 24),

            // Market Stats
            _buildMarketStats(),

            const SizedBox(height: 24),

            // Diversification Info
            _buildDiversificationInfo(),

            const SizedBox(height: 24),

            // Description
            _buildDescription(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isPositive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Symbol
          Text(
            widget.stockDetail.symbol,
            style: AppTypography.headline3Bold.copyWith(
              color: AppColors.accent,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),

          // Company Name
          Text(
            widget.stockDetail.name,
            style: AppTypography.headline3Bold.copyWith(
              color: AppColors.white,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),

          // Current Price
          Text(
            '\$${NumberFormat('#,##0.00').format(widget.stockDetail.currentPrice)}',
            style: AppTypography.headline3Bold.copyWith(
              color: AppColors.white,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 8),

          // 24h Change & Holdings
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? AppColors.success : AppColors.error,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive ? '+' : ''}${widget.stockDetail.change24h.toStringAsFixed(2)}%',
                style: AppTypography.headline2SemiBold.copyWith(
                  color: isPositive ? AppColors.success : AppColors.error,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gray80,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${widget.stockDetail.quantity.toStringAsFixed(2)} shares',
                  style: AppTypography.headline2Regular.copyWith(
                    color: AppColors.gray30,
                    fontSize: 12,
                  ),
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
        priceHistory: widget.stockDetail.priceHistory,
        isPositive: isPositive,
        height: 200,
        showTimeframeSelector: true,
      ),
    );
  }

  Widget _buildMarketStats() {
    final stats = widget.stockDetail.marketStats;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Market Statistics',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),

          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              if (stats.marketCap != null)
                _buildStatCard(
                  'Market Cap',
                  _formatMarketCap(stats.marketCap!),
                ),
              if (stats.peRatio != null)
                _buildStatCard('P/E Ratio', stats.peRatio!.toStringAsFixed(2)),
              if (stats.week52High != null)
                _buildStatCard(
                  '52W High',
                  '\$${stats.week52High!.toStringAsFixed(2)}',
                ),
              if (stats.week52Low != null)
                _buildStatCard(
                  '52W Low',
                  '\$${stats.week52Low!.toStringAsFixed(2)}',
                ),
              if (stats.volume != null)
                _buildStatCard('Volume', _formatVolume(stats.volume!)),
              if (stats.dividendYield != null)
                _buildStatCard(
                  'Dividend Yield',
                  '${stats.dividendYield!.toStringAsFixed(2)}%',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray80,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray80, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.headline1Regular.copyWith(
              color: AppColors.gray40,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.headline2SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiversificationInfo() {
    final div = widget.stockDetail.diversification;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diversification',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Sector Badge
              _buildBadge(
                icon: Icons.business,
                label: 'Sector',
                value: div.sector,
                color: const Color(0xFF3861FB),
              ),
              const SizedBox(width: 12),

              // Industry Badge
              _buildBadge(
                icon: Icons.factory,
                label: 'Industry',
                value: div.industry,
                color: const Color(0xFF00D16C),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Country Badge with Flag
          _buildCountryBadge(div.country, div.countryCode),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: AppTypography.headline1Regular.copyWith(
                    color: AppColors.gray40,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.headline2SemiBold.copyWith(
                color: AppColors.white,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryBadge(String country, String countryCode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFAA00).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFFAA00).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Country Flag
          Text(
            Country.tryParse(countryCode)?.flagEmoji ?? '🌍',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Country',
                style: AppTypography.headline1Regular.copyWith(
                  color: AppColors.gray40,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                country,
                style: AppTypography.headline2SemiBold.copyWith(
                  color: AppColors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),

          AnimatedCrossFade(
            firstChild: Text(
              widget.stockDetail.description,
              style: AppTypography.headline2Regular.copyWith(
                color: AppColors.gray30,
                fontSize: 14,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            secondChild: Text(
              widget.stockDetail.description,
              style: AppTypography.headline2Regular.copyWith(
                color: AppColors.gray30,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            crossFadeState: _isDescriptionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),

          const SizedBox(height: 8),

          GestureDetector(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Text(
              _isDescriptionExpanded ? 'Show less' : 'Read more',
              style: AppTypography.headline2SemiBold.copyWith(
                color: AppColors.accent,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMarketCap(double marketCap) {
    if (marketCap >= 1e12) {
      return '\$${(marketCap / 1e12).toStringAsFixed(2)}T';
    } else if (marketCap >= 1e9) {
      return '\$${(marketCap / 1e9).toStringAsFixed(2)}B';
    } else if (marketCap >= 1e6) {
      return '\$${(marketCap / 1e6).toStringAsFixed(2)}M';
    } else {
      return '\$${marketCap.toStringAsFixed(0)}';
    }
  }

  String _formatVolume(double volume) {
    if (volume >= 1e9) {
      return '${(volume / 1e9).toStringAsFixed(2)}B';
    } else if (volume >= 1e6) {
      return '${(volume / 1e6).toStringAsFixed(2)}M';
    } else if (volume >= 1e3) {
      return '${(volume / 1e3).toStringAsFixed(2)}K';
    } else {
      return volume.toStringAsFixed(0);
    }
  }
}
