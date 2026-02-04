import 'package:financo/features/finance/domain/entities/asset_payout.dart';

/// Data model for AssetPayout with JSON serialization
class AssetPayoutModel extends AssetPayout {
  const AssetPayoutModel({
    required super.id,
    required super.userId,
    required super.assetId,
    required super.amount,
    required super.payoutDate,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create model from JSON
  factory AssetPayoutModel.fromJson(Map<String, dynamic> json) {
    return AssetPayoutModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      assetId: json['asset_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      payoutDate: DateTime.parse(json['payout_date'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'asset_id': assetId,
      'amount': amount,
      'payout_date': payoutDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert model to entity
  AssetPayout toEntity() {
    return AssetPayout(
      id: id,
      userId: userId,
      assetId: assetId,
      amount: amount,
      payoutDate: payoutDate,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create model from entity
  factory AssetPayoutModel.fromEntity(AssetPayout entity) {
    return AssetPayoutModel(
      id: entity.id,
      userId: entity.userId,
      assetId: entity.assetId,
      amount: entity.amount,
      payoutDate: entity.payoutDate,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

/// Data model for AssetPayoutSummary with JSON serialization
class AssetPayoutSummaryModel extends AssetPayoutSummary {
  const AssetPayoutSummaryModel({
    required super.totalExpected,
    required super.totalReceived,
    required super.remainingBalance,
    required super.payoutCount,
    super.lastPayoutDate,
  });

  /// Create model from JSON
  factory AssetPayoutSummaryModel.fromJson(Map<String, dynamic> json) {
    return AssetPayoutSummaryModel(
      totalExpected: (json['total_expected'] as num?)?.toDouble() ?? 0.0,
      totalReceived: (json['total_received'] as num?)?.toDouble() ?? 0.0,
      remainingBalance: (json['remaining_balance'] as num?)?.toDouble() ?? 0.0,
      payoutCount: json['payout_count'] as int? ?? 0,
      lastPayoutDate: json['last_payout_date'] != null
          ? DateTime.parse(json['last_payout_date'] as String)
          : null,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'total_expected': totalExpected,
      'total_received': totalReceived,
      'remaining_balance': remainingBalance,
      'payout_count': payoutCount,
      'last_payout_date': lastPayoutDate?.toIso8601String(),
    };
  }

  /// Convert model to entity
  AssetPayoutSummary toEntity() {
    return AssetPayoutSummary(
      totalExpected: totalExpected,
      totalReceived: totalReceived,
      remainingBalance: remainingBalance,
      payoutCount: payoutCount,
      lastPayoutDate: lastPayoutDate,
    );
  }

  /// Create model from entity
  factory AssetPayoutSummaryModel.fromEntity(AssetPayoutSummary entity) {
    return AssetPayoutSummaryModel(
      totalExpected: entity.totalExpected,
      totalReceived: entity.totalReceived,
      remainingBalance: entity.remainingBalance,
      payoutCount: entity.payoutCount,
      lastPayoutDate: entity.lastPayoutDate,
    );
  }
}
