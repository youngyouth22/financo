// features/finance/domain/entities/asset.dart
import 'package:equatable/equatable.dart';

enum AssetType {
  crypto,
  stock,
  cash,
  investment,
  realEstate,
  commodity,
  liability,
  other,
}

enum AssetProvider { moralis, fmp, plaid, manual }

enum AssetStatus { active, inactive, pending }

class Asset extends Equatable {
  final String id;
  final String userId;
  final String name;
  final AssetType type;
  final AssetProvider provider;
  final double balanceUsd;
  final String assetAddressOrId;
  final DateTime lastSync;
  final double realizedPnlUsd;
  final double realizedPnlPercent;
  final String symbol;
  final double quantity;
  final double currentPrice;
  final double change24h;
  final double priceUsd;
  final String iconUrl;
  final String country;
  final String sector;
  final String industry;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AssetStatus status;
  final String currency;
  final double? manualValue;
  final List<double>? sparkline;
  final Map<String, dynamic>? metadata;

  const Asset({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.provider,
    required this.balanceUsd,
    required this.assetAddressOrId,
    required this.lastSync,
    required this.realizedPnlUsd,
    required this.realizedPnlPercent,
    required this.symbol,
    required this.quantity,
    required this.currentPrice,
    required this.change24h,
    required this.priceUsd,
    required this.iconUrl,
    required this.country,
    required this.sector,
    required this.industry,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.currency,
    this.manualValue,
    this.sparkline,
    this.metadata,
  });

  // Helper getters
  bool get isCrypto => type == AssetType.crypto;
  bool get isStock => type == AssetType.stock;
  bool get isCash => type == AssetType.cash;
  bool get isActive => status == AssetStatus.active;

  double get dailyChangeAmount => balanceUsd * (change24h / 100);
  bool get isPositiveChange => change24h > 0;
  bool get isNegativeChange => change24h < 0;

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    type,
    provider,
    balanceUsd,
    assetAddressOrId,
    lastSync,
    realizedPnlUsd,
    realizedPnlPercent,
    symbol,
    quantity,
    currentPrice,
    change24h,
    priceUsd,
    iconUrl,
    country,
    sector,
    industry,
    createdAt,
    updatedAt,
    status,
    currency,
    manualValue,
    sparkline,
    metadata,
  ];

  Asset copyWith({
    String? id,
    String? userId,
    String? name,
    AssetType? type,
    AssetProvider? provider,
    double? balanceUsd,
    String? assetAddressOrId,
    DateTime? lastSync,
    double? realizedPnlUsd,
    double? realizedPnlPercent,
    String? symbol,
    double? quantity,
    double? currentPrice,
    double? change24h,
    double? priceUsd,
    String? iconUrl,
    String? country,
    String? sector,
    String? industry,
    DateTime? createdAt,
    DateTime? updatedAt,
    AssetStatus? status,
    String? currency,
    double? manualValue,
    List<double>? sparkline,
    Map<String, dynamic>? metadata,
  }) {
    return Asset(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      provider: provider ?? this.provider,
      balanceUsd: balanceUsd ?? this.balanceUsd,
      assetAddressOrId: assetAddressOrId ?? this.assetAddressOrId,
      lastSync: lastSync ?? this.lastSync,
      realizedPnlUsd: realizedPnlUsd ?? this.realizedPnlUsd,
      realizedPnlPercent: realizedPnlPercent ?? this.realizedPnlPercent,
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      currentPrice: currentPrice ?? this.currentPrice,
      change24h: change24h ?? this.change24h,
      priceUsd: priceUsd ?? this.priceUsd,
      iconUrl: iconUrl ?? this.iconUrl,
      country: country ?? this.country,
      sector: sector ?? this.sector,
      industry: industry ?? this.industry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      currency: currency ?? this.currency,
      manualValue: manualValue ?? this.manualValue,
      sparkline: sparkline ?? this.sparkline,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'Asset{id: $id, name: $name, type: $type, provider: $provider, balance: \$$balanceUsd, symbol: $symbol}';
  }
}
