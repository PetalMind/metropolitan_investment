import 'package:flutter/material.dart';
import 'lib/services/font_family_service.dart';

/// Test script to verify local fonts are properly loaded
void main() {
  runApp(FontTestApp());
}

class FontTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Font Test',
      home: FontTestScreen(),
    );
  }
}

class FontTestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localFonts = FontFamilyService.getLocalFonts();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Lokalnych Czcionek'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: localFonts.length,
        itemBuilder: (context, index) {
          final fontName = localFonts.keys.elementAt(index);
          
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Czcionka: $fontName',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'To jest przykładowy tekst w czcionce $fontName. '
                    'Test różnych znaków: ąćęłńóśźż ĄĆĘŁŃÓŚŹŻ 1234567890',
                    style: TextStyle(
                      fontFamily: fontName,
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'CSS: ${FontFamilyService.getCssFontFamily(fontName)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}