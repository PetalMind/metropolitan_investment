import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'lib/services/font_family_service.dart';

/// Test czy Flutter Quill używa lokalnych czcionek
void main() {
  runApp(QuillFontTestApp());
}

class QuillFontTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quill Font Test',
      home: QuillFontTestScreen(),
    );
  }
}

class QuillFontTestScreen extends StatefulWidget {
  @override
  _QuillFontTestScreenState createState() => _QuillFontTestScreenState();
}

class _QuillFontTestScreenState extends State<QuillFontTestScreen> {
  late QuillController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    
    // Dodaj przykładowy tekst z różnymi czcionkami
    final Document doc = Document()..compose(_controller.document.toDelta(), ChangeSource.local);
    
    // Tekst testowy
    doc.insert(0, 'Test różnych czcionek:\n\n');
    doc.insert(doc.length - 1, 'Ten tekst powinien być w domyślnej czcionce.\n');
    doc.insert(doc.length - 1, 'Ten tekst będzie w CrimsonText.\n');
    doc.insert(doc.length - 1, 'Ten tekst będzie w Montserrat.\n');
    doc.insert(doc.length - 1, 'Ten tekst będzie w Inter.\n');
    
    // Zastosuj formatowanie czcionek
    doc.format(68, 32, Attribute('font', 'CrimsonText')); // CrimsonText
    doc.format(101, 30, Attribute('font', 'Montserrat')); // Montserrat  
    doc.format(132, 25, Attribute('font', 'Inter')); // Inter
    
    _controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Flutter Quill + Lokalne Czcionki'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Informacje o lokalnych czcionkach
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dostępne lokalne czcionki:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(FontFamilyService.getFontFamilyNames().join(', ')),
              ],
            ),
          ),
          
          // Quill Toolbar
          QuillSimpleToolbar(
            controller: _controller,
            config: QuillSimpleToolbarConfig(
              showFontFamily: true,
              showFontSize: true,
              showColorButton: true,
              showBackgroundColorButton: true,
              multiRowsDisplay: false,
            ),
          ),
          
          Divider(height: 1),
          
          // Quill Editor
          Expanded(
            child: QuillEditor(
              controller: _controller,
              focusNode: FocusNode(),
              scrollController: ScrollController(),
              config: QuillEditorConfig(
                padding: EdgeInsets.all(16),
                customStyles: DefaultStyles(
                  paragraph: DefaultTextBlockStyle(
                    TextStyle(
                      fontSize: 16,
                      fontFamily: 'Inter', // Domyślna lokalna czcionka
                    ),
                    HorizontalSpacing.zero,
                    VerticalSpacing.zero,
                    VerticalSpacing.zero,
                    null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}