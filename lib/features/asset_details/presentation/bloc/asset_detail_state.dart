import 'package:equatable/equatable.dart';
import 'package:financo/features/finance/domain/entities/crypto_wallet_detail.dart';
import 'package:financo/features/finance/domain/entities/stock_detail.dart';
import 'package:financo/features/finance/domain/entities/bank_account_detail.dart';
import 'package:financo/features/finance/domain/entities/manual_asset_detail.dart';

/// Base class for AssetDetail states
abstract class AssetDetailState extends Equatable {
  const AssetDetailState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AssetDetailInitial extends AssetDetailState {
  const AssetDetailInitial();
}

/// Loading state with shimmer
class AssetDetailLoading extends AssetDetailState {
  const AssetDetailLoading();
}

/// Crypto wallet detail loaded
class CryptoWalletDetailLoaded extends AssetDetailState {
  final CryptoWalletDetail detail;

  const CryptoWalletDetailLoaded(this.detail);

  @override
  List<Object?> get props => [detail];
}

/// Stock detail loaded
class StockDetailLoaded extends AssetDetailState {
  final StockDetail detail;

  const StockDetailLoaded(this.detail);

  @override
  List<Object?> get props => [detail];
}

/// Bank account detail loaded
class BankAccountDetailLoaded extends AssetDetailState {
  final BankAccountDetail detail;

  const BankAccountDetailLoaded(this.detail);

  @override
  List<Object?> get props => [detail];
}

/// Manual asset detail loaded
class ManualAssetDetailLoaded extends AssetDetailState {
  final ManualAssetDetail detail;

  const ManualAssetDetailLoaded(this.detail);

  @override
  List<Object?> get props => [detail];
}

/// Error state with retry capability
class AssetDetailError extends AssetDetailState {
  final String message;
  final AssetDetailEvent? lastEvent;

  const AssetDetailError(this.message, {this.lastEvent});

  @override
  List<Object?> get props => [message, lastEvent];
}
