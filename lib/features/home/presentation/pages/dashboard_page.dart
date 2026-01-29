import 'dart:math' show Random;

import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_spacing.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/common/common_widgets/custom_arc_180_painter.dart';
import 'package:financo/common/common_widgets/segment_button.dart';
import 'package:financo/common/common_widgets/status_button.dart';
import 'package:financo/common/image_resources.dart';
import 'package:financo/features/home/presentation/widgets/subscription_home_row.dart';
import 'package:financo/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:financo/features/finance/presentation/bloc/finance_event.dart';
import 'package:financo/features/finance/presentation/bloc/finance_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isSubscription = true;
  List<ArcValueModel> arcs = [
    // ArcValueModel(color: AppColors.accentS, value: 0.8),
    ArcValueModel(color: AppColors.accent, value: 0.5),
    // ArcValueModel(color: AppColors.primary10, value: 0.2),
  ];

  Random random = Random();
  late DateTime selectedDateNotAppBBar;

  @override
  void initState() {
    super.initState();
    // Load networth (which includes assets)
    context.read<FinanceBloc>().add(const LoadNetworthEvent());
  }

  Widget _buildAppBar() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
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

  Widget _buildTest() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.five,
        children: [
          SizedBox(
            width: double.infinity,
            child: Row(
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
          ),

          SizedBox(
            width: double.infinity,
            height: 8,
            child: Row(
              children: [
                Expanded(flex: 6, child: Container(color: AppColors.accent)),
                Expanded(flex: 2, child: Container(color: AppColors.primary10)),
                Expanded(flex: 1, child: Container(color: AppColors.accentS)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FinanceBloc, FinanceState>(
      listener: (context, state) {
        if (state is FinanceError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
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
                    BlocBuilder<FinanceBloc, FinanceState>(
                      builder: (context, state) {
                        String displayValue = '0.00';
                        if (state is NetworthLoaded) {
                          print(
                            'Networth total value: ${state.networth.assets.length}',
                          );
                          displayValue = state.networth.total.value
                              .toStringAsFixed(2)
                              .replaceAllMapped(
                                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                (Match m) => '${m[1]},',
                              );
                        }

                        final parts = displayValue.split('.');
                        final wholePart = parts[0];
                        final decimalPart = parts.length > 1 ? parts[1] : '00';

                        return RichText(
                          text: TextSpan(
                            style: AppTypography.headline7Bold.copyWith(
                              color: AppColors.gray30,
                              height: 1.2,
                              fontFamily: 'JetBrainsMono',
                            ),
                            children: [
                              const TextSpan(text: '\$ '),
                              TextSpan(
                                text: wholePart,
                                style: AppTypography.headline7Bold.copyWith(
                                  color: AppColors.white,
                                  height: 1,
                                  fontFamily: 'JetBrainsMono',
                                ),
                              ),
                              TextSpan(
                                text: '.$decimalPart',
                                style: AppTypography.headline6Bold.copyWith(
                                  color: AppColors.gray30,
                                  height: 1,
                                  fontFamily: 'JetBrainsMono',
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    _buildTest(),

                    const SizedBox(height: 20),

                    BlocBuilder<FinanceBloc, FinanceState>(
                      builder: (context, state) {
                        int activeSubs = 0;
                        double highestPrice = 0.0;
                        double lowestPrice = double.maxFinite;

                        if (state is NetworthLoaded) {
                          final assets = state.networth.assets;
                          activeSubs = assets.length;

                          for (var asset in assets) {
                            if (asset.price > highestPrice) {
                              highestPrice = asset.price;
                            }
                            if (asset.price < lowestPrice) {
                              lowestPrice = asset.price;
                            }
                          }

                          if (lowestPrice == double.maxFinite) {
                            lowestPrice = 0.0;
                          }
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: StatusButton(
                                title: "Active subs",
                                value: activeSubs.toString(),
                                statusColor: AppColors.accent,
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: StatusButton(
                                title: "Highest subs",
                                value: highestPrice > 0
                                    ? "\$${highestPrice.toStringAsFixed(2)}"
                                    : "\$0.00",
                                statusColor: AppColors.primary10,
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: StatusButton(
                                title: "Lowest subs",
                                value:
                                    lowestPrice < double.maxFinite &&
                                        lowestPrice > 0
                                    ? "\$${lowestPrice.toStringAsFixed(2)}"
                                    : "\$0.00",
                                statusColor: AppColors.accentS,
                                onPressed: () {},
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentButton(
                      title: "Your subscription",
                      isActive: isSubscription,
                      onPressed: () {
                        setState(() {
                          isSubscription = !isSubscription;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: SegmentButton(
                      title: "Upcoming bills",
                      isActive: !isSubscription,
                      onPressed: () {
                        setState(() {
                          isSubscription = !isSubscription;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            BlocBuilder<FinanceBloc, FinanceState>(
              builder: (context, state) {
                if (state is FinanceLoading) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is NetworthLoaded) {
                  final assets = state.networth.assets;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 0,
                    ),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: assets.length,
                    itemBuilder: (context, index) {
                      final asset = assets[index];
                      final assetMap = {
                        "name": asset.name,
                        "icon": asset.iconUrl,
                        "price": asset.value.toStringAsFixed(2),
                      };

                      return SubScriptionHomeRow(
                        sObj: assetMap,
                        onPressed: () {},
                      );
                    },
                  );
                }

                return const SizedBox(
                  height: 100,
                  child: Center(child: Text('No assets found')),
                );
              },
            ),
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }
}

// import 'package:financo/core/common/common_widgets/header_container.dart';
// import 'package:financo/core/configs/constants/colors/app_colors.dart';
// import 'package:financo/core/configs/constants/spacings/app_spacing.dart';
// import 'package:financo/core/configs/constants/typography/app_typography.dart';
// import 'package:financo/core/utils/currency_formatter_string.dart';
// import 'package:financo/features/account/data/models/balance_summary.dart';
// import 'package:financo/features/account/presentation/bloc/cubit/account_cubit.dart';
// import 'package:financo/features/home/presentation/widgets/custom_appbar_button.dart';
// import 'package:financo/features/home/presentation/widgets/financial_info_widget.dart';
// import 'package:financo/features/home/presentation/widgets/list_account_widget.dart';
// import 'package:financo/service_locator.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class DashboardPage extends StatefulWidget {
//   const DashboardPage({super.key});

//   @override
//   State<DashboardPage> createState() => _DashboardPageState();
// }

// class _DashboardPageState extends State<DashboardPage> {
//   late final ScrollController scrollController;
//   late final ValueNotifier<int> currentIndexNotifier;

//   @override
//   void initState() {
//     super.initState();
//     scrollController = ScrollController();
//     currentIndexNotifier = ValueNotifier<int>(0);
//   }

//   @override
//   void dispose() {
//     scrollController.dispose();
//     currentIndexNotifier.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) => getIt<AccountCubit>()..getUserBalanceSummary(),
//       child: Scaffold(
//         appBar: AppBar(
//           title: Row(
//             spacing: AppSpacing.five,
//             children: [
//               CircleAvatar(
//                 radius: 18,
//                 backgroundColor: AppColors.gray70,
//                 child: Text(
//                   'R',
//                   style: AppTypography.headline3SemiBold.copyWith(
//                     color: AppColors.gray20,
//                   ),
//                 ),
//               ),
//               Text('Hello, Rengo'),
//             ],
//           ),
//           backgroundColor: AppColors.gray70.withValues(alpha: 0.5),
//           actionsPadding: EdgeInsets.symmetric(horizontal: AppSpacing.fifteen),
//           actions: [
//             CustomAppbarButton(
//               icon: Icon(Icons.slow_motion_video_sharp, size: 30),
//               onPressed: () {},
//             ),
//             SizedBox(width: AppSpacing.ten),
//             CustomAppbarButton(
//               icon: Icon(Icons.notifications_none_rounded, size: 30),
//               onPressed: () {},
//             ),
//           ],
//         ),
//         body: SingleChildScrollView(
//           child: BlocBuilder<AccountCubit, AccountState>(
//             builder: (context, state) {
//               if (state is GetUserBalanceSummarySuccess) {
//                 BalanceSummary balanceSummary = state.balanceSummary;
//               }
//               return Column(
//                 spacing: AppSpacing.twenty,
//                 children: [
//                   HeaderContainer(
//                       height: 0.6,
//                       child: Column(
//                         children: [
//                           Expanded(
//                               child: Padding(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: AppSpacing.fifteen,
//                                 vertical: AppSpacing.ten),
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 SizedBox(
//                                   width: double.infinity,
//                                   child: Text('Balance total',
//                                       style: AppTypography.headline2Medium
//                                           .copyWith(color: AppColors.gray40)),
//                                 ),
//                                 Row(
//                                   children: [
//                                     Expanded(
//                                       child: Text(
//                                           state is GetUserBalanceSummarySuccess
//                                               ? formatCurrency(
//                                                   currencyCode: 'EUR',
//                                                   amount: state.balanceSummary
//                                                       .totalBalance)
//                                               : '',
//                                           style: AppTypography.headline7Bold
//                                               .copyWith(
//                                                   overflow:
//                                                       TextOverflow.ellipsis,
//                                                   color: AppColors.white)),
//                                     ),
//                                     GestureDetector(
//                                       onTap: () {},
//                                       child: Icon(
//                                         Icons.remove_red_eye_outlined,
//                                         color: AppColors.gray60,
//                                         size: 24,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           )),
//                           Container(
//                             height: 85,
//                             width: double.infinity,
//                             color: AppColors.gray70,
//                             padding: EdgeInsets.all(AppSpacing.ten),
//                             child: Row(
//                               children: [
//                                 FinancialInfoWidget(
//                                   title: 'Dépense total du mois',
//                                   amount: '\$ 1 000,00',
//                                   percentage: '+ 5%',
//                                 ),
//                                 VerticalDivider(
//                                   color: AppColors.gray60,
//                                   width: 1,
//                                   thickness: 1,
//                                 ),
//                                 FinancialInfoWidget(
//                                   title: 'Revenue total du mois',
//                                   amount: '\$ 500,00',
//                                   percentage: '+ 10%',
//                                 ),
//                               ],
//                             ),
//                           )
//                         ],
//                       )),
//                   if (false)
//                     ListAccountWidget(
//                       scrollController: scrollController,
//                       currentIndexNotifier: currentIndexNotifier,
//                     ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
