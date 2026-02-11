import 'dart:async';

import 'package:financo/common/common_widgets/add_security_in_sheet.dart';
import 'package:financo/core/services/notification_service.dart';
import 'package:financo/core/services/security_service.dart';
import 'package:financo/features/assets/presentation/pages/assets_page.dart';
import 'package:financo/features/insights/presentation/pages/portfolio_insights_page.dart';
import 'package:financo/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:financo/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:financo/features/assets/presentation/bloc/assets_bloc.dart';
import 'package:financo/features/assets/presentation/bloc/assets_event.dart';
import 'package:financo/features/home/presentation/pages/dashboard_page.dart';
import 'package:financo/features/home/presentation/widgets/custom_floating_button.dart';
import 'package:financo/features/home/presentation/widgets/custom_nav_bar.dart';
import 'package:financo/features/home/presentation/widgets/fab_expansion_menu.dart';
import 'package:financo/features/settings/presentation/pages/settings_page.dart';
import 'package:financo/features/finance/presentation/pages/add_stock_page.dart';
import 'package:financo/features/finance/presentation/pages/add_crypto_wallet_page.dart';
import 'package:financo/features/finance/presentation/pages/add_bank_account_page.dart';
import 'package:financo/features/finance/presentation/pages/add_manual_asset_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:financo/di/injection_container.dart';
import 'package:financo/core/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:financo/core/subscription/presentation/pages/paywall_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  Timer? _priceTimer;
  int _currentIndex = 0;
  late PageController _controller;
  bool _isMenuOpen = false;

  void _startLivePriceSync() {
    // 1. Première exécution
    _refreshPrices();

    // 2. Boucle de 30 secondes
    _priceTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _refreshPrices();
      }
    });
  }

  Future<void> _refreshPrices() async {
    try {
      // Get user ID safely
      final userId = sl<SupabaseClient>().auth.currentUser?.id;
      if (userId == null) return;

      // PREMIUM GATING: Skip market sync for free users to save resources
      final subState = context.read<SubscriptionBloc>().state;
      if (subState.status != SubscriptionStatus.premium) {
        debugPrint("Skipping market price sync (Free Tier)");
        return;
      }

      await sl<SupabaseClient>().functions.invoke(
        'refresh-market-prices',
        body: {'userId': userId},
      );
      debugPrint("Market Prices Updated!");

      // Refresh Dashboard UI with new calculations
      if (mounted) {
        context.read<DashboardBloc>().add(const RefreshDashboardEvent());
      }
    } catch (e) {
      debugPrint("Sync error: $e");
    }
  }

  // Wrap pages with their respective BLoC providers
  List<Widget> get _pages => [
    const DashboardPage(),
    const AssetsPage(),
    const PortfolioInsightsPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _startLivePriceSync();
    _syncFcmToken();
    _controller = PageController(initialPage: _currentIndex);
    _checkFirstLaunch();
  }

  /// Sync FCM token to Supabase profile
  Future<void> _syncFcmToken() async {
    try {
      final userId = sl<SupabaseClient>().auth.currentUser?.id;
      if (userId == null) return;

      // Get current token
      final token = await sl<NotificationService>().getToken();

      if (token != null) {
        await _updateTokenInSupabase(userId, token);
      }

      // Listen for token refreshes
      sl<NotificationService>().onTokenRefresh.listen((newToken) {
        _updateTokenInSupabase(userId, newToken);
      });
    } catch (e) {
      debugPrint('Error syncing FCM token: $e');
    }
  }

  Future<void> _updateTokenInSupabase(String userId, String token) async {
    try {
      // Use update instead of upsert since the profile MUST exist (created by trigger)
      await sl<SupabaseClient>()
          .from('profiles')
          .update({
            'fcm_token': token,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      debugPrint('FCM Token synced to Supabase');
    } catch (e) {
      debugPrint('Error updating FCM token in Supabase: $e');
    }
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
    _priceTimer?.cancel();
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

  void _handleTypeSelected(String type) async {
    setState(() {
      _isMenuOpen = false;
    });

    final subState = context.read<SubscriptionBloc>().state;
    final isPremium = subState.status == SubscriptionStatus.premium;

    if (!isPremium && type != 'manual') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const PaywallPage()));
      return;
    }

    Widget? page;
    switch (type) {
      case 'stock':
        page = const AddStockPage();
        break;
      case 'crypto':
        page = const AddCryptoWalletPage();
        break;
      case 'bank':
        page = const AddBankAccountPage();
        break;
      case 'manual':
        page = const AddManualAssetPage();
        break;
    }

    if (page != null) {
      final result = await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => page!));

      if (result == true && mounted) {
        BlocProvider.of<DashboardBloc>(
          context,
        ).add(const RefreshDashboardEvent());
        try {
          BlocProvider.of<AssetsBloc>(context).add(const WatchAssetsEvent());
        } catch (e) {
          debugPrint('AssetsBloc not available: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            children: _pages,
          ),
          FabExpansionMenu(
            isOpen: _isMenuOpen,
            onClose: () => setState(() => _isMenuOpen = false),
            onTypeSelected: _handleTypeSelected,
          ),
        ],
      ),
      floatingActionButton: CustomFloatingButton(
        onPressed: () {
          setState(() {
            _isMenuOpen = !_isMenuOpen;
          });
        },
        isMenuOpen: _isMenuOpen,
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
    );
  }
}
