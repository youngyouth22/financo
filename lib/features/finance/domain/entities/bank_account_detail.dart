import 'package:equatable/equatable.dart';

/// Entity representing an aggregated bank institution with multiple sub-accounts
class BankAccountDetail extends Equatable {
  final String institutionName;
  final double totalNetWorth;
  final String currency;
  final List<PlaidSubAccount> accounts;
  final List<BankTransaction> transactions;
  final List<double> balanceHistory;

  const BankAccountDetail({
    required this.institutionName,
    required this.totalNetWorth,
    required this.currency,
    required this.accounts,
    required this.transactions,
    required this.balanceHistory,
  });

  @override
  List<Object?> get props => [
    institutionName,
    totalNetWorth,
    currency,
    accounts,
    transactions,
    balanceHistory,
  ];
}

/// Entity representing a single sub-account within a bank institution
class PlaidSubAccount extends Equatable {
  final String accountId;
  final String name;
  final String mask; // e.g., "1234"
  final double balance;
  final bool isDebt;
  final BankAccountType type;
  final BankAccountSubtype subtype;

  const PlaidSubAccount({
    required this.accountId,
    required this.name,
    required this.mask,
    required this.balance,
    required this.isDebt,
    required this.type,
    required this.subtype,
  });

  @override
  List<Object?> get props => [
    accountId,
    name,
    mask,
    balance,
    isDebt,
    type,
    subtype,
  ];
}

/// Bank account types
enum BankAccountType {
  depository, // Checking, Savings
  credit, // Credit Card
  loan, // Mortgage, Student Loan
  investment, // Brokerage
  other,
}

/// Bank account subtypes
enum BankAccountSubtype {
  checking,
  savings,
  moneyMarket,
  cd,
  creditCard,
  paypal,
  other,
}

/// Bank transaction from Plaid
class BankTransaction extends Equatable {
  final String transactionId;
  final String name;
  final String? merchantName;
  final double amount;
  final String category;
  final DateTime date;
  final bool isPending;
  final String? logoUrl;

  const BankTransaction({
    required this.transactionId,
    required this.name,
    this.merchantName,
    required this.amount,
    required this.category,
    required this.date,
    required this.isPending,
    this.logoUrl,
  });

  bool get isDebit => amount > 0;
  bool get isCredit => amount < 0;

  @override
  List<Object?> get props => [
    transactionId,
    name,
    merchantName,
    amount,
    category,
    date,
    isPending,
    logoUrl,
  ];
}
