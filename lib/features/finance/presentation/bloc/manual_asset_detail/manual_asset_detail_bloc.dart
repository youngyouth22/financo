import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:financo/features/finance/domain/usecases/payout_usecases/get_asset_payout_summary_usecase.dart';
import 'package:financo/features/finance/domain/usecases/payout_usecases/get_asset_payouts_usecase.dart';
import 'package:financo/features/finance/domain/usecases/payout_usecases/mark_reminder_as_received_usecase.dart';
import 'manual_asset_detail_event.dart';
import 'manual_asset_detail_state.dart';

/// BLoC for managing manual asset detail page state
///
/// Handles:
/// - Loading payout summary
/// - Loading payout history
/// - Marking reminders as received
class ManualAssetDetailBloc extends Bloc<ManualAssetDetailEvent, ManualAssetDetailState> {
  final GetAssetPayoutSummaryUseCase getAssetPayoutSummaryUseCase;
  final GetAssetPayoutsUseCase getAssetPayoutsUseCase;
  final MarkReminderAsReceivedUseCase markReminderAsReceivedUseCase;

  ManualAssetDetailBloc({
    required this.getAssetPayoutSummaryUseCase,
    required this.getAssetPayoutsUseCase,
    required this.markReminderAsReceivedUseCase,
  }) : super(const ManualAssetDetailInitial()) {
    on<LoadAssetDetailEvent>(_onLoadAssetDetail);
    on<MarkReminderReceivedEvent>(_onMarkReminderReceived);
    on<RefreshAssetDetailEvent>(_onRefreshAssetDetail);
  }

  /// Load asset detail data (summary + payouts)
  Future<void> _onLoadAssetDetail(
    LoadAssetDetailEvent event,
    Emitter<ManualAssetDetailState> emit,
  ) async {
    emit(const ManualAssetDetailLoading());

    // Load summary and payouts in parallel
    final summaryResult = await getAssetPayoutSummaryUseCase(event.assetId);
    final payoutsResult = await getAssetPayoutsUseCase(event.assetId);

    // Handle results
    summaryResult.fold(
      (failure) => emit(ManualAssetDetailError(failure.message)),
      (summary) {
        payoutsResult.fold(
          (failure) => emit(ManualAssetDetailError(failure.message)),
          (payouts) => emit(ManualAssetDetailLoaded(
            summary: summary,
            payouts: payouts,
          )),
        );
      },
    );
  }

  /// Mark a reminder as received
  Future<void> _onMarkReminderReceived(
    MarkReminderReceivedEvent event,
    Emitter<ManualAssetDetailState> emit,
  ) async {
    // Don't emit loading state to avoid black screen
    // Keep current state while processing
    
    final params = MarkReminderAsReceivedParams(
      reminderId: event.reminderId,
      assetId: event.assetId,
      amount: event.amount,
      payoutDate: event.payoutDate,
      notes: event.notes,
    );

    final result = await markReminderAsReceivedUseCase(params);

    result.fold(
      (failure) => emit(ManualAssetDetailError(failure.message)),
      (_) {
        // Emit success state briefly to show snackbar
        emit(const ReminderMarkedSuccess());
        // Reload data after marking as received
        add(LoadAssetDetailEvent(event.assetId));
      },
    );
  }

  /// Refresh asset detail data
  Future<void> _onRefreshAssetDetail(
    RefreshAssetDetailEvent event,
    Emitter<ManualAssetDetailState> emit,
  ) async {
    // Same as load, but can be used for pull-to-refresh
    add(LoadAssetDetailEvent(event.assetId));
  }
}
