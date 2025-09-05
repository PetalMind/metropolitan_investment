import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../theme/app_theme.dart';
import '../services/email_html_converter_service.dart';

/// 🚀 Quill Email Editor Widget
///
/// Professional email editor using Quill with Delta JSON to HTML conversion
/// Provides rich text editing with HTML export via delta_to_html
/// Features local fonts from pubspec.yaml and font-family preservation
class QuillEmailEditor extends StatefulWidget {
  final String initialContent;
  final QuillController? controller; // 🔄 Optional external controller
  final Function(String html, String deltaJson)? onContentChanged;
  final Function()? onReady;
  final Function(bool focused)? onFocusChanged;
  final double height;
  final bool enabled;

  const QuillEmailEditor({
    super.key,
    this.initialContent = '',
    this.controller, // 🔄 Accept external controller
    this.onContentChanged,
    this.onReady,
    this.onFocusChanged,
    this.height = 400,
    this.enabled = true,
  });

  @override
  State<QuillEmailEditor> createState() => _QuillEmailEditorState();
}

class _QuillEmailEditorState extends State<QuillEmailEditor> {
  late QuillController _controller;
  late FocusNode _focusNode;
  bool _isReady = false;

  // 🆕 Real-time preview system
  String _currentHtml = '';
  String _currentDeltaJson = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _setupController();
    _setupListeners();
  }

  void _setupController() {
    // Use external controller if provided, otherwise create new one
    if (widget.controller != null) {
      _controller = widget.controller!;
      if (kDebugMode) {
        print('🔄 Using external QuillController');
      }
    } else {
      // Initialize with content if provided
      Document document;

      if (widget.initialContent.isNotEmpty) {
        try {
          // Try to parse as Delta JSON first
          final deltaJson = jsonDecode(widget.initialContent);
          document = Document.fromJson(deltaJson);
          if (kDebugMode) {
            print(
              '📄 Loaded content from Delta JSON: ${widget.initialContent.length} chars',
            );
          }
        } catch (e) {
          // If parsing fails, treat as plain text
          document = Document()..insert(0, widget.initialContent);
          if (kDebugMode) {
            print(
              '📄 Loaded content as plain text: ${widget.initialContent.length} chars',
            );
          }
        }
      } else {
        document = Document();
      }

      _controller = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Mark as ready after setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isReady = true;
      });
      widget.onReady?.call();
      // Initial content conversion
      _updateContent();
    });
  }

  void _setupListeners() {
    // Listen to document changes with debouncing
    _controller.document.changes.listen((change) {
      _handleContentChangeWithDebounce();
    });

    // Listen to focus changes
    _focusNode.addListener(() {
      widget.onFocusChanged?.call(_focusNode.hasFocus);
    });
  }

  void _handleContentChangeWithDebounce() {
    if (!_isReady) return;

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer for debounced update
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _updateContent();
    });
  }

  void _updateContent() {
    if (!_isReady) return;

    try {
      // Get Delta JSON
      final deltaJson = _controller.document.toDelta().toJson();
      final deltaString = jsonEncode(deltaJson);

      // Convert to HTML using EmailHtmlConverterService
      final html = EmailHtmlConverterService.convertQuillToHtml(_controller);

      // Update state
      setState(() {
        _currentHtml = html;
        _currentDeltaJson = deltaString;
      });

      // Notify parent
      widget.onContentChanged?.call(html, deltaString);

      if (kDebugMode) {
        print(
          '📝 Content updated - HTML: ${html.length} chars, Delta: ${deltaString.length} chars',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating content: $e');
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    // Only dispose controller if we created it ourselves
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  /// Get current content as HTML
  String getHtmlContent() {
    return _currentHtml.isNotEmpty
        ? _currentHtml
        : EmailHtmlConverterService.convertQuillToHtml(_controller);
  }

  /// Get current content as Delta JSON
  String getDeltaContent() {
    return _currentDeltaJson.isNotEmpty
        ? _currentDeltaJson
        : jsonEncode(_controller.document.toDelta().toJson());
  }

  /// Get current plain text
  String getPlainText() {
    return _controller.document.toPlainText();
  }

  /// Set content from HTML (converted to Delta)
  void setHtmlContent(String html) {
    try {
      // For now, set as plain text
      // TODO: Implement HTML to Delta conversion if needed
      final document = Document()..insert(0, html);
      _controller.document = document;
      _updateContent();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting HTML content: $e');
      }
    }
  }

  /// Set content from Delta JSON
  void setDeltaContent(String deltaJson) {
    try {
      final deltaMap = jsonDecode(deltaJson);
      final document = Document.fromJson(deltaMap);
      _controller.document = document;
      _updateContent();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting Delta content: $e');
      }
    }
  }

  /// Set content from plain text
  void setPlainText(String text) {
    try {
      _controller.clear();
      _controller.document.insert(0, text);
      _updateContent();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting plain text: $e');
      }
    }
  }

  /// Insert text at current cursor position
  void insertText(String text) {
    final selection = _controller.selection;
    _controller.document.insert(selection.baseOffset, text);
    _controller.updateSelection(
      TextSelection.collapsed(offset: selection.baseOffset + text.length),
      ChangeSource.local,
    );
  }

  /// Clear all content
  void clearContent() {
    _controller.clear();
    _updateContent();
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
        child: _buildEditor(),
      ),
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        // Toolbar
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundSecondary,
                AppTheme.backgroundPrimary,
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.borderPrimary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: QuillSimpleToolbar(
            controller: _controller,
            config: QuillSimpleToolbarConfig(
              multiRowsDisplay: false,
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showStrikeThrough: true,
              showColorButton: true,
              showBackgroundColorButton: true,
              showHeaderStyle: true,
              showListBullets: true,
              showListNumbers: true,
              showAlignmentButtons: true,
              showLink: true,
              showUndo: true,
              showRedo: true,
            ),
          ),
        ),

        // Editor
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.backgroundPrimary),
            child: QuillEditor(
              controller: _controller,
              focusNode: _focusNode,
              scrollController: ScrollController(),
              config: QuillEditorConfig(
                placeholder: 'Rozpocznij pisanie wiadomości email...',
                padding: const EdgeInsets.all(16),
                autoFocus: false,
                expands: false,
                customStyles: DefaultStyles(
                  paragraph: DefaultTextBlockStyle(
                    TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      height: 1.6,
                      fontFamily: 'Inter', // Local font from pubspec.yaml
                    ),
                    HorizontalSpacing.zero,
                    VerticalSpacing.zero,
                    VerticalSpacing.zero,
                    null,
                  ),
                  h1: DefaultTextBlockStyle(
                    TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                      fontFamily: 'Montserrat', // Local font from pubspec.yaml
                    ),
                    HorizontalSpacing.zero,
                    VerticalSpacing.zero,
                    VerticalSpacing.zero,
                    null,
                  ),
                  h2: DefaultTextBlockStyle(
                    TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                      fontFamily: 'Montserrat', // Local font from pubspec.yaml
                    ),
                    HorizontalSpacing.zero,
                    VerticalSpacing.zero,
                    VerticalSpacing.zero,
                    null,
                  ),
                  h3: DefaultTextBlockStyle(
                    TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                      fontFamily: 'Montserrat', // Local font from pubspec.yaml
                    ),
                    HorizontalSpacing.zero,
                    VerticalSpacing.zero,
                    VerticalSpacing.zero,
                    null,
                  ),
                  bold: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Inter', // Local font from pubspec.yaml
                  ),
                  italic: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Merriweather', // Local font from pubspec.yaml
                  ),
                  underline: TextStyle(
                    decoration: TextDecoration.underline,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Lato', // Local font from pubspec.yaml
                  ),
                  strikeThrough: TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: AppTheme.textSecondary,
                    fontFamily: 'Roboto', // Local font from pubspec.yaml
                  ),
                  link: TextStyle(
                    color: AppTheme.primaryColor,
                    decoration: TextDecoration.underline,
                    fontFamily: 'Nunito', // Local font from pubspec.yaml
                  ),
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ),

        // Status bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundPrimary,
                AppTheme.backgroundSecondary,
              ],
            ),
            border: Border(
              top: BorderSide(
                color: AppTheme.borderPrimary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.edit_note, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Quill Rich Text Editor',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                _isReady ? 'Ready' : 'Loading...',
                style: TextStyle(
                  color: _isReady
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
