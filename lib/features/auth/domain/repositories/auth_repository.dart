import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';
import 'package:financo/features/auth/domain/entities/auth_user.dart';

/// Interface du repository d'authentification.
/// 
/// Définit le contrat que doit respecter l'implémentation concrète
/// dans la couche Data. Utilise le type Either de Dartz pour une
/// gestion fonctionnelle des erreurs.
abstract class AuthRepository {
  /// Authentifie l'utilisateur avec Google OAuth.
  /// 
  /// Retourne [Right(AuthUser)] en cas de succès.
  /// Retourne [Left(Failure)] en cas d'échec.
  Future<Either<Failure, AuthUser>> signInWithGoogle();

  /// Déconnecte l'utilisateur actuel.
  /// 
  /// Retourne [Right(Unit)] en cas de succès.
  /// Retourne [Left(Failure)] en cas d'échec.
  Future<Either<Failure, Unit>> signOut();

  /// Récupère l'utilisateur actuellement connecté.
  /// 
  /// Retourne [Right(AuthUser)] si un utilisateur est connecté.
  /// Retourne [Right(null)] si aucun utilisateur n'est connecté.
  /// Retourne [Left(Failure)] en cas d'erreur.
  Future<Either<Failure, AuthUser?>> getCurrentUser();

  /// Stream qui émet les changements d'état d'authentification.
  /// 
  /// Émet [AuthUser] quand un utilisateur se connecte.
  /// Émet [null] quand un utilisateur se déconnecte.
  Stream<AuthUser?> get authStateChanges;
}
