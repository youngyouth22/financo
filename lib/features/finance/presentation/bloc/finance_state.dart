import 'package:equatable/equatable.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';
import 'package:financo/features/finance/domain/entities/global_wealth.dart';
import 'package:financo/features/finance/domain/entities/wealth_snapshot.dart';

/// Base class for all finance-related states
abstract class FinanceState extends Equatable {
  const FinanceState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class FinanceInitial extends FinanceState {
  const FinanceInitial();
}

/// State when data is being loaded
class FinanceLoading extends FinanceState {
  const FinanceLoading();
}

/// State when global wealth data is successfully loaded
class GlobalWealthLoaded extends FinanceState {
  final GlobalWealth globalWealth;
  final bool isWatching;

  const GlobalWealthLoaded({
    required this.globalWealth,
    this.isWatching = false,
  });

  @override
  List<Object?> get props => [globalWealth, isWatching];

  /// Create a copy with updated fields
  GlobalWealthLoaded copyWith({GlobalWealth? globalWealth, bool? isWatching}) {
    return GlobalWealthLoaded(
      globalWealth: globalWealth ?? this.globalWealth,
      isWatching: isWatching ?? this.isWatching,
    );
  }
}

/// State when assets are successfully loaded
class AssetsLoaded extends FinanceState {
  final List<Asset> assets;
  final bool isWatching;

  const AssetsLoaded({required this.assets, this.isWatching = false});

  @override
  List<Object?> get props => [assets, isWatching];

  /// Create a copy with updated fields
  AssetsLoaded copyWith({List<Asset>? assets, bool? isWatching}) {
    return AssetsLoaded(
      assets: assets ?? this.assets,
      isWatching: isWatching ?? this.isWatching,
    );
  }
}

/// State when wealth history is successfully loaded
class WealthHistoryLoaded extends FinanceState {
  final List<WealthSnapshot> snapshots;

  const WealthHistoryLoaded(this.snapshots);

  @override
  List<Object?> get props => [snapshots];
}

/// State when net worth is calculated
class NetWorthCalculated extends FinanceState {
  final double netWorth;

  const NetWorthCalculated(this.netWorth);

  @override
  List<Object?> get props => [netWorth];
}

/// State when an asset is successfully deleted
class AssetDeleted extends FinanceState {
  final String assetId;

  const AssetDeleted(this.assetId);

  @override
  List<Object?> get props => [assetId];
}

/// State when a crypto wallet is successfully added
class CryptoWalletAdded extends FinanceState {
  final String walletAddress;
  final String walletName;

  const CryptoWalletAdded({
    required this.walletAddress,
    required this.walletName,
  });

  @override
  List<Object?> get props => [walletAddress, walletName];
}

/// State when an error occurs
class FinanceError extends FinanceState {
  final String message;

  const FinanceError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when assets are updated in real-time
class AssetsRealTimeUpdated extends FinanceState {
  final List<Asset> assets;
  final DateTime updatedAt;

  const AssetsRealTimeUpdated({required this.assets, required this.updatedAt});

  @override
  List<Object?> get props => [assets, updatedAt];
}
