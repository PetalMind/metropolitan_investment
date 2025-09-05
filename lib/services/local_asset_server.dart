import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

/// Local HTTP server for serving TinyMCE assets
class LocalAssetServer {
  static LocalAssetServer? _instance;
  static LocalAssetServer get instance => _instance ??= LocalAssetServer._();

  LocalAssetServer._();

  HttpServer? _server;
  bool _isRunning = false;

  /// Start the local server
  Future<bool> start() async {
    if (_isRunning) return true;

    try {
      final handler = Cascade()
          .add(_createStaticHandler())
          .add(_createEditorHandler())
          .handler;

      _server = await io.serve(handler, 'localhost', 8080);
      _isRunning = true;

      if (kDebugMode) {
        print('🌐 Local asset server started at http://localhost:8080');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to start local asset server: $e');
      }
      return false;
    }
  }

  /// Stop the local server
  Future<void> stop() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      _isRunning = false;

      if (kDebugMode) {
        print('🛑 Local asset server stopped');
      }
    }
  }

  bool get isRunning => _isRunning;

  /// Create handler for static assets (TinyMCE files)
  Handler _createStaticHandler() {
    return (Request request) async {
      final path = request.url.path;

      try {
        // Handle TinyMCE assets
        if (path.startsWith('tinymce/')) {
          final assetPath = 'assets/$path';
          final content = await rootBundle.load(assetPath);
          final bytes = content.buffer.asUint8List();

          // Determine content type
          String contentType = 'application/octet-stream';
          if (path.endsWith('.js')) {
            contentType = 'application/javascript';
          } else if (path.endsWith('.css')) {
            contentType = 'text/css';
          } else if (path.endsWith('.json')) {
            contentType = 'application/json';
          } else if (path.endsWith('.html')) {
            contentType = 'text/html';
          } else if (path.endsWith('.woff') || path.endsWith('.woff2')) {
            contentType = 'font/woff';
          } else if (path.endsWith('.ttf')) {
            contentType = 'font/ttf';
          } else if (path.endsWith('.svg')) {
            contentType = 'image/svg+xml';
          } else if (path.endsWith('.png')) {
            contentType = 'image/png';
          } else if (path.endsWith('.ico')) {
            contentType = 'image/x-icon';
          }

          return Response.ok(
            bytes,
            headers: {
              'Content-Type': contentType,
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
              'Access-Control-Allow-Headers': 'Content-Type',
            },
          );
        }

        return Response.notFound('Asset not found: $path');
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error serving asset $path: $e');
        }
        return Response.notFound('Asset not found: $path');
      }
    };
  }

  /// Create handler for the editor HTML page
  Handler _createEditorHandler() {
    return (Request request) async {
      final path = request.url.path;

      if (path == 'editor.html' || path == '') {
        final html = _buildEditorHTML();

        return Response.ok(
          html,
          headers: {
            'Content-Type': 'text/html; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type',
          },
        );
      }

      return Response.notFound('Page not found: $path');
    };
  }

  /// Build the editor HTML content
  String _buildEditorHTML() {
    return '''
<!DOCTYPE html>
<html lang="pl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Metropolitan Investment - Email Editor</title>
    <script src="/tinymce/tinymce.min.js"></script>
    <style>
        body {
            margin: 0;
            padding: 8px;
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
            background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);
            color: #ffffff;
            overflow: hidden;
        }
        
        .editor-container {
            width: 100%;
            height: calc(100vh - 16px);
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 8px 32px rgba(212, 175, 55, 0.2);
            background: rgba(45, 45, 45, 0.9);
            backdrop-filter: blur(20px);
            border: 1px solid rgba(212, 175, 55, 0.2);
        }
        
        /* TinyMCE Custom Styling */
        .tox.tox-tinymce {
            border: none !important;
            border-radius: 12px !important;
            background: transparent !important;
        }
        
        .tox .tox-toolbar-overlord {
            background: linear-gradient(135deg, #2d2d2d 0%, #1a1a1a 100%) !important;
            border-bottom: 1px solid rgba(212, 175, 55, 0.3) !important;
        }
        
        .tox .tox-toolbar {
            background: transparent !important;
            border: none !important;
        }
        
        .tox .tox-tbtn {
            background: transparent !important;
            color: #ffffff !important;
            border-radius: 6px !important;
            margin: 2px !important;
            transition: all 0.2s ease !important;
        }
        
        .tox .tox-tbtn:hover,
        .tox .tox-tbtn--enabled {
            background: rgba(212, 175, 55, 0.2) !important;
            color: #d4af37 !important;
        }
        
        .tox .tox-edit-area__iframe {
            background: #ffffff !important;
        }
        
        .tox .tox-statusbar {
            background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%) !important;
            border-top: 1px solid rgba(212, 175, 55, 0.3) !important;
            color: #ffffff !important;
        }
    </style>
</head>
<body>
    <div class="editor-container">
        <textarea id="email-editor"></textarea>
    </div>

    <script>
        let editor = null;
        let isEditorReady = false;
        let contentChangeTimeout = null;

        // TinyMCE Configuration (Self-hosted - no API key needed)
        tinymce.init({
            selector: '#email-editor',
            // No api_key needed for self-hosted version
            height: '100%',
            resize: false,
            menubar: false,
            statusbar: true,
            branding: false,
            
            // Essential plugins for email editing
            plugins: [
                'advlist', 'autolink', 'lists', 'link', 'image', 'charmap',
                'preview', 'anchor', 'searchreplace', 'visualblocks', 'code',
                'fullscreen', 'insertdatetime', 'media', 'table', 'help',
                'wordcount', 'emoticons', 'autosave', 'directionality'
            ],
            
            // Professional toolbar for email editing
            toolbar: [
                'undo redo | formatselect fontselect fontsizeselect | bold italic underline strikethrough',
                'forecolor backcolor | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent',
                'link image media table | charmap emoticons | preview code fullscreen help'
            ],
            
            // Font options suitable for emails
            font_formats: 'Arial=arial,helvetica,sans-serif;' +
                         'Times New Roman=times new roman,times,serif;' +
                         'Courier New=courier new,courier,monospace;' +
                         'Georgia=georgia,serif;' +
                         'Verdana=verdana,geneva,sans-serif;' +
                         'Trebuchet MS=trebuchet ms,geneva,sans-serif;' +
                         'Tahoma=tahoma,arial,helvetica,sans-serif;' +
                         'Inter=Inter,system-ui,sans-serif;' +
                         'Open Sans=Open Sans,sans-serif;' +
                         'Roboto=Roboto,sans-serif;' +
                         'Lato=Lato,sans-serif;' +
                         'Montserrat=Montserrat,sans-serif',
            
            // Font sizes in px for better email compatibility
            fontsize_formats: '10px 11px 12px 14px 16px 18px 20px 24px 28px 32px 36px 48px',
            
            // Content styling
            content_css: [
                'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap',
                'https://fonts.googleapis.com/css2?family=Open+Sans:wght@400;600;700&display=swap',
                'https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap',
                'https://fonts.googleapis.com/css2?family=Lato:wght@400;700&display=swap',
                'https://fonts.googleapis.com/css2?family=Montserrat:wght@400;600;700&display=swap'
            ],
            
            // Email-specific settings
            content_style: \`
                body { 
                    font-family: Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif; 
                    font-size: 16px; 
                    line-height: 1.6; 
                    color: #333333; 
                    background-color: #ffffff;
                    margin: 16px;
                    padding: 0;
                }
                h1, h2, h3, h4, h5, h6 { 
                    color: #2c2c2c; 
                    margin-top: 1.2em; 
                    margin-bottom: 0.8em; 
                }
                p { 
                    margin: 0 0 1em 0; 
                }
                a { 
                    color: #d4af37; 
                    text-decoration: underline; 
                }
                table { 
                    border-collapse: collapse; 
                    width: 100%; 
                }
                table td, table th { 
                    border: 1px solid #ddd; 
                    padding: 8px; 
                }
                table th { 
                    background-color: #f2f2f2; 
                    font-weight: bold; 
                }
                .signature { 
                    margin-top: 2em; 
                    padding-top: 1em; 
                    border-top: 1px solid #e0e0e0; 
                    color: #666; 
                }
            \`,
            
            // Advanced configuration
            entity_encoding: 'raw',
            verify_html: false,
            convert_urls: false,
            remove_script_host: false,
            document_base_url: 'http://localhost:8080/',
            
            // Editor lifecycle callbacks
            setup: function(ed) {
                editor = ed;
                
                // Hide loading overlay when editor is ready
                ed.on('init', function() {
                    setTimeout(() => {
                        isEditorReady = true;
                        notifyFlutter('editor:ready', { ready: true });
                    }, 500);
                });
                
                // Content change detection with debouncing
                ed.on('input keyup paste', function() {
                    clearTimeout(contentChangeTimeout);
                    contentChangeTimeout = setTimeout(() => {
                        if (isEditorReady) {
                            const content = ed.getContent();
                            notifyFlutter('content:changed', { 
                                html: content,
                                plainText: ed.getContent({ format: 'text' }),
                                wordCount: ed.plugins.wordcount.getCount()
                            });
                        }
                    }, 300);
                });
                
                // Focus/blur events
                ed.on('focus', function() {
                    notifyFlutter('editor:focus', { focused: true });
                });
                
                ed.on('blur', function() {
                    notifyFlutter('editor:blur', { focused: false });
                });
            }
        });

        // Flutter communication functions
        function notifyFlutter(type, data) {
            if (window.flutter_inappwebview) {
                window.flutter_inappwebview.callHandler(type, data);
            }
        }

        // JavaScript functions callable from Flutter
        window.setContent = function(content) {
            if (editor && isEditorReady) {
                editor.setContent(content);
                return true;
            }
            return false;
        };

        window.getContent = function() {
            if (editor && isEditorReady) {
                return editor.getContent();
            }
            return '';
        };

        window.getPlainText = function() {
            if (editor && isEditorReady) {
                return editor.getContent({ format: 'text' });
            }
            return '';
        };

        window.insertContent = function(content) {
            if (editor && isEditorReady) {
                editor.insertContent(content);
                return true;
            }
            return false;
        };

        window.insertTextAtCursor = function(text) {
            if (editor && isEditorReady) {
                editor.insertContent(text);
                return true;
            }
            return false;
        };

        window.clearContent = function() {
            if (editor && isEditorReady) {
                editor.setContent('');
                return true;
            }
            return false;
        };

        window.focusEditor = function() {
            if (editor && isEditorReady) {
                editor.focus();
                return true;
            }
            return false;
        };

        window.getWordCount = function() {
            if (editor && isEditorReady && editor.plugins.wordcount) {
                return editor.plugins.wordcount.getCount();
            }
            return 0;
        };

        // Template insertion functions
        window.insertGreeting = function() {
            const greeting = '<p><br/>Szanowni Państwo,<br/><br/></p>';
            return window.insertContent(greeting);
        };

        window.insertSignature = function(senderName = 'Metropolitan Investment') {
            const signature = \`<div class="signature"><p>Z poważaniem,<br/>Zespół \${senderName}</p></div>\`;
            return window.insertContent(signature);
        };

        window.insertInvestmentPlaceholder = function() {
            const placeholder = '<div style="background-color: #f9f9f9; border: 2px dashed #d4af37; padding: 16px; margin: 16px 0; border-radius: 8px; text-align: center;"><p><strong>📊 Szczegóły inwestycji będą tutaj wstawione automatycznie</strong></p><p style="color: #666; font-size: 14px;">Dane inwestycyjne zostaną spersonalizowane dla każdego odbiorcy</p></div>';
            return window.insertContent(placeholder);
        };
    </script>
</body>
</html>
    ''';
  }
}
