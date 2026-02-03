import 'package:equatable/equatable.dart';

/// Base class for AssetDetail events
abstract class AssetDetailEvent extends Equatable {
  const AssetDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load crypto wallet details
class LoadCryptoWalletDetailEvent extends AssetDetailEvent {
  final String address;
  final String chain;

  const LoadCryptoWalletDetailEvent({
    required this.address,
    this.chain = 'eth',
  });

  @override
  List<Object?> get props => [address, chain];
}

/// Event to load stock details
class LoadStockDetailEvent extends AssetDetailEvent {
  final String symbol;
  final String userId;
  final String timeframe;

  const LoadStockDetailEvent({
    required this.symbol,
    required this.userId,
    this.timeframe = '1hour',
  });

  @override
  List<Object?> get props => [symbol, userId, timeframe];
}

/// Event to load bank account details
class LoadBankAccountDetailEvent extends AssetDetailEvent {
  final String itemId;
  final String accountId;
  final String userId;

  const LoadBankAccountDetailEvent({
    required this.itemId,
    required this.accountId,
    required this.userId,
  });

  @override
  List<Object?> get props => [itemId, accountId, userId];
}

/// Event to load manual asset details
class LoadManualAssetDetailEvent extends AssetDetailEvent {
  final String assetId;
  final String userId;

  const LoadManualAssetDetailEvent({
    required this.assetId,
    required this.userId,
  });

  @override
  List<Object?> get props => [assetId, userId];
}

/// Event to retry loading after error
class RetryLoadDetailEvent extends AssetDetailEvent {
  const RetryLoadDetailEvent();
}
