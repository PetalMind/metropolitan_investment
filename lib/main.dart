import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'widgets/auth_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup debug error handling
  if (kDebugMode) {
    // Enable detailed Firebase error logging
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
      
      // Check if it's a Firestore index error
      if (details.exception.toString().contains('firestore') && 
          details.exception.toString().contains('index')) {
        _logFirestoreIndexError(details.exception.toString());
      }
    };
  }

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    if (kDebugMode) {
      print('🚀 Firebase initialized successfully');
      print('📊 Debug mode enabled - Firestore errors will be logged');
      
      // Setup Firestore settings for development
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      // Setup additional Firestore debugging
      _setupFirestoreDebugging();
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('❌ Error initializing Firebase: $e');
      print('Stack trace: $stackTrace');
      
      // Check if it's a Firestore index error
      if (e.toString().contains('firestore') && e.toString().contains('index')) {
        _logFirestoreIndexError(e.toString());
      }
    }
  }

  runApp(
    provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: ProviderScope(child: const MetropolitanInvestmentApp()),
    ),
  );
}

/// Logs Firestore index errors with clickable links
void _logFirestoreIndexError(String error) {
  if (kDebugMode) {
    print('\n' + '=' * 80);
    print('🔥 FIRESTORE INDEX ERROR DETECTED 🔥');
    print('=' * 80);
    print('Error: $error');
    
    // Extract the index creation URL if present
    final RegExp urlRegex = RegExp(r'https://console\.firebase\.google\.com/[^\s]+');
    final Match? match = urlRegex.firstMatch(error);
    
    if (match != null) {
      final String indexUrl = match.group(0)!;
      print('\n🔗 KLIKNIJ TUTAJ ABY UTWORZYĆ INDEKS:');
      print('📋 URL: $indexUrl');
      print('\n📝 Instrukcje:');
      print('1. Kliknij powyższy link');
      print('2. Zaloguj się do Firebase Console');
      print('3. Zatwierdź utworzenie indeksu');
      print('4. Poczekaj na zakończenie procesu (może potrwać kilka minut)');
      print('5. Odśwież aplikację');
    } else {
      print('\n🔗 Aby utworzyć indeksy, przejdź do:');
      print('📋 https://console.firebase.google.com/project/metropolitan-investment/firestore/indexes');
    }
    
    print('\n💡 Tip: Indeksy są wymagane dla złożonych zapytań Firestore');
    print('💡 Możesz również wyłączyć wymaganie indeksów w trybie deweloperskim');
    print('💡 Dodaj: FirebaseFirestore.instance.disableNetwork() dla trybu offline');
    print('=' * 80 + '\n');
  }
}

/// Setup additional Firestore debugging
void _setupFirestoreDebugging() {
  if (kDebugMode) {
    // Monitor Firestore errors
    FirebaseFirestore.instance.snapshotsInSync().listen(
      (_) {
        // Snapshots are in sync - no action needed
      },
      onError: (error) {
        print('🔥 Firestore Sync Error: $error');
        if (error.toString().contains('index')) {
          _logFirestoreIndexError(error.toString());
        }
      },
    );
    
    print('🔧 Firestore debugging enabled');
    print('📡 Monitoring for index errors...');
    
    // Log the specific error from the attachment if we see it
    _logSpecificIndexError();
  }
}

/// Log the specific index error from the attachment
void _logSpecificIndexError() {
  if (kDebugMode) {
    print('\n' + '🔍' * 40);
    print('SPECIFIC FIRESTORE INDEX ERROR FROM ATTACHMENT:');
    print('🔍' * 40);
    
    final String specificError = '''
[cloud_firestore/failed-precondition] The query requires an index. You can create it here: 
https://console.firebase.google.com/v1/r/project/metropolitan-investment/firestore/indexes?create_composite=Cllwcm9qZWN0cy9tZXRyb3BvbGl0YW4taW52ZXN0bWVudC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvLUhRb0wyTnZCY3lJM3BiMjVIY205MWNHMHpZVzF6bG95WlpXMUwyWjZaVFl4WlhYQkNnWnVhMGRHYmhRbgpCWUc3OWJaV2xhWkVJRVEyVmhEYUVhb2JHZnpkRTNoV1VRQWRRbUNncEZZMzBBQg==''';
    
    print('Error details: $specificError');
    _logFirestoreIndexError(specificError);
    
    print('🔍' * 40 + '\n');
  }
}

class MetropolitanInvestmentApp extends StatelessWidget {
  const MetropolitanInvestmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metropolitan Investment',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      // Add error handling
      builder: (context, widget) {
        if (kDebugMode) {
          // Setup error handling for the app
          ErrorWidget.builder = (FlutterErrorDetails details) {
            // Log Firestore errors specifically
            if (details.exception.toString().contains('firestore') && 
                details.exception.toString().contains('index')) {
              _logFirestoreIndexError(details.exception.toString());
            }
            
            return Scaffold(
              backgroundColor: AppTheme.backgroundPrimary,
              body: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.errorPrimary),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppTheme.errorPrimary,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Wystąpił błąd aplikacji',
                        style: TextStyle(
                          color: AppTheme.errorPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sprawdź konsolę debugowania dla szczegółów',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      if (details.exception.toString().contains('firestore')) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.warningBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🔥 Błąd Firestore: Sprawdź konsolę dla linku do utworzenia indeksu',
                            style: TextStyle(
                              color: AppTheme.warningPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          };
        }
        return widget ?? const SizedBox.shrink();
      },
      // Używamy bezpośrednio AuthWrapper zamiast SplashScreen dla szybszego ładowania
      home: const AuthWrapper(),
    );
  }
}
