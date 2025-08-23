import 'dart:html' as html;
import 'dart:convert';

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
    print('🔍 [DownloadHelper] Base64 sample: ${base64Data.substring(0, 50)}...');
    
    // Decode base64 to bytes
    final bytes = base64Decode(base64Data);
    print('🔍 [DownloadHelper] Decoded bytes length: ${bytes.length}');
    
    // Check if it looks like an Excel file (should start with PK)
    if (bytes.length > 2) {
      final header = String.fromCharCodes(bytes.take(2));
      print('🔍 [DownloadHelper] File header: $header');
      
      if (header != 'PK' && filename.toLowerCase().endsWith('.xlsx')) {
        print('⚠️ [DownloadHelper] Warning: Excel file should start with "PK" but starts with "$header"');
      }
    }
    
    // Create blob with proper content type
    final blob = html.Blob([bytes], contentType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    print('🔍 [DownloadHelper] Blob URL created: ${url.substring(0, 50)}...');
    
    // Create download link
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';
    
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    
    print('✅ [DownloadHelper] Download completed: $filename');
  } catch (e) {
    print('❌ [DownloadHelper] Błąd pobierania pliku: $e');
    print('❌ [DownloadHelper] Stack trace: ${StackTrace.current}');
    throw Exception('Nie udało się pobrać pliku: $e');
  }
}
