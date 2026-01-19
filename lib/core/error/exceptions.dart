/// Exception de base pour toutes les exceptions de l'application.
class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception levée lors d'erreurs d'authentification.
class AuthException extends AppException {
  AuthException(super.message, {super.code});
}

/// Exception levée lors d'erreurs serveur.
class ServerException extends AppException {
  ServerException(super.message, {super.code});
}

/// Exception levée lors d'erreurs réseau.
class NetworkException extends AppException {
  NetworkException(super.message, {super.code});
}

/// Exception levée lors d'erreurs de cache.
class CacheException extends AppException {
  CacheException(super.message, {super.code});
}
