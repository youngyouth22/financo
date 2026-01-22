import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/usecases/delete_asset_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_assets_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_global_wealth_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_net_worth_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_wealth_history_usecase.dart';
import 'package:financo/features/finance/domain/usecases/watch_assets_usecase.dart';
import 'package:financo/features/finance/presentation/bloc/finance_event.dart';
import 'package:financo/features/finance/presentation/bloc/finance_state.dart';

/// BLoC for managing finance-related state and business logic
///
/// Handles all finance operations including:
/// - Loading and watching assets
/// - Real-time updates via Supabase
/// - Deleting assets
/// - Calculating net worth
/// - Loading wealth history
class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final GetGlobalWealthUseCase getGlobalWealthUseCase;
  final GetAssetsUseCase getAssetsUseCase;
  final WatchAssetsUseCase watchAssetsUseCase;
  final DeleteAssetUseCase deleteAssetUseCase;
  final GetNetWorthUseCase getNetWorthUseCase;
  final GetWealthHistoryUseCase getWealthHistoryUseCase;

  StreamSubscription? _assetsSubscription;

  FinanceBloc({
    required this.getGlobalWealthUseCase,
    required this.getAssetsUseCase,
    required this.watchAssetsUseCase,
    required this.deleteAssetUseCase,
    required this.getNetWorthUseCase,
    required this.getWealthHistoryUseCase,
  }) : super(const FinanceInitial()) {
    on<LoadGlobalWealthEvent>(_onLoadGlobalWealth);
    on<LoadAssetsEvent>(_onLoadAssets);
    on<WatchAssetsEvent>(_onWatchAssets);
    on<StopWatchingAssetsEvent>(_onStopWatchingAssets);
    on<AssetsUpdatedEvent>(_onAssetsUpdated);
    on<DeleteAssetEvent>(_onDeleteAsset);
    on<LoadWealthHistoryEvent>(_onLoadWealthHistory);
    on<CalculateNetWorthEvent>(_onCalculateNetWorth);
  }

  /// Handle LoadGlobalWealthEvent
  Future<void> _onLoadGlobalWealth(
    LoadGlobalWealthEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await getGlobalWealthUseCase(NoParams());

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (globalWealth) => emit(GlobalWealthLoaded(globalWealth: globalWealth)),
    );
  }

  /// Handle LoadAssetsEvent
  Future<void> _onLoadAssets(
    LoadAssetsEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await getAssetsUseCase(NoParams());

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (assets) => emit(AssetsLoaded(assets: assets)),
    );
  }

  /// Handle WatchAssetsEvent - Start real-time subscription
  Future<void> _onWatchAssets(
    WatchAssetsEvent event,
    Emitter<FinanceState> emit,
  ) async {
    // Cancel existing subscription if any
    await _assetsSubscription?.cancel();

    // Start watching assets
    _assetsSubscription = watchAssetsUseCase().listen((result) {
      result.fold(
        (failure) => add(const LoadAssetsEvent()), // Fallback to regular load
        (assets) => add(AssetsUpdatedEvent(assets)),
      );
    });

    // Update state to indicate watching is active
    if (state is AssetsLoaded) {
      emit((state as AssetsLoaded).copyWith(isWatching: true));
    } else if (state is GlobalWealthLoaded) {
      emit((state as GlobalWealthLoaded).copyWith(isWatching: true));
    }
  }

  /// Handle StopWatchingAssetsEvent
  Future<void> _onStopWatchingAssets(
    StopWatchingAssetsEvent event,
    Emitter<FinanceState> emit,
  ) async {
    await _assetsSubscription?.cancel();
    _assetsSubscription = null;

    // Update state to indicate watching is inactive
    if (state is AssetsLoaded) {
      emit((state as AssetsLoaded).copyWith(isWatching: false));
    } else if (state is GlobalWealthLoaded) {
      emit((state as GlobalWealthLoaded).copyWith(isWatching: false));
    }
  }

  /// Handle AssetsUpdatedEvent - Real-time update from stream
  Future<void> _onAssetsUpdated(
    AssetsUpdatedEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(
      AssetsRealTimeUpdated(assets: event.assets, updatedAt: DateTime.now()),
    );

    // Also update the main state
    if (state is AssetsLoaded) {
      emit((state as AssetsLoaded).copyWith(assets: event.assets));
    } else {
      emit(AssetsLoaded(assets: event.assets, isWatching: true));
    }
  }

  /// Handle DeleteAssetEvent
  Future<void> _onDeleteAsset(
    DeleteAssetEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final params = DeleteAssetParams(assetId: event.assetId);
    final result = await deleteAssetUseCase(params);

    result.fold((failure) => emit(FinanceError(failure.message)), (_) {
      emit(AssetDeleted(event.assetId));
      // Reload assets after deleting
      add(const LoadAssetsEvent());
    });
  }

  /// Handle LoadWealthHistoryEvent
  Future<void> _onLoadWealthHistory(
    LoadWealthHistoryEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final params = GetWealthHistoryParams(limit: event.limit);

    final result = await getWealthHistoryUseCase(params);

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (snapshots) => emit(WealthHistoryLoaded(snapshots)),
    );
  }

  /// Handle CalculateNetWorthEvent
  Future<void> _onCalculateNetWorth(
    CalculateNetWorthEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await getNetWorthUseCase(NoParams());

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (netWorth) => emit(NetWorthCalculated(netWorth)),
    );
  }

  @override
  Future<void> close() async {
    await _assetsSubscription?.cancel();
    return super.close();
  }
}
