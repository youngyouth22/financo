import 'package:equatable/equatable.dart';

/// Classe abstraite de base pour tous les événements d'authentification.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Événement déclenché pour vérifier l'état d'authentification actuel.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Événement déclenché pour se connecter avec Google.
class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

/// Événement déclenché pour se déconnecter.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Événement déclenché lors d'un changement d'état d'authentification.
class AuthStateChanged extends AuthEvent {
  final bool isAuthenticated;

  const AuthStateChanged(this.isAuthenticated);

  @override
  List<Object?> get props => [isAuthenticated];
}
