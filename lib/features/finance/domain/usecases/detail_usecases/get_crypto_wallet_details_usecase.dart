import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/entities/crypto_wallet_detail.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for fetching detailed crypto wallet information
class GetCryptoWalletDetailsUseCase
    implements UseCase<CryptoWalletDetail, CryptoWalletDetailsParams> {
  final FinanceRepository repository;

  GetCryptoWalletDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, CryptoWalletDetail>> call(
    CryptoWalletDetailsParams params,
  ) async {
    return await repository.getCryptoWalletDetails(
      address: params.address,
      chain: params.chain,
    );
  }
}

/// Parameters for GetCryptoWalletDetailsUseCase
class CryptoWalletDetailsParams extends Equatable {
  final String address;
  final String chain;

  const CryptoWalletDetailsParams({
    required this.address,
    this.chain = 'eth',
  });

  @override
  List<Object?> get props => [address, chain];
}
