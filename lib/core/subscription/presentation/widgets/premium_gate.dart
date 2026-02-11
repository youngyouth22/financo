import 'dart:ui';
import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/core/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:financo/core/subscription/presentation/pages/paywall_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PremiumGate extends StatelessWidget {
  final Widget child;
  final String? message;

  const PremiumGate({super.key, required this.child, this.message});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        if (state.status == SubscriptionStatus.premium) {
          return child;
        }

        return Stack(
          children: [
            // The restricted content (blurred)
            IgnorePointer(
              ignoring: true,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: child,
              ),
            ),

            // The Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.35),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainStrategy.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                          child: Icon(
                            Icons.lock_person_rounded,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Premium Feature",
                          textAlign: TextAlign.center,
                          style: AppTypography.headline1Bold.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message ??
                              "Upgrade to Financo Premium to unlock this insight and advanced portfolio analysis.",
                          textAlign: TextAlign.center,
                          style: AppTypography.headline3Regular.copyWith(
                            color: AppColors.gray20,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PaywallPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Unlock Now"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Support class for centering
class MainStrategy {
  static const center = MainAxisAlignment.center;
}
