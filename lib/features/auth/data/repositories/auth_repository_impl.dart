import 'package:dartz/dartz.dart';
import 'package:financo/core/error/exceptions.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:financo/features/auth/domain/entities/auth_user.dart';
import 'package:financo/features/auth/domain/repositories/auth_repository.dart';

/// Implémentation concrète du repository d'authentification.
/// 
/// Cette classe fait le pont entre la couche Domain et la couche Data.
/// Elle gère la conversion des exceptions en Failures et des modèles en entités.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AuthUser>> signInWithGoogle() async {
    try {
      final userModel = await remoteDataSource.signInWithGoogle();
      return Right(userModel.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Erreur lors de la déconnexion: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AuthUser?>> getCurrentUser() async {
    try {
      final userModel = await remoteDataSource.getCurrentUser();
      return Right(userModel?.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Erreur lors de la récupération de l\'utilisateur: ${e.toString()}'));
    }
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    return remoteDataSource.authStateChanges.map(
      (userModel) => userModel?.toEntity(),
    );
  }
}
