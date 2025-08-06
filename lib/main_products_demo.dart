import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/products_management_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const ProductsManagementDemo());
}

class ProductsManagementDemo extends StatelessWidget {
  const ProductsManagementDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Products Management Demo',
      theme: AppTheme.darkTheme,
      home: const ProductsManagementScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
