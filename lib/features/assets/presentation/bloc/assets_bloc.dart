import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/assets/presentation/bloc/assets_event.dart';
import 'package:financo/features/assets/presentation/bloc/assets_state.dart';
import 'package:financo/features/finance/data/models/asset_model.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';
import 'package:financo/features/finance/domain/usecases/add_crypto_wallet_usecase.dart';
import 'package:financo/features/finance/domain/usecases/add_manual_asset_usecase.dart';
import 'package:financo/features/finance/domain/usecases/add_stock_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_assets_usecase.dart';
import 'package:financo/features/finance/domain/usecases/update_asset_quantity_usecase.dart';
import 'package:financo/features/finance/domain/usecases/watch_assets_usecase.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// BLoC for Assets
/// 
/// Handles detailed list of assets (CRUD), real-time updates, sorting/filtering
class AssetsBloc extends Bloc<AssetsEvent, AssetsState> {
  final GetAssetsUseCase getAssetsUseCase;
  final WatchAssetsUseCase watchAssetsUseCase;
  final AddCryptoWalletUseCase addCryptoWalletUseCase;
  final AddStockUseCase addStockUseCase;
  final AddManualAssetUseCase addManualAssetUseCase;
  final UpdateAssetQuantityUseCase updateAssetQuantityUseCase;
  final FinanceRepository financeRepository;

  StreamSubscription? _assetsSubscription;

  AssetsBloc({
    required this.getAssetsUseCase,
    required this.watchAssetsUseCase,
    required this.addCryptoWalletUseCase,
    required this.addStockUseCase,
    required this.addManualAssetUseCase,
    required this.updateAssetQuantityUseCase,
    required this.financeRepository,
  }) : super(const AssetsInitial()) {
    on<LoadAssetsEvent>(_onLoadAssets);
    on<WatchAssetsEvent>(_onWatchAssets);
    on<StopWatchingAssetsEvent>(_onStopWatchingAssets);
    on<AddCryptoWalletEvent>(_onAddCryptoWallet);
    on<RemoveCryptoWalletEvent>(_onRemoveCryptoWallet);
    on<AddStockEvent>(_onAddStock);
    on<RemoveStockEvent>(_onRemoveStock);
    on<UpdateAssetQuantityEvent>(_onUpdateAssetQuantity);
    on<DeleteAssetEvent>(_onDeleteAsset);
    on<AddManualAssetEvent>(_onAddManualAsset);
    on<SortAssetsEvent>(_onSortAssets);
    on<FilterAssetsByTypeEvent>(_onFilterAssets);
  }

  /// Load assets
  Future<void> _onLoadAssets(
    LoadAssetsEvent event,
    Emitter<AssetsState> emit,
  ) async {
    emit(const AssetsLoading());

    final result = await getAssetsUseCase.call(const NoParams());

    result.fold(
      (failure) {
        final isOffline = failure is OfflineFailure;
        emit(AssetsError(failure.message, isOffline: isOffline));
      },
      (assets) => emit(AssetsLoaded(assets: assets)),
    );
  }

 Future<void> _onWatchAssets(
  WatchAssetsEvent event,
  Emitter<AssetsState> emit,
) async {
  await emit.forEach<Either<Failure, List<Asset>>>(
    watchAssetsUseCase.call(),
    onData: (either) {
      return either.fold(
        (failure) {
          final isOffline = failure is OfflineFailure;
          return AssetsError(failure.message, isOffline: isOffline);
        },
        (assets) => AssetsRealTimeUpdated(assets),
      );
    },
    onError: (error, stackTrace) {
      return AssetsError('Connection to assets lost: $error');
    },
  );
}
  /// Stop watching assets
  Future<void> _onStopWatchingAssets(
    StopWatchingAssetsEvent event,
    Emitter<AssetsState> emit,
  ) async {
    await _assetsSubscription?.cancel();
    _assetsSubscription = null;
  }

  /// Add crypto wallet
  Future<void> _onAddCryptoWallet(
    AddCryptoWalletEvent event,
    Emitter<AssetsState> emit,
  ) async {
    emit(const AssetsLoading());

    final result = await addCryptoWalletUseCase.call(AddCryptoWalletParams(walletAddress:event.walletAddress));

    result.fold(
      (failure) {
        final isOffline = failure is OfflineFailure;
        emit(AssetsError(failure.message, isOffline: isOffline));
      },
      (_) {
        emit(const AssetAdded('Crypto wallet added successfully'));
        add(const LoadAssetsEvent());
      },
    );
  }

  /// Remove crypto wallet
  Future<void> _onRemoveCryptoWallet(
    RemoveCryptoWalletEvent event,
    Emitter<AssetsState> emit,
  ) async {
    emit(const AssetsLoading());

    final result = await financeRepository.removeCryptoWallet(event.walletAddress);

    result.fold(
      (failure) {
        final isOffline = failure is OfflineFailure;
        emit(AssetsError(failure.message, isOffline: isOffline));
      },
      (_) {
        emit(const AssetDeleted('Crypto wallet removed successfully'));
        add(const LoadAssetsEvent());
      },
    );
  }

  /// Add stock
  Future<void> _onAddStock(
    AddStockEvent event,
    Emitter<AssetsState> emit,
  ) async {
    emit(const AssetsLoading());

    final result = await addStockUseCase(AddStockParams(
      symbol: event.symbol,
      quantity: event.quantity,
    ));

    result.fold(
      (failure) {
        final isOffline = failure is OfflineFailure;
        emit(AssetsError(failure.message, isOffline: isOffline));
      },
      (_) {
        emit(const AssetAdded('Stock added successfully'));
        add(const LoadAssetsEvent());
      },
    );
  }

  /// Remove stock
  Future<void> _onRemoveStock(
    RemoveStockEvent event,
    Emitter<AssetsState> emit,
  ) async {
    emit(const AssetsLoading());

    final result = await financeRepository.removeStock(event.assetId);

    result.fold(
      (failure) {
        final isOffline = failure is OfflineFailure;
        emit(AssetsError(failure.message, isOffline: isOffline));
      },
      (_) {
        emit(const AssetDeleted('Stock removed successfully'));
        add(const LoadAssetsEvent());
      },
    );
  }

  /// Update asset quantity
  Future<void> _onUpdateAssetQuantity(
    UpdateAssetQuantityEvent event,
    Emitter<AssetsState> emit,
  ) async {
    final result = await updateAssetQuantityUseCase(UpdateAssetQuantityParams(
      assetId: event.assetId,
      newQuantity: event.newQuantity,
    ));

    result.fold(
      (failure) {
        final isOffline = failure is OfflineFailure;
        emit(AssetsError(failure.message, isOffline: isOffline));
      },
      (_) {
        emit(const AssetUpdated('Asset quantity updated successfully'));
        add(const LoadAssetsEvent());
      },
    );
  }

  /// Delete asset
  Future<void> _onDeleteAsset(
    DeleteAssetEvent event,
    Emitter<AssetsState> emit,
  ) async {
    emit(const AssetsLoading());

    final result = await financeRepository.deleteAsset(event.assetId);

    result.fold(
      (failure) {
        final isOffline = failure is OfflineFailure;
        emit(AssetsError(failure.message, isOffline: isOffline));
      },
      (_) {
        emit(const AssetDeleted('Asset deleted successfully'));
        add(const LoadAssetsEvent());
      },
    );
  }

  /// Add manual asset
  Future<void> _onAddManualAsset(
    AddManualAssetEvent event,
    Emitter<AssetsState> emit,
  ) async {
    emit(const AssetsLoading());

    final result = await addManualAssetUseCase(AddManualAssetParams(
      name: event.name,
      type: event.type,
      amount: event.amount,
      currency: event.currency,
      sector: event.sector,
      country: event.country,
    ));

    result.fold(
      (failure) {
        final isOffline = failure is OfflineFailure;
        emit(AssetsError(failure.message, isOffline: isOffline));
      },
      (_) {
        emit(const AssetAdded('Manual asset added successfully'));
        add(const LoadAssetsEvent());
      },
    );
  }

  /// Sort assets
  void _onSortAssets(
    SortAssetsEvent event,
    Emitter<AssetsState> emit,
  ) {
    if (state is! AssetsLoaded) return;

    final currentState = state as AssetsLoaded;
    final sortedAssets = List<Asset>.from(currentState.assets);

    switch (event.sortType) {
      case AssetSortType.nameAsc:
        sortedAssets.sort((a, b) => a.name.compareTo(b.name));
        break;
      case AssetSortType.nameDesc:
        sortedAssets.sort((a, b) => b.name.compareTo(a.name));
        break;
      case AssetSortType.valueAsc:
        sortedAssets.sort((a, b) => a.balanceUsd.compareTo(b.balanceUsd));
        break;
      case AssetSortType.valueDesc:
        sortedAssets.sort((a, b) => b.balanceUsd.compareTo(a.balanceUsd));
        break;
      case AssetSortType.typeAsc:
        sortedAssets.sort((a, b) => a.type.toString().compareTo(b.type.toString()));
        break;
      case AssetSortType.typeDesc:
        sortedAssets.sort((a, b) => b.type.toString().compareTo(a.type.toString()));
        break;
    }

    emit(currentState.copyWith(
      assets: sortedAssets,
      currentSort: event.sortType,
    ));
  }

  /// Filter assets by type
  void _onFilterAssets(
    FilterAssetsByTypeEvent event,
    Emitter<AssetsState> emit,
  ) {
    if (state is! AssetsLoaded) return;

    final currentState = state as AssetsLoaded;

    if (event.filterType == null) {
      // Clear filter - reload all assets
      add(const LoadAssetsEvent());
      return;
    }

    final filteredAssets = currentState.assets
        .where((asset) => asset.type == event.filterType)
        .toList();

    emit(currentState.copyWith(
      assets: filteredAssets,
      currentFilter: event.filterType,
    ));
  }

  @override
  Future<void> close() {
    _assetsSubscription?.cancel();
    return super.close();
  }
}
