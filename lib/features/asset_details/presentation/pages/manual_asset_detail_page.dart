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

import '../../../finance/domain/entities/asset_payout.dart';

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
    context.read<ManualAssetDetailBloc>().add(
      LoadAssetDetailEvent(widget.assetDetail.assetId),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- MOTEUR DE GÉNÉRATION CORRIGÉ ---
  List<AmortizationPayment> _generateFuturePayments(ManualAssetDetail asset) {
    if (asset.rruleString == null || asset.rruleString!.isEmpty) {
      return asset.amortizationSchedule ?? [];
    }

    try {
      // 1. On s'assure que la règle a le bon préfixe pour le parser Dart
      String rruleText = asset.rruleString!;
      if (!rruleText.startsWith('RRULE:')) {
        rruleText = 'RRULE:$rruleText';
      }

      final recur = RecurrenceRule.fromString(rruleText);

      // 2. On utilise la date d'achat comme ancre (DTSTART)
      // On génère à partir de maintenant pour être sûr d'avoir le futur
      final now = DateTime.now();

      // On génère les instances à partir du début de l'investissement
      final allInstances = recur.getInstances(
        start: asset.purchaseDate.toUtc(),
      );

      // 3. On filtre pour prendre les 12 prochaines à partir d'aujourd'hui
      // On autorise les dates depuis hier pour inclure le paiement du jour même s'il vient de passer
      final upcomingDates = allInstances
          .where((date) => date.isAfter(now.subtract(const Duration(days: 1))))
          .take(12)
          .toList();

      // Si aucune date n'est trouvée (règle expirée), on renvoie ce qu'il y a en DB
      if (upcomingDates.isEmpty) return asset.amortizationSchedule ?? [];

      return upcomingDates.asMap().entries.map((entry) {
        int idx = entry.key;
        DateTime date = entry.value;

        // On vérifie si cette date précise est déjà marquée comme payée dans le backend
        final existingInDb = asset.amortizationSchedule
            ?.where(
              (e) =>
                  e.dueDate.year == date.year &&
                  e.dueDate.month == date.month &&
                  e.dueDate.day == date.day,
            )
            .toList();

        if (existingInDb != null && existingInDb.isNotEmpty) {
          return existingInDb.first;
        }

        // Sinon, on crée l'échéance prévisionnelle
        return AmortizationPayment(
          paymentNumber: idx + 1,
          dueDate: date,
          principalAmount: asset.purchasePrice / 12,
          interestAmount: 0,
          totalPayment: asset.purchasePrice / 12,
          remainingBalance: 0,
          isPaid: false,
        );
      }).toList();
    } catch (e) {
      debugPrint('RRULE Logic Error: $e');
      return asset.amortizationSchedule ?? [];
    }
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
        }
      },
      builder: (context, state) {
        if (state is ManualAssetDetailLoading) {
          return Scaffold(
            backgroundColor: AppColors.gray,
            body: const Center(child: CircularProgressIndicator()),
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
          body: SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppColors.gray,
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
                ),
                SliverToBoxAdapter(child: _buildHeaderStats(state)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ManualAssetTabBarDelegate(child: _buildTabBar()),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [_buildScheduleTab(state), _buildHistoryTab(state)],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderStats(ManualAssetDetailLoaded state) {
    final summary = state.summary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray80,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.headline1Regular.copyWith(
              color: AppColors.gray60,
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: AppTypography.headline3Bold.copyWith(
              color: AppColors.white,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.gray,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.accent,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.gray40,
        tabs: const [
          Tab(text: 'Schedule'),
          Tab(text: 'History'),
        ],
      ),
    );
  }

  Widget _buildScheduleTab(ManualAssetDetailLoaded state) {
    // Utilisation de widget.assetDetail pour le rruleString
    final futurePayments = _generateFuturePayments(widget.assetDetail);

    if (futurePayments.isEmpty) {
      return _buildEmptyState(
        'No upcoming payments',
        'Check your recurrence rule',
        Icons.calendar_today,
        AppColors.primary,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: futurePayments.length,
      itemBuilder: (context, index) {
        final payment = futurePayments[index];
        final isUpcoming = payment.dueDate.isAfter(DateTime.now());
        final isPaid = payment.isPaid;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.gray80,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _buildDateLeading(payment.dueDate, isUpcoming),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment #${payment.paymentNumber}',
                      style: AppTypography.headline2SemiBold.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      DateFormat('MMMM dd, yyyy').format(payment.dueDate),
                      style: AppTypography.headline1Regular.copyWith(
                        color: AppColors.gray40,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${NumberFormat('#,##0.00').format(payment.totalPayment)}',
                    style: AppTypography.headline2SemiBold.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!isPaid)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      ),
                      onPressed: () {
                        context.read<ManualAssetDetailBloc>().add(
                          MarkReminderReceivedEvent(
                            assetId: widget.assetDetail.assetId,
                            amount: payment.totalPayment,
                            payoutDate: payment.dueDate,
                            reminderId:
                                'rem_${payment.dueDate.millisecondsSinceEpoch}',
                            notes: 'Manual payment received',
                          ),
                        );
                      },
                      child: const Text('Pay', style: TextStyle(fontSize: 12)),
                    )
                  else
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateLeading(DateTime date, bool isUpcoming) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      decoration: BoxDecoration(
        color:
            // isUpcoming
            //     ? AppColors.accentP50.withValues(alpha: 0.1)
            //     :
            AppColors.gray70.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            DateFormat('MMM').format(date),
            style: TextStyle(
              color:
                  // isUpcoming ? AppColors.accentP50 :
                  AppColors.gray30,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            DateFormat('dd').format(date),
            style: TextStyle(
              color:
                  // isUpcoming ? AppColors.accentP50 :
                  AppColors.gray30,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ManualAssetDetailLoaded state) {
    if (state.payouts.isEmpty) {
      return _buildEmptyState(
        'No history',
        'Payments will appear here',
        Icons.history,
        AppColors.gray60,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: state.payouts.length,
      itemBuilder: (context, index) => _buildPayoutCard(state.payouts[index]),
    );
  }

  Widget _buildPayoutCard(AssetPayout payout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray80,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${NumberFormat('#,##0.00').format(payout.amount)}',
                  style: AppTypography.headline2SemiBold.copyWith(
                    color: AppColors.white,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(payout.payoutDate),
                  style: AppTypography.headline1Regular.copyWith(
                    color: AppColors.gray40,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: color.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTypography.headline4Medium.copyWith(
              color: AppColors.white,
            ),
          ),
          Text(
            subtitle,
            style: AppTypography.headline3Regular.copyWith(
              color: AppColors.gray60,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualAssetTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _ManualAssetTabBarDelegate({required this.child});
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;
  @override
  double get maxExtent => 48;
  @override
  double get minExtent => 48;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
