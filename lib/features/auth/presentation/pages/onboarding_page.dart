import 'dart:ui';

import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/common/image_resources.dart';
import 'package:financo/core/services/toast_service.dart';
import 'package:financo/features/auth/presentation/widgets/onboading_step_page_widget.dart';
import 'package:financo/features/auth/presentation/widgets/onboarding/onboarding_graphics.dart';
import 'package:financo/features/auth/presentation/bloc/onboarding_bloc.dart';
import 'package:financo/features/auth/presentation/bloc/onboarding_event.dart';
import 'package:financo/features/auth/presentation/bloc/onboarding_state.dart';
import 'package:financo/di/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'
    hide ScaleEffect;

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  PageController pageController = PageController();
  bool isLast = false;

  void _stepNextPage() async {
    await pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void initState() {
    pageController.addListener(() {
      final currentPage = pageController.page?.round() ?? 0;
      if (isLast != (currentPage == 4)) {
        setState(() {
          isLast = currentPage == 4;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  final List<OnboardingModel> onboardingDatas = const [
    OnboardingModel(
      graphic: AIPromptGraphic(),
      title: 'Master Your Wealth in One Place',
      subTitle:
          'Track all your assets, from crypto to bank accounts, in one beautiful dashboard.',
    ),
    OnboardingModel(
      graphic: IntegrationsGraphic(),
      title: 'Seamless Financial Connections',
      subTitle:
          'Connect your banks and exchanges securely to get a real-time view of your net worth.',
    ),
    OnboardingModel(
      graphic: BudgetTrackingGraphic(),
      title: 'Budgeting Made Effortless',
      subTitle:
          'Set monthly limits and track every expense automatically to save more each month.',
    ),
    OnboardingModel(
      graphic: GrowthMetricsGraphic(),
      title: 'AI-Powered Wealth Insights',
      subTitle:
          'Get personalized suggestions and forecasting to reach your financial goals faster.',
    ),
    OnboardingModel(
      graphic: FinancoMaxGraphic(),
      title: 'Unlock Your Financial Potential',
      subTitle:
          'Get unlimited accounts, advanced analytics, and priority support with MAX.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<OnboardingBloc>(),
      child: Builder(
        builder: (context) {
          return AnnotatedRegion(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.black,
              systemNavigationBarIconBrightness: Brightness.light,
            ),
            child: Scaffold(
              backgroundColor: Colors.black,
              body: BlocListener<OnboardingBloc, OnboardingState>(
                listener: (context, state) {
                  if (state is OnboardingSuccess) {
                    context.go('/paywall');
                  } else if (state is OnboardingFailure) {
                    ToastService.showError(context, state.message);
                  }
                },
                child: Stack(
                  children: [
                    Transform.scale(
                      scale: 3.4,
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 1.0),
                              Colors.black.withValues(alpha: 0.0),
                            ],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 350),
                          child: SvgPicture.asset(
                            ImageResources.grilledSvg,
                            colorFilter: ColorFilter.mode(
                              AppColors.white,
                              BlendMode.srcIn,
                            ),
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: Opacity(
                        opacity: 0.7,
                        child: Image.asset(
                          ImageResources.star,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                      child: Transform(
                        alignment: Alignment.topRight,
                        transform: Matrix4.identity()
                          ..translateByDouble(100.0, -100, 0.0, 1.0)
                          ..rotateZ(-0.6),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.7,
                          height: 250,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.04),
                                Colors.white.withValues(alpha: 0.2),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Top Skip Button
                    Positioned(
                      top: 20,
                      right: 20,
                      child: SafeArea(
                        child: GestureDetector(
                          onTap: () {
                            context.read<OnboardingBloc>().add(
                              const CompleteOnboardingRequested(),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Skip",
                                style: AppTypography.headline3Medium.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Main Content
                    Column(
                      children: [
                        Expanded(
                          child: PageView(
                            controller: pageController,
                            children: onboardingDatas
                                .map(
                                  (onboarding) => OnboadingStepPageWidget(
                                    graphic: onboarding.graphic,
                                    title: onboarding.title,
                                    subTitle: onboarding.subTitle,
                                  ),
                                )
                                .toList(),
                          ),
                        ),

                        // Bottom Section (Indicator + Button)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 40,
                          ),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: SmoothPageIndicator(
                                  controller: pageController,
                                  effect: const ExpandingDotsEffect(
                                    activeDotColor: Colors.white,
                                    dotColor: Colors.white24,
                                    dotHeight: 4,
                                    dotWidth: 4,
                                    expansionFactor: 4,
                                    spacing: 8,
                                  ),
                                  count: 5,
                                ),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: isLast
                                      ? () {
                                          context.read<OnboardingBloc>().add(
                                            const CompleteOnboardingRequested(),
                                          );
                                        }
                                      : _stepNextPage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    isLast ? 'Get Started' : 'Continue',
                                    style: AppTypography.headline3Bold.copyWith(
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class OnboardingModel {
  final Widget graphic;
  final String title;
  final String subTitle;

  const OnboardingModel({
    required this.graphic,
    required this.subTitle,
    required this.title,
  });
}
