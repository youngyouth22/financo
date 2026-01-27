import 'package:equatable/equatable.dart';

/// Base class for all Finance events
abstract class FinanceEvent extends Equatable {
  const FinanceEvent();

  @override
  List<Object?> get props => [];
}

// ===========================================================================
// NETWORTH & DASHBOARD
// ===========================================================================

/// Event to load networth data
class LoadNetworthEvent extends FinanceEvent {
  final bool forceRefresh;

  const LoadNetworthEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Event to load daily change
class LoadDailyChangeEvent extends FinanceEvent {
  const LoadDailyChangeEvent();
}

// ===========================================================================
// ASSETS
// ===========================================================================

/// Event to load all assets
class LoadAssetsEvent extends FinanceEvent {
  const LoadAssetsEvent();
}

/// Event to start watching assets in real-time
class WatchAssetsEvent extends FinanceEvent {
  const WatchAssetsEvent();
}

/// Event to stop watching assets
class StopWatchingAssetsEvent extends FinanceEvent {
  const StopWatchingAssetsEvent();
}

/// Event to delete an asset
class DeleteAssetEvent extends FinanceEvent {
  final String assetId;

  const DeleteAssetEvent(this.assetId);

  @override
  List<Object?> get props => [assetId];
}

/// Event to update asset quantity
class UpdateAssetQuantityEvent extends FinanceEvent {
  final String assetId;
  final double newQuantity;

  const UpdateAssetQuantityEvent({
    required this.assetId,
    required this.newQuantity,
  });

  @override
  List<Object?> get props => [assetId, newQuantity];
}

// ===========================================================================
// CRYPTO (MORALIS)
// ===========================================================================

/// Event to add a crypto wallet
class AddCryptoWalletEvent extends FinanceEvent {
  final String walletAddress;

  const AddCryptoWalletEvent(this.walletAddress);

  @override
  List<Object?> get props => [walletAddress];
}

/// Event to remove a crypto wallet
class RemoveCryptoWalletEvent extends FinanceEvent {
  final String walletAddress;

  const RemoveCryptoWalletEvent(this.walletAddress);

  @override
  List<Object?> get props => [walletAddress];
}

// ===========================================================================
// STOCKS (FMP)
// ===========================================================================

/// Event to search stocks
class SearchStocksEvent extends FinanceEvent {
  final String query;

  const SearchStocksEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Event to add a stock
class AddStockEvent extends FinanceEvent {
  final String symbol;
  final double quantity;

  const AddStockEvent({
    required this.symbol,
    required this.quantity,
  });

  @override
  List<Object?> get props => [symbol, quantity];
}

/// Event to update stock prices
class UpdateStockPricesEvent extends FinanceEvent {
  const UpdateStockPricesEvent();
}

/// Event to remove a stock
class RemoveStockEvent extends FinanceEvent {
  final String assetId;

  const RemoveStockEvent(this.assetId);

  @override
  List<Object?> get props => [assetId];
}

// ===========================================================================
// BANKING (PLAID)
// ===========================================================================

/// Event to get Plaid link token
class GetPlaidLinkTokenEvent extends FinanceEvent {
  const GetPlaidLinkTokenEvent();
}

/// Event to exchange Plaid public token
class ExchangePlaidTokenEvent extends FinanceEvent {
  final String publicToken;

  const ExchangePlaidTokenEvent(this.publicToken);

  @override
  List<Object?> get props => [publicToken];
}

/// Event to sync bank accounts
class SyncBankAccountsEvent extends FinanceEvent {
  const SyncBankAccountsEvent();
}

// ===========================================================================
// WEALTH HISTORY
// ===========================================================================

/// Event to load wealth history
class LoadWealthHistoryEvent extends FinanceEvent {
  final int? limit;

  const LoadWealthHistoryEvent({this.limit});

  @override
  List<Object?> get props => [limit];
}

// ===========================================================================
// PORTFOLIO INSIGHTS
// ===========================================================================

/// Event to load portfolio insights
class LoadPortfolioInsightsEvent extends FinanceEvent {
  const LoadPortfolioInsightsEvent();
}
