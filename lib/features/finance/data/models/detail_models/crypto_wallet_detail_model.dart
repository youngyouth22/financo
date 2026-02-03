import 'package:financo/features/finance/domain/entities/crypto_wallet_detail.dart';

/// Data model for CryptoWalletDetail from Supabase Edge Function
class CryptoWalletDetailModel extends CryptoWalletDetail {
  const CryptoWalletDetailModel({
    required super.walletAddress,
    required super.name,
    required super.totalValueUsd,
    required super.change24h,
    required super.tokens,
    required super.transactions,
    required super.priceHistory,
  });

  /// Factory constructor from JSON (Edge Function response)
  factory CryptoWalletDetailModel.fromJson(Map<String, dynamic> json) {
    return CryptoWalletDetailModel(
      walletAddress: json['walletAddress'] as String? ?? '',
      name: json['name'] as String? ?? 'Main Wallet',
      totalValueUsd: (json['totalValueUsd'] as num?)?.toDouble() ?? 0.0,
      change24h: (json['change24h'] as num?)?.toDouble() ?? 0.0,
      tokens: (json['tokens'] as List?)
              ?.map((t) => CryptoTokenModel.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      transactions: (json['transactions'] as List?)
              ?.map((t) =>
                  CryptoTransactionModel.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      priceHistory: (json['priceHistory'] as List?)
              ?.map((p) => (p as num).toDouble())
              .toList() ??
          [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'walletAddress': walletAddress,
      'name': name,
      'totalValueUsd': totalValueUsd,
      'change24h': change24h,
      'tokens': tokens
          .map((t) => (t as CryptoTokenModel).toJson())
          .toList(),
      'transactions': transactions
          .map((t) => (t as CryptoTransactionModel).toJson())
          .toList(),
      'priceHistory': priceHistory,
    };
  }
}

/// Data model for CryptoToken
class CryptoTokenModel extends CryptoToken {
  const CryptoTokenModel({
    required super.symbol,
    required super.name,
    required super.balance,
    required super.valueUsd,
    required super.priceUsd,
    required super.change24h,
    required super.iconUrl,
  });

  factory CryptoTokenModel.fromJson(Map<String, dynamic> json) {
    return CryptoTokenModel(
      symbol: json['symbol'] as String? ?? '',
      name: json['name'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      valueUsd: (json['valueUsd'] as num?)?.toDouble() ?? 0.0,
      priceUsd: (json['priceUsd'] as num?)?.toDouble() ?? 0.0,
      change24h: (json['change24h'] as num?)?.toDouble() ?? 0.0,
      iconUrl: json['iconUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'balance': balance,
      'valueUsd': valueUsd,
      'priceUsd': priceUsd,
      'change24h': change24h,
      'iconUrl': iconUrl,
    };
  }
}

/// Data model for CryptoTransaction
class CryptoTransactionModel extends CryptoTransaction {
  const CryptoTransactionModel({
    required super.hash,
    required super.type,
    required super.fromAddress,
    required super.toAddress,
    required super.amountUsd,
    required super.tokenSymbol,
    required super.tokenAmount,
    required super.timestamp,
    super.entityName,
    super.entityLogo,
  });

  factory CryptoTransactionModel.fromJson(Map<String, dynamic> json) {
    return CryptoTransactionModel(
      hash: json['hash'] as String? ?? '',
      type: _parseTransactionType(json['type'] as String?),
      fromAddress: json['fromAddress'] as String? ?? '',
      toAddress: json['toAddress'] as String? ?? '',
      amountUsd: (json['amountUsd'] as num?)?.toDouble() ?? 0.0,
      tokenSymbol: json['tokenSymbol'] as String? ?? '',
      tokenAmount: (json['tokenAmount'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      entityName: json['entityName'] as String?,
      entityLogo: json['entityLogo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'type': type.name,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'amountUsd': amountUsd,
      'tokenSymbol': tokenSymbol,
      'tokenAmount': tokenAmount,
      'timestamp': timestamp.toIso8601String(),
      'entityName': entityName,
      'entityLogo': entityLogo,
    };
  }

  static CryptoTransactionType _parseTransactionType(String? type) {
    switch (type?.toLowerCase()) {
      case 'sent':
        return CryptoTransactionType.sent;
      case 'received':
        return CryptoTransactionType.received;
      case 'swap':
        return CryptoTransactionType.swap;
      case 'stake':
        return CryptoTransactionType.stake;
      case 'unstake':
        return CryptoTransactionType.unstake;
      default:
        return CryptoTransactionType.received;
    }
  }
}
