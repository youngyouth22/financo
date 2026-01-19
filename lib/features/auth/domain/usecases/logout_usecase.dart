import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/auth/domain/repositories/auth_repository.dart';

/// Cas d'utilisation pour la déconnexion de l'utilisateur.
/// 
/// Ce UseCase encapsule la logique métier de déconnexion.
/// Il délègue l'implémentation technique au repository.
class LogoutUseCase implements UseCase<Unit, NoParams> {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    return await repository.signOut();
  }
}
