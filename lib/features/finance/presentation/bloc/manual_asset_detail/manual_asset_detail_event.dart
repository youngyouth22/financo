import 'package:equatable/equatable.dart';

/// Events for ManualAssetDetailBloc
abstract class ManualAssetDetailEvent extends Equatable {
  const ManualAssetDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load asset detail data (summary + payouts + reminders)
class LoadAssetDetailEvent extends ManualAssetDetailEvent {
  final String assetId;

  const LoadAssetDetailEvent(this.assetId);

  @override
  List<Object?> get props => [assetId];
}

/// Event to mark a reminder as received
class MarkReminderReceivedEvent extends ManualAssetDetailEvent {
  final String reminderId;
  final String assetId;
  final double amount;
  final DateTime payoutDate;
  final String? notes;

  const MarkReminderReceivedEvent({
    required this.reminderId,
    required this.assetId,
    required this.amount,
    required this.payoutDate,
    this.notes,
  });

  @override
  List<Object?> get props => [reminderId, assetId, amount, payoutDate, notes];
}

/// Event to refresh asset detail data
class RefreshAssetDetailEvent extends ManualAssetDetailEvent {
  final String assetId;

  const RefreshAssetDetailEvent(this.assetId);

  @override
  List<Object?> get props => [assetId];
}
