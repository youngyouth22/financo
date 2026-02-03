import 'package:equatable/equatable.dart';

/// Entity representing detailed bank account information from Plaid
class BankAccountDetail extends Equatable {
  final String accountId;
  final String name;
  final String institutionName;
  final String accountMask; // e.g., "**** 4242"
  final BankAccountType accountType;
  final BankAccountSubtype accountSubtype;
  final double currentBalance;
  final double availableBalance;
  final double? creditLimit; // Only for credit cards
  final String currency;
  final List<BankTransaction> transactions;
  final List<double> balanceHistory;

  const BankAccountDetail({
    required this.accountId,
    required this.name,
    required this.institutionName,
    required this.accountMask,
    required this.accountType,
    required this.accountSubtype,
    required this.currentBalance,
    required this.availableBalance,
    this.creditLimit,
    required this.currency,
    required this.transactions,
    required this.balanceHistory,
  });

  bool get isCreditCard => accountType == BankAccountType.credit;
  
  double get creditUsed => isCreditCard && creditLimit != null 
      ? creditLimit! - availableBalance 
      : 0;

  @override
  List<Object?> get props => [
        accountId,
        name,
        institutionName,
        accountMask,
        accountType,
        accountSubtype,
        currentBalance,
        availableBalance,
        creditLimit,
        currency,
        transactions,
        balanceHistory,
      ];
}

/// Bank account types
enum BankAccountType {
  depository, // Checking, Savings
  credit,     // Credit Card
  loan,       // Mortgage, Student Loan
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
