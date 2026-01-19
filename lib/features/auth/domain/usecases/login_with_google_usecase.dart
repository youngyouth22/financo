import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/auth/domain/entities/auth_user.dart';
import 'package:financo/features/auth/domain/repositories/auth_repository.dart';

/// Cas d'utilisation pour l'authentification avec Google.
/// 
/// Ce UseCase encapsule la logique métier de connexion avec Google OAuth.
/// Il délègue l'implémentation technique au repository.
class LoginWithGoogleUseCase implements UseCase<AuthUser, NoParams> {
  final AuthRepository repository;

  LoginWithGoogleUseCase(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(NoParams params) async {
    return await repository.signInWithGoogle();
  }
}
