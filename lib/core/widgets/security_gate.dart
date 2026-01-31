import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/core/services/security_service.dart';
import 'package:financo/di/injection_container.dart';
import 'package:flutter/material.dart';

/// Production-ready security gate
///
/// This widget blocks access to the app until the user authenticates
/// with PIN/Biometric if security is enabled.
///
/// Features:
/// - Automatic authentication on app resume
/// - Biometric/PIN authentication
/// - Error handling with retry
/// - Beautiful lock screen UI
class SecurityGate extends StatefulWidget {
  final Widget child;

  const SecurityGate({
    super.key,
    required this.child,
  });

  @override
  State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate> with WidgetsBindingObserver {
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;
  String? _errorMessage;
  late final SecurityService _securityService;

  @override
  void initState() {
    super.initState();
    _securityService = sl<SecurityService>();
    WidgetsBinding.instance.addObserver(this);
    _checkAuthentication();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app comes to foreground, check authentication again
    if (state == AppLifecycleState.resumed) {
      if (_securityService.isSecurityEnabled() && _isAuthenticated) {
        setState(() {
          _isAuthenticated = false;
        });
        _authenticate();
      }
    }
  }

  Future<void> _checkAuthentication() async {
    final isSecurityEnabled = _securityService.isSecurityEnabled();

    if (!isSecurityEnabled) {
      // Security is disabled, allow access
      setState(() {
        _isAuthenticated = true;
      });
      return;
    }

    // Security is enabled, require authentication
    await _authenticate();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final biometricType = await _securityService.getBiometricTypeName();
      final authenticated = await _securityService.authenticate(
        reason: 'Authenticate to access Financo',
        useErrorDialogs: true,
      );

      if (authenticated) {
        setState(() {
          _isAuthenticated = true;
          _isAuthenticating = false;
        });
      } else {
        setState(() {
          _isAuthenticating = false;
          _errorMessage = 'Authentication failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lock Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 60,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Financo is Locked',
                  style: AppTypography.headline4SemiBold.copyWith(
                    color: AppColors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                FutureBuilder<String>(
                  future: _securityService.getBiometricTypeName(),
                  builder: (context, snapshot) {
                    final biometricType = snapshot.data ?? 'PIN';
                    return Text(
                      'Use $biometricType to unlock',
                      style: AppTypography.headline2Regular.copyWith(
                        color: AppColors.gray30,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 48),

                // Error Message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.headline2Regular.copyWith(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Unlock Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isAuthenticating ? null : _authenticate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isAuthenticating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.fingerprint_rounded, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Unlock',
                                style: AppTypography.headline3SemiBold.copyWith(
                                  color: AppColors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
