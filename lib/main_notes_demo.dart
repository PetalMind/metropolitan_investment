import 'package:flutter/material.dart';
import 'screens/client_notes_demo_screen.dart';

void main() {
  runApp(const ClientNotesApp());
}

class ClientNotesApp extends StatelessWidget {
  const ClientNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Client Notes Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ClientNotesDemo(),
      debugShowCheckedModeBanner: false,
    );
  }
}
