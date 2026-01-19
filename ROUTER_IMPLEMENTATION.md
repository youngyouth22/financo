# Go Router Implementation with Authentication

## 📋 Overview

This document describes the implementation of **go_router** for declarative navigation with automatic authentication-based redirects in the Financo application.

## 🏗️ Architecture

The router implementation follows Clean Architecture principles and integrates seamlessly with the AuthBloc to provide automatic navigation based on authentication state.

### Key Components

1. **AppRouter** (`lib/core/router/app_router.dart`)
   - Configures all application routes
   - Listens to AuthBloc state changes
   - Implements redirect logic based on authentication status

2. **GoRouterRefreshStream** (`lib/core/router/app_router.dart`)
   - Helper class that converts a Stream into a Listenable
   - Allows GoRouter to react to authentication state changes
   - Triggers automatic redirects when auth state changes

3. **Routes**
   - `/auth` - Authentication page (AuthPage)
   - `/` - Home page (AppShellPage) - requires authentication

## 🔄 Redirect Logic

The router implements the following redirect rules:

| Current State | Current Location | Redirect To | Reason |
|--------------|------------------|-------------|---------|
| `Authenticated` | `/auth` | `/` (home) | User is logged in, send to app |
| `Unauthenticated` | Any except `/auth` | `/auth` | User not logged in, send to auth |
| `AuthLoading` | Any | No redirect | Wait for auth check to complete |
| `AuthError` | Any | No redirect | Stay on current page, show error |

## 📱 Pages

### AuthPage (`lib/features/auth/presentation/pages/auth_page.dart`)

**Purpose**: User authentication interface

**Features**:
- Google Sign-In button with custom styling
- Loading state indicator during authentication
- Error message display with SnackBar
- Terms and privacy notice
- Responsive design with proper spacing

**BLoC Integration**:
- Uses `BlocConsumer` to listen and react to auth state
- Dispatches `AuthGoogleSignInRequested` event on button press
- Shows loading indicator when `AuthLoading` state is active
- Displays error messages when `AuthError` state is active

### AppShellPage (`lib/features/home/presentation/pages/app_shell_page.dart`)

**Purpose**: Main application hub for authenticated users

**Features**:
- User profile display in AppBar
- User avatar (from Google profile photo or initials)
- Popup menu with user info and logout option
- Welcome message with user name
- User information card showing:
  - Full name
  - Email address
  - User ID (truncated)
- Logout confirmation dialog

**BLoC Integration**:
- Uses `BlocBuilder` to access current user data
- Dispatches `AuthSignOutRequested` event on logout
- Automatically redirected to `/auth` when user signs out

## 🔧 Configuration

### 1. Add go_router Dependency

```yaml
dependencies:
  go_router: ^14.6.2
```

### 2. Update main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  await initializeDependencies();
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuthBloc>()..add(const AuthCheckRequested()),
      child: MaterialApp.router(
        routerConfig: AppRouter.createRouter(),
        // ... other properties
      ),
    );
  }
}
```

### 3. Router Configuration

The router is configured in `AppRouter.createRouter()`:

```dart
static GoRouter createRouter() {
  final authBloc = sl<AuthBloc>();

  return GoRouter(
    initialLocation: authRoute,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      // Redirect logic based on auth state
    },
    routes: [
      // Route definitions
    ],
  );
}
```

## 🎯 User Flow

### Login Flow

1. App starts → Router checks auth state
2. User is unauthenticated → Redirected to `/auth`
3. User sees AuthPage with Google Sign-In button
4. User clicks "Sign in with Google"
5. AuthBloc dispatches `AuthGoogleSignInRequested`
6. AuthPage shows loading indicator
7. Authentication succeeds → AuthBloc emits `Authenticated` state
8. Router detects state change → Automatically redirects to `/` (AppShellPage)
9. User sees welcome screen with their profile information

### Logout Flow

1. User is on AppShellPage (authenticated)
2. User clicks profile menu → Selects "Sign out"
3. Confirmation dialog appears
4. User confirms logout
5. AuthBloc dispatches `AuthSignOutRequested`
6. Authentication cleared → AuthBloc emits `Unauthenticated` state
7. Router detects state change → Automatically redirects to `/auth`
8. User sees AuthPage again

### Session Persistence

1. App starts → `AuthCheckRequested` event is dispatched
2. AuthBloc checks for existing session via `GetCurrentUserUseCase`
3. If session exists → Emits `Authenticated` state → User goes to AppShellPage
4. If no session → Emits `Unauthenticated` state → User stays on AuthPage

## 🔐 Security Considerations

- All authentication logic is handled by AuthBloc (Clean Architecture)
- Router only handles navigation, not authentication logic
- Session tokens are managed by Supabase (secure, httpOnly cookies)
- No sensitive data is stored in router state
- Automatic redirects prevent unauthorized access to protected routes

## 🎨 UI/UX Features

### AuthPage
- Clean, centered layout
- App branding (icon and name)
- Large, prominent Google Sign-In button
- Loading state with spinner
- Error messages with visual feedback
- Terms and privacy notice

### AppShellPage
- User profile in AppBar
- Avatar with fallback to initials
- Popup menu for user actions
- Welcome message personalization
- User info card with key details
- Logout confirmation dialog (prevents accidental logout)

## 🧪 Testing the Implementation

1. **Cold Start (No Session)**
   - Close and reopen app
   - Should land on AuthPage
   - Sign in with Google
   - Should redirect to AppShellPage

2. **Hot Start (Active Session)**
   - Sign in with Google
   - Close app (don't logout)
   - Reopen app
   - Should land directly on AppShellPage

3. **Logout**
   - From AppShellPage, click profile menu
   - Click "Sign out"
   - Confirm in dialog
   - Should redirect to AuthPage

4. **Error Handling**
   - Cancel Google Sign-In
   - Should show error message
   - Should stay on AuthPage

## 📂 File Structure

```
lib/
├── core/
│   └── router/
│       └── app_router.dart              # Router configuration
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       └── pages/
│   │           └── auth_page.dart       # Authentication UI
│   └── home/
│       └── presentation/
│           └── pages/
│               └── app_shell_page.dart  # Main app UI
└── main.dart                            # App entry point with router
```

## 🚀 Next Steps

1. Add more routes for different features (portfolio, transactions, etc.)
2. Implement nested navigation with ShellRoute
3. Add route guards for role-based access
4. Implement deep linking
5. Add route transitions and animations
6. Create a bottom navigation bar in AppShellPage
7. Add profile editing page
8. Implement settings page

## 📚 Resources

- [go_router Documentation](https://pub.dev/packages/go_router)
- [go_router with BLoC](https://codewithandrea.com/articles/flutter-navigation-gorouter-go-vs-push/)
- [Declarative Navigation in Flutter](https://docs.flutter.dev/ui/navigation)
