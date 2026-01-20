import 'package:equatable/equatable.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';

/// Base class for all finance-related events
abstract class FinanceEvent extends Equatable {
  const FinanceEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load global wealth data
class LoadGlobalWealthEvent extends FinanceEvent {
  const LoadGlobalWealthEvent();
}

/// Event to load all assets
class LoadAssetsEvent extends FinanceEvent {
  const LoadAssetsEvent();
}

/// Event to start watching assets for real-time updates
class WatchAssetsEvent extends FinanceEvent {
  const WatchAssetsEvent();
}

/// Event to stop watching assets
class StopWatchingAssetsEvent extends FinanceEvent {
  const StopWatchingAssetsEvent();
}

/// Event triggered when assets are updated in real-time
class AssetsUpdatedEvent extends FinanceEvent {
  final List<Asset> assets;

  const AssetsUpdatedEvent(this.assets);

  @override
  List<Object?> get props => [assets];
}

/// Event to add a new asset
class AddAssetEvent extends FinanceEvent {
  final String name;
  final AssetType type;
  final AssetProvider provider;
  final String assetAddressOrId;
  final double initialBalance;

  const AddAssetEvent({
    required this.name,
    required this.type,
    required this.provider,
    required this.assetAddressOrId,
    this.initialBalance = 0.0,
  });

  @override
  List<Object?> get props => [
        name,
        type,
        provider,
        assetAddressOrId,
        initialBalance,
      ];
}

/// Event to delete an asset
class DeleteAssetEvent extends FinanceEvent {
  final String assetId;

  const DeleteAssetEvent(this.assetId);

  @override
  List<Object?> get props => [assetId];
}

/// Event to load wealth history
class LoadWealthHistoryEvent extends FinanceEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? limit;

  const LoadWealthHistoryEvent({
    this.startDate,
    this.endDate,
    this.limit,
  });

  @override
  List<Object?> get props => [startDate, endDate, limit];
}

/// Event to sync assets manually (pull-to-refresh)
class SyncAssetsEvent extends FinanceEvent {
  const SyncAssetsEvent();
}

/// Event to calculate net worth
class CalculateNetWorthEvent extends FinanceEvent {
  const CalculateNetWorthEvent();
}
