// features/finance/data/models/asset_model.dart
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
    required super.provider,
    required super.balanceUsd,
    required super.assetAddressOrId,
    required super.lastSync,
    required super.realizedPnlUsd,
    required super.realizedPnlPercent,
    required super.symbol,
    required super.quantity,
    required super.currentPrice,
    required super.change24h,
    required super.priceUsd,
    required super.iconUrl,
    required super.country,
    required super.sector,
    required super.industry,
    required super.createdAt,
    required super.updatedAt,
    required super.status,
    required super.currency,
    super.manualValue,
    super.metadata,
  });

  /// Create AssetModel from JSON (Supabase response)
  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: _parseAssetType(json['type'] as String?),
      provider: _parseAssetProvider(json['provider'] as String?),
      balanceUsd: _parseDecimal(json['balance_usd']),
      assetAddressOrId: json['asset_address_or_id'] as String? ?? '',
      lastSync: _parseDateTime(json['last_sync']),
      realizedPnlUsd: _parseDecimal(json['realized_pnl_usd']),
      realizedPnlPercent: _parseDecimal(json['realized_pnl_percent']),
      symbol: json['symbol'] as String? ?? '',
      quantity: _parseDecimal(json['quantity']),
      currentPrice: _parseDecimal(json['current_price']),
      change24h: _parseDecimal(json['change_24h']),
      priceUsd: _parseDecimal(json['price_usd']),
      iconUrl: json['icon_url'] as String? ?? '',
      country: json['country'] as String? ?? '',
      sector: json['sector'] as String? ?? '',
      industry: json['industry'] as String? ?? '',
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      status: _parseAssetStatus(json['status'] as String?),
      currency: json['currency'] as String? ?? 'USD',
      manualValue: json['balance_usd_manual'] != null 
          ? _parseDecimal(json['balance_usd_manual'])
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  /// Convert AssetModel to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': _assetTypeToString(type),
      'provider': _assetProviderToString(provider),
      'balance_usd': balanceUsd,
      'asset_address_or_id': assetAddressOrId,
      'last_sync': lastSync.toIso8601String(),
      'realized_pnl_usd': realizedPnlUsd,
      'realized_pnl_percent': realizedPnlPercent,
      'symbol': symbol,
      'quantity': quantity,
      'current_price': currentPrice,
      'change_24h': change24h,
      'price_usd': priceUsd,
      'icon_url': iconUrl,
      'country': country,
      'sector': sector,
      'industry': industry,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': _assetStatusToString(status),
      'currency': currency,
      if (manualValue != null) 'balance_usd_manual': manualValue,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Create AssetModel from domain entity
  factory AssetModel.fromEntity(Asset entity) {
    return AssetModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      type: entity.type,
      provider: entity.provider,
      balanceUsd: entity.balanceUsd,
      assetAddressOrId: entity.assetAddressOrId,
      lastSync: entity.lastSync,
      realizedPnlUsd: entity.realizedPnlUsd,
      realizedPnlPercent: entity.realizedPnlPercent,
      symbol: entity.symbol,
      quantity: entity.quantity,
      currentPrice: entity.currentPrice,
      change24h: entity.change24h,
      priceUsd: entity.priceUsd,
      iconUrl: entity.iconUrl,
      country: entity.country,
      sector: entity.sector,
      industry: entity.industry,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      status: entity.status,
      currency: entity.currency,
      manualValue: entity.manualValue,
      metadata: entity.metadata,
    );
  }

  /// Convert AssetModel to domain entity
  Asset toEntity() {
    return Asset(
      id: id,
      userId: userId,
      name: name,
      type: type,
      provider: provider,
      balanceUsd: balanceUsd,
      assetAddressOrId: assetAddressOrId,
      lastSync: lastSync,
      realizedPnlUsd: realizedPnlUsd,
      realizedPnlPercent: realizedPnlPercent,
      symbol: symbol,
      quantity: quantity,
      currentPrice: currentPrice,
      change24h: change24h,
      priceUsd: priceUsd,
      iconUrl: iconUrl,
      country: country,
      sector: sector,
      industry: industry,
      createdAt: createdAt,
      updatedAt: updatedAt,
      status: status,
      currency: currency,
      manualValue: manualValue,
      metadata: metadata,
    );
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Parse asset type from string
  static AssetType _parseAssetType(String? type) {
    switch (type?.toLowerCase()) {
      case 'crypto':
        return AssetType.crypto;
      case 'stock':
        return AssetType.stock;
      case 'cash':
        return AssetType.cash;
      case 'investment':
        return AssetType.investment;
      case 'real_estate':
        return AssetType.realEstate;
      case 'commodity':
        return AssetType.commodity;
      case 'liability':
        return AssetType.liability;
      case 'other':
        return AssetType.other;
      default:
        return AssetType.other;
    }
  }

  /// Parse asset provider from string
  static AssetProvider _parseAssetProvider(String? provider) {
    switch (provider?.toLowerCase()) {
      case 'moralis':
        return AssetProvider.moralis;
      case 'fmp':
        return AssetProvider.fmp;
      case 'plaid':
        return AssetProvider.plaid;
      case 'manual':
        return AssetProvider.manual;
      default:
        return AssetProvider.manual;
    }
  }

  /// Parse asset status from string
  static AssetStatus _parseAssetStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return AssetStatus.active;
      case 'inactive':
        return AssetStatus.inactive;
      case 'pending':
        return AssetStatus.pending;
      default:
        return AssetStatus.active;
    }
  }

  /// Convert asset type to string
  static String _assetTypeToString(AssetType type) {
    switch (type) {
      case AssetType.crypto:
        return 'crypto';
      case AssetType.stock:
        return 'stock';
      case AssetType.cash:
        return 'cash';
      case AssetType.investment:
        return 'investment';
      case AssetType.realEstate:
        return 'real_estate';
      case AssetType.commodity:
        return 'commodity';
      case AssetType.liability:
        return 'liability';
      case AssetType.other:
        return 'other';
    }
  }

  /// Convert asset provider to string
  static String _assetProviderToString(AssetProvider provider) {
    switch (provider) {
      case AssetProvider.moralis:
        return 'moralis';
      case AssetProvider.fmp:
        return 'fmp';
      case AssetProvider.plaid:
        return 'plaid';
      case AssetProvider.manual:
        return 'manual';
    }
  }

  /// Convert asset status to string
  static String _assetStatusToString(AssetStatus status) {
    switch (status) {
      case AssetStatus.active:
        return 'active';
      case AssetStatus.inactive:
        return 'inactive';
      case AssetStatus.pending:
        return 'pending';
    }
  }

  /// Parse decimal value from various formats
  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }

  /// Parse datetime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}