import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/common/common_widgets/price_line_chart.dart';
import 'package:financo/features/finance/domain/entities/manual_asset_detail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Premium Manual Asset Detail Page with Amortization Engine
class ManualAssetDetailPage extends StatelessWidget {
  final ManualAssetDetail assetDetail;

  const ManualAssetDetailPage({
    super.key,
    required this.assetDetail,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = assetDetail.totalGain >= 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: AppColors.white),
            onPressed: () {
              // Edit asset
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.white),
            onPressed: () {
              // More options
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
            
            // Re-evaluate Button
            _buildReEvaluateButton(context),
            
            const SizedBox(height: 24),
            
            // Asset Metadata
            _buildMetadata(),
            
            const SizedBox(height: 24),
            
            // Amortization Schedule (if applicable)
            if (assetDetail.amortizationSchedule != null &&
                assetDetail.amortizationSchedule!.isNotEmpty) ...[
              _buildAmortizationSection(),
              const SizedBox(height: 24),
            ],
            
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
          // Category Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getCategoryColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getCategoryColor().withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(),
                  color: _getCategoryColor(),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatCategory(),
                  style: AppTypography.headline2SemiBold.copyWith(
                    color: _getCategoryColor(),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Asset Name
          Text(
            assetDetail.name,
            style: AppTypography.headline3Bold.copyWith(
              color: AppColors.white,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),
          
          // Current Value
          Text(
            '\$${NumberFormat('#,##0.00').format(assetDetail.currentValue)}',
            style: AppTypography.headline3Bold.copyWith(
              color: AppColors.white,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 8),
          
          // Total Gain/Loss
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? AppColors.success : AppColors.error,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive ? '+' : ''}\$${assetDetail.totalGain.toStringAsFixed(2)}',
                style: AppTypography.headline2SemiBold.copyWith(
                  color: isPositive ? AppColors.success : AppColors.error,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${isPositive ? '+' : ''}${assetDetail.totalGainPercent.toStringAsFixed(2)}%)',
                style: AppTypography.headline2Regular.copyWith(
                  color: isPositive ? AppColors.success : AppColors.error,
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
        priceHistory: assetDetail.valueHistory,
        isPositive: isPositive,
        height: 180,
        showTimeframeSelector: true,
      ),
    );
  }

  Widget _buildReEvaluateButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            _showReEvaluateDialog(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.refresh, size: 20),
              const SizedBox(width: 8),
              Text(
                'Re-evaluate Asset',
                style: AppTypography.headline2SemiBold.copyWith(
                  color: AppColors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadata() {
    final metadata = assetDetail.metadata;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asset Details',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray90,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray80, width: 1),
            ),
            child: Column(
              children: [
                _buildInfoRow('Purchase Price', '\$${NumberFormat('#,##0.00').format(assetDetail.purchasePrice)}'),
                const Divider(color: Color(0xFF2A2D36), height: 24),
                _buildInfoRow('Purchase Date', DateFormat('MMM d, yyyy').format(assetDetail.purchaseDate)),
                const Divider(color: Color(0xFF2A2D36), height: 24),
                _buildInfoRow('Currency', assetDetail.currency),
                
                // Category-specific metadata
                if (metadata.propertyAddress != null) ...[
                  const Divider(color: Color(0xFF2A2D36), height: 24),
                  _buildInfoRow('Property Address', metadata.propertyAddress!),
                ],
                if (metadata.propertyType != null) ...[
                  const Divider(color: Color(0xFF2A2D36), height: 24),
                  _buildInfoRow('Property Type', metadata.propertyType!),
                ],
                if (metadata.loanAmount != null) ...[
                  const Divider(color: Color(0xFF2A2D36), height: 24),
                  _buildInfoRow('Loan Amount', '\$${NumberFormat('#,##0.00').format(metadata.loanAmount!)}'),
                ],
                if (metadata.interestRate != null) ...[
                  const Divider(color: Color(0xFF2A2D36), height: 24),
                  _buildInfoRow('Interest Rate', '${metadata.interestRate!.toStringAsFixed(2)}%'),
                ],
                if (metadata.commodityType != null) ...[
                  const Divider(color: Color(0xFF2A2D36), height: 24),
                  _buildInfoRow('Commodity Type', metadata.commodityType!),
                ],
                if (metadata.purity != null) ...[
                  const Divider(color: Color(0xFF2A2D36), height: 24),
                  _buildInfoRow('Purity', '${metadata.purity!.toStringAsFixed(1)}%'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmortizationSection() {
    final schedule = assetDetail.amortizationSchedule!;
    final upcomingPayments = schedule.where((p) => p.isUpcoming).take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Upcoming Recalls / Amortization',
                style: AppTypography.headline3SemiBold.copyWith(
                  color: AppColors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (upcomingPayments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No upcoming payments',
                  style: AppTypography.headline2Regular.copyWith(
                    color: AppColors.gray40,
                  ),
                ),
              ),
            )
          else
            ...upcomingPayments.map((payment) => _buildPaymentCard(payment)),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(AmortizationPayment payment) {
    final daysUntil = payment.dueDate.difference(DateTime.now()).inDays;
    final isOverdue = payment.isOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue
            ? AppColors.error.withOpacity(0.1)
            : AppColors.gray90,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withOpacity(0.5)
              : AppColors.gray80,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment #${payment.paymentNumber}',
                style: AppTypography.headline2SemiBold.copyWith(
                  color: AppColors.white,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? AppColors.error.withOpacity(0.2)
                      : AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isOverdue
                      ? 'OVERDUE'
                      : daysUntil == 0
                          ? 'TODAY'
                          : '$daysUntil days',
                  style: AppTypography.headline2SemiBold.copyWith(
                    color: isOverdue ? AppColors.error : AppColors.accent,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Text(
            DateFormat('MMMM d, yyyy').format(payment.dueDate),
            style: AppTypography.headline2Regular.copyWith(
              color: AppColors.gray40,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Principal',
                    style: AppTypography.headline1Regular.copyWith(
                      color: AppColors.gray40,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${NumberFormat('#,##0.00').format(payment.principalAmount)}',
                    style: AppTypography.headline2SemiBold.copyWith(
                      color: AppColors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interest',
                    style: AppTypography.headline1Regular.copyWith(
                      color: AppColors.gray40,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${NumberFormat('#,##0.00').format(payment.interestAmount)}',
                    style: AppTypography.headline2SemiBold.copyWith(
                      color: AppColors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Payment',
                    style: AppTypography.headline1Regular.copyWith(
                      color: AppColors.gray40,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${NumberFormat('#,##0.00').format(payment.totalPayment)}',
                    style: AppTypography.headline2Bold.copyWith(
                      color: AppColors.accent,
                      fontSize: 15,
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.headline2Regular.copyWith(
            color: AppColors.gray40,
            fontSize: 13,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTypography.headline2SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 13,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  void _showReEvaluateDialog(BuildContext context) {
    final controller = TextEditingController(
      text: assetDetail.currentValue.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.gray90,
        title: Text(
          'Re-evaluate Asset',
          style: AppTypography.headline3SemiBold.copyWith(
            color: AppColors.white,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: AppTypography.headline2Regular.copyWith(
            color: AppColors.white,
          ),
          decoration: InputDecoration(
            labelText: 'New Value (USD)',
            labelStyle: AppTypography.headline2Regular.copyWith(
              color: AppColors.gray40,
            ),
            prefixText: '\$',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.gray70),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.headline2Regular.copyWith(
                color: AppColors.gray40,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Update asset value
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
            ),
            child: Text(
              'Update',
              style: AppTypography.headline2SemiBold.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCategory() {
    switch (assetDetail.category) {
      case ManualAssetCategory.realEstate:
        return 'Real Estate';
      case ManualAssetCategory.privateEquity:
        return 'Private Equity';
      case ManualAssetCategory.commodity:
        return 'Commodity';
      case ManualAssetCategory.collectible:
        return 'Collectible';
      case ManualAssetCategory.loan:
        return 'Loan';
      case ManualAssetCategory.other:
        return 'Other';
    }
  }

  IconData _getCategoryIcon() {
    switch (assetDetail.category) {
      case ManualAssetCategory.realEstate:
        return Icons.home;
      case ManualAssetCategory.privateEquity:
        return Icons.business;
      case ManualAssetCategory.commodity:
        return Icons.diamond;
      case ManualAssetCategory.collectible:
        return Icons.collections;
      case ManualAssetCategory.loan:
        return Icons.account_balance;
      case ManualAssetCategory.other:
        return Icons.category;
    }
  }

  Color _getCategoryColor() {
    switch (assetDetail.category) {
      case ManualAssetCategory.realEstate:
        return const Color(0xFF00D16C);
      case ManualAssetCategory.privateEquity:
        return const Color(0xFF3861FB);
      case ManualAssetCategory.commodity:
        return const Color(0xFFFFAA00);
      case ManualAssetCategory.collectible:
        return const Color(0xFFFF4D4D);
      case ManualAssetCategory.loan:
        return const Color(0xFF9B51E0);
      case ManualAssetCategory.other:
        return AppColors.gray40;
    }
  }
}
