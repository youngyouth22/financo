import 'dart:async';
import 'package:financo/core/error/exceptions.dart';
import 'package:financo/features/auth/data/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

/// Interface définissant les opérations d'authentification distantes.
abstract class AuthRemoteDataSource {
  /// Authentifie l'utilisateur avec Google OAuth via Supabase.
  Future<UserModel> signInWithGoogle();

  /// Déconnecte l'utilisateur actuel.
  Future<void> signOut();

  /// Récupère l'utilisateur actuellement connecté.
  Future<UserModel?> getCurrentUser();

  /// Stream des changements d'état d'authentification.
  Stream<UserModel?> get authStateChanges;
}

/// Implémentation de la source de données distante d'authentification.
///
/// Utilise Supabase et Google Sign-In pour gérer l'authentification.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;
  final GoogleSignIn googleSignIn;

  AuthRemoteDataSourceImpl({
    required this.supabaseClient,
    required this.googleSignIn,
  });

  bool _isGoogleSignInInitialized = false;

  Future<void> _initializeGoogleSignIn() async {
    try {
      await dotenv.load(fileName: ".env");
      await googleSignIn.initialize(
        serverClientId: dotenv.env['WEB_CLIENT_AUTH']!,
      );
      _isGoogleSignInInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize Google Sign-In: $e');
    }
  }

  /// Always check Google sign in initialization before use
  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      await _initializeGoogleSignIn();
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      if (!_isGoogleSignInInitialized) {
        throw AuthException('Google is not initialize');
      }

      final googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw AuthException('Impossible de récupérer les tokens Google');
      }

      // Étape 3: Authentification avec Supabase en utilisant les tokens Google
      final response = await supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        // accessToken: accessToken,
      );

      if (response.user == null) {
        throw AuthException('Échec de l\'authentification avec Supabase');
      }

      // Étape 4: Conversion en UserModel
      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Failed to sign in with Google: $e');
      throw AuthException(
        'Erreur lors de la connexion Google: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Déconnexion de Google Sign-In
      await googleSignIn.signOut();

      // Déconnexion de Supabase
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw AuthException('Erreur lors de la déconnexion: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final User? currentUser = supabaseClient.auth.currentUser;

      if (currentUser == null) {
        return null;
      }

      return UserModel.fromSupabaseUser(currentUser);
    } catch (e) {
      throw AuthException(
        'Erreur lors de la récupération de l\'utilisateur: ${e.toString()}',
      );
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return supabaseClient.auth.onAuthStateChange.map((data) {
      final User? user = data.session?.user;
      return user != null ? UserModel.fromSupabaseUser(user) : null;
    });
  }
}
