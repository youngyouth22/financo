import 'package:financo/common/common_widgets/add_security_in_sheet.dart';
import 'package:financo/core/services/security_service.dart';
import 'package:financo/features/assets/presentation/pages/assets_page.dart';
import 'package:financo/features/finance/presentation/pages/add_asset_choice_page.dart';
import 'package:financo/features/insights/presentation/pages/portfolio_insights_page.dart';
import 'package:financo/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:financo/features/home/presentation/pages/dashboard_page.dart';
import 'package:financo/features/home/presentation/widgets/custom_floating_button.dart';
import 'package:financo/features/home/presentation/widgets/custom_nav_bar.dart';
import 'package:financo/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:financo/di/injection_container.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int _currentIndex = 0;
  late PageController _controller;
  List<Widget> get _pages => [
    const DashboardPage(),
    const AssetsPage(),
    const PortfolioInsightsPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _currentIndex);
    _checkFirstLaunch();
  }

  /// Check if this is the first time the app is launched
  /// and show security setup popup if needed
  Future<void> _checkFirstLaunch() async {
    final securityService = sl<SecurityService>();
    final isFirst = await securityService.isFirstLaunch();

    if (isFirst && mounted) {
      // Show popup after a short delay to ensure UI is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          showAddSecurityInSheet(context);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void animateToPage(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.decelerate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<FinanceBloc>(),
      child: Scaffold(
        extendBody: true,
        floatingActionButton: CustomFloatingButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddAssetChoicePage(),
              ),
            );
          },
          isMenuOpen: false,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          clipBehavior: Clip.antiAlias,
          shape: const CircularNotchedRectangle(),
          notchMargin: 7,
          padding: EdgeInsets.zero,
          color: Colors.transparent,
          child: CustomNavBar(
            currentIndex: _currentIndex,
            onItemSelected: (index) {
              setState(() {
                _currentIndex = index;
                animateToPage(index);
              });
            },
          ),
        ),
        body: PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          children: _pages,
        ),
      ),
    );
  }
}
