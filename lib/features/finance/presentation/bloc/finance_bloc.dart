import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';
import 'package:financo/features/finance/domain/usecases/add_asset_reminder_usecase.dart';
import 'package:financo/features/finance/domain/usecases/add_crypto_wallet_usecase.dart';
import 'package:financo/features/finance/domain/usecases/add_manual_asset_usecase.dart';
import 'package:financo/features/finance/domain/usecases/add_stock_usecase.dart';
import 'package:financo/features/finance/domain/usecases/delete_asset_usecase.dart';
import 'package:financo/features/finance/domain/usecases/exchange_plaid_token_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_assets_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_daily_change_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_networth_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_plaid_link_token_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_wealth_history_usecase.dart';
import 'package:financo/features/finance/domain/usecases/search_stocks_usecase.dart';
import 'package:financo/features/finance/domain/usecases/update_asset_quantity_usecase.dart';
import 'package:financo/features/finance/domain/usecases/watch_assets_usecase.dart';
import 'package:financo/features/finance/presentation/bloc/finance_event.dart';
import 'package:financo/features/finance/presentation/bloc/finance_state.dart';

/// BLoC for managing finance-related business logic
///
/// Handles all finance operations including:
/// - Networth and dashboard data
/// - Assets CRUD operations
/// - Real-time asset updates
/// - Crypto wallet management (Moralis)
/// - Stock management (FMP)
/// - Bank account management (Plaid)
/// - Wealth history tracking
class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final GetNetworthUseCase getNetworthUseCase;
  final GetDailyChangeUseCase getDailyChangeUseCase;
  final GetAssetsUseCase getAssetsUseCase;
  final WatchAssetsUseCase watchAssetsUseCase;
  final DeleteAssetUseCase deleteAssetUseCase;
  final UpdateAssetQuantityUseCase updateAssetQuantityUseCase;
  final AddCryptoWalletUseCase addCryptoWalletUseCase;
  final SearchStocksUseCase searchStocksUseCase;
  final AddStockUseCase addStockUseCase;
  final GetPlaidLinkTokenUseCase getPlaidLinkTokenUseCase;
  final ExchangePlaidTokenUseCase exchangePlaidTokenUseCase;
  final GetWealthHistoryUseCase getWealthHistoryUseCase;
  final AddManualAssetUseCase addManualAssetUseCase;
  final AddAssetReminderUseCase addAssetReminderUseCase;

  StreamSubscription? _assetsSubscription;

  FinanceBloc({
    required this.getNetworthUseCase,
    required this.getDailyChangeUseCase,
    required this.getAssetsUseCase,
    required this.watchAssetsUseCase,
    required this.deleteAssetUseCase,
    required this.updateAssetQuantityUseCase,
    required this.addCryptoWalletUseCase,
    required this.searchStocksUseCase,
    required this.addStockUseCase,
    required this.getPlaidLinkTokenUseCase,
    required this.exchangePlaidTokenUseCase,
    required this.getWealthHistoryUseCase,
    required this.addManualAssetUseCase,
    required this.addAssetReminderUseCase,
  }) : super(const FinanceInitial()) {
    on<LoadNetworthEvent>(_onLoadNetworth);
    on<LoadDailyChangeEvent>(_onLoadDailyChange);
    on<LoadAssetsEvent>(_onLoadAssets);
    on<WatchAssetsEvent>(_onWatchAssets);
    on<StopWatchingAssetsEvent>(_onStopWatchingAssets);
    on<DeleteAssetEvent>(_onDeleteAsset);
    on<UpdateAssetQuantityEvent>(_onUpdateAssetQuantity);
    on<AddCryptoWalletEvent>(_onAddCryptoWallet);
    on<SearchStocksEvent>(_onSearchStocks);
    on<AddStockEvent>(_onAddStock);
    on<GetPlaidLinkTokenEvent>(_onGetPlaidLinkToken);
    on<ExchangePlaidTokenEvent>(_onExchangePlaidToken);
    on<LoadWealthHistoryEvent>(_onLoadWealthHistory);
    on<AddManualAssetEvent>(_onAddManualAsset);
    on<AddAssetReminderEvent>(_onAddAssetReminder);
  }

  // ===========================================================================
  // NETWORTH & DASHBOARD
  // ===========================================================================

  Future<void> _onLoadNetworth(
    LoadNetworthEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await getNetworthUseCase(forceRefresh: event.forceRefresh);

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (networth) => emit(NetworthLoaded(networth)),
    );
  }

  Future<void> _onLoadDailyChange(
    LoadDailyChangeEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await getDailyChangeUseCase(const NoParams());

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (dailyChange) => emit(DailyChangeLoaded(dailyChange)),
    );
  }

  // ===========================================================================
  // ASSETS
  // ===========================================================================

  Future<void> _onLoadAssets(
    LoadAssetsEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await getAssetsUseCase.call(const NoParams());

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (assets) => emit(AssetsLoaded(assets)),
    );
  }

  Future<void> _onWatchAssets(
  WatchAssetsEvent event,
  Emitter<FinanceState> emit,
) async {
  await _assetsSubscription?.cancel();

  await emit.forEach<Either<Failure, List<Asset>>>(
    watchAssetsUseCase.call(), 
    onData: (result) {
      return result.fold(
        (failure) => FinanceError(failure.message),
        (assets) => AssetsWatching(assets),
      );
    },
    onError: (error, stackTrace) {
      return FinanceError('Stream error: $error');
    },
  );
}
  Future<void> _onStopWatchingAssets(
    StopWatchingAssetsEvent event,
    Emitter<FinanceState> emit,
  ) async {
    await _assetsSubscription?.cancel();
    _assetsSubscription = null;
  }

  Future<void> _onDeleteAsset(
    DeleteAssetEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await deleteAssetUseCase(DeleteAssetParams(assetId: event.assetId));

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (_) {
        emit(const AssetDeleted());
        add(const LoadAssetsEvent()); // Reload assets after deletion
      },
    );
  }

  Future<void> _onUpdateAssetQuantity(
    UpdateAssetQuantityEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await updateAssetQuantityUseCase(
      UpdateAssetQuantityParams(
        assetId: event.assetId,
        newQuantity: event.newQuantity,
      ),
    );

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (_) {
        emit(const AssetQuantityUpdated());
        add(const LoadAssetsEvent()); // Reload assets after update
      },
    );
  }

  // ===========================================================================
  // CRYPTO (MORALIS)
  // ===========================================================================

  Future<void> _onAddCryptoWallet(
    AddCryptoWalletEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await addCryptoWalletUseCase(
      AddCryptoWalletParams(walletAddress: event.walletAddress),
    );

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (_) {
        emit(const CryptoWalletAdded());
        add(const LoadNetworthEvent()); // Reload networth after adding wallet
      },
    );
  }

  // ===========================================================================
  // STOCKS (FMP)
  // ===========================================================================

  Future<void> _onSearchStocks(
    SearchStocksEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await searchStocksUseCase(
      SearchStocksParams(query: event.query),
    );

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (results) => emit(StockSearchResultsLoaded(results)),
    );
  }

  Future<void> _onAddStock(
    AddStockEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await addStockUseCase(
      AddStockParams(symbol: event.symbol, quantity: event.quantity),
    );

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (result) {
        emit(StockAdded(result));
        add(const LoadNetworthEvent()); // Reload networth after adding stock
      },
    );
  }

  // ===========================================================================
  // BANKING (PLAID)
  // ===========================================================================

  Future<void> _onGetPlaidLinkToken(
    GetPlaidLinkTokenEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await getPlaidLinkTokenUseCase(const NoParams());

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (tokenData) => emit(PlaidLinkTokenLoaded(tokenData)),
    );
  }

  Future<void> _onExchangePlaidToken(
    ExchangePlaidTokenEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await exchangePlaidTokenUseCase(
      ExchangePlaidTokenParams(publicToken: event.publicToken),
    );

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (result) {
        emit(PlaidTokenExchanged(result));
        add(const LoadNetworthEvent()); // Reload networth after connecting bank
      },
    );
  }

  // ===========================================================================
  // WEALTH HISTORY
  // ===========================================================================

  Future<void> _onLoadWealthHistory(
    LoadWealthHistoryEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await getWealthHistoryUseCase(
      GetWealthHistoryParams(limit: event.limit),
    );

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (snapshots) => emit(WealthHistoryLoaded(snapshots)),
    );
  }

  // ===========================================================================
  // MANUAL ASSETS
  // ===========================================================================

  Future<void> _onAddManualAsset(
    AddManualAssetEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    // Convert string type to AssetType enum
    AssetType assetType;
    switch (event.type.toLowerCase()) {
      case 'crypto':
        assetType = AssetType.crypto;
        break;
      case 'stock':
        assetType = AssetType.stock;
        break;
      case 'cash':
        assetType = AssetType.cash;
        break;
      case 'investment':
        assetType = AssetType.investment;
        break;
      case 'real_estate':
      case 'realestate':
        assetType = AssetType.realEstate;
        break;
      case 'commodity':
        assetType = AssetType.commodity;
        break;
      case 'liability':
        assetType = AssetType.liability;
        break;
      default:
        assetType = AssetType.other;
    }

    final result = await addManualAssetUseCase(
      AddManualAssetParams(
        name: event.name,
        type: assetType,
        amount: event.amount,
        currency: event.currency,
        sector: event.sector,
        country: event.country,
      ),
    );

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (_) {
        emit(const ManualAssetAdded());
        add(const LoadNetworthEvent()); // Reload networth after adding manual asset
      },
    );
  }

  // ===========================================================================
  // ASSET REMINDERS
  // ===========================================================================

  Future<void> _onAddAssetReminder(
    AddAssetReminderEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await addAssetReminderUseCase(
      AddAssetReminderParams(
        assetId: event.assetId,
        title: event.title,
        rruleExpression: event.rruleExpression,
        nextEventDate: event.nextEventDate,
        amountExpected: event.amountExpected,
      ),
    );

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (_) => emit(const AssetReminderAdded()),
    );
  }

  @override
  Future<void> close() {
    _assetsSubscription?.cancel();
    return super.close();
  }
}
