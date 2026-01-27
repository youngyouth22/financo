import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';

/// Base class for all use cases
///
/// Type: Return type of the use case
/// Params: Parameters required by the use case
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case with no parameters
class NoParams {
  const NoParams();
}
