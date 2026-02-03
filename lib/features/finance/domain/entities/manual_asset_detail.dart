import 'package:equatable/equatable.dart';
import 'package:rrule/rrule.dart';

/// Entity representing detailed manual asset information
class ManualAssetDetail extends Equatable {
  final String assetId;
  final String name;
  final ManualAssetCategory category;
  final double currentValue;
  final double purchasePrice;
  final DateTime purchaseDate;
  final String currency;
  final ManualAssetMetadata metadata;
  final List<AmortizationPayment>? amortizationSchedule;
  final String? rruleString; // Recurrence rule for reminders
  final List<double> valueHistory;

  const ManualAssetDetail({
    required this.assetId,
    required this.name,
    required this.category,
    required this.currentValue,
    required this.purchasePrice,
    required this.purchaseDate,
    required this.currency,
    required this.metadata,
    this.amortizationSchedule,
    this.rruleString,
    required this.valueHistory,
  });

  double get totalGain => currentValue - purchasePrice;
  double get totalGainPercent => 
      purchasePrice > 0 ? ((currentValue - purchasePrice) / purchasePrice) * 100 : 0;

  @override
  List<Object?> get props => [
        assetId,
        name,
        category,
        currentValue,
        purchasePrice,
        purchaseDate,
        currency,
        metadata,
        amortizationSchedule,
        rruleString,
        valueHistory,
      ];
}

/// Categories for manual assets
enum ManualAssetCategory {
  realEstate,
  privateEquity,
  commodity,
  collectible,
  loan,
  other,
}

/// Metadata specific to different manual asset types
class ManualAssetMetadata extends Equatable {
  // Real Estate
  final String? propertyAddress;
  final String? propertyType;
  final double? propertySize;

  // Loan
  final double? loanAmount;
  final double? interestRate;
  final DateTime? loanStartDate;
  final DateTime? loanEndDate;

  // Commodity
  final String? commodityType;
  final double? purity; // e.g., 99.9% for gold
  final String? unit; // e.g., "oz", "kg"

  // Private Equity
  final String? companyName;
  final double? equityPercentage;

  // Collectible
  final String? collectibleType;
  final String? condition;
  final String? certification;

  const ManualAssetMetadata({
    this.propertyAddress,
    this.propertyType,
    this.propertySize,
    this.loanAmount,
    this.interestRate,
    this.loanStartDate,
    this.loanEndDate,
    this.commodityType,
    this.purity,
    this.unit,
    this.companyName,
    this.equityPercentage,
    this.collectibleType,
    this.condition,
    this.certification,
  });

  @override
  List<Object?> get props => [
        propertyAddress,
        propertyType,
        propertySize,
        loanAmount,
        interestRate,
        loanStartDate,
        loanEndDate,
        commodityType,
        purity,
        unit,
        companyName,
        equityPercentage,
        collectibleType,
        condition,
        certification,
      ];
}

/// Amortization payment schedule entry
class AmortizationPayment extends Equatable {
  final int paymentNumber;
  final DateTime dueDate;
  final double principalAmount;
  final double interestAmount;
  final double totalPayment;
  final double remainingBalance;
  final bool isPaid;

  const AmortizationPayment({
    required this.paymentNumber,
    required this.dueDate,
    required this.principalAmount,
    required this.interestAmount,
    required this.totalPayment,
    required this.remainingBalance,
    this.isPaid = false,
  });

  bool get isUpcoming => dueDate.isAfter(DateTime.now()) && !isPaid;
  bool get isOverdue => dueDate.isBefore(DateTime.now()) && !isPaid;

  @override
  List<Object?> get props => [
        paymentNumber,
        dueDate,
        principalAmount,
        interestAmount,
        totalPayment,
        remainingBalance,
        isPaid,
      ];
}
