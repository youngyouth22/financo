import 'package:financo/features/finance/domain/entities/asset.dart';

/// Data model for Asset entity
///
/// This model handles serialization/deserialization from Supabase
/// and mapping to/from domain entities.
class AssetModel extends Asset {
  const AssetModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.type,
    required super.assetGroup,
    required super.provider,
    required super.balanceUsd,
    required super.assetAddressOrId,
    required super.lastSync,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create AssetModel from JSON (Supabase response)
  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: _parseAssetType(json['type'] as String),
      assetGroup: _parseAssetGroup(json['asset_group'] as String),
      provider: _parseAssetProvider(json['provider'] as String),
      balanceUsd: _parseDecimal(json['balance_usd']),
      assetAddressOrId: json['asset_address_or_id'] as String,
      lastSync: DateTime.parse(json['last_sync'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert AssetModel to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': _assetTypeToString(type),
      'asset_group': _assetGroupToString(assetGroup),
      'provider': _assetProviderToString(provider),
      'balance_usd': balanceUsd,
      'asset_address_or_id': assetAddressOrId,
      'last_sync': lastSync.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create AssetModel from domain entity
  factory AssetModel.fromEntity(Asset entity) {
    return AssetModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      type: entity.type,
      assetGroup: entity.assetGroup,
      provider: entity.provider,
      balanceUsd: entity.balanceUsd,
      assetAddressOrId: entity.assetAddressOrId,
      lastSync: entity.lastSync,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert AssetModel to domain entity
  Asset toEntity() {
    return Asset(
      id: id,
      userId: userId,
      name: name,
      type: type,
      assetGroup: assetGroup,
      provider: provider,
      balanceUsd: balanceUsd,
      assetAddressOrId: assetAddressOrId,
      lastSync: lastSync,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Parse asset type from string
  static AssetType _parseAssetType(String type) {
    switch (type.toLowerCase()) {
      case 'crypto':
        return AssetType.crypto;
      case 'bank':
        return AssetType.bank;
      default:
        throw ArgumentError('Unknown asset type: $type');
    }
  }

  /// Parse asset provider from string
  static AssetProvider _parseAssetProvider(String provider) {
    switch (provider.toLowerCase()) {
      case 'moralis':
        return AssetProvider.moralis;
      case 'plaid':
        return AssetProvider.plaid;
      default:
        throw ArgumentError('Unknown asset provider: $provider');
    }
  }

  /// Convert asset type to string
  static String _assetTypeToString(AssetType type) {
    switch (type) {
      case AssetType.crypto:
        return 'crypto';
      case AssetType.bank:
        return 'bank';
    }
  }

  /// Convert asset provider to string
  static String _assetProviderToString(AssetProvider provider) {
    switch (provider) {
      case AssetProvider.moralis:
        return 'moralis';
      case AssetProvider.plaid:
        return 'plaid';
    }
  }

  /// Parse asset group from string
  static AssetGroup _parseAssetGroup(String group) {
    switch (group.toLowerCase()) {
      case 'crypto':
        return AssetGroup.crypto;
      case 'stocks':
        return AssetGroup.stocks;
      case 'cash':
        return AssetGroup.cash;
      default:
        throw ArgumentError('Unknown asset group: $group');
    }
  }

  /// Convert asset group to string
  static String _assetGroupToString(AssetGroup group) {
    switch (group) {
      case AssetGroup.crypto:
        return 'crypto';
      case AssetGroup.stocks:
        return 'stocks';
      case AssetGroup.cash:
        return 'cash';
    }
  }

  /// Parse decimal value from various formats
  static double _parseDecimal(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    throw ArgumentError('Cannot parse decimal from: $value');
  }
}
