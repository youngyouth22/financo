import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:financo/features/asset_details/presentation/bloc/asset_detail_event.dart';
import 'package:financo/features/asset_details/presentation/bloc/asset_detail_state.dart';
import 'package:financo/features/finance/domain/usecases/detail_usecases/get_crypto_wallet_details_usecase.dart';
import 'package:financo/features/finance/domain/usecases/detail_usecases/get_stock_details_usecase.dart';
import 'package:financo/features/finance/domain/usecases/detail_usecases/get_bank_account_details_usecase.dart';
import 'package:financo/features/finance/domain/usecases/detail_usecases/get_manual_asset_details_usecase.dart';

/// BLoC for managing asset detail state
class AssetDetailBloc extends Bloc<AssetDetailEvent, AssetDetailState> {
  final GetCryptoWalletDetailsUseCase getCryptoWalletDetailsUseCase;
  final GetStockDetailsUseCase getStockDetailsUseCase;
  final GetBankAccountDetailsUseCase getBankAccountDetailsUseCase;
  final GetManualAssetDetailsUseCase getManualAssetDetailsUseCase;

  AssetDetailEvent? _lastEvent;

  AssetDetailBloc({
    required this.getCryptoWalletDetailsUseCase,
    required this.getStockDetailsUseCase,
    required this.getBankAccountDetailsUseCase,
    required this.getManualAssetDetailsUseCase,
  }) : super(const AssetDetailInitial()) {
    on<LoadCryptoWalletDetailEvent>(_onLoadCryptoWalletDetail);
    on<LoadStockDetailEvent>(_onLoadStockDetail);
    on<LoadBankAccountDetailEvent>(_onLoadBankAccountDetail);
    on<LoadManualAssetDetailEvent>(_onLoadManualAssetDetail);
    on<RetryLoadDetailEvent>(_onRetryLoadDetail);
  }

  Future<void> _onLoadCryptoWalletDetail(
    LoadCryptoWalletDetailEvent event,
    Emitter<AssetDetailState> emit,
  ) async {
    _lastEvent = event;
    emit(const AssetDetailLoading());

    final result = await getCryptoWalletDetailsUseCase(
      CryptoWalletDetailsParams(
        address: event.address,
        chain: event.chain,
      ),
    );

    result.fold(
      (failure) => emit(AssetDetailError(failure.message, lastEvent: event)),
      (detail) => emit(CryptoWalletDetailLoaded(detail)),
    );
  }

  Future<void> _onLoadStockDetail(
    LoadStockDetailEvent event,
    Emitter<AssetDetailState> emit,
  ) async {
    _lastEvent = event;
    emit(const AssetDetailLoading());

    final result = await getStockDetailsUseCase(
      StockDetailsParams(
        symbol: event.symbol,
        userId: event.userId,
        timeframe: event.timeframe,
      ),
    );

    result.fold(
      (failure) => emit(AssetDetailError(failure.message, lastEvent: event)),
      (detail) => emit(StockDetailLoaded(detail)),
    );
  }

  Future<void> _onLoadBankAccountDetail(
    LoadBankAccountDetailEvent event,
    Emitter<AssetDetailState> emit,
  ) async {
    _lastEvent = event;
    emit(const AssetDetailLoading());

    final result = await getBankAccountDetailsUseCase(
      BankAccountDetailsParams(
        itemId: event.itemId,
        accountId: event.accountId,
        userId: event.userId,
      ),
    );

    result.fold(
      (failure) => emit(AssetDetailError(failure.message, lastEvent: event)),
      (detail) => emit(BankAccountDetailLoaded(detail)),
    );
  }

  Future<void> _onLoadManualAssetDetail(
    LoadManualAssetDetailEvent event,
    Emitter<AssetDetailState> emit,
  ) async {
    _lastEvent = event;
    emit(const AssetDetailLoading());

    final result = await getManualAssetDetailsUseCase(
      ManualAssetDetailsParams(
        assetId: event.assetId,
        userId: event.userId,
      ),
    );

    result.fold(
      (failure) => emit(AssetDetailError(failure.message, lastEvent: event)),
      (detail) => emit(ManualAssetDetailLoaded(detail)),
    );
  }

  Future<void> _onRetryLoadDetail(
    RetryLoadDetailEvent event,
    Emitter<AssetDetailState> emit,
  ) async {
    if (_lastEvent != null) {
      add(_lastEvent!);
    }
  }
}
