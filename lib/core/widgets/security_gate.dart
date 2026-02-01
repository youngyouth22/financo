import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/core/services/security_service.dart';
import 'package:financo/di/injection_container.dart';
import 'package:flutter/material.dart';

class SecurityGate extends StatefulWidget {
  final Widget child;

  const SecurityGate({super.key, required this.child});

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

    // Initial check on app startup
    _checkInitialAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

 @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_securityService.isSecurityEnabled()) return;
    if (_securityService.isInternalAuthAction) return; 

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_isAuthenticated) {
        setState(() => _isAuthenticated = false);
      }
    }

    if (state == AppLifecycleState.resumed) {
      if (!_isAuthenticated && !_isAuthenticating) {
        _authenticate();
      }
    }
  }

  Future<void> _checkInitialAuth() async {
    if (!_securityService.isSecurityEnabled()) {
      setState(() => _isAuthenticated = true);
    } else {
      // Force authentication on startup
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
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
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If the user is authenticated, we show the app content
    if (_isAuthenticated) {
      return widget.child;
    }

    // Otherwise, we show the beautiful lock screen
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLockIcon(),
                const SizedBox(height: 32),
                Text(
                  'Financo is Locked',
                  style: AppTypography.headline4Bold.copyWith(
                    color: AppColors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBiometricTypeDescription(),
                const SizedBox(height: 48),
                if (_errorMessage != null) _buildErrorBadge(),
                const SizedBox(height: 24),
                _buildUnlockButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // UI HELPERS (Preserving your original design)
  // ===========================================================================

  Widget _buildLockIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.lock_rounded, size: 60, color: AppColors.accent),
    );
  }

  Widget _buildBiometricTypeDescription() {
    return FutureBuilder<String>(
      future: _securityService.getBiometricTypeName(),
      builder: (context, snapshot) => Text(
        'Use ${snapshot.data ?? "PIN"} to unlock',
        style: AppTypography.headline2Regular.copyWith(
          color: AppColors.gray30,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildErrorBadge() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Text(
        _errorMessage!,
        style: const TextStyle(color: Colors.red, fontSize: 14),
      ),
    );
  }

  Widget _buildUnlockButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isAuthenticating ? null : _authenticate,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isAuthenticating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Unlock Now', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}