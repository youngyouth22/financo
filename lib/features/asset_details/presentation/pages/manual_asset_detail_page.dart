import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/features/finance/domain/entities/manual_asset_detail.dart';
import 'package:financo/features/finance/presentation/bloc/manual_asset_detail/manual_asset_detail_bloc.dart';
import 'package:financo/features/finance/presentation/bloc/manual_asset_detail/manual_asset_detail_event.dart';
import 'package:financo/features/finance/presentation/bloc/manual_asset_detail/manual_asset_detail_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rrule/rrule.dart';

/// Premium Manual Asset Detail Page with Amortization Engine
///
/// Features:
/// - Header stats (Total Expected, Total Received, Remaining Balance)
/// - Tab 1: Schedule (Future reminders with mark as received)
/// - Tab 2: History (Past payouts)
class ManualAssetDetailPage extends StatefulWidget {
  final ManualAssetDetail assetDetail;

  const ManualAssetDetailPage({super.key, required this.assetDetail});

  @override
  State<ManualAssetDetailPage> createState() => _ManualAssetDetailPageState();
}

class _ManualAssetDetailPageState extends State<ManualAssetDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load payout data when page opens
    context.read<ManualAssetDetailBloc>().add(
      LoadAssetDetailEvent(widget.assetDetail.assetId),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ManualAssetDetailBloc, ManualAssetDetailState>(
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
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is ManualAssetDetailLoading) {
          return Scaffold(
            backgroundColor: AppColors.gray,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (state is ManualAssetDetailError) {
          return Scaffold(
            backgroundColor: AppColors.gray,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: AppTypography.headline3Regular.copyWith(
                      color: AppColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    onPressed: () {
                      context.read<ManualAssetDetailBloc>().add(
                        RefreshAssetDetailEvent(widget.assetDetail.assetId),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is! ManualAssetDetailLoaded) {
          return Scaffold(
            backgroundColor: AppColors.gray,
            body: const SizedBox.shrink(),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.gray,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // AppBar fixe en haut
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  elevation: 0,
                  backgroundColor: AppColors.gray,
                  forceMaterialTransparency: true,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    widget.assetDetail.name,
                    style: AppTypography.headline4Medium.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.edit, color: AppColors.white),
                      onPressed: () {
                        // TODO: Edit asset
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.more_vert, color: AppColors.white),
                      onPressed: () {
                        // TODO: More options
                      },
                    ),
                  ],
                ),

                // Header Stats Section
                SliverToBoxAdapter(child: _buildHeaderStats(state)),

                // Tab Bar (fixe sous le header quand on scroll)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ManualAssetTabBarDelegate(child: _buildTabBar()),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [_buildScheduleTab(state), _buildHistoryTab(state)],
            ),
          ),
        );
      },
    );
  }

  /// Build header stats cards avec design premium
  Widget _buildHeaderStats(ManualAssetDetailLoaded state) {
    final summary = state.summary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Asset Description
          // if (widget.assetDetail.description != null &&
          //     widget.assetDetail.description!.isNotEmpty)
          //   Padding(
          //     padding: const EdgeInsets.only(bottom: 12),
          //     child: Text(
          //       widget.assetDetail.description!,
          //       style: AppTypography.headline2Regular.copyWith(
          //         color: AppColors.gray40,
          //         fontSize: 14,
          //       ),
          //     ),
          //   ),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'Total Expected',
                  value:
                      '\$${NumberFormat('#,##0.00').format(summary.totalExpected)}',
                  icon: Icons.account_balance_wallet,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  label: 'Total Received',
                  value:
                      '\$${NumberFormat('#,##0.00').format(summary.totalReceived)}',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  label: 'Remaining',
                  value:
                      '\$${NumberFormat('#,##0.00').format(summary.remainingBalance)}',
                  icon: Icons.pending,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual stat card avec design premium
  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray80,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray80, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(child: Icon(icon, color: color, size: 20)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTypography.headline1Regular.copyWith(
              color: AppColors.gray60,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.headline3Bold.copyWith(
              color: AppColors.white,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Build TabBar avec le même design que la page précédente
  Widget _buildTabBar() {
    return Container(
      color: AppColors.gray,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.accent,
        indicatorWeight: 3,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.gray40,
        labelStyle: AppTypography.headline2SemiBold,
        unselectedLabelStyle: AppTypography.headline2Regular,
        tabs: const [
          Tab(text: 'Schedule'),
          Tab(text: 'History'),
        ],
      ),
    );
  }

  List<AmortizationPayment> _generateFuturePayments(ManualAssetDetail asset) {
    if (asset.rruleString == null || asset.rruleString!.isEmpty) {
      return asset.amortizationSchedule ?? [];
    }

    try {
      final recur = RecurrenceRule.fromString(asset.rruleString!);
      final start = asset.purchaseDate.toUtc();
      final instances = recur.getInstances(start: start).take(12).toList();

      return instances.asMap().entries.map((entry) {
        int idx = entry.key;
        DateTime date = entry.value;

        final existing = asset.amortizationSchedule?.firstWhere(
          (e) =>
              e.dueDate.day == date.day &&
              e.dueDate.month == date.month &&
              e.dueDate.year == date.year,
          orElse: () => AmortizationPayment(
            paymentNumber: idx + 1,
            dueDate: date,
            principalAmount: asset.purchasePrice / 12,
            interestAmount: 0,
            totalPayment: asset.purchasePrice / 12,
            remainingBalance: 0,
          ),
        );

        return existing!;
      }).toList();
    } catch (e) {
      return asset.amortizationSchedule ?? [];
    }
  }

  /// Build Schedule tab avec design premium
  Widget _buildScheduleTab(ManualAssetDetailLoaded state) {
    final futurePayments = _generateFuturePayments(widget.assetDetail);

    if (futurePayments.isEmpty) {
      return _buildEmptyState(
        title: 'No upcoming payments',
        subtitle: 'Set a recurrence rule to see the schedule',
        icon: Icons.calendar_today,
        iconColor: AppColors.primary,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const ClampingScrollPhysics(),
      itemCount: futurePayments.length,
      itemBuilder: (context, index) {
        final payment = futurePayments[index];
        final isUpcoming = payment.dueDate.isAfter(DateTime.now());
        final isPaid = payment.isPaid ?? false;

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
              // Date Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isUpcoming
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.gray70,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd').format(payment.dueDate),
                        style: AppTypography.headline3Bold.copyWith(
                          color: isUpcoming
                              ? AppColors.primary
                              : AppColors.gray60,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(payment.dueDate),
                        style: AppTypography.headline1Regular.copyWith(
                          color: isUpcoming
                              ? AppColors.primary
                              : AppColors.gray60,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Payment Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment #${payment.paymentNumber}',
                      style: AppTypography.headline2SemiBold.copyWith(
                        color: AppColors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMMM dd, yyyy').format(payment.dueDate),
                      style: AppTypography.headline1Regular.copyWith(
                        color: AppColors.gray40,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount & Action
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${NumberFormat('#,##0.00').format(payment.totalPayment)}',
                    style: AppTypography.headline2SemiBold.copyWith(
                      color: AppColors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!isPaid)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        context.read<ManualAssetDetailBloc>().add(
                          MarkReminderReceivedEvent(
                            assetId: widget.assetDetail.assetId,
                            amount: payment.totalPayment,
                            payoutDate: payment.dueDate,
                            reminderId: 'payment_${payment.paymentNumber}',
                            notes: '',
                          ),
                        );
                      },
                      child: const Text('Mark as Paid'),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Paid',
                            style: AppTypography.headline1Regular.copyWith(
                              color: Colors.green,
                              fontSize: 10,
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
      },
    );
  }

  /// Build History tab avec design premium
  Widget _buildHistoryTab(ManualAssetDetailLoaded state) {
    final payouts = state.payouts;

    if (payouts.isEmpty) {
      return _buildEmptyState(
        title: 'No payment history',
        subtitle: 'Mark reminders as received to see history here',
        icon: Icons.history,
        iconColor: AppColors.gray60,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const ClampingScrollPhysics(),
      itemCount: payouts.length,
      itemBuilder: (context, index) {
        final payout = payouts[index];
        return _buildPayoutCard(payout);
      },
    );
  }

  /// Build payout card avec design premium
  Widget _buildPayoutCard(payout) {
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
          // Icon avec badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.check_circle, color: Colors.green, size: 24),
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
                  style: AppTypography.headline2SemiBold.copyWith(
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM dd, yyyy').format(payout.payoutDate),
                  style: AppTypography.headline1Regular.copyWith(
                    color: AppColors.gray40,
                    fontSize: 12,
                  ),
                ),
                if (payout.notes != null && payout.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    payout.notes!,
                    style: AppTypography.headline1Regular.copyWith(
                      color: AppColors.gray60,
                      fontSize: 11,
                    ),
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

  /// Build empty state avec design premium
  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: iconColor.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Center(child: Icon(icon, size: 36, color: iconColor)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTypography.headline4Medium.copyWith(
                color: AppColors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.headline3Regular.copyWith(
                color: AppColors.gray60,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom delegate pour le TabBar fixe
class _ManualAssetTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _ManualAssetTabBarDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.gray, child: child);
  }

  @override
  double get maxExtent => 48; // Hauteur du TabBar

  @override
  double get minExtent => 48; // Même hauteur, ne se réduit pas

  @override
  bool shouldRebuild(_ManualAssetTabBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
