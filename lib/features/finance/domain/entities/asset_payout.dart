import 'package:equatable/equatable.dart';

/// Entity representing a payout received from a manual asset
///
/// Tracks actual payments received for amortization, loan repayments,
/// rent income, or any recurring income from manual assets.
class AssetPayout extends Equatable {
  /// Unique identifier for the payout
  final String id;

  /// ID of the user who owns the asset
  final String userId;

  /// ID of the asset this payout belongs to
  final String assetId;

  /// Amount received in this payout
  final double amount;

  /// Date when the payment was received
  final DateTime payoutDate;

  /// Optional notes about the payout
  final String? notes;

  /// Timestamp when the record was created
  final DateTime createdAt;

  /// Timestamp when the record was last updated
  final DateTime updatedAt;

  const AssetPayout({
    required this.id,
    required this.userId,
    required this.assetId,
    required this.amount,
    required this.payoutDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        assetId,
        amount,
        payoutDate,
        notes,
        createdAt,
        updatedAt,
      ];

  /// Create a copy with updated fields
  AssetPayout copyWith({
    String? id,
    String? userId,
    String? assetId,
    double? amount,
    DateTime? payoutDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssetPayout(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assetId: assetId ?? this.assetId,
      amount: amount ?? this.amount,
      payoutDate: payoutDate ?? this.payoutDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Summary of payouts for a specific asset
class AssetPayoutSummary extends Equatable {
  /// Total expected value of the asset
  final double totalExpected;

  /// Total amount received from payouts
  final double totalReceived;

  /// Remaining balance (expected - received)
  final double remainingBalance;

  /// Number of payouts received
  final int payoutCount;

  /// Date of the last payout (null if no payouts yet)
  final DateTime? lastPayoutDate;

  const AssetPayoutSummary({
    required this.totalExpected,
    required this.totalReceived,
    required this.remainingBalance,
    required this.payoutCount,
    this.lastPayoutDate,
  });

  /// Calculate completion percentage
  double get completionPercentage {
    if (totalExpected == 0) return 0;
    return (totalReceived / totalExpected * 100).clamp(0, 100);
  }

  /// Check if asset is fully paid
  bool get isFullyPaid => remainingBalance <= 0;

  @override
  List<Object?> get props => [
        totalExpected,
        totalReceived,
        remainingBalance,
        payoutCount,
        lastPayoutDate,
      ];

  AssetPayoutSummary copyWith({
    double? totalExpected,
    double? totalReceived,
    double? remainingBalance,
    int? payoutCount,
    DateTime? lastPayoutDate,
  }) {
    return AssetPayoutSummary(
      totalExpected: totalExpected ?? this.totalExpected,
      totalReceived: totalReceived ?? this.totalReceived,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      payoutCount: payoutCount ?? this.payoutCount,
      lastPayoutDate: lastPayoutDate ?? this.lastPayoutDate,
    );
  }
}
