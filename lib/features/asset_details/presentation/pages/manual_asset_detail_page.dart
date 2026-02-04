import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/features/finance/domain/entities/manual_asset_detail.dart';
import 'package:financo/features/finance/presentation/bloc/manual_asset_detail/manual_asset_detail_bloc.dart';
import 'package:financo/features/finance/presentation/bloc/manual_asset_detail/manual_asset_detail_event.dart';
import 'package:financo/features/finance/presentation/bloc/manual_asset_detail/manual_asset_detail_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Premium Manual Asset Detail Page with Amortization Engine
///
/// Features:
/// - Header stats (Total Expected, Total Received, Remaining Balance)
/// - Tab 1: Schedule (Future reminders with mark as received)
/// - Tab 2: History (Past payouts)
class ManualAssetDetailPage extends StatefulWidget {
  final ManualAssetDetail assetDetail;

  const ManualAssetDetailPage({
    super.key,
    required this.assetDetail,
  });

  @override
  State<ManualAssetDetailPage> createState() => _ManualAssetDetailPageState();
}

class _ManualAssetDetailPageState extends State<ManualAssetDetailPage> {
  @override
  void initState() {
    super.initState();
    // Load payout data when page opens
    context.read<ManualAssetDetailBloc>().add(
          LoadAssetDetailEvent(widget.assetDetail.assetId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.assetDetail.name,
            style: AppTypography.h3.copyWith(color: AppColors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.white),
              onPressed: () {
                // TODO: Edit asset
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.white),
              onPressed: () {
                // TODO: More options
              },
            ),
          ],
        ),
        body: BlocConsumer<ManualAssetDetailBloc, ManualAssetDetailState>(
          listener: (context, state) {
            if (state is ReminderMarkedSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment marked as received!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is ManualAssetDetailError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ManualAssetDetailLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state is ManualAssetDetailError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: AppTypography.body.copyWith(color: AppColors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ManualAssetDetailBloc>().add(
                              RefreshAssetDetailEvent(widget.assetDetail.assetId),
                            );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is! ManualAssetDetailLoaded) {
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                // Header Stats Section
                _buildHeaderStats(state),

                // TabBar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: AppColors.white,
                    unselectedLabelColor: AppColors.gray60,
                    labelStyle: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'Schedule'),
                      Tab(text: 'History'),
                    ],
                  ),
                ),

                // TabBarView
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildScheduleTab(state),
                      _buildHistoryTab(state),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Build header stats cards
  Widget _buildHeaderStats(ManualAssetDetailLoaded state) {
    final summary = state.summary;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Expected',
              '\$${NumberFormat('#,##0.00').format(summary.totalExpected)}',
              Icons.account_balance_wallet,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Received',
              '\$${NumberFormat('#,##0.00').format(summary.totalReceived)}',
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Remaining',
              '\$${NumberFormat('#,##0.00').format(summary.remainingBalance)}',
              Icons.pending,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual stat card
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.gray60),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Build Schedule tab (future reminders)
  Widget _buildScheduleTab(ManualAssetDetailLoaded state) {
    // TODO: Fetch reminders from database
    // For now, show placeholder
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Upcoming Payments',
          style: AppTypography.h3.copyWith(color: AppColors.white),
        ),
        const SizedBox(height: 16),
        _buildEmptyState(
          'No upcoming reminders',
          'Add a reminder to track future payments',
          Icons.calendar_today,
        ),
      ],
    );
  }

  /// Build History tab (past payouts)
  Widget _buildHistoryTab(ManualAssetDetailLoaded state) {
    final payouts = state.payouts;

    if (payouts.isEmpty) {
      return _buildEmptyState(
        'No payment history',
        'Mark reminders as received to see history here',
        Icons.history,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: payouts.length,
      itemBuilder: (context, index) {
        final payout = payouts[index];
        return _buildPayoutCard(payout);
      },
    );
  }

  /// Build payout card
  Widget _buildPayoutCard(payout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gray70.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${NumberFormat('#,##0.00').format(payout.amount)}',
                  style: AppTypography.body.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(payout.payoutDate),
                  style: AppTypography.caption.copyWith(color: AppColors.gray60),
                ),
                if (payout.notes != null && payout.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    payout.notes!,
                    style: AppTypography.caption.copyWith(color: AppColors.gray60),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.gray60),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.h3.copyWith(color: AppColors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.body.copyWith(color: AppColors.gray60),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
