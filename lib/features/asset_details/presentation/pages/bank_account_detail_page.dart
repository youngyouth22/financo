import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/common/common_widgets/price_line_chart.dart';
import 'package:financo/features/finance/domain/entities/bank_account_detail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Premium Bank Account Detail Page with Aggregated Institution View
class BankAccountDetailPage extends StatefulWidget {
  final BankAccountDetail accountDetail;

  const BankAccountDetailPage({super.key, required this.accountDetail});

  @override
  State<BankAccountDetailPage> createState() => _BankAccountDetailPageState();
}

class _BankAccountDetailPageState extends State<BankAccountDetailPage>
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        forceMaterialTransparency: true,
        title: Text(
          widget.accountDetail.institutionName,
          style: AppTypography.headline3SemiBold.copyWith(
            color: AppColors.white,
            fontSize: 18,
          ),
        ),
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
      body: Column(
        children: [
          // Header Section with Net Worth and Chart
          _buildHeader(),

          // Tab Bar
          _buildTabBar(),

          // Tab View Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildAccountsTab(), _buildHistoryTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Net Worth Label
          Text(
            'Total Net Worth',
            style: AppTypography.headline2Regular.copyWith(
              color: AppColors.gray40,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),

          // Total Net Worth Value
          Text(
            '${widget.accountDetail.currency} ${NumberFormat('#,##0.00').format(widget.accountDetail.totalNetWorth)}',
            style: AppTypography.headline3Bold.copyWith(
              color: AppColors.white,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 8),

          // Accounts Count
          Text(
            '${widget.accountDetail.accounts.length} account${widget.accountDetail.accounts.length != 1 ? 's' : ''}',
            style: AppTypography.headline2Regular.copyWith(
              color: AppColors.gray40,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Sparkline Chart
          if (widget.accountDetail.balanceHistory.isNotEmpty)
            PriceLineChart(
              priceHistory: widget.accountDetail.balanceHistory,
              isPositive: true,
              height: 180,
              showTimeframeSelector: false,
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.gray80,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.gray40,
        labelStyle: AppTypography.headline2SemiBold.copyWith(fontSize: 14),
        unselectedLabelStyle: AppTypography.headline2Regular.copyWith(
          fontSize: 14,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Accounts'),
          Tab(text: 'History'),
        ],
      ),
    );
  }

  Widget _buildAccountsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        Text(
          'Sub-Accounts',
          style: AppTypography.headline3SemiBold.copyWith(
            color: AppColors.white,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),

        // Grid of sub-account cards
        if (widget.accountDetail.accounts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No accounts available',
                style: AppTypography.headline2Regular.copyWith(
                  color: AppColors.gray40,
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: widget.accountDetail.accounts.length,
            itemBuilder: (context, index) {
              final account = widget.accountDetail.accounts[index];
              return _buildSubAccountCard(account);
            },
          ),
      ],
    );
  }

  Widget _buildSubAccountCard(PlaidSubAccount account) {
    // Determine color based on debt status
    final balanceColor = account.isDebt ? AppColors.warning : AppColors.white;
    final backgroundColor = account.isDebt
        ? AppColors.warning.withValues(alpha: 0.1)
        : AppColors.gray80;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: account.isDebt
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.gray70,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Account Type/Name
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatAccountSubtype(account.subtype),
                style: AppTypography.headline1Regular.copyWith(
                  color: AppColors.gray40,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                account.name,
                style: AppTypography.headline2SemiBold.copyWith(
                  color: AppColors.white,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          // Account Mask and Balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '•••• ${account.mask}',
                style: AppTypography.headline1Regular.copyWith(
                  color: AppColors.gray50,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${account.isDebt ? '-' : ''}${widget.accountDetail.currency} ${NumberFormat('#,##0.00').format(account.balance.abs())}',
                style: AppTypography.headline2SemiBold.copyWith(
                  color: balanceColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        Text(
          'Transaction History',
          style: AppTypography.headline3SemiBold.copyWith(
            color: AppColors.white,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),

        if (widget.accountDetail.transactions.isEmpty)
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
          ...widget.accountDetail.transactions.map(
            (tx) => _buildTransactionCard(tx),
          ),
      ],
    );
  }

  Widget _buildTransactionCard(BankTransaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray80,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray70, width: 1),
      ),
      child: Row(
        children: [
          // Transaction Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tx.isDebit
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.success.withValues(alpha: 0.1),
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
                          color: AppColors.warning.withValues(alpha: 0.2),
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
            '${tx.isDebit ? '-' : '+'}${widget.accountDetail.currency} ${tx.amount.abs().toStringAsFixed(2)}',
            style: AppTypography.headline2SemiBold.copyWith(
              color: tx.isDebit ? AppColors.error : AppColors.success,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAccountSubtype(BankAccountSubtype subtype) {
    switch (subtype) {
      case BankAccountSubtype.checking:
        return 'Checking';
      case BankAccountSubtype.savings:
        return 'Savings';
      case BankAccountSubtype.moneyMarket:
        return 'Money Market';
      case BankAccountSubtype.cd:
        return 'CD';
      case BankAccountSubtype.creditCard:
        return 'Credit Card';
      case BankAccountSubtype.paypal:
        return 'PayPal';
      case BankAccountSubtype.other:
        return 'Other';
    }
  }
}
