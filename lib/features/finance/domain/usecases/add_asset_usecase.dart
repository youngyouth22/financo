import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/entities/asset.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for adding a new asset to the user's portfolio
///
/// Automatically adds crypto wallets to Moralis stream for real-time tracking.
class AddAssetUseCase implements UseCase<Asset, AddAssetParams> {
  final FinanceRepository repository;

  AddAssetUseCase(this.repository);

  @override
  Future<Either<Failure, Asset>> call(AddAssetParams params) async {
    return await repository.addAsset(
      name: params.name,
      type: params.type,
      assetGroup: params.assetGroup,
      provider: params.provider,
      assetAddressOrId: params.assetAddressOrId,
      initialBalance: params.initialBalance,
    );
  }
}

/// Parameters for AddAssetUseCase
class AddAssetParams extends Equatable {
  /// Display name for the asset
  final String name;

  /// Type of asset (crypto or bank)
  final AssetType type;

  /// Asset group for categorization
  final AssetGroup assetGroup;

  /// Provider (moralis or plaid)
  final AssetProvider provider;

  /// Wallet address or account ID
  final String assetAddressOrId;

  /// Initial balance (optional, defaults to 0.0)
  final double initialBalance;

  const AddAssetParams({
    required this.name,
    required this.type,
    required this.assetGroup,
    required this.provider,
    required this.assetAddressOrId,
    this.initialBalance = 0.0,
  });

  @override
  List<Object?> get props => [
        name,
        type,
        assetGroup,
        provider,
        assetAddressOrId,
        initialBalance,
      ];
}
