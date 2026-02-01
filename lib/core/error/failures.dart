import 'package:equatable/equatable.dart';

/// Classe abstraite représentant un échec dans l'application.
/// 
/// Utilisée avec le type Either<Failure, Success> de Dartz pour
/// une gestion fonctionnelle des erreurs.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Échec lié à l'authentification
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Échec lié au serveur
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Échec lié à la connexion réseau
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Échec lié au cache local
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Échec lié à l'absence de connexion internet
class OfflineFailure extends Failure {
  const OfflineFailure(super.message);
}

/// Échec générique
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
