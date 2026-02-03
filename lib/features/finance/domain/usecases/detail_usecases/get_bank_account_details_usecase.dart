import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/entities/bank_account_detail.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for fetching detailed bank account information
class GetBankAccountDetailsUseCase
    implements UseCase<BankAccountDetail, BankAccountDetailsParams> {
  final FinanceRepository repository;

  GetBankAccountDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, BankAccountDetail>> call(
    BankAccountDetailsParams params,
  ) async {
    return await repository.getBankAccountDetails(
      itemId: params.itemId,
      accountId: params.accountId,
      userId: params.userId,
    );
  }
}

/// Parameters for GetBankAccountDetailsUseCase
class BankAccountDetailsParams extends Equatable {
  final String itemId;
  final String accountId;
  final String userId;

  const BankAccountDetailsParams({
    required this.itemId,
    required this.accountId,
    required this.userId,
  });

  @override
  List<Object?> get props => [itemId, accountId, userId];
}
