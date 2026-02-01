import 'package:equatable/equatable.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';
import 'package:financo/features/assets/presentation/bloc/assets_event.dart';

/// States for AssetsBloc
abstract class AssetsState extends Equatable {
  const AssetsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AssetsInitial extends AssetsState {
  const AssetsInitial();
}

/// Loading state
class AssetsLoading extends AssetsState {
  const AssetsLoading();
}

/// Assets loaded successfully
class AssetsLoaded extends AssetsState {
  final List<Asset> assets;
  final AssetSortType? currentSort;
  final AssetType? currentFilter;

  const AssetsLoaded({
    required this.assets,
    this.currentSort,
    this.currentFilter,
  });

  @override
  List<Object?> get props => [assets, currentSort, currentFilter];

  /// Create a copy with updated values
  AssetsLoaded copyWith({
    List<Asset>? assets,
    AssetSortType? currentSort,
    AssetType? currentFilter,
    bool clearFilter = false,
  }) {
    return AssetsLoaded(
      assets: assets ?? this.assets,
      currentSort: currentSort ?? this.currentSort,
      currentFilter: clearFilter ? null : (currentFilter ?? this.currentFilter),
    );
  }
}

/// Assets real-time update
class AssetsRealTimeUpdated extends AssetsState {
  final List<Asset> assets;

  const AssetsRealTimeUpdated(this.assets);

  @override
  List<Object?> get props => [assets];
}

/// Asset added successfully
class AssetAdded extends AssetsState {
  final String message;

  const AssetAdded(this.message);

  @override
  List<Object?> get props => [message];
}

/// Asset updated successfully
class AssetUpdated extends AssetsState {
  final String message;

  const AssetUpdated(this.message);

  @override
  List<Object?> get props => [message];
}

/// Asset deleted successfully
class AssetDeleted extends AssetsState {
  final String message;

  const AssetDeleted(this.message);

  @override
  List<Object?> get props => [message];
}

/// Error state
class AssetsError extends AssetsState {
  final String message;
  final bool isOffline;

  const AssetsError(this.message, {this.isOffline = false});

  @override
  List<Object?> get props => [message, isOffline];
}
