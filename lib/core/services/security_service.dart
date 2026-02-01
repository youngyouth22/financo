import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Production-ready security service
///
/// Handles:
/// - First-time app launch detection
/// - PIN/Biometric authentication setup
/// - Security state persistence
/// - Authentication verification
class SecurityService {
  static const String _keyFirstLaunch = 'is_first_launch';
  static const String _keySecurityEnabled = 'is_security_enabled';
  static const String _keyBiometricType = 'biometric_type';
  
  final SharedPreferences _prefs;
  final LocalAuthentication _localAuth;

  SecurityService({
    required SharedPreferences prefs,
    required LocalAuthentication localAuth,
  })  : _prefs = prefs,
        _localAuth = localAuth;

  bool _isCurrentlyAuthenticating = false;
   bool isInternalAuthAction = false; 

  /// Check if this is the first time the app is launched
  Future<bool> isFirstLaunch() async {
    final isFirst = _prefs.getBool(_keyFirstLaunch) ?? true;
    if (isFirst) {
      await _prefs.setBool(_keyFirstLaunch, false);
    }
    return isFirst;
  }

  /// Check if security (PIN/Biometric) is enabled
  bool isSecurityEnabled() {
    return _prefs.getBool(_keySecurityEnabled) ?? false;
  }

  /// Enable security after successful setup
  Future<void> enableSecurity({String? biometricType}) async {
    await _prefs.setBool(_keySecurityEnabled, true);
    if (biometricType != null) {
      await _prefs.setString(_keyBiometricType, biometricType);
    }
  }

  /// Disable security (requires authentication first)
  Future<void> disableSecurity() async {
    await _prefs.setBool(_keySecurityEnabled, false);
    await _prefs.remove(_keyBiometricType);
  }

  /// Get the type of biometric authentication available
  Future<BiometricType> getAvailableBiometric() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        return BiometricType.weak;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      if (availableBiometrics.contains(BiometricType.face)) {
        return BiometricType.face;
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return BiometricType.fingerprint;
      } else if (availableBiometrics.contains(BiometricType.iris)) {
        return BiometricType.iris;
      } else if (availableBiometrics.contains(BiometricType.strong) ||
          availableBiometrics.contains(BiometricType.weak)) {
        return BiometricType.strong;
      }

      return BiometricType.weak;
    } catch (e) {
      return BiometricType.weak;
    }
  }

  /// Get human-readable biometric type name
  Future<String> getBiometricTypeName() async {
    final type = await getAvailableBiometric();
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris Scan';
      case BiometricType.strong:
      case BiometricType.weak:
        return 'Biometric';
    }
  }

  /// Authenticate user with biometric or PIN
  ///
  /// Returns true if authentication is successful
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
  }) async {
      isInternalAuthAction = true;
    // Si une demande est déjà en cours, on ignore la nouvelle immédiatement
    if (_isCurrentlyAuthenticating) {
      debugPrint('Auth déjà en cours, rejet de la nouvelle demande.');
      return false; 
    }

    try {
      _isCurrentlyAuthenticating = true; // On verrouille

      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) return true;

      final result = await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: false
      );
      return result;
    } catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      isInternalAuthAction = false; 
      _isCurrentlyAuthenticating = false; 
    }
  }

  /// Authenticate with device credentials only (PIN/Pattern/Password)
  Future<bool> _authenticateWithDeviceCredentials(String reason) async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
      );

      return authenticated;
    } catch (e) {
      debugPrint('Device credentials authentication error: $e');
      return false;
    }
  }

  /// Setup security for the first time
  ///
  /// This method handles the complete setup flow:
  /// 1. Check available biometric
  /// 2. Authenticate user
  /// 3. Save security state
  Future<SecuritySetupResult> setupSecurity() async {
    try {
      final biometricType = await getAvailableBiometric();
      final biometricName = await getBiometricTypeName();

      final authenticated = await authenticate(
        reason: 'Set up security to protect your account',
        useErrorDialogs: true,
      );

      if (!authenticated) {
        return SecuritySetupResult(
          success: false,
          message: 'Authentication failed',
        );
      }

      await enableSecurity(
        biometricType: biometricType != BiometricType.weak
            ? biometricName
            : null,
      );

      return SecuritySetupResult(
        success: true,
        message: 'Security enabled with $biometricName',
        biometricType: biometricName,
      );
    } catch (e) {
      return SecuritySetupResult(
        success: false,
        message: 'Error setting up security: $e',
      );
    }
  }

  /// Reset first launch flag (for testing purposes)
  Future<void> resetFirstLaunch() async {
    await _prefs.setBool(_keyFirstLaunch, true);
  }
}

/// Result of security setup operation
class SecuritySetupResult {
  final bool success;
  final String message;
  final String? biometricType;

  SecuritySetupResult({
    required this.success,
    required this.message,
    this.biometricType,
  });
}
