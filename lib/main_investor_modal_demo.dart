import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/investor_modal_demo_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase może nie być skonfigurowane w środowisku demo
    print('Firebase nie został zainicjalizowany: $e');
  }

  runApp(const InvestorModalDemoApp());
}

class InvestorModalDemoApp extends StatelessWidget {
  const InvestorModalDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo - Rozszerzone funkcjonalności modalu inwestora',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: AppTheme.primaryColor,
          secondary: AppTheme.secondaryGold,
          surface: AppTheme.backgroundSecondary,
          background: AppTheme.backgroundPrimary,
          onSurface: AppTheme.textPrimary,
          onBackground: AppTheme.textPrimary,
        ),
        scaffoldBackgroundColor: AppTheme.backgroundPrimary,
        appBarTheme: AppBarTheme(
          backgroundColor: AppTheme.backgroundSecondary,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppTheme.backgroundSecondary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppTheme.backgroundSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.borderSecondary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.borderSecondary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor),
          ),
        ),
      ),
      home: const InvestorModalDemoScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
