import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/auth/domain/entities/auth_user.dart';
import 'package:financo/features/auth/domain/repositories/auth_repository.dart';

/// Cas d'utilisation pour récupérer l'utilisateur actuellement connecté.
/// 
/// Ce UseCase encapsule la logique métier de récupération de l'utilisateur courant.
/// Il délègue l'implémentation technique au repository.
class GetCurrentUserUseCase implements UseCase<AuthUser?, NoParams> {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  @override
  Future<Either<Failure, AuthUser?>> call(NoParams params) async {
    return await repository.getCurrentUser();
  }
}
