import 'package:equatable/equatable.dart';
import 'package:financo/features/auth/domain/entities/auth_user.dart';

/// Classe abstraite de base pour tous les états d'authentification.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// État initial avant toute vérification d'authentification.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// État pendant le chargement d'une opération d'authentification.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// État quand l'utilisateur est authentifié.
class Authenticated extends AuthState {
  final AuthUser user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// État quand l'utilisateur n'est pas authentifié.
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// État en cas d'erreur d'authentification.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
