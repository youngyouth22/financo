import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/core/services/security_service.dart';
import 'package:financo/di/injection_container.dart';
import 'package:financo/features/auth/domain/usecases/logout_usecase.dart';
import 'package:financo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:financo/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Settings page with logout and security management
///
/// Features:
/// - User profile section
/// - Security toggle (requires authentication to disable)
/// - Logout functionality
/// - Modern UI design
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SecurityService _securityService;
  bool _isSecurityEnabled = false;
  String _biometricType = 'PIN';

  @override
  void initState() {
    super.initState();
    _securityService = sl<SecurityService>();
    _loadSecurityState();
  }

  Future<void> _loadSecurityState() async {
    final isEnabled = _securityService.isSecurityEnabled();
    final biometricType = await _securityService.getBiometricTypeName();

    setState(() {
      _isSecurityEnabled = isEnabled;
      _biometricType = biometricType;
    });
  }

  Future<void> _toggleSecurity(bool value) async {
    if (value) {
      // Enable security
      final result = await _securityService.setupSecurity();

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _isSecurityEnabled = true;
          _biometricType = result.biometricType ?? 'PIN';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Disable security - requires authentication first
      final authenticated = await _securityService.authenticate(
        reason: 'Authenticate to disable security',
        useErrorDialogs: true,
      );

      if (!mounted) return;

      if (authenticated) {
        await _securityService.disableSecurity();

        setState(() {
          _isSecurityEnabled = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security disabled successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. Security remains enabled.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
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
              style: AppTypography.headline3Medium.copyWith(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Dispatch logout event to AuthBloc
      context.read<AuthBloc>().add(const LogoutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Settings',
          style: AppTypography.headline3SemiBold.copyWith(
            color: AppColors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gray70),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 32,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Account',
                          style: AppTypography.headline3SemiBold.copyWith(
                            color: AppColors.white,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your account settings',
                          style: AppTypography.headline2Regular.copyWith(
                            color: AppColors.gray30,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Security Section
            Text(
              'Security',
              style: AppTypography.headline3SemiBold.copyWith(
                color: AppColors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            // Security Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray70),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isSecurityEnabled
                          ? Colors.green.withOpacity(0.2)
                          : AppColors.gray80,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isSecurityEnabled
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded,
                      size: 20,
                      color: _isSecurityEnabled ? Colors.green : AppColors.gray40,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Lock',
                          style: AppTypography.headline3Medium.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isSecurityEnabled
                              ? 'Secured with $_biometricType'
                              : 'Not enabled',
                          style: AppTypography.headline1Regular.copyWith(
                            color: AppColors.gray40,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isSecurityEnabled,
                    onChanged: _toggleSecurity,
                    activeColor: Colors.green,
                    activeTrackColor: Colors.green.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Account Section
            Text(
              'Account',
              style: AppTypography.headline3SemiBold.copyWith(
                color: AppColors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            // Logout Button
            InkWell(
              onTap: _handleLogout,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Logout',
                            style: AppTypography.headline3Medium.copyWith(
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sign out of your account',
                            style: AppTypography.headline1Regular.copyWith(
                              color: AppColors.gray40,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.red.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // App Info
            Center(
              child: Column(
                children: [
                  Text(
                    'Financo',
                    style: AppTypography.headline3SemiBold.copyWith(
                      color: AppColors.gray50,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: AppTypography.headline1Regular.copyWith(
                      color: AppColors.gray60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
