import 'package:financo/features/finance/domain/entities/bank_account_detail.dart';

/// Data model for BankAccountDetail from Supabase Edge Function
class BankAccountDetailModel extends BankAccountDetail {
  const BankAccountDetailModel({
    required super.accountId,
    required super.name,
    required super.institutionName,
    required super.accountMask,
    required super.accountType,
    required super.accountSubtype,
    required super.currentBalance,
    required super.availableBalance,
    super.creditLimit,
    required super.currency,
    required super.transactions,
    required super.balanceHistory,
  });

  /// Factory constructor from JSON (Edge Function response)
  factory BankAccountDetailModel.fromJson(Map<String, dynamic> json) {
    return BankAccountDetailModel(
      accountId: json['accountId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      institutionName: json['institutionName'] as String? ?? '',
      accountMask: json['accountMask'] as String? ?? '**** 0000',
      accountType: _parseAccountType(json['accountType'] as String?),
      accountSubtype: _parseAccountSubtype(json['accountSubtype'] as String?),
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0.0,
      availableBalance: (json['availableBalance'] as num?)?.toDouble() ?? 0.0,
      creditLimit: (json['creditLimit'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      transactions: (json['transactions'] as List?)
              ?.map((t) =>
                  BankTransactionModel.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      balanceHistory: (json['balanceHistory'] as List?)
              ?.map((b) => (b as num).toDouble())
              .toList() ??
          [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'name': name,
      'institutionName': institutionName,
      'accountMask': accountMask,
      'accountType': accountType.name,
      'accountSubtype': accountSubtype.name,
      'currentBalance': currentBalance,
      'availableBalance': availableBalance,
      'creditLimit': creditLimit,
      'currency': currency,
      'transactions': transactions
          .map((t) => (t as BankTransactionModel).toJson())
          .toList(),
      'balanceHistory': balanceHistory,
    };
  }

  static BankAccountType _parseAccountType(String? type) {
    switch (type?.toLowerCase()) {
      case 'depository':
        return BankAccountType.depository;
      case 'credit':
        return BankAccountType.credit;
      case 'loan':
        return BankAccountType.loan;
      case 'investment':
        return BankAccountType.investment;
      default:
        return BankAccountType.other;
    }
  }

  static BankAccountSubtype _parseAccountSubtype(String? subtype) {
    switch (subtype?.toLowerCase()) {
      case 'checking':
        return BankAccountSubtype.checking;
      case 'savings':
        return BankAccountSubtype.savings;
      case 'money market':
      case 'money_market':
        return BankAccountSubtype.moneyMarket;
      case 'cd':
        return BankAccountSubtype.cd;
      case 'credit card':
      case 'credit_card':
        return BankAccountSubtype.creditCard;
      case 'paypal':
        return BankAccountSubtype.paypal;
      default:
        return BankAccountSubtype.other;
    }
  }
}

/// Data model for BankTransaction
class BankTransactionModel extends BankTransaction {
  const BankTransactionModel({
    required super.transactionId,
    required super.name,
    super.merchantName,
    required super.amount,
    required super.category,
    required super.date,
    required super.isPending,
    super.logoUrl,
  });

  factory BankTransactionModel.fromJson(Map<String, dynamic> json) {
    return BankTransactionModel(
      transactionId: json['transactionId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      merchantName: json['merchantName'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'General',
      date: DateTime.parse(json['date'] as String? ?? DateTime.now().toIso8601String()),
      isPending: json['isPending'] as bool? ?? false,
      logoUrl: json['logoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'name': name,
      'merchantName': merchantName,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'isPending': isPending,
      'logoUrl': logoUrl,
    };
  }
}
