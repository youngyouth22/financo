import 'package:financo/features/auth/domain/entities/auth_user.dart' as user_entity;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modèle de données représentant un utilisateur.
/// 
/// Ce modèle est utilisé dans la couche Data pour la sérialisation/désérialisation
/// des données provenant de Supabase. Il peut être converti en entité AuthUser
/// pour la couche Domain.
class UserModel extends user_entity.AuthUser {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    super.photoUrl,
  });

  /// Crée un UserModel à partir d'un User Supabase.
  factory UserModel.fromSupabaseUser(User user) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['full_name'] as String? ?? 
            user.userMetadata?['name'] as String?,
      photoUrl: user.userMetadata?['avatar_url'] as String? ?? 
                user.userMetadata?['picture'] as String?,
    );
  }

  /// Crée un UserModel à partir d'un Map JSON.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }

  /// Convertit le UserModel en Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photo_url': photoUrl,
    };
  }

  /// Convertit le UserModel en entité AuthUser.
  user_entity.AuthUser toEntity() {
    return user_entity.AuthUser(
      id: id,
      email: email,
      name: name,
      photoUrl: photoUrl,
    );
  }

  /// Crée un UserModel à partir d'une entité AuthUser.
  factory UserModel.fromEntity(user_entity.AuthUser entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      photoUrl: entity.photoUrl,
    );
  }
}
