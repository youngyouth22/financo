import 'dart:ui';
import 'package:financo/common/app_colors.dart';
import 'package:financo/core/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:financo/features/home/presentation/widgets/fab_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FabExpansionMenu extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final Function(String type) onTypeSelected;

  const FabExpansionMenu({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onTypeSelected,
  });

  @override
  State<FabExpansionMenu> createState() => _FabExpansionMenuState();
}

class _FabExpansionMenuState extends State<FabExpansionMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.2), // Start from below the screen
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    if (widget.isOpen) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(FabExpansionMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen && _controller.isDismissed) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Backdrop Blur
        GestureDetector(
          onTap: widget.onClose,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
          ),
        ),
        // Menu content
        Positioned(
          bottom: 90, // Seated on the FAB notch
          left: 20,
          right: 20,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomPaint(
                painter: NotchedMenuPainter(),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 24, 12, 60),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20, bottom: 10),
                        child: Text(
                          'Add...',
                          style: TextStyle(
                            color: AppColors.white.withOpacity(0.7),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      BlocBuilder<SubscriptionBloc, SubscriptionState>(
                        builder: (context, state) {
                          final isPremium =
                              state.status == SubscriptionStatus.premium;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FABMenuItem(
                                icon: Icons.trending_up,
                                iconColor: AppColors.success,
                                label: 'Stock',
                                trailingIcon: !isPremium
                                    ? Icons.lock_outline
                                    : null,
                                onTap: () => widget.onTypeSelected('stock'),
                              ),
                              FABMenuItem(
                                icon: Icons.account_balance_wallet_outlined,
                                iconColor: AppColors.accent,
                                label: 'Crypto Wallet',
                                trailingIcon: !isPremium
                                    ? Icons.lock_outline
                                    : null,
                                onTap: () => widget.onTypeSelected('crypto'),
                              ),
                              FABMenuItem(
                                icon: Icons.account_balance,
                                iconColor: AppColors.primary20,
                                label: 'Bank Account',
                                trailingIcon: !isPremium
                                    ? Icons.lock_outline
                                    : null,
                                onTap: () => widget.onTypeSelected('bank'),
                              ),
                              FABMenuItem(
                                icon: Icons.edit_document,
                                iconColor: AppColors.warning,
                                label: 'Manual Asset',
                                onTap: () => widget.onTypeSelected('manual'),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class NotchedMenuPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gray80
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final path = Path();
    const double radius = 24.0;
    const double notchRadius = 34; // Slightly larger than FAB radius (30)

    // Main box with rounded corners
    path.moveTo(radius, 0);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height - radius - 20); // Stop before notch

    // Bottom right corner
    path.quadraticBezierTo(
      size.width,
      size.height - 20,
      size.width - radius,
      size.height - 20,
    );

    // Bottom edge with notch
    path.lineTo(size.width / 2 + notchRadius, size.height - 20);

    // The Notch (Inverted arc)
    path.arcToPoint(
      Offset(size.width / 2 - notchRadius, size.height - 20),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );

    path.lineTo(radius, size.height - 20);

    // Bottom left corner
    path.quadraticBezierTo(0, size.height - 20, 0, size.height - radius - 20);
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);

    path.close();

    // Draw shadow
    canvas.drawPath(path, shadowPaint);
    // Draw background
    canvas.drawPath(path, paint);

    // Add border
    final borderPaint = Paint()
      ..color = AppColors.gray70.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
