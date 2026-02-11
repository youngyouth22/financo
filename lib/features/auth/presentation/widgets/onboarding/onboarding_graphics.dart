import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

class AIPromptGraphic extends StatelessWidget {
  const AIPromptGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background glow
          Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 800.ms)
              .scale(begin: const Offset(0.8, 0.8)),

          // The Prompt Bubble
          ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 280,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Analyze my portfolio for the last 30 days and suggest optimizations",
                          style: AppTypography.headline3Medium.copyWith(
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildActionIcon(Icons.pie_chart_outline),
                            const SizedBox(width: 8),
                            _buildActionIcon(
                              Icons.account_balance_wallet_outlined,
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    "AI Scan",
                                    style: AppTypography.headline1Medium
                                        .copyWith(color: Colors.white70),
                                  ),
                                  const Icon(
                                    Icons.bolt,
                                    color: Colors.yellow,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_upward,
                                color: Colors.black,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white70, size: 16),
    );
  }
}

class IntegrationsGraphic extends StatelessWidget {
  const IntegrationsGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Financial Logos floating around
          _buildFloatingLogo("Chase", const Offset(-110, -90), 0),
          _buildFloatingLogo("Binance", const Offset(110, -80), 100),
          _buildFloatingLogo("Coinbase", const Offset(-120, 40), 200),
          _buildFloatingLogo("Revolut", const Offset(120, 50), 300),
          _buildFloatingLogo("Bank", const Offset(0, -130), 400),

          // Center Prompt
          const AIPromptGraphic().animate().scale(
            begin: const Offset(0.9, 0.9),
          ),

          // "256-bit AES Encryption" pill
          Positioned(
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "256-bit AES Encryption",
                    style: AppTypography.headline1SemiBold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5, end: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingLogo(String name, Offset offset, int delayMs) {
    return Transform.translate(
      offset: offset,
      child:
          Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gray80,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getIconForName(name),
                  color: Colors.white,
                  size: 24,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .fadeIn(delay: delayMs.ms)
              .moveY(
                begin: -5,
                end: 5,
                duration: 2000.ms,
                curve: Curves.easeInOutSine,
              ),
    );
  }

  IconData _getIconForName(String name) {
    switch (name) {
      case "Chase":
        return Icons.account_balance;
      case "Binance":
        return Icons.currency_bitcoin;
      case "Coinbase":
        return Icons.currency_exchange;
      case "Revolut":
        return Icons.credit_card;
      case "Bank":
        return Icons.savings;
      default:
        return Icons.account_balance;
    }
  }
}

class BudgetTrackingGraphic extends StatelessWidget {
  const BudgetTrackingGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Budget Status
          _buildStatusRow("Monthly Budget Set", true),
          _buildConnectingLine(),
          _buildStatusRow("Tracking expenses...", false, badge: "Live"),
          _buildConnectingLine(),

          // Budget Card
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      width: double.infinity,
                      color: Colors.green,
                      child: Center(
                        child: Text(
                          "On Track: 45% of budget spent",
                          style: AppTypography.headline1Bold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.gray80,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Groceries",
                                  style: AppTypography.headline3Bold.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "\$450.00 / \$1,000.00",
                                  style: AppTypography.headline1Regular
                                      .copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String title, bool isCompleted, {String? badge}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gray80,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.sync,
            color: isCompleted ? Colors.green : Colors.blue,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTypography.headline2Medium.copyWith(color: Colors.white),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: AppTypography.headline1Medium.copyWith(
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }

  Widget _buildConnectingLine() {
    return Container(
      width: 2,
      height: 20,
      color: Colors.white12,
    ).animate().scaleY(begin: 0, end: 1);
  }
}

class GrowthMetricsGraphic extends StatelessWidget {
  const GrowthMetricsGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Asset Stack
          Positioned(
            top: -20,
            left: 20,
            child: _buildAppCard("Crypto Portfolio", Colors.orange, 0.8),
          ),
          _buildAppCard("Main Savings", Colors.blue, 1.0),

          // Growth Chart Overlay
          Positioned(
            bottom: -30,
            right: -20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.show_chart,
                            color: Colors.blue,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Net Worth Growth",
                            style: AppTypography.headline1Medium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "+\$12,450.00",
                        style: AppTypography.headline4Bold.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.2, end: 0),
          ),

          // Total ROI Pill
          Positioned(
            top: 40,
            left: -30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gray80,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Monthly ROI",
                    style: AppTypography.headline1Medium.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                  Text(
                    "+8.4%",
                    style: AppTypography.headline3Bold.copyWith(
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(String name, Color color, double opacity) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray80.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12.withValues(alpha: opacity)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.wallet, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: AppTypography.headline2Bold.copyWith(
              color: Colors.white.withValues(alpha: opacity),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class FinancoMaxGraphic extends StatelessWidget {
  const FinancoMaxGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(Icons.stars, color: Colors.yellow, size: 48),
          ).animate().fadeIn().scale(),
          const SizedBox(height: 24),
          Text(
            "Financo MAX",
            style: AppTypography.headline6Bold.copyWith(color: Colors.white),
          ).animate().fadeIn(delay: 200.ms),
          Text(
            "Take full control of your finances\nwith our most powerful tools",
            textAlign: TextAlign.center,
            style: AppTypography.headline3Regular.copyWith(
              color: Colors.white70,
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}
