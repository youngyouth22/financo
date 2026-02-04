import 'package:equatable/equatable.dart';
import 'package:financo/features/finance/domain/entities/asset_payout.dart';

/// States for ManualAssetDetailBloc
abstract class ManualAssetDetailState extends Equatable {
  const ManualAssetDetailState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ManualAssetDetailInitial extends ManualAssetDetailState {
  const ManualAssetDetailInitial();
}

/// Loading state
class ManualAssetDetailLoading extends ManualAssetDetailState {
  const ManualAssetDetailLoading();
}

/// Loaded state with all data
class ManualAssetDetailLoaded extends ManualAssetDetailState {
  final AssetPayoutSummary summary;
  final List<AssetPayout> payouts;

  const ManualAssetDetailLoaded({
    required this.summary,
    required this.payouts,
  });

  @override
  List<Object?> get props => [summary, payouts];

  ManualAssetDetailLoaded copyWith({
    AssetPayoutSummary? summary,
    List<AssetPayout>? payouts,
  }) {
    return ManualAssetDetailLoaded(
      summary: summary ?? this.summary,
      payouts: payouts ?? this.payouts,
    );
  }
}

/// Error state
class ManualAssetDetailError extends ManualAssetDetailState {
  final String message;

  const ManualAssetDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when marking reminder as received
class MarkingReminderReceived extends ManualAssetDetailState {
  const MarkingReminderReceived();
}

/// State when reminder marked successfully
class ReminderMarkedSuccess extends ManualAssetDetailState {
  const ReminderMarkedSuccess();
}
