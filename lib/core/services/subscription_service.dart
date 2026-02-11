import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for managing subscriptions through RevenueCat.
/// RevenueCat is the Single Source of Truth (SSO) for premium status.
class SubscriptionService {
  final String entitlementId = 'premium';

  SubscriptionService();

  /// Stream of CustomerInfo updates from RevenueCat.
  /// Listen to this to react to changes in subscription status in real-time.
  Stream<CustomerInfo> get customerInfoStream {
    final controller = StreamController<CustomerInfo>();
    Purchases.addCustomerInfoUpdateListener((info) {
      // Trigger silent sync on real-time updates
      final premium = info.entitlements.active.containsKey(entitlementId);
      _syncStatusToSupabase(premium);

      if (!controller.isClosed) {
        controller.add(info);
      }
    });
    return controller.stream;
  }

  /// Private method to silently sync premium status to Supabase profiles table.
  /// This ensures backend Edge Functions are aware of the user's plan.
  Future<void> _syncStatusToSupabase(bool isPremium) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final planType = isPremium ? 'premium' : 'free';

      // Silent sync should not block or crash the app
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'plan_type': planType,
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Silent sync to Supabase: $planType');
    } catch (e) {
      debugPrint('Silent sync error: $e');
    }
  }

  /// Get the current customer info from RevenueCat.
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('Error getting customer info: $e');
      return null;
    }
  }

  /// Check if the user has an active premium entitlement.
  /// This relies solely on RevenueCat.
  Future<bool> isPremium({CustomerInfo? info}) async {
    try {
      final customerInfo = info ?? await getCustomerInfo();
      final premium =
          customerInfo?.entitlements.active.containsKey(entitlementId) ?? false;

      // Trigger background sync
      unawaited(_syncStatusToSupabase(premium));

      return premium;
    } catch (e) {
      debugPrint('Error checking premium status: $e');
      return false;
    }
  }

  /// Restores previous purchases for the current user.
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      final premium = await isPremium(info: customerInfo);

      // sync is already triggered in isPremium, but we ensure it here
      unawaited(_syncStatusToSupabase(premium));

      return premium;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }

  /// Purchases a specific package.
  Future<bool> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      final premium = await isPremium(info: result.customerInfo);

      if (premium) {
        unawaited(_syncStatusToSupabase(true));
      }

      return premium;
    } catch (e) {
      debugPrint('Error purchasing package: $e');
      return false;
    }
  }
}
