import 'package:dartz/dartz.dart';
import 'package:financo/core/error/failures.dart';

/// Classe abstraite de base pour tous les cas d'utilisation.
/// 
/// [Type] est le type de retour en cas de succès.
/// [Params] est le type des paramètres d'entrée.
abstract class UseCase<Type, Params> {
  /// Exécute le cas d'utilisation.
  /// 
  /// Retourne [Right(Type)] en cas de succès.
  /// Retourne [Left(Failure)] en cas d'échec.
  Future<Either<Failure, Type>> call(Params params);
}

/// Classe représentant l'absence de paramètres pour un UseCase.
class NoParams {
  const NoParams();
}
