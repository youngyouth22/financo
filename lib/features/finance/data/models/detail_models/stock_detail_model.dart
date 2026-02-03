import 'package:financo/features/finance/domain/entities/stock_detail.dart';

/// Data model for StockDetail from Supabase Edge Function
class StockDetailModel extends StockDetail {
  const StockDetailModel({
    required super.symbol,
    required super.name,
    required super.currentPrice,
    required super.change24h,
    required super.quantity,
    required super.totalValueUsd,
    required super.marketStats,
    required super.diversification,
    required super.description,
    required super.priceHistory,
  });

  /// Factory constructor from JSON (Edge Function response)
  factory StockDetailModel.fromJson(Map<String, dynamic> json) {
    return StockDetailModel(
      symbol: json['symbol'] as String? ?? '',
      name: json['name'] as String? ?? '',
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
      change24h: (json['change24h'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      totalValueUsd: (json['totalValueUsd'] as num?)?.toDouble() ?? 0.0,
      marketStats: StockMarketStatsModel.fromJson(
        json['marketStats'] as Map<String, dynamic>? ?? {},
      ),
      diversification: StockDiversificationModel.fromJson(
        json['diversification'] as Map<String, dynamic>? ?? {},
      ),
      description: json['description'] as String? ?? 'No description available.',
      priceHistory: (json['priceHistory'] as List?)
              ?.map((p) => (p as num).toDouble())
              .toList() ??
          [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'currentPrice': currentPrice,
      'change24h': change24h,
      'quantity': quantity,
      'totalValueUsd': totalValueUsd,
      'marketStats': (marketStats as StockMarketStatsModel).toJson(),
      'diversification': (diversification as StockDiversificationModel).toJson(),
      'description': description,
      'priceHistory': priceHistory,
    };
  }
}

/// Data model for StockMarketStats
class StockMarketStatsModel extends StockMarketStats {
  const StockMarketStatsModel({
    super.peRatio,
    super.marketCap,
    super.week52High,
    super.week52Low,
    super.volume,
    super.avgVolume,
    super.dividendYield,
    super.eps,
  });

  factory StockMarketStatsModel.fromJson(Map<String, dynamic> json) {
    return StockMarketStatsModel(
      peRatio: (json['peRatio'] as num?)?.toDouble(),
      marketCap: (json['marketCap'] as num?)?.toDouble(),
      week52High: (json['week52High'] as num?)?.toDouble(),
      week52Low: (json['week52Low'] as num?)?.toDouble(),
      volume: (json['volume'] as num?)?.toDouble(),
      avgVolume: (json['avgVolume'] as num?)?.toDouble(),
      dividendYield: (json['dividendYield'] as num?)?.toDouble(),
      eps: (json['eps'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'peRatio': peRatio,
      'marketCap': marketCap,
      'week52High': week52High,
      'week52Low': week52Low,
      'volume': volume,
      'avgVolume': avgVolume,
      'dividendYield': dividendYield,
      'eps': eps,
    };
  }
}

/// Data model for StockDiversification
class StockDiversificationModel extends StockDiversification {
  const StockDiversificationModel({
    required super.sector,
    required super.industry,
    required super.country,
    required super.countryCode,
  });

  factory StockDiversificationModel.fromJson(Map<String, dynamic> json) {
    return StockDiversificationModel(
      sector: json['sector'] as String? ?? 'Other',
      industry: json['industry'] as String? ?? 'Other',
      country: json['country'] as String? ?? 'US',
      countryCode: json['countryCode'] as String? ?? 'US',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sector': sector,
      'industry': industry,
      'country': country,
      'countryCode': countryCode,
    };
  }
}
