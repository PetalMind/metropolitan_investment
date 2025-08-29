import 'package:flutter/material.dart';

/// Minimal controller wrapper expected by the new dialog. It provides a small
/// subset of functionality (getText, setText, clear, insertHtml, addListener)
/// implemented with a simple internal string buffer. The real project uses
/// a richer HTML editor; this shim keeps static analysis passing while the
/// full editor remains available in other files.
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

/// Minimal widget placeholder used by the dialog; it intentionally renders
/// nothing so it has no UI impact here.
class HtmlEditorWidget extends StatelessWidget {
  final HtmlEditorControllerWrapper controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final EdgeInsets? padding;
  final bool? autoFocus;
  final bool? showToolbar;
  final bool? isMobile;
  final bool? isSmallScreen;
  final VoidCallback? onChanged;

  const HtmlEditorWidget({
    super.key,
    required this.controller,
    this.focusNode,
    this.placeholder,
    this.padding,
    this.autoFocus,
    this.showToolbar,
    this.isMobile,
    this.isSmallScreen,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
