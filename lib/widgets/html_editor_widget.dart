import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:flutter_html/flutter_html.dart' as html_package;
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../models_and_services.dart';

/// 🚀 Enhanced HTML Email Editor Widget
///
/// Professional email editor using html_editor_enhanced package
/// Provides Gmail-like experience with full HTML formatting and real-time preview
class HtmlEditorWidget extends StatefulWidget {
  final String initialContent;
  final Function(String html)? onContentChanged;
  final Function()? onReady;
  final Function(bool focused)? onFocusChanged;
  final Function(String error)? onError;
  final double height;
  final bool enabled;
  final bool showPreview;

  const HtmlEditorWidget({
    super.key,
    this.initialContent = '',
    this.onContentChanged,
    this.onReady,
    this.onFocusChanged,
    this.onError,
    this.height = 400,
    this.enabled = true,
    this.showPreview = false,
  });

  @override
  State<HtmlEditorWidget> createState() => _HtmlEditorWidgetState();
}

class _HtmlEditorWidgetState extends State<HtmlEditorWidget>
    with TickerProviderStateMixin {
  // HTML Editor Controller
  final HtmlEditorController _htmlController = HtmlEditorController();

  // State variables
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _currentHtml = '';
  bool _isEditorReady = false;
  bool _useFallbackEditor = false;

  // Get available fonts from FontFamilyService - dynamic list from assets/fonts
  List<String> get _availableFonts {
    final localFonts = FontFamilyService.getFontFamilyNames();
    
    // Add some commonly requested web-safe fallbacks at the end
    final webSafeFallbacks = [
      'Arial',
      'Helvetica', 
      'Times New Roman',
      'Georgia',
      'Verdana',
      'serif',
      'sans-serif',
      'monospace',
    ];
    
    return [...localFonts, ...webSafeFallbacks];
  }

  // Animation controllers
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  // Preview state
  bool _showPreviewInternal = false;

  // Debounce timer for content changes
  Timer? _contentChangeTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _currentHtml = widget.initialContent;
    _showPreviewInternal = widget.showPreview;

    // Add safety timeout in case onInit callback doesn't fire
    Timer(const Duration(seconds: 5), () {
      if (mounted && _isLoading) {
        if (kDebugMode) {
          print('⚠️ HTML Editor timeout - forcing ready state');
        }
        _onEditorReady();
      }
    });
  }

  void _initializeAnimations() {
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _loadingController.repeat();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _contentChangeTimer?.cancel();
    super.dispose();
  }

  void _onEditorReady() {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isEditorReady = true;
      _hasError = false; // Clear any previous errors
    });
    _loadingController.stop();

    // Inject custom fonts and CSS into the editor
    _injectFontsAndStyles();

    // Set initial content if provided with slight delay
    if (widget.initialContent.isNotEmpty) {
      Timer(const Duration(milliseconds: 100), () {
        if (mounted && _isEditorReady) {
          try {
            _htmlController.setText(widget.initialContent);
          } catch (e) {
            if (kDebugMode) {
              print('❌ Error setting initial content: $e');
            }
            // Try alternative approach if direct setText fails
            _tryAlternativeContentSetting();
          }
        }
      });
    }

    if (widget.onReady != null) {
      widget.onReady!();
    }

    // Check font loading status after a delay
    Timer(const Duration(milliseconds: 1000), () async {
      if (mounted && _isEditorReady) {
        await _verifyFontLoading();
      }
    });

    if (kDebugMode) {
      print(
        '🚀 Enhanced HTML Editor ready with ${_availableFonts.length} fonts from FontFamilyService',
      );
      print(
        '📋 Available local fonts: ${FontFamilyService.getFontFamilyNames().join(', ')}',
      );
    }
  }

  /// Alternative method to set content if primary method fails
  void _tryAlternativeContentSetting() {
    Timer(const Duration(milliseconds: 500), () async {
      if (!mounted || !_isEditorReady) return;

      try {
        // Try using JavaScript evaluation to set content
        await _htmlController.evaluateJavascriptWeb('''
          document.body.innerHTML = `${widget.initialContent}`;
        ''');

        if (kDebugMode) {
          print('✅ Alternative content setting successful');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Alternative content setting failed: $e');
        }
        _handleEditorError('Failed to set initial content: $e');
      }
    });
  }

  /// Handle editor errors gracefully
  void _handleEditorError(String error) {
    if (!mounted) return;

    setState(() {
      _hasError = true;
      _errorMessage = error;
      _isLoading = false;
    });

    if (widget.onError != null) {
      widget.onError!(error);
    }

    if (kDebugMode) {
      print('❌ HTML Editor error handled: $error');
    }

    // Try to load fallback editor if enhanced editor fails
    if (!_useFallbackEditor) {
      _loadFallbackEditor();
    }
  }

  /// Loads a simple fallback HTML editor when the enhanced editor fails
  void _loadFallbackEditor() {
    if (!mounted) return;

    try {
      debugPrint('🔄 Loading fallback HTML editor...');
      setState(() {
        _useFallbackEditor = true;
        _hasError = false; // Clear error since we have a working fallback
        _isLoading = false;
        _isEditorReady = true;
      });

      // Notify that editor is ready
      if (widget.onReady != null) {
        widget.onReady!();
      }

      debugPrint('✅ Fallback editor loaded successfully');
    } catch (e) {
      debugPrint('❌ Failed to load fallback editor: $e');
      // Keep error state if even fallback fails
      setState(() {
        _hasError = true;
        _errorMessage = 'Both enhanced and fallback editors failed to load';
      });
    }
  }

  /// Checks if local fonts are available in the HTML editor context
  Future<bool> _checkLocalFontsAvailability() async {
    try {
      // Test if we can detect a local font in the HTML editor
      final result = await _htmlController.evaluateJavascriptWeb('''
        (function() {
          // Create a test element to check font availability
          var testDiv = document.createElement('div');
          testDiv.style.fontFamily = 'Inter, Arial, sans-serif';
          testDiv.style.position = 'absolute';
          testDiv.style.left = '-9999px';
          testDiv.innerHTML = 'Test';
          document.body.appendChild(testDiv);
          
          // Check if the font was loaded by measuring width difference
          var width1 = testDiv.offsetWidth;
          testDiv.style.fontFamily = 'Arial, sans-serif';
          var width2 = testDiv.offsetWidth;
          
          document.body.removeChild(testDiv);
          
          // If widths are different, font is available
          return width1 !== width2;
        })();
      ''');

      if (kDebugMode) {
        print('🔍 Font availability check result: $result');
      }

      return result == true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking font availability: $e');
      }
      return false;
    }
  }

  /// Enhanced font verification with detailed logging
  Future<void> _verifyFontLoading() async {
    try {
      if (kDebugMode) {
        print('🔍 === FONT LOADING VERIFICATION ===');
        print(
          '📋 Available fonts from FontFamilyService: ${_availableFonts.length}',
        );
        print(
          '🏠 Local fonts: ${FontFamilyService.getFontFamilyNames().join(', ')}',
        );
      }

      // Check if we're running on web
      final isWeb = kIsWeb;
      if (kDebugMode) {
        print('🌐 Running on web: $isWeb');
      }

      // Test font availability in HTML editor context
      final localFontsAvailable = await _checkLocalFontsAvailability();
      if (kDebugMode) {
        print('✅ Local fonts available in HTML editor: $localFontsAvailable');
      }

      // Test specific fonts
      final testFonts = ['Inter', 'Montserrat', 'Arial'];
      for (final font in testFonts) {
        final fontStack = await _getEditorSafeFontStack(font);
        final isLocal = FontFamilyService.isLocalFont(font);
        if (kDebugMode) {
          print('🎨 Font: $font | Local: $isLocal | Stack: $fontStack');
        }
      }

      // Check if fonts are properly injected
      await _testFontInjection();

      if (kDebugMode) {
        print('🔍 === FONT VERIFICATION COMPLETE ===');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during font verification: $e');
      }
    }
  }

  /// Test if fonts are properly injected into the HTML editor
  Future<void> _testFontInjection() async {
    try {
      // Check if our custom CSS was injected
      final cssInjected = await _htmlController.evaluateJavascriptWeb('''
        (function() {
          var styles = document.querySelectorAll('style');
          var foundCustomCSS = false;
          for (var i = 0; i < styles.length; i++) {
            if (styles[i].innerHTML.includes('Inter') && styles[i].innerHTML.includes('@import')) {
              foundCustomCSS = true;
              break;
            }
          }
          return foundCustomCSS;
        })();
      ''');

      if (kDebugMode) {
        print('🎨 Custom CSS injected: $cssInjected');
      }

      // Test if a specific font is available
      final fontAvailable = await _htmlController.evaluateJavascriptWeb('''
        (function() {
          // Create test element
          var testDiv = document.createElement('div');
          testDiv.style.fontFamily = 'Inter, Arial, sans-serif';
          testDiv.style.position = 'absolute';
          testDiv.style.left = '-9999px';
          testDiv.style.fontSize = '24px';
          testDiv.innerHTML = 'Test font rendering';
          document.body.appendChild(testDiv);
          
          // Measure width
          var width1 = testDiv.offsetWidth;
          
          // Change to fallback and measure again
          testDiv.style.fontFamily = 'Arial, sans-serif';
          var width2 = testDiv.offsetWidth;
          
          // Clean up
          document.body.removeChild(testDiv);
          
          // Return if font made a difference
          return {
            width1: width1,
            width2: width2,
            different: width1 !== width2,
            difference: Math.abs(width1 - width2)
          };
        })();
      ''');

      if (kDebugMode) {
        print('🔤 Font rendering test: $fontAvailable');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error testing font injection: $e');
      }
    }
  }

  /// Injects custom fonts, styles, and jQuery dependencies into the HTML editor
  void _injectFontsAndStyles() {
    Timer(const Duration(milliseconds: 300), () async {
      if (!mounted || !_isEditorReady) return;

      try {
        // First, ensure jQuery is loaded if needed
        await _ensureJQueryLoaded();

        // Check if local fonts are available in the HTML editor context
        final localFontsAvailable = await _checkLocalFontsAvailability();

        // Inject Google Fonts and custom CSS for better font support
        const String fontCSS = '''
          <style>
            @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
            @import url('https://fonts.googleapis.com/css2?family=Open+Sans:wght@300;400;600;700&display=swap');
            @import url('https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap');
            @import url('https://fonts.googleapis.com/css2?family=Lato:wght@300;400;700&display=swap');
            @import url('https://fonts.googleapis.com/css2?family=Montserrat:wght@300;400;500;600;700&display=swap');
            @import url('https://fonts.googleapis.com/css2?family=Source+Sans+Pro:wght@300;400;600;700&display=swap');
            @import url('https://fonts.googleapis.com/css2?family=Nunito:wght@300;400;600;700&display=swap');
            @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
            @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;500;600;700&display=swap');
            @import url('https://fonts.googleapis.com/css2?family=Merriweather:wght@300;400;700&display=swap');
            @import url('https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap');
            @import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&display=swap');
            @import url('https://fonts.googleapis.com/css2?family=Raleway:wght@300;400;500;600;700&display=swap');
            @import url('https://fonts.googleapis.com/css2?family=Ubuntu:wght@300;400;500;700&display=swap');
            @import url('https://fonts.googleapis.com/css2?family=PT+Sans:wght@400;700&display=swap');
            @import url('https://fonts.googleapis.com/css2?family=Exo:wght@300;400;500;600;700&display=swap');
            @import url('https://fonts.googleapis.com/css2?family=Fira+Code:wght@300;400;500;600;700&display=swap');
            @import url('https://fonts.googleapis.com/css2?family=Crimson+Text:wght@400;600;700&display=swap');
            @import url('https://fonts.googleapis.com/css2?family=Libre+Baskerville:wght@400;700&display=swap');
            
            body {
              font-family: 'Inter', 'Arial', sans-serif;
              line-height: 1.6;
              color: #333;
            }
            
            .font-arial { font-family: 'Arial', sans-serif; }
            .font-arial-black { font-family: 'Arial Black', sans-serif; }
            .font-helvetica { font-family: 'Helvetica', 'Arial', sans-serif; }
            .font-times { font-family: 'Times New Roman', 'Times', serif; }
            .font-georgia { font-family: 'Georgia', serif; }
            .font-garamond { font-family: 'Garamond', serif; }
            .font-calibri { font-family: 'Calibri', sans-serif; }
            .font-trebuchet { font-family: 'Trebuchet MS', sans-serif; }
            .font-verdana { font-family: 'Verdana', sans-serif; }
            .font-tahoma { font-family: 'Tahoma', sans-serif; }
            .font-inter { font-family: 'Inter', sans-serif; }
            .font-open-sans { font-family: 'Open Sans', sans-serif; }
            .font-roboto { font-family: 'Roboto', sans-serif; }
            .font-lato { font-family: 'Lato', sans-serif; }
            .font-montserrat { font-family: 'Montserrat', sans-serif; }
            .font-source-sans { font-family: 'Source Sans Pro', sans-serif; }
            .font-nunito { font-family: 'Nunito', sans-serif; }
            .font-poppins { font-family: 'Poppins', sans-serif; }
            .font-playfair { font-family: 'Playfair Display', serif; }
            .font-merriweather { font-family: 'Merriweather', serif; }
            .font-courier { font-family: 'Courier New', 'Courier', monospace; }
            .font-monaco { font-family: 'Monaco', 'Menlo', monospace; }
            .font-consolas { font-family: 'Consolas', monospace; }
            .font-fira-code { font-family: 'Fira Code', monospace; }
            .font-impact { font-family: 'Impact', sans-serif; }
            .font-oswald { font-family: 'Oswald', sans-serif; }
            .font-bebas { font-family: 'Bebas Neue', sans-serif; }
            .font-raleway { font-family: 'Raleway', sans-serif; }
            .font-ubuntu { font-family: 'Ubuntu', sans-serif; }
            .font-pt-sans { font-family: 'PT Sans', sans-serif; }
            .font-exo { font-family: 'Exo', sans-serif; }
            .font-crimson-text { font-family: 'Crimson Text', serif; }
            .font-libre-baskerville { font-family: 'Libre Baskerville', serif; }
          </style>
        ''';

        // Insert the CSS into the editor's head
        await _htmlController.evaluateJavascriptWeb('''
          var head = document.head || document.getElementsByTagName('head')[0];
          var style = document.createElement('style');
          style.type = 'text/css';
          style.innerHTML = `$fontCSS`;
          head.appendChild(style);
        ''');

        if (kDebugMode) {
          print('✅ Custom fonts and styles injected successfully');
          print(
            '🔍 Local fonts available in HTML editor: $localFontsAvailable',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error injecting fonts: $e');
        }
      }
    });
  }

  /// Ensures jQuery is loaded for HTML editor functionality
  Future<void> _ensureJQueryLoaded() async {
    try {
      // Check if jQuery is already loaded
      final jqueryExists = await _htmlController.evaluateJavascriptWeb('''
        (function() {
          return typeof jQuery !== 'undefined' && typeof \$ !== 'undefined';
        })();
      ''');

      if (jqueryExists != true) {
        if (kDebugMode) {
          print('⚠️ jQuery not found, loading jQuery...');
        }

        // Load jQuery from CDN
        await _htmlController.evaluateJavascriptWeb('''
          (function() {
            if (typeof jQuery === 'undefined' || typeof \$ === 'undefined') {
              var script = document.createElement('script');
              script.src = 'https://code.jquery.com/jquery-3.6.0.min.js';
              script.integrity = 'sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=';
              script.crossOrigin = 'anonymous';
              script.onload = function() {
                console.log('✅ jQuery loaded successfully');
              };
              script.onerror = function() {
                console.warn('❌ Failed to load jQuery from CDN');
              };
              document.head.appendChild(script);
            }
          })();
        ''');

        // Wait a bit for jQuery to load
        await Future.delayed(const Duration(milliseconds: 500));

        if (kDebugMode) {
          print('✅ jQuery loading initiated');
        }
      } else {
        if (kDebugMode) {
          print('✅ jQuery already available');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking/loading jQuery: $e');
      }
    }
  }

  /// Apply font with simple execCommand method (matches FontSettingButtons behavior)
  Future<void> _applyFontWithFallbacks(String fontName) async {
    if (!_isEditorReady) return;

    try {
      // Get font stack with fallbacks for email safety
      final fontStack = await _getEditorSafeFontStack(fontName);

      if (kDebugMode) {
        print('🎨 Applying font stack: $fontStack');
      }

      // Use simple execCommand method (same as FontSettingButtons)
      _htmlController.execCommand('fontName', argument: fontStack);

      if (kDebugMode) {
        print('✅ Font applied successfully: $fontName → $fontStack');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error applying font: $e');
      }
      // Ultimate fallback: try simple fontName without fallbacks
      try {
        _htmlController.execCommand('fontName', argument: fontName);
        if (kDebugMode) {
          print('✅ Fallback font applied: $fontName');
        }
      } catch (fallbackError) {
        if (kDebugMode) {
          print('❌ Fallback font application failed: $fallbackError');
        }
      }
    }
  }

  /// Get editor-safe font stack that works in HTML editor context
  Future<String> _getEditorSafeFontStack(String primaryFont) async {
    // Check if local fonts are available in the editor
    final localFontsAvailable = await _checkLocalFontsAvailability();

    if (localFontsAvailable && FontFamilyService.isLocalFont(primaryFont)) {
      // Use local font with fallbacks
      return FontFamilyService.getEmailSafeFontFamily(primaryFont);
    } else {
      // Use Google Fonts equivalent or web-safe fallback
      return _getGoogleFontEquivalent(primaryFont);
    }
  }

  /// Get Google Font equivalent for local fonts when local fonts aren't available
  String _getGoogleFontEquivalent(String fontName) {
    // Map local fonts to their Google Font equivalents
    final googleFontMap = {
      'CrimsonText': 'Crimson Text',
      'FiraSans': 'Fira Sans',
      'Inter': 'Inter',
      'Lato': 'Lato',
      'LibreBaskerville': 'Libre Baskerville',
      'Merriweather': 'Merriweather',
      'Montserrat': 'Montserrat',
      'Nunito': 'Nunito',
      // Add more mappings as needed
    };

    // Web-safe fallbacks for each font type
    final webSafeFallbacks = {
      'CrimsonText': 'serif',
      'FiraSans': 'sans-serif',
      'Inter': 'sans-serif',
      'Lato': 'sans-serif',
      'LibreBaskerville': 'serif',
      'Merriweather': 'serif',
      'Montserrat': 'sans-serif',
      'Nunito': 'sans-serif',
    };

    final googleFont = googleFontMap[fontName] ?? fontName;

    // For system fonts, get CSS font family from FontFamilyService
    if (!FontFamilyService.isLocalFont(fontName)) {
      return FontFamilyService.getCssFontFamily(fontName);
    }

    // Return Google Font with fallback
    return '"$googleFont", ${webSafeFallbacks[fontName] ?? 'sans-serif'}';
  }

  void _onContentChanged(String html) {
    if (!mounted) return; // Add mounted check

    try {
      _currentHtml = html;

      // Debounce content changes to avoid excessive updates
      _contentChangeTimer?.cancel();
      _contentChangeTimer = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return; // Add mounted check in timer too

        try {
          if (widget.onContentChanged != null) {
            widget.onContentChanged!(html);
          }

          if (mounted) {
            setState(() {}); // Trigger preview update
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error in content change callback: $e');
          }
        }
      });

      if (kDebugMode) {
        print('📝 Content changed: ${html.length} characters');
        print(
          '🖼️ Rendering preview HTML: "${html.length > 100 ? html.substring(0, 100) + '...' : html}"',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling content change: $e');
      }
      _handleEditorError('Content change error: $e');
    }
  }

  void _onFocusChanged(bool focused) {
    if (!mounted) return; // Add mounted check

    if (widget.onFocusChanged != null) {
      widget.onFocusChanged!(focused);
    }

    if (kDebugMode) {
      print('🎯 Editor focus: $focused');
    }
  }

  void _togglePreview() {
    setState(() {
      _showPreviewInternal = !_showPreviewInternal;
    });
  }

  Future<String> getContent() async {
    if (!_isEditorReady) return _currentHtml;

    try {
      final html = await _htmlController.getText();
      return html;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting content: $e');
      }
      return _currentHtml;
    }
  }

  Future<void> setContent(String html) async {
    if (!_isEditorReady) {
      _currentHtml = html;
      return;
    }

    try {
      _htmlController.setText(html);
      _currentHtml = html;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting content: $e');
      }
    }
  }

  Future<void> insertContent(String html) async {
    if (!_isEditorReady) return;

    try {
      _htmlController.insertHtml(html);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error inserting content: $e');
      }
    }
  }

  Future<void> insertText(String text) async {
    if (!_isEditorReady) return;

    try {
      _htmlController.insertText(text);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error inserting text: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Toolbar with preview toggle
            _buildToolbar(),

            // Main content area
            Expanded(
              child: _showPreviewInternal
                  ? _buildSplitView()
                  : _buildEditorView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundSecondary,
            AppTheme.backgroundSecondary.withOpacity(0.8),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppTheme.borderPrimary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.edit_note, color: AppTheme.secondaryGold, size: 20),
          const SizedBox(width: 8),
          Text(
            'HTML Editor',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),

          const Spacer(),

          // Preview toggle button
          IconButton(
            icon: Icon(
              _showPreviewInternal ? Icons.edit : Icons.preview,
              color: AppTheme.secondaryGold,
              size: 20,
            ),
            onPressed: _togglePreview,
            tooltip: _showPreviewInternal ? 'Tryb edycji' : 'Podgląd',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildEditorView() {
    if (_hasError && !_useFallbackEditor) {
      return _buildErrorView();
    }

    if (_isLoading) {
      return _buildLoadingView();
    }

    // Show fallback editor if needed
    if (_useFallbackEditor) {
      return _buildFallbackEditor();
    }

    return Stack(
      children: [
        // Main HTML Editor with explicit sizing
        SizedBox(
          width: double.infinity,
          height: widget.height - 90,
          child: HtmlEditor(
            controller: _htmlController,
            htmlEditorOptions: HtmlEditorOptions(
              hint: 'Napisz swoją wiadomość...',
              shouldEnsureVisible: true,
              initialText: widget.initialContent.isNotEmpty
                  ? widget.initialContent
                  : '',
              autoAdjustHeight: false,
              adjustHeightForKeyboard: true,
              disabled: !widget.enabled, // Fix: use widget.enabled properly
              darkMode: false, // Light mode for better compatibility
              webInitialScripts: UnmodifiableListView([
                // Ensure jQuery is available for the editor
                WebScript(
                  name: 'jQuery-loader',
                  script: '''
                    if (typeof jQuery === 'undefined') {
                      var script = document.createElement('script');
                      script.src = 'https://code.jquery.com/jquery-3.6.0.min.js';
                      script.crossOrigin = 'anonymous';
                      document.head.appendChild(script);
                    }
                  ''',
                ),
              ]),
            ),
            htmlToolbarOptions: HtmlToolbarOptions(
              toolbarPosition: ToolbarPosition.aboveEditor,
              toolbarType: ToolbarType.nativeGrid,
              customToolbarButtons: [
                // Enhanced font family dropdown with extensive font options
                SizedBox(
                  width: 120, // Fixed width to prevent layout issues
                  height: 40,
                  child: Container(
                    padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundSecondary,
                      border: Border.all(
                        color: AppTheme.borderPrimary.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: CustomDropdownButtonHideUnderline(
                      child: CustomDropdownButton<String>(
                        elevation: 8,
                        iconEnabledColor: AppTheme.secondaryGold,
                        iconSize: 14,
                        isExpanded:
                            true, // Important: allows dropdown to use full width
                        itemHeight:
                            48, // Increased height for better touch targets
                        dropdownColor: AppTheme.backgroundSecondary,
                        menuDirection: DropdownMenuDirection.down,
                        menuMaxHeight:
                            MediaQuery.of(context).size.height /
                            3, // Limit height for scrolling
                        hint: Text(
                          'Czcionka',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        items: _availableFonts.map((String font) {
                          return CustomDropdownMenuItem<String>(
                            value: font,
                            child: PointerInterceptor(
                              child: SizedBox(
                                width: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6.0,
                                    vertical: 4.0,
                                  ),
                                  child: Text(
                                    font,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontFamily:
                                          font == 'serif' ||
                                              font == 'sans-serif' ||
                                              font == 'monospace' ||
                                              font == 'cursive' ||
                                              font == 'fantasy'
                                          ? null
                                          : font,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        value: null,
                        onChanged: (String? newFont) async {
                          if (newFont != null && _isEditorReady) {
                            try {
                              // Enhanced font application with fallbacks for email compatibility
                              await _applyFontWithFallbacks(newFont);
                              if (kDebugMode) {
                                print('✅ Applied font: $newFont');
                              }
                            } catch (e) {
                              if (kDebugMode) {
                                print('❌ Error applying font: $e');
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
              defaultToolbarButtons: [
                StyleButtons(),
                FontSettingButtons(
                  fontName:
                      true, // Enable default font dropdown to compare with custom implementation
                  fontSize: true,
                  fontSizeUnit: false,
                ),
                FontButtons(
                  bold: true,
                  italic: true,
                  underline: true,
                  clearAll: false,
                  strikethrough: true,
                  superscript: false,
                  subscript: false,
                ),
                ColorButtons(foregroundColor: true, highlightColor: true),
                ListButtons(ul: true, ol: true, listStyles: false),
                ParagraphButtons(
                  textDirection: false,
                  lineHeight: true,
                  caseConverter: false,
                  alignCenter: true,
                  alignJustify: false,
                  alignLeft: true,
                  alignRight: true,
                  increaseIndent: true,
                  decreaseIndent: true,
                ),
                InsertButtons(
                  link: true,
                  picture: true,
                  audio: false,
                  video: false,
                  table: true,
                  hr: false,
                  otherFile: false,
                ),
                OtherButtons(
                  fullscreen: true,
                  codeview: true,
                  undo: true,
                  redo: true,
                  help: false,
                  copy: false,
                  paste: false,
                ),
              ],
              toolbarItemHeight: 40,
              gridViewHorizontalSpacing: 5,
              gridViewVerticalSpacing: 5,
            ),
            otherOptions: OtherOptions(
              height: widget.height - 90, // Account for toolbar and padding
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            callbacks: Callbacks(
              onBeforeCommand: (String? currentHtml) {
                if (kDebugMode) {
                  print('🔧 Before command executed');
                }
              },
              onChangeContent: (String? changed) {
                try {
                  if (changed != null) {
                    _onContentChanged(changed);
                  }
                } catch (e) {
                  if (kDebugMode) {
                    print('❌ Error in onChangeContent: $e');
                  }
                  _handleEditorError('Content change error: $e');
                }
              },
              onChangeCodeview: (String? changed) {
                try {
                  if (changed != null) {
                    _onContentChanged(changed);
                  }
                } catch (e) {
                  if (kDebugMode) {
                    print('❌ Error in onChangeCodeview: $e');
                  }
                  _handleEditorError('Code view change error: $e');
                }
              },
              onInit: () {
                try {
                  if (kDebugMode) {
                    print('🎯 HtmlEditor onInit callback fired');
                  }
                  _onEditorReady();
                } catch (e) {
                  if (kDebugMode) {
                    print('❌ Error in onInit: $e');
                  }
                  _handleEditorError('Editor initialization error: $e');
                }
              },
              onFocus: () {
                try {
                  _onFocusChanged(true);
                } catch (e) {
                  if (kDebugMode) {
                    print('❌ Error in onFocus: $e');
                  }
                }
              },
              onBlur: () {
                try {
                  _onFocusChanged(false);
                } catch (e) {
                  if (kDebugMode) {
                    print('❌ Error in onBlur: $e');
                  }
                }
              },
              onBlurCodeview: () {
                try {
                  _onFocusChanged(false);
                } catch (e) {
                  if (kDebugMode) {
                    print('❌ Error in onBlurCodeview: $e');
                  }
                }
              },
              onEnter: () {
                if (kDebugMode) {
                  print('↵ Enter pressed in editor');
                }
              },
              onPaste: () {
                if (kDebugMode) {
                  print('📋 Content pasted');
                }
              },
              onKeyDown: (int? keyCode) {
                if (kDebugMode && keyCode != null) {
                  print('⌨️ Key pressed: $keyCode');
                }
              },
              onKeyUp: (int? keyCode) {
                // Handle key up events if needed
              },
              onMouseDown: () {
                // Handle mouse down if needed
              },
              onMouseUp: () {
                // Handle mouse up if needed
              },
              onNavigationRequestMobile: (String url) {
                if (kDebugMode) {
                  print('🔗 Navigation request: $url');
                }
                return NavigationActionPolicy.ALLOW;
              },
            ),
            plugins: const [
              // Remove plugins for now to simplify initialization
            ],
          ),
        ),

        // Disabled overlay
        if (!widget.enabled)
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary.withOpacity(0.8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Edytor jest wyłączony',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSplitView() {
    return Row(
      children: [
        // Editor on the left
        Expanded(flex: 1, child: _buildEditorView()),

        // Divider
        Container(width: 1, color: AppTheme.borderPrimary.withOpacity(0.3)),

        // Preview on the right
        Expanded(flex: 1, child: _buildPreviewView()),
      ],
    );
  }

  Widget _buildPreviewView() {
    return Container(
      decoration: BoxDecoration(color: AppTheme.backgroundPrimary),
      child: Column(
        children: [
          // Preview header
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary.withOpacity(0.5),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.borderPrimary.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.preview, color: AppTheme.secondaryGold, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Podgląd',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Preview content
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, // Email preview background
              ),
              child: SingleChildScrollView(
                child: _currentHtml.isEmpty
                    ? Center(
                        child: Text(
                          'Podgląd będzie widoczny po napisaniu treści...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : html_package.Html(
                        data:
                            '''
                        <style>
                          @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
                          @import url('https://fonts.googleapis.com/css2?family=Open+Sans:wght@300;400;600;700&display=swap');
                          @import url('https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap');
                          @import url('https://fonts.googleapis.com/css2?family=Lato:wght@300;400;700&display=swap');
                          @import url('https://fonts.googleapis.com/css2?family=Montserrat:wght@300;400;500;600;700&display=swap');
                          @import url('https://fonts.googleapis.com/css2?family=Source+Sans+Pro:wght@300;400;600;700&display=swap');
                          @import url('https://fonts.googleapis.com/css2?family=Nunito:wght@300;400;600;700&display=swap');
                          @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
                          @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;500;600;700&display=swap');
                          @import url('https://fonts.googleapis.com/css2?family=Merriweather:wght@300;400;700&display=swap');
                          @import url('https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap');
                          @import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&display=swap');
                          @import url('https://fonts.googleapis.com/css2?family=Raleway:wght@300;400;500;600;700&display=swap');
                          @import url('https://fonts.googleapis.com/css2?family=Ubuntu:wght@300;400;500;700&display=swap');
                          @import url('https://fonts.googleapis.com/css2?family=PT+Sans:wght@400;700&display=swap');
                          @import url('https://fonts.googleapis.com/css2?family=Exo:wght@300;400;500;600;700&display=swap');
                          @import url('https://fonts.googleapis.com/css2?family=Fira+Code:wght@300;400;500;600;700&display=swap');
                        </style>
                        $_currentHtml
                        ''',
                        style: {
                          "body": html_package.Style(
                            margin: html_package.Margins.zero,
                            padding: html_package.HtmlPaddings.zero,
                            fontSize: html_package.FontSize(16),
                            lineHeight: const html_package.LineHeight(1.6),
                            fontFamily: 'Inter, Arial, sans-serif',
                            color: const Color(0xFF333333),
                          ),
                          "h1, h2, h3, h4, h5, h6": html_package.Style(
                            color: const Color(0xFF2c2c2c),
                            margin: html_package.Margins.only(
                              top: 1.2,
                              bottom: 0.8,
                            ),
                          ),
                          "p": html_package.Style(
                            margin: html_package.Margins.only(bottom: 1),
                          ),
                          "div": html_package.Style(
                            margin: html_package.Margins.only(bottom: 0.5),
                          ),
                          // Bold formatting
                          "b, strong": html_package.Style(
                            fontWeight: FontWeight.bold,
                          ),
                          // Italic formatting
                          "i, em": html_package.Style(
                            fontStyle: FontStyle.italic,
                          ),
                          // Underline formatting
                          "u": html_package.Style(
                            textDecoration: TextDecoration.underline,
                          ),
                          // Strikethrough formatting
                          "s, strike, del": html_package.Style(
                            textDecoration: TextDecoration.lineThrough,
                          ),
                          // Font elements with color support
                          "font": html_package.Style(
                            // Color will be handled by flutter_html automatically
                          ),
                          // Span elements for inline styling
                          "span": html_package.Style(
                            // Flutter_html handles inline styles automatically
                          ),
                          "a": html_package.Style(
                            color: AppTheme.secondaryGold,
                            textDecoration: TextDecoration.underline,
                          ),
                          "table": html_package.Style(
                            border: const Border.fromBorderSide(
                              BorderSide(color: Colors.grey, width: 1),
                            ),
                            width: html_package.Width(
                              100,
                              html_package.Unit.percent,
                            ),
                          ),
                          "td, th": html_package.Style(
                            border: const Border.fromBorderSide(
                              BorderSide(color: Colors.grey, width: 1),
                            ),
                            padding: html_package.HtmlPaddings.all(8),
                          ),
                          "th": html_package.Style(
                            backgroundColor: const Color(0xFFF2F2F2),
                            fontWeight: FontWeight.bold,
                          ),
                          // Lists
                          "ul, ol": html_package.Style(
                            margin: html_package.Margins.only(
                              left: 1.5,
                              bottom: 1,
                            ),
                          ),
                          "li": html_package.Style(
                            margin: html_package.Margins.only(bottom: 0.5),
                          ),
                        },
                        onLinkTap: (url, attributes, element) {
                          if (kDebugMode) {
                            print('🔗 Link tapped: $url');
                          }
                        },
                        onAnchorTap: (url, attributes, element) {
                          if (kDebugMode) {
                            print('⚓ Anchor tapped: $url');
                          }
                        },
                        extensions: [
                          // Support for additional HTML elements
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return AnimatedBuilder(
      animation: _loadingAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundPrimary,
                AppTheme.backgroundSecondary,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: _loadingAnimation.value,
                        strokeWidth: 3,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    Icon(Icons.html, size: 28, color: AppTheme.primaryColor),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Ładowanie edytora HTML...',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.3),
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.3),
                      ],
                      stops: [0.0, _loadingAnimation.value, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackEditor() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        border: Border.all(
          color: AppTheme.borderPrimary.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Fallback status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.warningColor.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  size: 16,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tryb zapasowy - podstawowy edytor HTML',
                  style: TextStyle(
                    color: AppTheme.warningColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Simple HTML editor with WebView loading the fallback HTML
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.borderPrimary.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TextField(
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  decoration: const InputDecoration(
                    hintText:
                        'Wprowadź kod HTML...\n\nPrzykład:\n<p>Twoja wiadomość</p>\n<h2>Nagłówek</h2>\n<ul>\n  <li>Element listy</li>\n</ul>',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  onChanged: (html) {
                    _currentHtml = html;
                    if (widget.onContentChanged != null) {
                      widget.onContentChanged!(html);
                    }
                  },
                  controller: TextEditingController(text: _currentHtml),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              'Błąd edytora HTML',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                  _errorMessage = '';
                });
                _loadingController.repeat();

                // Try to reinitialize the editor
                _onEditorReady();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Legacy wrapper class for backward compatibility
class HtmlEditorControllerWrapper {
  String _content = '';
  final List<void Function()> _listeners = [];

  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  void dispose() {
    _listeners.clear();
    _content = '';
  }

  Future<String> getText() async => _content;

  void setText(String html) {
    _content = html.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?<\/script>'), '');
    _notifyListeners();
  }

  void setTextWithWhiteDefault(String html) {
    // Ensure white text color is applied as default
    String styledHtml = html;
    if (!html.contains('color:') || !html.contains('white')) {
      styledHtml =
          '''
      <div style="color: white; font-family: Arial, sans-serif; font-size: 14px;">
        $html
      </div>
      ''';
    }
    setText(styledHtml);
  }

  void clear() {
    _content = '';
    _notifyListeners();
  }

  void insertHtml(String html) {
    _content = _content + html;
    _notifyListeners();
  }

  void _notifyListeners() {
    for (final l in _listeners) {
      try {
        l();
      } catch (_) {}
    }
  }
}
