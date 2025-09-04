import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Enhanced Firebase initialization with error handling for Metropolitan Investment
class FirebaseService {
  static bool _initialized = false;
  static bool _initializationFailed = false;

  /// Initialize Firebase with enhanced error handling
  static Future<void> initialize() async {
    if (_initialized) return;
    if (_initializationFailed) {
      print('Firebase initialization previously failed, skipping...');
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Configure Firebase Auth settings
      await _configureAuth();

      _initialized = true;
      print('Metropolitan Investment: Firebase initialized successfully');
    } catch (e) {
      _initializationFailed = true;
      print('Metropolitan Investment: Firebase initialization failed: $e');

      // Handle specific OAuth domain errors
      if (e.toString().contains('OAuth') || e.toString().contains('domain')) {
        print('''
╔══════════════════════════════════════════════════════════════════════════════╗
║                           FIREBASE OAUTH DOMAIN ERROR                       ║
║                                                                            ║
║  The domain 'metropolitan-investment.pl' is not authorized for OAuth       ║
║  operations in Firebase Console.                                           ║
║                                                                            ║
║  REQUIRED ACTION:                                                          ║
║  1. Go to Firebase Console                                                 ║
║  2. Navigate to: Authentication > Settings > Authorized domains           ║
║  3. Add the following domain:                                              ║
║     metropolitan-investment.pl                                             ║
║                                                                            ║
║  This will enable:                                                         ║
║  - Google Sign-In                                                          ║
║  - Facebook Sign-In                                                        ║
║  - Other OAuth providers                                                   ║
║                                                                            ║
║  Alternative: Use local authentication for development                     ║
╚══════════════════════════════════════════════════════════════════════════════╝
        ''');
      }

      // Re-throw to allow app to handle gracefully
      rethrow;
    }
  }

  /// Configure Firebase Auth with enhanced settings
  static Future<void> _configureAuth() async {
    final auth = FirebaseAuth.instance;

    // Configure auth settings
    try {
      // Set auth settings for better error handling
      await auth.setSettings(
        appVerificationDisabledForTesting: false,
        // Add other auth settings as needed
      );

      // Set up auth state change listener with error handling
      auth.authStateChanges().listen(
        (User? user) {
          if (user != null) {
            print('Metropolitan Investment: User signed in: ${user.email}');
          } else {
            print('Metropolitan Investment: User signed out');
          }
        },
        onError: (error) {
          print('Metropolitan Investment: Auth state change error: $error');

          // Handle OAuth domain errors specifically
          if (error.toString().contains('OAuth') || error.toString().contains('domain')) {
            print('Metropolitan Investment: OAuth domain authorization required');
          }
        },
      );

      // Set up ID token change listener
      auth.idTokenChanges().listen(
        (User? user) {
          // Handle token changes if needed
        },
        onError: (error) {
          print('Metropolitan Investment: ID token change error: $error');
        },
      );

    } catch (e) {
      print('Metropolitan Investment: Auth configuration failed: $e');
      // Don't re-throw auth config errors as they're not critical
    }
  }

  /// Enhanced sign-in method with OAuth error handling
  static Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      print('Metropolitan Investment: Email sign-in failed: $e');

      // Handle specific Firebase errors
      if (e.toString().contains('user-not-found')) {
        throw 'Użytkownik nie został znaleziony';
      } else if (e.toString().contains('wrong-password')) {
        throw 'Nieprawidłowe hasło';
      } else if (e.toString().contains('too-many-requests')) {
        throw 'Zbyt wiele prób logowania. Spróbuj ponownie później';
      } else if (e.toString().contains('network-request-failed')) {
        throw 'Problem z połączeniem internetowym';
      }

      rethrow;
    }
  }

  /// Enhanced sign-up method
  static Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      print('Metropolitan Investment: Email sign-up failed: $e');

      // Handle specific Firebase errors
      if (e.toString().contains('email-already-in-use')) {
        throw 'Ten adres email jest już używany';
      } else if (e.toString().contains('weak-password')) {
        throw 'Hasło jest zbyt słabe';
      } else if (e.toString().contains('invalid-email')) {
        throw 'Nieprawidłowy format adresu email';
      } else if (e.toString().contains('network-request-failed')) {
        throw 'Problem z połączeniem internetowym';
      }

      rethrow;
    }
  }

  /// Enhanced OAuth sign-in with domain error handling
  static Future<UserCredential?> signInWithOAuth(String provider) async {
    try {
      // This would be implemented based on the specific OAuth provider
      // For now, we'll just show the domain error message
      throw FirebaseAuthException(
        code: 'oauth-domain-error',
        message: '''
OAuth sign-in wymaga autoryzacji domeny w Firebase Console.

Przejdź do: Firebase Console > Authentication > Settings > Authorized domains
i dodaj domenę: metropolitan-investment.pl
        ''',
      );
    } catch (e) {
      print('Metropolitan Investment: OAuth sign-in failed: $e');
      rethrow;
    }
  }

  /// Check if Firebase is properly initialized
  static bool get isInitialized => _initialized;

  /// Check if initialization failed
  static bool get initializationFailed => _initializationFailed;

  /// Get current user safely
  static User? get currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (e) {
      print('Metropolitan Investment: Error getting current user: $e');
      return null;
    }
  }

  /// Sign out safely
  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      print('Metropolitan Investment: User signed out successfully');
    } catch (e) {
      print('Metropolitan Investment: Sign out failed: $e');
      rethrow;
    }
  }
}