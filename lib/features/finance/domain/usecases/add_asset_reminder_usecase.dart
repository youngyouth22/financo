import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for adding a reminder to an asset
///
/// Reminders are used for:
/// - Mortgage/loan payments (amortization)
/// - Bond coupon payments
/// - Dividend payments
/// - Rent collection
/// - Insurance premiums
/// 
/// Uses RRULE (RFC 5545) for recurring events
class AddAssetReminderUseCase implements UseCase<void, AddAssetReminderParams> {
  final FinanceRepository repository;

  AddAssetReminderUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddAssetReminderParams params) async {
    return await repository.addAssetReminder(
      assetId: params.assetId,
      title: params.title,
      rruleExpression: params.rruleExpression,
      nextEventDate: params.nextEventDate,
      amountExpected: params.amountExpected,
    );
  }
}

/// Parameters for AddAssetReminderUseCase
class AddAssetReminderParams {
  final String assetId;
  final String title;
  final String rruleExpression;
  final DateTime nextEventDate;
  final double? amountExpected;

  const AddAssetReminderParams({
    required this.assetId,
    required this.title,
    required this.rruleExpression,
    required this.nextEventDate,
    this.amountExpected,
  });
}
