import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_spacing.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/common/common_widgets/add_security_in_sheet.dart';
import 'package:financo/common/common_widgets/segment_button.dart';
import 'package:financo/common/common_widgets/status_button.dart';
import 'package:financo/common/image_resources.dart';
import 'package:financo/common/widgets/shimmer/dashboard_shimmer.dart';
import 'package:financo/common/widgets/empty_states/no_data_state.dart';
import 'package:financo/features/finance/data/models/networth_response_model.dart';
import 'package:financo/features/home/presentation/widgets/subscription_home_row.dart';
import 'package:financo/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:financo/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:financo/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isPortfolioView = true;

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const LoadDashboardEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DashboardBloc, DashboardState>(
      listener: (context, state) {
        if (state is DashboardError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: BlocBuilder<DashboardBloc, DashboardState>(
            buildWhen: (previous, current) =>
                current is NetworthLoaded || current is DashboardLoading,
            builder: (context, state) {
              if (state is DashboardLoading) {
                return const DashboardShimmer();
              }

              if (state is NetworthLoaded) {
                final networth = state.networth;
                final assets = networth.assets;

                return Column(
                  children: [
                    _buildTopHeader(networth.total.value, assets),
                    _buildFilterToggle(),
                    _buildListSection(assets),
                    const SizedBox(height: 110),
                  ],
                );
              }

              return NoDataState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'No Assets Connected',
                message:
                    'Add your first crypto wallet, stock, or bank account to get started',
                actionLabel: 'Add Asset',
                onAction: () => showAddSecurityInSheet(context),
              );
            },
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADER SECTION (Logic fixed, Design preserved)
  // ===========================================================================

  Widget _buildTopHeader(double totalVal, List<AssetDetail> assets) {
    // LOGIQUE DE CALCUL ROBUSTE
    // On normalize les types en minuscules pour ne rater aucun actif
    final cryptoAssets = assets
        .where((a) => a.type.toLowerCase() == 'crypto')
        .toList();
    final stockAssets = assets
        .where(
          (a) =>
              a.type.toLowerCase() == 'stock' || a.type.toLowerCase() == 'etf',
        )
        .toList();

    final double cryptoSum = cryptoAssets.fold(0.0, (sum, a) => sum + a.value);
    final double stockSum = stockAssets.fold(0.0, (sum, a) => sum + a.value);

    // "Other" = Tout ce qui n'est pas crypto ou stock (Cash, Real Estate, Commodities)
    double otherSum = totalVal - cryptoSum - stockSum;
    if (otherSum < 0.01) otherSum = 0; // Nettoyage des arrondis

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.gray70.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAppBar(),
            const SizedBox(height: 20),
            Text(
              'Total networth',
              style: AppTypography.headline2Regular.copyWith(
                color: AppColors.gray40,
                letterSpacing: 2.4,
                fontFamily: 'JetBrainsMono',
              ),
            ),
            _buildNetworthText(totalVal),
            const SizedBox(height: 20),

            // Barre d'allocation liée aux vrais chiffres
            _buildAllocationBar(totalVal, cryptoSum, stockSum, otherSum),

            const SizedBox(height: 20),

            // Légendes dynamiques (Crypto, Stocks, Other)
            Row(
              children: [
                Expanded(
                  child: StatusButton(
                    title: "Crypto",
                    value: "\$${_formatCompact(cryptoSum)}",
                    statusColor: AppColors.accent,
                    onPressed: () {
                      showAddSecurityInSheet(context);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatusButton(
                    title: "Stocks",
                    value: "\$${_formatCompact(stockSum)}",
                    statusColor: AppColors.primary10,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatusButton(
                    title: "Other",
                    value: "\$${_formatCompact(otherSum)}",
                    statusColor: AppColors.accentS,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationBar(
    double total,
    double crypto,
    double stock,
    double other,
  ) {
    // Calcul précis des flex (base 100)
    int flexCrypto = total > 0 ? ((crypto / total) * 100).round() : 0;
    int flexStock = total > 0 ? ((stock / total) * 100).round() : 0;
    int flexOther = total > 0
        ? (100 - flexCrypto - flexStock).clamp(0, 100)
        : 100;

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.five,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Allocation',
                style: AppTypography.headline1Regular.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
            Text(
              '100%',
              style: AppTypography.headline1Regular.copyWith(
                color: AppColors.gray40,
              ),
            ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          height: 8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Row(
              children: [
                if (flexCrypto > 0)
                  Expanded(
                    flex: flexCrypto,
                    child: Container(color: AppColors.accent),
                  ),
                if (flexStock > 0)
                  Expanded(
                    flex: flexStock,
                    child: Container(color: AppColors.primary10),
                  ),
                if (flexOther > 0)
                  Expanded(
                    flex: flexOther,
                    child: Container(color: AppColors.accentS),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // LIST SECTION (Top 5 Logic)
  // ===========================================================================

  Widget _buildListSection(List<AssetDetail> assets) {
    if (assets.isEmpty) {
      return const NoDataState(
        icon: Icons.search_off,
        title: 'No Data Available',
        message: 'Unable to load your assets',
      );
    }

    // Tri selon le filtre sélectionné
    List<AssetDetail> sorted = List.from(assets);
    if (isPortfolioView) {
      sorted.sort((a, b) => b.value.compareTo(a.value)); // Plus gros montants
    } else {
      sorted.sort(
        (a, b) => b.change24h.abs().compareTo(a.change24h.abs()),
      ); // Plus grosses variations
    }

    final top5 = sorted.take(5).toList();

    return Column(
      children: [
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: top5.length,
          itemBuilder: (context, index) {
            final a = top5[index];
            return SubScriptionHomeRow(
              sObj: {
                "name": a.name,
                "icon": a.iconUrl,
                "price": a.value.toStringAsFixed(2),
              },
              onPressed: () {},
            );
          },
        ),
        if (assets.length > 5)
          TextButton(
            onPressed: () {},
            child: Text(
              "See all ${assets.length} assets",
              style: TextStyle(color: AppColors.accent),
            ),
          ),

        const SizedBox(height: 40),
      ],
    );
  }

  // ===========================================================================
  // DESIGN ATOMS (Preserved)
  // ===========================================================================

  Widget _buildAppBar() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Row(
        children: [
          SvgPicture.asset(
            ImageResources.financoLogo,
            colorFilter: ColorFilter.mode(AppColors.white, BlendMode.srcIn),
            height: 40,
          ),
          Expanded(
            child: Center(
              child: Text(
                'Financo',
                style: AppTypography.headline5Bold.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworthText(double val) {
    String display = val
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    final parts = display.split('.');
    return RichText(
      text: TextSpan(
        style: AppTypography.headline7Bold.copyWith(
          color: AppColors.gray30,
          fontFamily: 'JetBrainsMono',
        ),
        children: [
          const TextSpan(text: '\$ '),
          TextSpan(
            text: parts[0],
            style: AppTypography.headline7Bold.copyWith(color: AppColors.white),
          ),
          TextSpan(
            text: '.${parts[1]}',
            style: AppTypography.headline6Bold.copyWith(
              color: AppColors.gray30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.all(8),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: SegmentButton(
              title: "Portfolio",
              isActive: isPortfolioView,
              onPressed: () => setState(() => isPortfolioView = true),
            ),
          ),
          Expanded(
            child: SegmentButton(
              title: "Top Movers",
              isActive: !isPortfolioView,
              onPressed: () => setState(() => isPortfolioView = false),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompact(double val) {
    if (val.abs() >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
    if (val.abs() >= 1000) return '${(val / 1000).toStringAsFixed(0)}K';
    return val.toStringAsFixed(0);
  }
}
