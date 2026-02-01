import 'package:equatable/equatable.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';

/// Events for AssetsBloc
/// 
/// Handles detailed list of assets (CRUD), real-time updates, sorting/filtering
abstract class AssetsEvent extends Equatable {
  const AssetsEvent();

  @override
  List<Object?> get props => [];
}

/// Load assets list
class LoadAssetsEvent extends AssetsEvent {
  const LoadAssetsEvent();
}

/// Watch assets for real-time updates
class WatchAssetsEvent extends AssetsEvent {
  const WatchAssetsEvent();
}

/// Stop watching assets
class StopWatchingAssetsEvent extends AssetsEvent {
  const StopWatchingAssetsEvent();
}

/// Add crypto wallet
class AddCryptoWalletEvent extends AssetsEvent {
  final String walletAddress;

  const AddCryptoWalletEvent(this.walletAddress);

  @override
  List<Object?> get props => [walletAddress];
}

/// Remove crypto wallet
class RemoveCryptoWalletEvent extends AssetsEvent {
  final String walletAddress;

  const RemoveCryptoWalletEvent(this.walletAddress);

  @override
  List<Object?> get props => [walletAddress];
}

/// Add stock
class AddStockEvent extends AssetsEvent {
  final String symbol;
  final double quantity;

  const AddStockEvent({required this.symbol, required this.quantity});

  @override
  List<Object?> get props => [symbol, quantity];
}

/// Remove stock
class RemoveStockEvent extends AssetsEvent {
  final String assetId;

  const RemoveStockEvent(this.assetId);

  @override
  List<Object?> get props => [assetId];
}

/// Update asset quantity
class UpdateAssetQuantityEvent extends AssetsEvent {
  final String assetId;
  final double newQuantity;

  const UpdateAssetQuantityEvent({
    required this.assetId,
    required this.newQuantity,
  });

  @override
  List<Object?> get props => [assetId, newQuantity];
}

/// Delete asset
class DeleteAssetEvent extends AssetsEvent {
  final String assetId;

  const DeleteAssetEvent(this.assetId);

  @override
  List<Object?> get props => [assetId];
}

/// Add manual asset
class AddManualAssetEvent extends AssetsEvent {
  final String name;
  final AssetType type;
  final double amount;
  final String? currency;
  final String? sector;
  final String? country;

  const AddManualAssetEvent({
    required this.name,
    required this.type,
    required this.amount,
    this.currency,
    this.sector,
    this.country,
  });

  @override
  List<Object?> get props => [name, type, amount, currency, sector, country];
}

/// Sort assets
class SortAssetsEvent extends AssetsEvent {
  final AssetSortType sortType;

  const SortAssetsEvent(this.sortType);

  @override
  List<Object?> get props => [sortType];
}

/// Filter assets by type
class FilterAssetsByTypeEvent extends AssetsEvent {
  final AssetType? filterType;

  const FilterAssetsByTypeEvent(this.filterType);

  @override
  List<Object?> get props => [filterType];
}

/// Asset sort types
enum AssetSortType {
  nameAsc,
  nameDesc,
  valueAsc,
  valueDesc,
  typeAsc,
  typeDesc,
}
