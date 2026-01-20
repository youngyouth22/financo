import 'package:equatable/equatable.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';

/// Represents the user's complete financial portfolio
///
/// Aggregates all assets and provides calculated metrics like net worth,
/// asset distribution, and performance indicators.
class GlobalWealth extends Equatable {
  /// List of all user assets
  final List<Asset> assets;

  /// Timestamp when this wealth data was last updated
  final DateTime lastUpdated;

  const GlobalWealth({
    required this.assets,
    required this.lastUpdated,
  });

  /// Calculate total net worth across all assets
  double get netWorth {
    return assets.fold(0.0, (sum, asset) => sum + asset.balanceUsd);
  }

  /// Get formatted net worth with currency symbol
  String get formattedNetWorth => '\$${netWorth.toStringAsFixed(2)}';

  /// Get all crypto assets
  List<Asset> get cryptoAssets {
    return assets.where((asset) => asset.isCrypto).toList();
  }

  /// Get all bank assets
  List<Asset> get bankAssets {
    return assets.where((asset) => asset.isBank).toList();
  }

  /// Calculate total crypto balance
  double get totalCryptoBalance {
    return cryptoAssets.fold(0.0, (sum, asset) => sum + asset.balanceUsd);
  }

  /// Calculate total bank balance
  double get totalBankBalance {
    return bankAssets.fold(0.0, (sum, asset) => sum + asset.balanceUsd);
  }

  /// Get formatted crypto balance
  String get formattedCryptoBalance =>
      '\$${totalCryptoBalance.toStringAsFixed(2)}';

  /// Get formatted bank balance
  String get formattedBankBalance => '\$${totalBankBalance.toStringAsFixed(2)}';

  /// Calculate percentage of wealth in crypto
  double get cryptoPercentage {
    if (netWorth == 0) return 0.0;
    return (totalCryptoBalance / netWorth) * 100;
  }

  /// Calculate percentage of wealth in bank accounts
  double get bankPercentage {
    if (netWorth == 0) return 0.0;
    return (totalBankBalance / netWorth) * 100;
  }

  /// Get number of crypto assets
  int get cryptoAssetCount => cryptoAssets.length;

  /// Get number of bank assets
  int get bankAssetCount => bankAssets.length;

  /// Get total number of assets
  int get totalAssetCount => assets.length;

  /// Check if user has any assets
  bool get hasAssets => assets.isNotEmpty;

  /// Check if user has crypto assets
  bool get hasCryptoAssets => cryptoAssets.isNotEmpty;

  /// Check if user has bank assets
  bool get hasBankAssets => bankAssets.isNotEmpty;

  /// Check if any asset data is stale
  bool get hasStaleData {
    return assets.any((asset) => asset.isStale);
  }

  /// Get the most recently updated asset
  Asset? get mostRecentAsset {
    if (assets.isEmpty) return null;
    return assets.reduce(
      (current, next) =>
          next.lastSync.isAfter(current.lastSync) ? next : current,
    );
  }

  /// Get the least recently updated asset
  Asset? get leastRecentAsset {
    if (assets.isEmpty) return null;
    return assets.reduce(
      (current, next) =>
          next.lastSync.isBefore(current.lastSync) ? next : current,
    );
  }

  /// Create an empty GlobalWealth instance
  factory GlobalWealth.empty() {
    return GlobalWealth(
      assets: const [],
      lastUpdated: DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  GlobalWealth copyWith({
    List<Asset>? assets,
    DateTime? lastUpdated,
  }) {
    return GlobalWealth(
      assets: assets ?? this.assets,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [assets, lastUpdated];

  @override
  String toString() {
    return 'GlobalWealth(netWorth: $formattedNetWorth, assetCount: $totalAssetCount, lastUpdated: $lastUpdated)';
  }
}
