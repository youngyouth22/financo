import 'package:financo/features/finance/domain/entities/manual_asset_detail.dart';

/// Data model for ManualAssetDetail from Supabase Edge Function
class ManualAssetDetailModel extends ManualAssetDetail {
  const ManualAssetDetailModel({
    required super.assetId,
    required super.name,
    required super.category,
    required super.currentValue,
    required super.purchasePrice,
    required super.purchaseDate,
    required super.currency,
    required super.metadata,
    super.amortizationSchedule,
    super.rruleString,
    required super.valueHistory,
  });

  /// Factory constructor from JSON (Edge Function response)
  factory ManualAssetDetailModel.fromJson(Map<String, dynamic> json) {
    return ManualAssetDetailModel(
      assetId: json['assetId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: _parseCategory(json['category'] as String?),
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: DateTime.parse(
        json['purchaseDate'] as String? ?? DateTime.now().toIso8601String(),
      ),
      currency: json['currency'] as String? ?? 'USD',
      metadata: ManualAssetMetadataModel.fromJson(
        json['metadata'] as Map<String, dynamic>? ?? {},
      ),
      amortizationSchedule: (json['amortizationSchedule'] as List?)
          ?.map((p) =>
              AmortizationPaymentModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      rruleString: json['rruleString'] as String?,
      valueHistory: (json['valueHistory'] as List?)
              ?.map((v) => (v as num).toDouble())
              .toList() ??
          [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'assetId': assetId,
      'name': name,
      'category': category.name,
      'currentValue': currentValue,
      'purchasePrice': purchasePrice,
      'purchaseDate': purchaseDate.toIso8601String(),
      'currency': currency,
      'metadata': (metadata as ManualAssetMetadataModel).toJson(),
      'amortizationSchedule': amortizationSchedule
          ?.map((p) => (p as AmortizationPaymentModel).toJson())
          .toList(),
      'rruleString': rruleString,
      'valueHistory': valueHistory,
    };
  }

  static ManualAssetCategory _parseCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'realestate':
      case 'real_estate':
        return ManualAssetCategory.realEstate;
      case 'privateequity':
      case 'private_equity':
        return ManualAssetCategory.privateEquity;
      case 'commodity':
        return ManualAssetCategory.commodity;
      case 'collectible':
        return ManualAssetCategory.collectible;
      case 'loan':
        return ManualAssetCategory.loan;
      default:
        return ManualAssetCategory.other;
    }
  }
}

/// Data model for ManualAssetMetadata
class ManualAssetMetadataModel extends ManualAssetMetadata {
  const ManualAssetMetadataModel({
    super.propertyAddress,
    super.propertyType,
    super.propertySize,
    super.loanAmount,
    super.interestRate,
    super.loanStartDate,
    super.loanEndDate,
    super.commodityType,
    super.purity,
    super.unit,
    super.companyName,
    super.equityPercentage,
    super.collectibleType,
    super.condition,
    super.certification,
  });

  factory ManualAssetMetadataModel.fromJson(Map<String, dynamic> json) {
    return ManualAssetMetadataModel(
      propertyAddress: json['propertyAddress'] as String?,
      propertyType: json['propertyType'] as String?,
      propertySize: (json['propertySize'] as num?)?.toDouble(),
      loanAmount: (json['loanAmount'] as num?)?.toDouble(),
      interestRate: (json['interestRate'] as num?)?.toDouble(),
      loanStartDate: json['loanStartDate'] != null
          ? DateTime.parse(json['loanStartDate'] as String)
          : null,
      loanEndDate: json['loanEndDate'] != null
          ? DateTime.parse(json['loanEndDate'] as String)
          : null,
      commodityType: json['commodityType'] as String?,
      purity: (json['purity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      companyName: json['companyName'] as String?,
      equityPercentage: (json['equityPercentage'] as num?)?.toDouble(),
      collectibleType: json['collectibleType'] as String?,
      condition: json['condition'] as String?,
      certification: json['certification'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyAddress': propertyAddress,
      'propertyType': propertyType,
      'propertySize': propertySize,
      'loanAmount': loanAmount,
      'interestRate': interestRate,
      'loanStartDate': loanStartDate?.toIso8601String(),
      'loanEndDate': loanEndDate?.toIso8601String(),
      'commodityType': commodityType,
      'purity': purity,
      'unit': unit,
      'companyName': companyName,
      'equityPercentage': equityPercentage,
      'collectibleType': collectibleType,
      'condition': condition,
      'certification': certification,
    };
  }
}

/// Data model for AmortizationPayment
class AmortizationPaymentModel extends AmortizationPayment {
  const AmortizationPaymentModel({
    required super.paymentNumber,
    required super.dueDate,
    required super.principalAmount,
    required super.interestAmount,
    required super.totalPayment,
    required super.remainingBalance,
    super.isPaid,
  });

  factory AmortizationPaymentModel.fromJson(Map<String, dynamic> json) {
    return AmortizationPaymentModel(
      paymentNumber: json['paymentNumber'] as int? ?? 0,
      dueDate: DateTime.parse(
        json['dueDate'] as String? ?? DateTime.now().toIso8601String(),
      ),
      principalAmount: (json['principalAmount'] as num?)?.toDouble() ?? 0.0,
      interestAmount: (json['interestAmount'] as num?)?.toDouble() ?? 0.0,
      totalPayment: (json['totalPayment'] as num?)?.toDouble() ?? 0.0,
      remainingBalance: (json['remainingBalance'] as num?)?.toDouble() ?? 0.0,
      isPaid: json['isPaid'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentNumber': paymentNumber,
      'dueDate': dueDate.toIso8601String(),
      'principalAmount': principalAmount,
      'interestAmount': interestAmount,
      'totalPayment': totalPayment,
      'remainingBalance': remainingBalance,
      'isPaid': isPaid,
    };
  }
}
