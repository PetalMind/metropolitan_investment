import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'lib/services/font_family_service.dart';
import 'lib/services/email_html_converter_service.dart';

/// Test konwersji Quill do HTML z lokalnymi czcionkami
void main() {
  runApp(HtmlConversionTestApp());
}

class HtmlConversionTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HTML Conversion Test',
      home: HtmlConversionTestScreen(),
    );
  }
}

class HtmlConversionTestScreen extends StatefulWidget {
  @override
  _HtmlConversionTestScreenState createState() => _HtmlConversionTestScreenState();
}

class _HtmlConversionTestScreenState extends State<HtmlConversionTestScreen> {
  late QuillController _controller;
  String _htmlOutput = '';
  String _previewHtml = '';

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    _setupTestContent();
    _convertToHtml();
    
    // Listen to content changes
    _controller.addListener(_convertToHtml);
  }

  void _setupTestContent() {
    final Document doc = Document();
    
    // Add test content
    doc.insert(0, 'Test konwersji do HTML:\n\n');
    doc.insert(doc.length - 1, 'Tekst w CrimsonText (serif)\n');
    doc.insert(doc.length - 1, 'Tekst w Montserrat (sans-serif)\n');  
    doc.insert(doc.length - 1, 'Tekst w Inter (modern sans)\n');
    doc.insert(doc.length - 1, 'Pogrubiony tekst\n');
    doc.insert(doc.length - 1, 'Kursywa tekst\n');
    doc.insert(doc.length - 1, 'Podkreślony tekst\n');
    
    // Apply font formatting
    int offset = 26; // After "Test konwersji do HTML:\n\n"
    doc.format(offset, 26, Attribute('font', 'CrimsonText'));
    offset += 27;
    doc.format(offset, 29, Attribute('font', 'Montserrat'));
    offset += 30;
    doc.format(offset, 23, Attribute('font', 'Inter'));
    offset += 24;
    doc.format(offset, 15, Attribute.bold);
    offset += 16;
    doc.format(offset, 13, Attribute.italic);
    offset += 14;
    doc.format(offset, 17, Attribute.underline);
    
    _controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  void _convertToHtml() {
    setState(() {
      _htmlOutput = EmailHtmlConverterService.convertQuillToHtml(_controller);
      _previewHtml = EmailHtmlConverterService.convertQuillToHtmlForPreview(_controller);
    });
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
        title: Text('Test Konwersji HTML + Czcionki'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Font info header
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lokalne czcionki:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(FontFamilyService.getFontFamilyNames().join(', ')),
                SizedBox(height: 8),
                Text('Test CSS mappingu:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('CrimsonText → ${FontFamilyService.getCssFontFamily('CrimsonText')}'),
                Text('Montserrat → ${FontFamilyService.getCssFontFamily('Montserrat')}'),
              ],
            ),
          ),
          
          Expanded(
            child: Row(
              children: [
                // Left side - Quill Editor
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        color: Colors.blue[50],
                        child: Text('Quill Editor', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      QuillSimpleToolbar(
                        controller: _controller,
                        config: QuillSimpleToolbarConfig(
                          showFontFamily: true,
                          showFontSize: true,
                          showColorButton: true,
                          multiRowsDisplay: false,
                        ),
                      ),
                      Expanded(
                        child: QuillEditor(
                          controller: _controller,
                          focusNode: FocusNode(),
                          scrollController: ScrollController(),
                          config: QuillEditorConfig(
                            padding: EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                VerticalDivider(width: 1),
                
                // Right side - HTML Output
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        color: Colors.green[50],
                        child: Text('HTML Output', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              TabBar(
                                tabs: [
                                  Tab(text: 'Email HTML'),
                                  Tab(text: 'Preview HTML'),
                                ],
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    // Email HTML
                                    SingleChildScrollView(
                                      padding: EdgeInsets.all(16),
                                      child: SelectableText(
                                        _htmlOutput,
                                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                                      ),
                                    ),
                                    // Preview HTML
                                    SingleChildScrollView(
                                      padding: EdgeInsets.all(16),
                                      child: SelectableText(
                                        _previewHtml,
                                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}