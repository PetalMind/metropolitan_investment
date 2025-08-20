import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'theme/app_theme_professional.dart';
import 'providers/auth_provider.dart';
import 'config/app_routes.dart';
import 'services/calendar_notification_service.dart'; // 🚀 NOWE

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Polish locale for date formatting
    await initializeDateFormatting('pl_PL', null);

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Setup Firestore settings for production
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Setup Firebase Functions region
    FirebaseFunctions.instanceFor(region: 'europe-west1');

    // 🚀 NOWE: Inicjalizuj system powiadomień kalendarza
    await CalendarNotificationService().initialize();
  } catch (e) {
    // Silent fail for production
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

class MetropolitanInvestmentApp extends StatelessWidget {
  const MetropolitanInvestmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Metropolitan Investment',
      theme: AppThemePro.professionalTheme,
      darkTheme: AppThemePro.professionalTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pl', 'PL'),
        Locale('en', 'US'),
      ],
    );
  }
}
