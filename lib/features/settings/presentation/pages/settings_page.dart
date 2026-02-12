import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/common/image_resources.dart';
import 'package:financo/core/services/security_service.dart';
import 'package:financo/core/services/subscription_service.dart';
import 'package:financo/core/services/toast_service.dart';
import 'package:financo/di/injection_container.dart';
import 'package:financo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:financo/features/auth/presentation/bloc/auth_event.dart';
import 'package:financo/features/auth/presentation/bloc/auth_state.dart';
import 'package:financo/features/settings/presentation/widgets/icon_item_row.dart';
import 'package:financo/features/settings/presentation/widgets/icon_item_switch_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SecurityService _securityService;
  bool _isSecurityEnabled = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _securityService = sl<SecurityService>();
    _loadSecurityState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    final isPremium = await sl<SubscriptionService>().isPremium();
    if (mounted) {
      setState(() {
        _isPremium = isPremium;
      });
    }
  }

  Future<void> _loadSecurityState() async {
    final isEnabled = _securityService.isSecurityEnabled();

    setState(() {
      _isSecurityEnabled = isEnabled;
    });
  }

  bool _isProcessing = false;

  Future<void> _toggleSecurity(bool value) async {
    debugPrint('[_toggleSecurity] Toggling security to: $value');
    if (_isProcessing) {
      debugPrint('[_toggleSecurity] Already processing, ignoring request');
      return;
    }
    setState(() => _isProcessing = true);

    try {
      if (value) {
        debugPrint('[_toggleSecurity] Calling setupSecurity...');
        final result = await _securityService.setupSecurity();
        debugPrint(
          '[_toggleSecurity] setupSecurity result: ${result.success}, ${result.message}',
        );
        if (result.success) {
          setState(() {
            _isSecurityEnabled = true;
          });
          ToastService.showSuccess(context, result.message);
        } else {
          setState(() => _isSecurityEnabled = false);
          ToastService.showError(context, result.message);
        }
      } else {
        debugPrint('[_toggleSecurity] Calling authenticate to disable...');
        final authenticated = await _securityService.authenticate(
          reason: 'Authenticate to disable app lock',
        );
        debugPrint('[_toggleSecurity] authentication result: $authenticated');

        if (authenticated) {
          await _securityService.disableSecurity();
          setState(() {
            _isSecurityEnabled = false;
          });
          ToastService.showSuccess(context, 'Security disabled');
        } else {
          setState(() => _isSecurityEnabled = true);
          ToastService.showError(context, 'Authentication failed');
        }
      }
    } catch (e) {
      debugPrint('[_toggleSecurity] Error: $e');
      ToastService.showError(context, 'Error: ${e.toString()}');
      // Reset state based on original service state
      _loadSecurityState();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
      debugPrint('[_toggleSecurity] Processing finished');
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          'Logout',
          style: AppTypography.headline3SemiBold.copyWith(
            color: AppColors.white,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTypography.headline2Regular.copyWith(
            color: AppColors.gray30,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.headline3Medium.copyWith(
                color: AppColors.gray30,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Logout',
              style: AppTypography.headline3Medium.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AuthBloc>().add(const AuthSignOutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final user = state is Authenticated ? state.user : null;
              final name = user?.name ?? "User Account";
              final email = user?.email ?? "Sign in to sync your data";
              final photoUrl = user?.photoUrl;

              return Column(
                children: [
                  const SizedBox(height: 20),
                  // Profile Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gray70,
                          image: photoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(photoUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: photoUrl == null
                            ? Image.asset(
                                ImageResources.placeHolderPng,
                                width: 70,
                                height: 70,
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        email,
                        style: TextStyle(
                          color: AppColors.gray30,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 15, bottom: 8),
                          child: Text(
                            "Account & Security",
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.1),
                            ),
                            color: AppColors.gray60.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              IconItemSwitchRow(
                                title: "App Lock",
                                icon: Icons.lock,
                                value: _isSecurityEnabled,
                                isLoading: _isProcessing,
                                didChange: (val) {
                                  if (!_isProcessing) {
                                    _toggleSecurity(val);
                                  }
                                },
                              ),
                              Divider(
                                color: AppColors.border.withValues(alpha: 0.1),
                                height: 1,
                                indent: 20,
                                endIndent: 20,
                              ),
                              IconItemRow(
                                title: "Plan",
                                icon: Icons.payments,
                                value: _isPremium ? "Premium" : "Free",
                                onTap: () => context.push('/paywall'),
                              ),
                              Divider(
                                color: AppColors.border.withValues(alpha: 0.1),
                                height: 1,
                                indent: 20,
                                endIndent: 20,
                              ),
                              IconItemRow(
                                title: "Logout",
                                icon: Icons.logout,
                                textColor: Colors.red,
                                onTap: _handleLogout,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: Text(
                            "Financo v1.0.0",
                            style: AppTypography.headline1Regular.copyWith(
                              color: AppColors.gray50,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
