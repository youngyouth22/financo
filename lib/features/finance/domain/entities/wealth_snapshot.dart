import 'package:equatable/equatable.dart';

/// Represents a snapshot of total wealth at a specific point in time
///
/// Used for tracking wealth history and displaying charts/graphs.
class WealthSnapshot extends Equatable {
  /// Unique identifier for this snapshot
  final String id;

  /// ID of the user who owns this wealth snapshot
  final String userId;

  /// Total wealth amount in USD at this point in time
  final double totalAmount;

  /// Timestamp when this snapshot was recorded
  final DateTime timestamp;

  const WealthSnapshot({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.timestamp,
  });

  /// Get formatted total amount with currency symbol
  String get formattedAmount => '\$${totalAmount.toStringAsFixed(2)}';

  /// Get formatted date string
  String get formattedDate {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
  }

  /// Get formatted time string
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Get formatted datetime string
  String get formattedDateTime => '$formattedDate $formattedTime';

  @override
  List<Object?> get props => [id, userId, totalAmount, timestamp];

  @override
  String toString() {
    return 'WealthSnapshot(id: $id, amount: $formattedAmount, timestamp: $formattedDateTime)';
  }
}
