import 'package:flutter/material.dart';
import 'lib/widgets/quill_email_editor.dart';

void main() {
  runApp(TestQuillApp());
}

class TestQuillApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Quill Editor with Preview',
      theme: ThemeData.dark(),
      home: TestQuillScreen(),
    );
  }
}

class TestQuillScreen extends StatefulWidget {
  @override
  _TestQuillScreenState createState() => _TestQuillScreenState();
}

class _TestQuillScreenState extends State<TestQuillScreen> {
  String _htmlContent = '';
  String _deltaContent = '';
  bool _showPreview = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Quill Editor with Delta → HTML'),
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showPreview = !_showPreview;
              });
            },
            tooltip: _showPreview ? 'Ukryj podgląd' : 'Pokaż podgląd',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header info
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🚀 Quill Email Editor z Delta JSON → HTML',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Delta: ${_deltaContent.length} chars | HTML: ${_htmlContent.length} chars',
                    style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Editor with optional preview
            Expanded(
              child: QuillEmailEditor(
                height: double.infinity,
                showPreview: _showPreview,
                autoUpdatePreview: true,
                onContentChanged: (html, deltaJson) {
                  setState(() {
                    _htmlContent = html;
                    _deltaContent = deltaJson;
                  });
                  print(
                    '📝 Content updated - HTML: ${html.length}, Delta: ${deltaJson.length}',
                  );
                },
                onReady: () {
                  print('� Quill Editor ready!');
                },
                onFocusChanged: (focused) {
                  print('🎯 Editor ${focused ? "focused" : "blurred"}');
                },
              ),
            ),

            // Debug info at bottom
            if (_deltaContent.isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delta JSON:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blue[300],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _deltaContent,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Colors.grey[300],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Test predefined content
          setState(() {
            _htmlContent =
                '<h1>Test</h1><p><strong>Bold text</strong> and <em>italic text</em></p>';
            _deltaContent =
                '{"ops":[{"insert":"Test","attributes":{"header":1}},{"insert":"\\n"},{"insert":"Bold text","attributes":{"bold":true}},{"insert":" and "},{"insert":"italic text","attributes":{"italic":true}},{"insert":"\\n"}]}';
          });
        },
        child: Icon(Icons.add),
        tooltip: 'Dodaj przykładową treść',
      ),
    );
  }
}
