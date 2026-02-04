import 'package:equatable/equatable.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';
import 'package:financo/features/finance/domain/entities/networth_response.dart';
import 'package:financo/features/finance/domain/entities/wealth_snapshot.dart';

/// Base class for all Finance states
abstract class FinanceState extends Equatable {
  const FinanceState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class FinanceInitial extends FinanceState {
  const FinanceInitial();
}

/// Loading state
class FinanceLoading extends FinanceState {
  const FinanceLoading();
}

/// Error state
class FinanceError extends FinanceState {
  final String message;

  const FinanceError(this.message);

  @override
  List<Object?> get props => [message];
}

// ===========================================================================
// NETWORTH & DASHBOARD
// ===========================================================================

/// State when networth is loaded
class NetworthLoaded extends FinanceState {
  final NetworthResponse networth;

  const NetworthLoaded(this.networth);

  @override
  List<Object?> get props => [networth];
}

/// State when daily change is loaded
class DailyChangeLoaded extends FinanceState {
  final Map<String, dynamic> dailyChange;

  const DailyChangeLoaded(this.dailyChange);

  @override
  List<Object?> get props => [dailyChange];
}

// ===========================================================================
// ASSETS
// ===========================================================================

/// State when assets are loaded
class AssetsLoaded extends FinanceState {
  final List<Asset> assets;

  const AssetsLoaded(this.assets);

  @override
  List<Object?> get props => [assets];
}

/// State when assets are being watched (real-time)
class AssetsWatching extends FinanceState {
  final List<Asset> assets;

  const AssetsWatching(this.assets);

  @override
  List<Object?> get props => [assets];
}

/// State when an asset is deleted
class AssetDeleted extends FinanceState {
  const AssetDeleted();
}

/// State when asset quantity is updated
class AssetQuantityUpdated extends FinanceState {
  const AssetQuantityUpdated();
}

// ===========================================================================
// CRYPTO (MORALIS)
// ===========================================================================

/// State when crypto wallet is added
class CryptoWalletAdded extends FinanceState {
  const CryptoWalletAdded();
}

/// State when crypto wallet is removed
class CryptoWalletRemoved extends FinanceState {
  const CryptoWalletRemoved();
}

// ===========================================================================
// STOCKS (FMP)
// ===========================================================================

/// State when stock search results are loaded
class StockSearchResultsLoaded extends FinanceState {
  final List<dynamic> results;

  const StockSearchResultsLoaded(this.results);

  @override
  List<Object?> get props => [results];
}

/// State when stock is added
class StockAdded extends FinanceState {
  final Map<String, dynamic> result;

  const StockAdded(this.result);

  @override
  List<Object?> get props => [result];
}

/// State when stock prices are updated
class StockPricesUpdated extends FinanceState {
  final Map<String, dynamic> result;

  const StockPricesUpdated(this.result);

  @override
  List<Object?> get props => [result];
}

/// State when stock is removed
class StockRemoved extends FinanceState {
  const StockRemoved();
}

// ===========================================================================
// BANKING (PLAID)
// ===========================================================================

/// State when Plaid link token is loaded
class PlaidLinkTokenLoaded extends FinanceState {
  final Map<String, dynamic> tokenData;

  const PlaidLinkTokenLoaded(this.tokenData);

  @override
  List<Object?> get props => [tokenData];
}

/// State when Plaid token is exchanged
class PlaidTokenExchanged extends FinanceState {
  final Map<String, dynamic> result;

  const PlaidTokenExchanged(this.result);

  @override
  List<Object?> get props => [result];
}

/// State when bank accounts are synced
class BankAccountsSynced extends FinanceState {
  final Map<String, dynamic> result;

  const BankAccountsSynced(this.result);

  @override
  List<Object?> get props => [result];
}

// ===========================================================================
// WEALTH HISTORY
// ===========================================================================

/// State when wealth history is loaded
class WealthHistoryLoaded extends FinanceState {
  final List<WealthSnapshot> snapshots;

  const WealthHistoryLoaded(this.snapshots);

  @override
  List<Object?> get props => [snapshots];
}

// ===========================================================================
// PORTFOLIO INSIGHTS
// ===========================================================================

/// State when portfolio insights are loaded
class PortfolioInsightsLoaded extends FinanceState {
  final Map<String, dynamic> insights;

  const PortfolioInsightsLoaded(this.insights);

  @override
  List<Object?> get props => [insights];
}

// ===========================================================================
// MANUAL ASSETS
// ===========================================================================

/// State when manual asset is added
class ManualAssetAdded extends FinanceState {
  final String assetId;
  
  const ManualAssetAdded(this.assetId);
  
  @override
  List<Object?> get props => [assetId];
}

// ===========================================================================
// ASSET REMINDERS
// ===========================================================================

/// State when asset reminder is added
class AssetReminderAdded extends FinanceState {
  const AssetReminderAdded();
}
