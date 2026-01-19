# Implémentation de l'Authentification Google avec Supabase

## 📋 Vue d'ensemble

Cette implémentation suit les principes de la **Clean Architecture** avec une séparation claire entre les couches Domain, Data et Presentation. L'authentification Google est gérée via **Supabase** et **Google Sign-In**, avec une gestion des erreurs fonctionnelle utilisant **Dartz** (type `Either<Failure, Success>`).

## 🏗️ Architecture

```
lib/
├── core/
│   ├── error/
│   │   ├── exceptions.dart          # Exceptions personnalisées
│   │   └── failures.dart            # Classes Failure pour Dartz
│   └── usecase/
│       └── usecase.dart             # Classe de base UseCase
├── di/
│   └── injection_container.dart     # Configuration Get_it
└── features/
    └── auth/
        ├── domain/
        │   ├── entities/
        │   │   └── auth_user.dart           # Entité AuthUser
        │   ├── repositories/
        │   │   └── auth_repository.dart     # Interface du repository
        │   └── usecases/
        │       ├── login_with_google_usecase.dart
        │       ├── logout_usecase.dart
        │       └── get_current_user_usecase.dart
        ├── data/
        │   ├── models/
        │   │   └── user_model.dart          # Modèle avec mappers
        │   ├── datasources/
        │   │   └── auth_remote_datasource.dart
        │   └── repositories/
        │       └── auth_repository_impl.dart
        └── presentation/
            └── bloc/
                ├── auth_bloc.dart           # BLoC principal
                ├── auth_event.dart          # Événements
                └── auth_state.dart          # États
```

## 🔑 Configuration requise

### 1. Fichier `.env`

Le fichier `.env` doit contenir les clés suivantes :

```env
# Configuration Supabase
SUPABASE_URL=https://votre-projet.supabase.co
SUPABASE_KEY=votre_cle_anon_publique

# Google Sign-In Config
ANDROID_CLIENT_AUTH=votre_client_id_android.apps.googleusercontent.com
IOS_CLIENT_AUTH=votre_client_id_ios.apps.googleusercontent.com
WEB_CLIENT_AUTH=votre_client_id_web.apps.googleusercontent.com
```

### 2. Configuration Supabase

Dans la console Supabase :

1. Allez dans **Authentication** > **Providers**
2. Activez **Google** comme provider OAuth
3. Configurez les **Client ID** et **Client Secret** de votre projet Google Cloud
4. Ajoutez les URLs de redirection autorisées

### 3. Configuration Google Cloud Console

1. Créez un projet dans [Google Cloud Console](https://console.cloud.google.com/)
2. Activez l'API **Google+ API**
3. Créez des identifiants OAuth 2.0 pour :
   - Application Web (WEB_CLIENT_AUTH)
   - Application Android (ANDROID_CLIENT_AUTH)
   - Application iOS (IOS_CLIENT_AUTH)

### 4. Configuration Android (`android/app/build.gradle`)

Ajoutez le plugin Google Services si nécessaire :

```gradle
dependencies {
    implementation 'com.google.android.gms:play-services-auth:20.7.0'
}
```

### 5. Configuration iOS (`ios/Runner/Info.plist`)

Ajoutez le schéma URL pour Google Sign-In :

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.VOTRE_CLIENT_ID_INVERSE</string>
        </array>
    </dict>
</array>
```

## 📦 Dépendances

Les dépendances suivantes ont été ajoutées au `pubspec.yaml` :

```yaml
dependencies:
  supabase_flutter: ^2.12.0
  google_sign_in: ^7.2.0
  dartz: ^0.10.1
  get_it: ^8.0.3
  flutter_dotenv: ^5.2.1
  flutter_secure_storage: ^9.2.2
  equatable: ^2.0.7
  flutter_bloc: ^8.1.6
  bloc: ^8.1.4
```

## 🚀 Utilisation

### Initialisation

L'initialisation est automatique au démarrage de l'application dans `main.dart` :

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Chargement des variables d'environnement
  await dotenv.load(fileName: ".env");
  
  // Initialisation des dépendances
  await initializeDependencies();
  
  runApp(const MainApp());
}
```

### Utilisation du AuthBloc dans l'UI

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:financo/di/injection_container.dart';
import 'package:financo/features/auth/presentation/bloc/auth_bloc.dart';

// Dans votre widget principal
BlocProvider(
  create: (context) => sl<AuthBloc>()..add(const AuthCheckRequested()),
  child: YourApp(),
)

// Dans une page de connexion
BlocConsumer<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is Authenticated) {
      // Naviguer vers la page d'accueil
    } else if (state is AuthError) {
      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  builder: (context, state) {
    if (state is AuthLoading) {
      return const CircularProgressIndicator();
    }
    
    return ElevatedButton(
      onPressed: () {
        context.read<AuthBloc>().add(const AuthGoogleSignInRequested());
      },
      child: const Text('Se connecter avec Google'),
    );
  },
)

// Pour se déconnecter
context.read<AuthBloc>().add(const AuthSignOutRequested());
```

## 🔄 Flux d'authentification

### Connexion avec Google

1. L'utilisateur clique sur le bouton de connexion
2. L'événement `AuthGoogleSignInRequested` est envoyé au BLoC
3. Le BLoC appelle le `LoginWithGoogleUseCase`
4. Le UseCase délègue au `AuthRepository`
5. Le Repository appelle le `AuthRemoteDataSource`
6. Le DataSource :
   - Ouvre le flux Google Sign-In
   - Récupère les tokens d'authentification Google
   - Authentifie l'utilisateur avec Supabase via `signInWithIdToken`
7. Le résultat remonte la chaîne et le BLoC émet l'état `Authenticated`

### Déconnexion

1. L'événement `AuthSignOutRequested` est envoyé au BLoC
2. Le BLoC appelle le `LogoutUseCase`
3. Le DataSource déconnecte l'utilisateur de Google Sign-In et Supabase
4. Le BLoC émet l'état `Unauthenticated`

### Vérification de l'état

Le BLoC écoute automatiquement les changements d'état d'authentification via le stream `authStateChanges` de Supabase.

## 🧪 Tests

Pour tester l'implémentation :

1. **Test de connexion** : Vérifiez que l'utilisateur peut se connecter avec son compte Google
2. **Test de déconnexion** : Vérifiez que l'utilisateur peut se déconnecter
3. **Test de persistance** : Vérifiez que l'utilisateur reste connecté après redémarrage de l'app
4. **Test d'erreur** : Vérifiez la gestion des erreurs (annulation, échec réseau, etc.)

## 📝 États du BLoC

- **AuthInitial** : État initial avant toute vérification
- **AuthLoading** : Chargement en cours
- **Authenticated** : Utilisateur connecté (contient l'objet `AuthUser`)
- **Unauthenticated** : Utilisateur non connecté
- **AuthError** : Erreur d'authentification (contient le message d'erreur)

## 🎯 Événements du BLoC

- **AuthCheckRequested** : Vérifier l'état d'authentification actuel
- **AuthGoogleSignInRequested** : Se connecter avec Google
- **AuthSignOutRequested** : Se déconnecter
- **AuthStateChanged** : Changement d'état d'authentification (interne)

## 🔐 Sécurité

- Les tokens d'authentification sont gérés automatiquement par Supabase
- Les clés sensibles sont stockées dans le fichier `.env` (ne pas commiter)
- L'authentification utilise OAuth 2.0 avec PKCE
- Les sessions sont sécurisées et gérées côté serveur par Supabase

## 📚 Ressources

- [Documentation Supabase Auth](https://supabase.com/docs/guides/auth)
- [Documentation Google Sign-In Flutter](https://pub.dev/packages/google_sign_in)
- [Documentation Flutter Bloc](https://bloclibrary.dev/)
- [Documentation Dartz](https://pub.dev/packages/dartz)

## ✅ Prochaines étapes

1. Créer l'interface utilisateur pour les pages de connexion/inscription
2. Implémenter la navigation conditionnelle (connecté/non connecté)
3. Ajouter la gestion du profil utilisateur
4. Implémenter la synchronisation des données utilisateur avec Supabase
5. Ajouter des tests unitaires et d'intégration
