import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:flutter_html/flutter_html.dart' as html_package;

import '../theme/app_theme.dart';

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
    });
    _loadingController.stop();

    // Set initial content if provided with slight delay
    if (widget.initialContent.isNotEmpty) {
      Timer(const Duration(milliseconds: 100), () {
        if (mounted && _isEditorReady) {
          _htmlController.setText(widget.initialContent);
        }
      });
    }

    if (widget.onReady != null) {
      widget.onReady!();
    }

    if (kDebugMode) {
      print('🚀 Enhanced HTML Editor ready');
    }
  }

  void _onContentChanged(String html) {
    if (!mounted) return; // Add mounted check

    _currentHtml = html;

    // Debounce content changes to avoid excessive updates
    _contentChangeTimer?.cancel();
    _contentChangeTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return; // Add mounted check in timer too

      if (widget.onContentChanged != null) {
        widget.onContentChanged!(html);
      }

      if (mounted) {
        setState(() {}); // Trigger preview update
      }
    });

    if (kDebugMode) {
      print('📝 Content changed: ${html.length} characters');
      print(
        '🖼️ Rendering preview HTML: "${html.length > 100 ? html.substring(0, 100) + '...' : html}"',
      );
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
    if (_hasError) {
      return _buildErrorView();
    }

    if (_isLoading) {
      return _buildLoadingView();
    }

    return Stack(
      children: [
        // Main HTML Editor
        HtmlEditor(
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
          ),
          htmlToolbarOptions: const HtmlToolbarOptions(
            toolbarPosition: ToolbarPosition.aboveEditor,
            toolbarType: ToolbarType.nativeGrid,
            defaultToolbarButtons: [
              StyleButtons(),
              FontSettingButtons(
                fontName: true,
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
                picture: false,
                audio: false,
                video: false,
                table: true,
                hr: false,
                otherFile: false,
              ),
              OtherButtons(
                fullscreen: false,
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
              if (changed != null) {
                _onContentChanged(changed);
              }
            },
            onChangeCodeview: (String? changed) {
              if (changed != null) {
                _onContentChanged(changed);
              }
            },
            onInit: () {
              if (kDebugMode) {
                print('🎯 HtmlEditor onInit callback fired');
              }
              _onEditorReady();
            },
            onFocus: () {
              _onFocusChanged(true);
            },
            onBlur: () {
              _onFocusChanged(false);
            },
            onBlurCodeview: () {
              _onFocusChanged(false);
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
                        data: _currentHtml,
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
