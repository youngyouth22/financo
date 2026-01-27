import 'package:equatable/equatable.dart';

/// Entity representing unified networth response with detailed breakdown
class NetworthResponse extends Equatable {
  final TotalValue total;
  final Breakdown breakdown;
  final Performance performance;
  final List<AssetDetail> assets;
  final Insights insights;

  const NetworthResponse({
    required this.total,
    required this.breakdown,
    required this.performance,
    required this.assets,
    required this.insights,
  });

  @override
  List<Object?> get props => [total, breakdown, performance, assets, insights];
}

class TotalValue extends Equatable {
  final double value;
  final String currency;
  final DateTime updatedAt;

  const TotalValue({
    required this.value,
    required this.currency,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [value, currency, updatedAt];
}

class Breakdown extends Equatable {
  final Map<String, double> byType;
  final Map<String, double> byProvider;
  final Map<String, double> byCountry;
  final Map<String, double> bySector;

  const Breakdown({
    required this.byType,
    required this.byProvider,
    required this.byCountry,
    required this.bySector,
  });

  @override
  List<Object?> get props => [byType, byProvider, byCountry, bySector];
}

class Performance extends Equatable {
  final DailyChange dailyChange;
  final TotalPnl totalPnl;

  const Performance({
    required this.dailyChange,
    required this.totalPnl,
  });

  @override
  List<Object?> get props => [dailyChange, totalPnl];
}

class DailyChange extends Equatable {
  final double amount;
  final double percentage;
  final String direction;

  const DailyChange({
    required this.amount,
    required this.percentage,
    required this.direction,
  });

  @override
  List<Object?> get props => [amount, percentage, direction];
}

class TotalPnl extends Equatable {
  final double realizedUsd;
  final double realizedPercent;
  final double estimated24h;

  const TotalPnl({
    required this.realizedUsd,
    required this.realizedPercent,
    required this.estimated24h,
  });

  @override
  List<Object?> get props => [realizedUsd, realizedPercent, estimated24h];
}

class AssetDetail extends Equatable {
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

  const AssetDetail({
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

  @override
  List<Object?> get props => [
        id,
        name,
        symbol,
        type,
        provider,
        value,
        quantity,
        price,
        change24h,
        pnlUsd,
        pnlPercent,
        iconUrl,
        country,
        sector,
        lastUpdated,
      ];
}

class Insights extends Equatable {
  final double diversificationScore;
  final String riskLevel;
  final List<String> concentrationWarnings;
  final String updateStatus;

  const Insights({
    required this.diversificationScore,
    required this.riskLevel,
    required this.concentrationWarnings,
    required this.updateStatus,
  });

  @override
  List<Object?> get props => [
        diversificationScore,
        riskLevel,
        concentrationWarnings,
        updateStatus,
      ];
}
