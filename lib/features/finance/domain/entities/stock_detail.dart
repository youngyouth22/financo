import 'package:equatable/equatable.dart';

/// Entity representing detailed stock information
class StockDetail extends Equatable {
  final String symbol;
  final String name;
  final double currentPrice;
  final double change24h;
  final double quantity;
  final double totalValueUsd;
  final StockMarketStats marketStats;
  final StockDiversification diversification;
  final String description;
  final List<double> priceHistory;

  const StockDetail({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.change24h,
    required this.quantity,
    required this.totalValueUsd,
    required this.marketStats,
    required this.diversification,
    required this.description,
    required this.priceHistory,
  });

  @override
  List<Object?> get props => [
        symbol,
        name,
        currentPrice,
        change24h,
        quantity,
        totalValueUsd,
        marketStats,
        diversification,
        description,
        priceHistory,
      ];
}

/// Market statistics for a stock
class StockMarketStats extends Equatable {
  final double? peRatio;
  final double? marketCap;
  final double? week52High;
  final double? week52Low;
  final double? volume;
  final double? avgVolume;
  final double? dividendYield;
  final double? eps;

  const StockMarketStats({
    this.peRatio,
    this.marketCap,
    this.week52High,
    this.week52Low,
    this.volume,
    this.avgVolume,
    this.dividendYield,
    this.eps,
  });

  @override
  List<Object?> get props => [
        peRatio,
        marketCap,
        week52High,
        week52Low,
        volume,
        avgVolume,
        dividendYield,
        eps,
      ];
}

/// Diversification information for a stock
class StockDiversification extends Equatable {
  final String sector;
  final String industry;
  final String country;
  final String countryCode; // ISO 2-letter code for flag

  const StockDiversification({
    required this.sector,
    required this.industry,
    required this.country,
    required this.countryCode,
  });

  @override
  List<Object?> get props => [sector, industry, country, countryCode];
}
