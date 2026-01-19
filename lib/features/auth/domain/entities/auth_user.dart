import 'package:equatable/equatable.dart';

/// Entité représentant un utilisateur authentifié dans le domaine métier.
/// 
/// Cette entité est indépendante de toute implémentation technique et
/// représente le concept métier d'un utilisateur authentifié.
class AuthUser extends Equatable {
  /// Identifiant unique de l'utilisateur
  final String id;

  /// Adresse email de l'utilisateur
  final String email;

  /// Nom complet de l'utilisateur
  final String? name;

  /// URL de la photo de profil de l'utilisateur
  final String? photoUrl;

  const AuthUser({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [id, email, name, photoUrl];

  @override
  bool get stringify => true;
}
