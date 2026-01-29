
import 'package:financo/features/finance/domain/entities/networth_response.dart' as entity;

class NetworthResponseModel {
  final TotalValue total;
  final Breakdown breakdown;
  final Performance performance;
  final List<AssetDetail> assets;
  final Insights insights;

  NetworthResponseModel({
    required this.total,
    required this.breakdown,
    required this.performance,
    required this.assets,
    required this.insights,
  });

  factory NetworthResponseModel.fromJson(Map<String, dynamic> json) {
    return NetworthResponseModel(
      total: TotalValue.fromJson(json['total']),
      breakdown: Breakdown.fromJson(json['breakdown']),
      performance: Performance.fromJson(json['performance']),
      assets: List<AssetDetail>.from(
          json['assets'].map((x) => AssetDetail.fromJson(x))),
      insights: Insights.fromJson(json['insights']),
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total.toJson(),
        'breakdown': breakdown.toJson(),
        'performance': performance.toJson(),
        'assets': List<dynamic>.from(assets.map((x) => x.toJson())),
        'insights': insights.toJson(),
      };

  /// Convert model to domain entity
  entity.NetworthResponse toEntity() {
    return entity.NetworthResponse(
      total: entity.TotalValue(
        value: total.value,
        currency: total.currency,
        updatedAt: total.updatedAt,
      ),
      breakdown: entity.Breakdown(
        byType: breakdown.byType,
        byProvider: breakdown.byProvider,
        byCountry: breakdown.byCountry,
        bySector: breakdown.bySector,
      ),
      performance: entity.Performance(
        dailyChange: entity.DailyChange(
          amount: performance.dailyChange.amount,
          percentage: performance.dailyChange.percentage,
          direction: performance.dailyChange.direction,
        ),
        totalPnl: entity.TotalPnl(
          realizedUsd: performance.totalPnl.realizedUsd,
          realizedPercent: performance.totalPnl.realizedPercent,
          estimated24h: performance.totalPnl.estimated24h,
        ),
      ),
      assets: assets.map((asset) => entity.AssetDetail(
        id: asset.id,
        name: asset.name,
        symbol: asset.symbol,
        type: asset.type,
        provider: asset.provider,
        value: asset.value,
        quantity: asset.quantity,
        price: asset.price,
        change24h: asset.change24h,
        pnlUsd: asset.pnlUsd,
        pnlPercent: asset.pnlPercent,
        iconUrl: asset.iconUrl,
        country: asset.country,
        sector: asset.sector,
        lastUpdated: asset.lastUpdated,
      )).toList(),
      insights: entity.Insights(
        diversificationScore: insights.diversificationScore,
        riskLevel: insights.riskLevel,
        concentrationWarnings: insights.concentrationWarnings,
        updateStatus: insights.updateStatus,
      ),
    );
  }
}

class TotalValue {
  final double value;
  final String currency;
  final DateTime updatedAt;

  TotalValue({
    required this.value,
    required this.currency,
    required this.updatedAt,
  });

  factory TotalValue.fromJson(Map<String, dynamic> json) => TotalValue(
        value: (json['value'] as num).toDouble(),
        currency: json['currency'],
        updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'value': value,
        'currency': currency,
        'updated_at': updatedAt.toIso8601String(),
      };
}

class Breakdown {
  final Map<String, double> byType;
  final Map<String, double> byProvider;
  final Map<String, double> byCountry;
  final Map<String, double> bySector;

  Breakdown({
    required this.byType,
    required this.byProvider,
    required this.byCountry,
    required this.bySector,
  });

  factory Breakdown.fromJson(Map<String, dynamic> json) {
    Map<String, double> parseMap(dynamic mapData) {
      if (mapData == null) return {};
      return (mapData as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    }

    return Breakdown(
      byType: parseMap(json['by_type']),
      byProvider: parseMap(json['by_provider']),
      byCountry: parseMap(json['by_country']),
      bySector: parseMap(json['by_sector']),
    );
  }

  Map<String, dynamic> toJson() => {
        'by_type': byType,
        'by_provider': byProvider,
        'by_country': byCountry,
        'by_sector': bySector,
      };
}

class Performance {
  final DailyChange dailyChange;
  final TotalPnl totalPnl;

  Performance({
    required this.dailyChange,
    required this.totalPnl,
  });

  factory Performance.fromJson(Map<String, dynamic> json) => Performance(
        dailyChange: DailyChange.fromJson(json['daily_change']),
        totalPnl: TotalPnl.fromJson(json['total_pnl']),
      );

  Map<String, dynamic> toJson() => {
        'daily_change': dailyChange.toJson(),
        'total_pnl': totalPnl.toJson(),
      };
}

class DailyChange {
  final double amount;
  final double percentage;
  final String direction;

  DailyChange({
    required this.amount,
    required this.percentage,
    required this.direction,
  });

  factory DailyChange.fromJson(Map<String, dynamic> json) => DailyChange(
        amount: (json['amount'] as num).toDouble(),
        percentage: (json['percentage'] as num).toDouble(),
        direction: json['direction'],
      );

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'percentage': percentage,
        'direction': direction,
      };
}

class TotalPnl {
  final double realizedUsd;
  final double realizedPercent;
  final double estimated24h;

  TotalPnl({
    required this.realizedUsd,
    required this.realizedPercent,
    required this.estimated24h,
  });

  factory TotalPnl.fromJson(Map<String, dynamic> json) => TotalPnl(
        realizedUsd: (json['realized_usd'] as num).toDouble(),
        realizedPercent: (json['realized_percent'] as num).toDouble(),
        estimated24h: (json['estimated_24h'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'realized_usd': realizedUsd,
        'realized_percent': realizedPercent,
        'estimated_24h': estimated24h,
      };
}

class AssetDetail {
  final String id;
  final String name;
  final String symbol;
  final String type;
  final String provider;
  final double value;
  final double quantity;
  final double price;
  final double change24h;
  final double pnlUsd;
  final double pnlPercent;
  final String iconUrl;
  final String country;
  final String sector;
  final DateTime lastUpdated;

  AssetDetail({
    required this.id,
    required this.name,
    required this.symbol,
    required this.type,
    required this.provider,
    required this.value,
    required this.quantity,
    required this.price,
    required this.change24h,
    required this.pnlUsd,
    required this.pnlPercent,
    required this.iconUrl,
    required this.country,
    required this.sector,
    required this.lastUpdated,
  });

  factory AssetDetail.fromJson(Map<String, dynamic> json) => AssetDetail(
        id: json['id'],
        name: json['name'],
        symbol: json['symbol'],
        type: json['type'],
        provider: json['provider'],
        value: (json['value'] as num).toDouble(),
        quantity: (json['quantity'] as num).toDouble(),
        price: (json['price'] as num).toDouble(),
        change24h: (json['change_24h'] as num).toDouble(),
        pnlUsd: (json['pnl_usd'] as num).toDouble(),
        pnlPercent: (json['pnl_percent'] as num).toDouble(),
        iconUrl: json['icon_url'] ?? '',
        country: json['country'] ?? '',
        sector: json['sector'] ?? '',
        lastUpdated: DateTime.parse(json['last_updated']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'symbol': symbol,
        'type': type,
        'provider': provider,
        'value': value,
        'quantity': quantity,
        'price': price,
        'change_24h': change24h,
        'pnl_usd': pnlUsd,
        'pnl_percent': pnlPercent,
        'icon_url': iconUrl,
        'country': country,
        'sector': sector,
        'last_updated': lastUpdated.toIso8601String(),
      };
}

class Insights {
  final double diversificationScore;
  final String riskLevel;
  final List<String> concentrationWarnings;
  final String updateStatus;

  Insights({
    required this.diversificationScore,
    required this.riskLevel,
    required this.concentrationWarnings,
    required this.updateStatus,
  });

  factory Insights.fromJson(Map<String, dynamic> json) => Insights(
        diversificationScore: (json['diversification_score'] as num).toDouble(),
        riskLevel: json['risk_level'],
        concentrationWarnings: List<String>.from(json['concentration_warnings']),
        updateStatus: json['update_status'],
      );

  Map<String, dynamic> toJson() => {
        'diversification_score': diversificationScore,
        'risk_level': riskLevel,
        'concentration_warnings': concentrationWarnings,
        'update_status': updateStatus,
      };
}