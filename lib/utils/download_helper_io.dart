import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> downloadFileFromUrl(String url, {String? filename}) async {
  // For remote URLs on IO platforms, try to open in browser
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
    return;
  }

  // Otherwise, do nothing
  debugPrint('[download_helper_io] cannot launch url: $url');
}

Future<void> downloadRawData(String data, String filename, {String mime = 'text/csv'}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(data);

  // Try to open the file with the platform default
  final uri = Uri.file(file.path);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    debugPrint('[download_helper_io] saved file to ${file.path} but cannot open automatically');
  }
}

Future<void> downloadBase64File(String base64Data, String filename, String contentType) async {
  try {
    // Decode base64 to bytes
    final bytes = base64Decode(base64Data);
    
    // Get directory and write file
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    
    // Try to open the file with the platform default
    final uri = Uri.file(file.path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('[download_helper_io] saved file to ${file.path} but cannot open automatically');
    }
  } catch (e) {
    debugPrint('❌ Błąd pobierania pliku: $e');
    throw Exception('Nie udało się pobrać pliku: $e');
  }
}
