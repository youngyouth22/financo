import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecases/usecase.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for adding a crypto wallet to Moralis monitoring
class AddCryptoWalletUseCase implements UseCase<void, AddCryptoWalletParams> {
  final FinanceRepository repository;

  AddCryptoWalletUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddCryptoWalletParams params) {
    return repository.addCryptoWallet(params.walletAddress);
  }
}

class AddCryptoWalletParams extends Equatable {
  final String walletAddress;

  const AddCryptoWalletParams({required this.walletAddress});

  @override
  List<Object?> get props => [walletAddress];
}
