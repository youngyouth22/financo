import 'package:equatable/equatable.dart';

/// Entity representing detailed crypto wallet information
class CryptoWalletDetail extends Equatable {
  final String walletAddress;
  final String name;
  final double totalValueUsd;
  final double change24h;
  final List<CryptoToken> tokens;
  final List<CryptoTransaction> transactions;
  final List<double> priceHistory;

  const CryptoWalletDetail({
    required this.walletAddress,
    required this.name,
    required this.totalValueUsd,
    required this.change24h,
    required this.tokens,
    required this.transactions,
    required this.priceHistory,
  });

  @override
  List<Object?> get props => [
        walletAddress,
        name,
        totalValueUsd,
        change24h,
        tokens,
        transactions,
        priceHistory,
      ];
}

/// Individual token in a crypto wallet
class CryptoToken extends Equatable {
  final String symbol;
  final String name;
  final double balance;
  final double valueUsd;
  final double priceUsd;
  final double change24h;
  final String iconUrl;

  const CryptoToken({
    required this.symbol,
    required this.name,
    required this.balance,
    required this.valueUsd,
    required this.priceUsd,
    required this.change24h,
    required this.iconUrl,
  });

  @override
  List<Object?> get props => [
        symbol,
        name,
        balance,
        valueUsd,
        priceUsd,
        change24h,
        iconUrl,
      ];
}

/// Crypto transaction activity
class CryptoTransaction extends Equatable {
  final String hash;
  final CryptoTransactionType type;
  final String fromAddress;
  final String toAddress;
  final double amountUsd;
  final String tokenSymbol;
  final double tokenAmount;
  final DateTime timestamp;
  final String? entityName; // e.g., "Binance", "Uniswap"
  final String? entityLogo;

  const CryptoTransaction({
    required this.hash,
    required this.type,
    required this.fromAddress,
    required this.toAddress,
    required this.amountUsd,
    required this.tokenSymbol,
    required this.tokenAmount,
    required this.timestamp,
    this.entityName,
    this.entityLogo,
  });

  @override
  List<Object?> get props => [
        hash,
        type,
        fromAddress,
        toAddress,
        amountUsd,
        tokenSymbol,
        tokenAmount,
        timestamp,
        entityName,
        entityLogo,
      ];
}

enum CryptoTransactionType {
  sent,
  received,
  swap,
  stake,
  unstake,
}
