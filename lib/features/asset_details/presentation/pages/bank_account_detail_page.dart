import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/common/common_widgets/price_line_chart.dart';
import 'package:financo/features/finance/domain/entities/bank_account_detail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Premium Bank Account Detail Page with Plaid integration
class BankAccountDetailPage extends StatelessWidget {
  final BankAccountDetail accountDetail;

  const BankAccountDetailPage({
    super.key,
    required this.accountDetail,
  });

  @override
  Widget build(BuildContext context) {
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
            icon: Icon(Icons.refresh, color: AppColors.white),
            onPressed: () {
              // Refresh account data
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(),
            
            // Chart Section
            _buildChartSection(),
            
            const SizedBox(height: 24),
            
            // Account Info
            _buildAccountInfo(),
            
            const SizedBox(height: 24),
            
            // Credit Card Section (if applicable)
            if (accountDetail.isCreditCard) ...[
              _buildCreditCardInfo(),
              const SizedBox(height: 24),
            ],
            
            // Transactions
            _buildTransactions(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Institution Name
          Text(
            accountDetail.institutionName,
            style: AppTypography.headline2Regular.copyWith(
              color: AppColors.gray40,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          
          // Account Name
          Text(
            accountDetail.name,
            style: AppTypography.headline3Bold.copyWith(
              color: AppColors.white,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          
          // Account Mask
          Text(
            accountDetail.accountMask,
            style: AppTypography.headline2Regular.copyWith(
              color: AppColors.gray40,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          
          // Current Balance
          Text(
            accountDetail.isCreditCard ? 'Available Balance' : 'Current Balance',
            style: AppTypography.headline2Regular.copyWith(
              color: AppColors.gray40,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${NumberFormat('#,##0.00').format(accountDetail.currentBalance)}',
            style: AppTypography.headline3Bold.copyWith(
              color: AppColors.white,
              fontSize: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: PriceLineChart(
        priceHistory: accountDetail.balanceHistory,
        isPositive: true,
        height: 180,
        showTimeframeSelector: true,
      ),
    );
  }

  Widget _buildAccountInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
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
                _buildInfoRow('Account Type', _formatAccountType()),
                const Divider(color: Color(0xFF2A2D36), height: 24),
                _buildInfoRow('Account Subtype', _formatAccountSubtype()),
                const Divider(color: Color(0xFF2A2D36), height: 24),
                _buildInfoRow('Currency', accountDetail.currency),
                const Divider(color: Color(0xFF2A2D36), height: 24),
                _buildInfoRow(
                  'Available Balance',
                  '\$${NumberFormat('#,##0.00').format(accountDetail.availableBalance)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardInfo() {
    final creditLimit = accountDetail.creditLimit ?? 0;
    final creditUsed = accountDetail.creditUsed;
    final creditUtilization = creditLimit > 0 ? (creditUsed / creditLimit) * 100 : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Credit Card Details',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF3861FB).withOpacity(0.2),
                  const Color(0xFF3861FB).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Credit Limit',
                          style: AppTypography.headline2Regular.copyWith(
                            color: AppColors.gray40,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${NumberFormat('#,##0.00').format(creditLimit)}',
                          style: AppTypography.headline2SemiBold.copyWith(
                            color: AppColors.white,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Credit Used',
                          style: AppTypography.headline2Regular.copyWith(
                            color: AppColors.gray40,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${NumberFormat('#,##0.00').format(creditUsed)}',
                          style: AppTypography.headline2SemiBold.copyWith(
                            color: AppColors.white,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Credit Utilization Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Credit Utilization',
                          style: AppTypography.headline2Regular.copyWith(
                            color: AppColors.gray40,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${creditUtilization.toStringAsFixed(1)}%',
                          style: AppTypography.headline2SemiBold.copyWith(
                            color: _getCreditUtilizationColor(creditUtilization),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: creditUtilization / 100,
                        backgroundColor: AppColors.gray80,
                        valueColor: AlwaysStoppedAnimation(
                          _getCreditUtilizationColor(creditUtilization),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Transactions',
            style: AppTypography.headline3SemiBold.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          
          if (accountDetail.transactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No transactions available',
                  style: AppTypography.headline2Regular.copyWith(
                    color: AppColors.gray40,
                  ),
                ),
              ),
            )
          else
            ...accountDetail.transactions.map((tx) => _buildTransactionCard(tx)),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BankTransaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray90,
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
              color: tx.isDebit
                  ? AppColors.error.withOpacity(0.1)
                  : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              tx.isDebit ? Icons.arrow_upward : Icons.arrow_downward,
              color: tx.isDebit ? AppColors.error : AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Transaction Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.merchantName ?? tx.name,
                  style: AppTypography.headline2SemiBold.copyWith(
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tx.category,
                  style: AppTypography.headline1Regular.copyWith(
                    color: AppColors.gray40,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      DateFormat('MMM d, yyyy').format(tx.date),
                      style: AppTypography.headline1Regular.copyWith(
                        color: AppColors.gray50,
                        fontSize: 10,
                      ),
                    ),
                    if (tx.isPending) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Pending',
                          style: AppTypography.headline1Regular.copyWith(
                            color: AppColors.warning,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Amount
          Text(
            '${tx.isDebit ? '-' : '+'}\$${tx.amount.abs().toStringAsFixed(2)}',
            style: AppTypography.headline2SemiBold.copyWith(
              color: tx.isDebit ? AppColors.error : AppColors.success,
              fontSize: 14,
            ),
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
        Text(
          value,
          style: AppTypography.headline2SemiBold.copyWith(
            color: AppColors.white,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _formatAccountType() {
    switch (accountDetail.accountType) {
      case BankAccountType.depository:
        return 'Depository';
      case BankAccountType.credit:
        return 'Credit Card';
      case BankAccountType.loan:
        return 'Loan';
      case BankAccountType.investment:
        return 'Investment';
      case BankAccountType.other:
        return 'Other';
    }
  }

  String _formatAccountSubtype() {
    switch (accountDetail.accountSubtype) {
      case BankAccountSubtype.checking:
        return 'Checking';
      case BankAccountSubtype.savings:
        return 'Savings';
      case BankAccountSubtype.moneyMarket:
        return 'Money Market';
      case BankAccountSubtype.cd:
        return 'Certificate of Deposit';
      case BankAccountSubtype.creditCard:
        return 'Credit Card';
      case BankAccountSubtype.paypal:
        return 'PayPal';
      case BankAccountSubtype.other:
        return 'Other';
    }
  }

  Color _getCreditUtilizationColor(double utilization) {
    if (utilization < 30) {
      return AppColors.success;
    } else if (utilization < 70) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }
}
