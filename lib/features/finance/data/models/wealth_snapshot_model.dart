import 'package:financo/features/finance/domain/entities/wealth_snapshot.dart';

/// Data model for WealthSnapshot entity
///
/// Handles serialization/deserialization from Supabase wealth_history table
/// and mapping to/from domain entities.
class WealthSnapshotModel extends WealthSnapshot {
  const WealthSnapshotModel({
    required super.id,
    required super.userId,
    required super.totalAmount,
    required super.timestamp,
  });

  /// Create WealthSnapshotModel from JSON (Supabase response)
  factory WealthSnapshotModel.fromJson(Map<String, dynamic> json) {
    return WealthSnapshotModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      totalAmount: _parseDecimal(json['total_amount']),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert WealthSnapshotModel to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'total_amount': totalAmount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create WealthSnapshotModel from domain entity
  factory WealthSnapshotModel.fromEntity(WealthSnapshot entity) {
    return WealthSnapshotModel(
      id: entity.id,
      userId: entity.userId,
      totalAmount: entity.totalAmount,
      timestamp: entity.timestamp,
    );
  }

  /// Convert WealthSnapshotModel to domain entity
  WealthSnapshot toEntity() {
    return WealthSnapshot(
      id: id,
      userId: userId,
      totalAmount: totalAmount,
      timestamp: timestamp,
    );
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Parse decimal value from various formats
  static double _parseDecimal(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    throw ArgumentError('Cannot parse decimal from: $value');
  }
}
