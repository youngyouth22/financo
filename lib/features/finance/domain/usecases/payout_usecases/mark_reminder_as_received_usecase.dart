import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';

/// Use case for marking a reminder as received
///
/// This creates a payout record and updates the reminder's next event date
/// based on the RRULE expression
class MarkReminderAsReceivedUseCase implements UseCase<void, MarkReminderAsReceivedParams> {
  final FinanceRepository repository;

  MarkReminderAsReceivedUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkReminderAsReceivedParams params) async {
    return await repository.markReminderAsReceived(
      reminderId: params.reminderId,
      assetId: params.assetId,
      amount: params.amount,
      payoutDate: params.payoutDate,
      notes: params.notes,
    );
  }
}

/// Parameters for MarkReminderAsReceivedUseCase
class MarkReminderAsReceivedParams {
  final String reminderId;
  final String assetId;
  final double amount;
  final DateTime payoutDate;
  final String? notes;

  const MarkReminderAsReceivedParams({
    required this.reminderId,
    required this.assetId,
    required this.amount,
    required this.payoutDate,
    this.notes,
  });
}
