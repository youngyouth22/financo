import 'package:equatable/equatable.dart';

/// Represents a financial asset (crypto wallet or bank account)
///
/// This entity is part of the domain layer and contains only business logic,
/// with no dependencies on external frameworks or data sources.
class Asset extends Equatable {
  /// Unique identifier for the asset
  final String id;

  /// ID of the user who owns this asset
  final String userId;

  /// Display name of the asset (e.g., 'Ethereum Wallet', 'Chase Checking')
  final String name;

  /// Type of asset: 'crypto' or 'bank'
  final AssetType type;

  /// Asset group for categorization: 'crypto', 'stocks', or 'cash'
  final AssetGroup assetGroup;

  /// Provider of the asset data: 'moralis' or 'plaid'
  final AssetProvider provider;

  /// Current balance in USD
  final double balanceUsd;

  /// Wallet address (for crypto) or account ID (for bank)
  final String assetAddressOrId;

  /// Timestamp of last synchronization with provider
  final DateTime lastSync;

  /// Timestamp when asset was created
  final DateTime createdAt;

  /// Timestamp when asset was last updated
  final DateTime updatedAt;

  const Asset({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.assetGroup,
    required this.provider,
    required this.balanceUsd,
    required this.assetAddressOrId,
    required this.lastSync,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if this asset is a crypto wallet
  bool get isCrypto => type == AssetType.crypto;

  /// Check if this asset is a bank account
  bool get isBank => type == AssetType.bank;

  /// Check if this asset uses Moralis as provider
  bool get usesMoralis => provider == AssetProvider.moralis;

  /// Check if this asset uses Plaid as provider
  bool get usesPlaid => provider == AssetProvider.plaid;

  /// Get formatted balance with currency symbol
  String get formattedBalance => '\$${balanceUsd.toStringAsFixed(2)}';

  /// Check if asset data is stale (not synced in last 24 hours)
  bool get isStale {
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    return difference.inHours > 24;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        type,
        assetGroup,
        provider,
        balanceUsd,
        assetAddressOrId,
        lastSync,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Asset(id: $id, name: $name, type: $type, provider: $provider, balance: $formattedBalance)';
  }
}

/// Enum representing the type of asset
enum AssetType {
  /// Cryptocurrency wallet
  crypto,

  /// Bank account
  bank,
}

/// Enum representing the data provider for the asset
enum AssetProvider {
  /// Moralis provider for crypto assets
  moralis,

  /// Plaid provider for bank accounts
  plaid,
}

/// Enum representing the asset group for dashboard categorization
enum AssetGroup {
  /// Cryptocurrency assets
  crypto,

  /// Stocks and ETFs
  stocks,

  /// Cash and bank accounts
  cash,
}
