import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

/// 🛡️ HTML Sanitization Service for XSS Protection
/// Provides comprehensive HTML sanitization for email content using html package
class HtmlSanitizationService {
  // Allowed HTML tags for email content
  static const Set<String> _allowedTags = {
    'p',
    'div',
    'span',
    'br',
    'hr',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'strong',
    'b',
    'em',
    'i',
    'u',
    's',
    'del',
    'ul',
    'ol',
    'li',
    'blockquote',
    'pre',
    'code',
    'a',
    'img',
    'table',
    'thead',
    'tbody',
    'tr',
    'th',
    'td',
  };

  // Forbidden HTML tags (security risk)
  static const Set<String> _forbiddenTags = {
    'script',
    'iframe',
    'object',
    'embed',
    'applet',
    'form',
    'input',
    'button',
    'textarea',
    'select',
    'link',
    'style',
    'meta',
    'base',
    'title',
    'frame',
    'frameset',
    'noframes',
    'audio',
    'video',
    'source',
    'track',
  };

  /// Sanitize HTML content using DOM parsing for better accuracy
  static String sanitizeHtml(String html) {
    if (html.trim().isEmpty) return html;

    try {
      // Parse HTML into DOM
      final document = html_parser.parse(html);

      // Recursively sanitize all elements
      _sanitizeElement(document.body);

      // Return sanitized HTML
      return document.body?.innerHtml ?? '';
    } catch (e) {
      // If parsing fails, fall back to regex-based sanitization
      return _regexBasedSanitization(html);
    }
  }

  /// Recursively sanitize DOM elements
  static void _sanitizeElement(dom.Element? element) {
    if (element == null) return;

    final elementsToRemove = <dom.Element>[];

    // Check all child elements
    for (final child in element.children) {
      final tagName = child.localName?.toLowerCase();

      if (tagName != null) {
        if (_forbiddenTags.contains(tagName)) {
          // Mark for removal
          elementsToRemove.add(child);
        } else if (_allowedTags.contains(tagName)) {
          // Clean attributes for allowed tags
          _sanitizeAttributes(child);
          // Recursively sanitize children
          _sanitizeElement(child);
        } else {
          // Unknown tag - remove it but keep content
          elementsToRemove.add(child);
        }
      }
    }

    // Remove forbidden elements
    for (final element in elementsToRemove) {
      element.remove();
    }
  }

  /// Sanitize attributes of an element
  static void _sanitizeAttributes(dom.Element element) {
    final attributesToRemove = <String>[];

    // Check all attributes
    element.attributes.forEach((name, value) {
      final attrName = name.toString().toLowerCase();

      // Allow only safe attributes
      if (!_isSafeAttribute(attrName, value)) {
        attributesToRemove.add(name.toString());
      }
    });

    // Remove dangerous attributes
    for (final attr in attributesToRemove) {
      element.attributes.remove(attr);
    }
  }

  /// Check if attribute is safe
  static bool _isSafeAttribute(String attrName, String value) {
    // Allow common safe attributes
    const safeAttributes = {
      'style',
      'class',
      'id',
      'title',
      'href',
      'src',
      'alt',
      'width',
      'height',
      'colspan',
      'rowspan',
    };

    if (!safeAttributes.contains(attrName)) {
      return false;
    }

    // Check for dangerous patterns in value
    final dangerous = [
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'vbscript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
    ];

    for (final pattern in dangerous) {
      if (pattern.hasMatch(value)) {
        return false;
      }
    }

    return true;
  }

  /// Fallback regex-based sanitization
  static String _regexBasedSanitization(String html) {
    String cleaned = html;

    // Remove script tags and their content
    cleaned = cleaned.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true),
      '',
    );

    // Remove dangerous tags
    for (final tag in _forbiddenTags) {
      cleaned = cleaned.replaceAll(
        RegExp('</?$tag[^>]*>', caseSensitive: false),
        '',
      );
    }

    return cleaned;
  }

  /// Quick sanitization for email preview
  static String sanitizeForPreview(String html) {
    return _regexBasedSanitization(html);
  }

  /// Strict sanitization for email sending
  static String sanitizeForEmail(String html) {
    return sanitizeHtml(html);
  }

  /// Validate if HTML is safe
  static bool isHtmlSafe(String html) {
    // Check for forbidden tags
    for (final tag in _forbiddenTags) {
      if (RegExp('<$tag', caseSensitive: false).hasMatch(html)) {
        return false;
      }
    }

    // Check for dangerous patterns
    final dangerousPatterns = [
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'vbscript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
    ];

    for (final pattern in dangerousPatterns) {
      if (pattern.hasMatch(html)) {
        return false;
      }
    }

    return true;
  }
}
