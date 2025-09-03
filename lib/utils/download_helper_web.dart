import 'dart:html' as html;
import 'dart:convert';
import 'dart:math' as math;

/// Triggers a download in web by opening a blob or direct URL.
Future<void> downloadFileFromUrl(String url, {String? filename}) async {
  try {
    // If it's a data URL or direct URL, create an anchor and click it
    final anchor = html.AnchorElement(href: url);
    anchor.download = filename ?? '';
    anchor.target = '_blank';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  } catch (e) {
    // Fallback: open in new tab
    html.window.open(url, '_blank');
  }
}

/// Accepts raw bytes as a string (CSV/JSON) and triggers download as blob
Future<void> downloadRawData(String data, String filename, {String mime = 'text/csv'}) async {
  final bytes = html.Blob([data], mime);
  final url = html.Url.createObjectUrlFromBlob(bytes);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

/// Downloads binary file from base64 data (PDF, Excel, Word)
Future<void> downloadBase64File(String base64Data, String filename, String contentType) async {
  try {
    print('🔍 [DownloadHelper] Starting download: $filename');
    print('🔍 [DownloadHelper] Content type: $contentType');
    print('🔍 [DownloadHelper] Base64 length: ${base64Data.length}');
    print(
      '🔍 [DownloadHelper] Base64 sample: ${base64Data.substring(0, math.min(50, base64Data.length))}...',
    );

    // Validate base64 string
    if (base64Data.isEmpty) {
      throw Exception('Base64 data is empty');
    }

    // Check if base64 contains valid characters
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
    if (!base64Pattern.hasMatch(base64Data)) {
      print('⚠️ [DownloadHelper] Warning: Base64 contains invalid characters');
    }
    
    // Decode base64 to bytes
    final bytes = base64Decode(base64Data);
    print('🔍 [DownloadHelper] Decoded bytes length: ${bytes.length}');
    
    // Enhanced file validation for Excel
    if (bytes.length >= 2) {
      final hexHeader = bytes
          .sublist(0, math.min(8, bytes.length))
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(' ')
          .toUpperCase();
      print('🔍 [DownloadHelper] File header (hex): $hexHeader');

      // Check for ZIP signature (Excel files are ZIP containers)
      if (bytes.length >= 4 &&
          bytes[0] == 0x50 &&
          bytes[1] == 0x4B &&
          (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07) &&
          (bytes[3] == 0x04 || bytes[3] == 0x06 || bytes[3] == 0x08)) {
        print('✅ [DownloadHelper] Valid ZIP signature detected');
      } else {
        print(
          '❌ [DownloadHelper] Invalid ZIP signature - Excel files must be ZIP containers',
        );
      }
    } // Force correct content type for Excel files
    String finalContentType = contentType;
    if (filename.toLowerCase().endsWith('.xlsx')) {
      finalContentType =
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      print(
        '🔍 [DownloadHelper] Forcing Excel content type: $finalContentType',
      );
    }
    
    // Create blob with proper content type
    final blob = html.Blob([bytes], finalContentType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    print('🔍 [DownloadHelper] Blob created successfully');
    print(
      '🔍 [DownloadHelper] Blob URL: ${url.substring(0, math.min(50, url.length))}...',
    );
    
    // Create download link with additional attributes
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none'
      ..setAttribute('type', finalContentType);
    
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    
    print('✅ [DownloadHelper] Download completed: $filename');
    print('✅ [DownloadHelper] File size: ${bytes.length} bytes');
    
  } catch (e) {
    print('❌ [DownloadHelper] Błąd pobierania pliku: $e');
    print('❌ [DownloadHelper] Stack trace: ${StackTrace.current}');
    
    // Additional debug info on error
    print('🔍 [DownloadHelper] Debug info:');
    print('  - Base64 length: ${base64Data.length}');
    print('  - Filename: $filename');
    print('  - Content type: $contentType');
    if (base64Data.isNotEmpty) {
      print(
        '  - Base64 start: ${base64Data.substring(0, math.min(20, base64Data.length))}',
      );
      print(
        '  - Base64 end: ${base64Data.substring(math.max(0, base64Data.length - 20))}',
      );
    }
    
    throw Exception('Nie udało się pobrać pliku: $e');
  }
}
