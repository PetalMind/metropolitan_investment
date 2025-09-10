import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import '../models/investor_summary.dart';
import '../models/email_attachment.dart';
import 'base_service.dart';

/// Serwis obsługi email i eksportu danych
///
/// Zapewnia funkcjonalności wysyłania maili do klientów
/// oraz eksportu danych inwestorów do różnych formatów.
class EmailAndExportService extends BaseService {
  /// Wysyła email z listą inwestycji do klienta
  /// Eksportuje dane wybranych inwestorów
  ///
  /// @param clientIds Lista ID klientów do eksportu
  /// @param exportFormat Format eksportu ('csv'|'json'|'excel')
  /// @param includeFields Pola do uwzględnienia w eksporcie
  /// @param filters Filtry danych (opcjonalnie)
  /// @param sortBy Pole sortowania (opcjonalnie)
  /// @param sortDescending Kierunek sortowania (opcjonalnie)
  /// @param exportTitle Tytuł eksportu (opcjonalnie)
  /// @param requestedBy Email osoby żądającej eksportu
  /// @param includePersonalData Czy uwzględnić dane osobowe
  Future<ExportResult> exportInvestorsData({
    required List<String> clientIds,
    String exportFormat = 'csv',
    List<String> includeFields = const [
      'clientName',
      'totalInvestmentAmount',
      'totalRemainingCapital',
      'investmentCount',
    ],
    Map<String, dynamic>? filters,
    String sortBy = 'totalRemainingCapital',
    bool sortDescending = true,
    String exportTitle = 'Raport Inwestorów',
    required String requestedBy,
    bool includePersonalData = false,
  }) async {
    const String cacheKey = 'export_investors_data';

    try {
      // 🔍 Walidacja danych wejściowych
      if (clientIds.isEmpty) {
        throw Exception('Lista clientIds nie może być pusta');
      }

      if (clientIds.length > 1000) {
        throw Exception('Maksymalna liczba klientów w jednym eksporcie: 1000');
      }

      if (requestedBy.isEmpty) {
        throw Exception('Wymagany jest requestedBy (email osoby żądającej)');
      }

      const supportedFormats = ['csv', 'json', 'excel', 'pdf', 'word'];
      if (!supportedFormats.contains(exportFormat)) {
        throw Exception(
          'Nieprawidłowy format eksportu. Dostępne: ${supportedFormats.join(', ')}',
        );
      }

      // 🔄 Przygotuj dane do wysłania do Firebase Functions
      final functionData = {
        'clientIds': clientIds,
        'exportFormat': exportFormat,
        'includeFields': includeFields,
        if (filters != null && filters.isNotEmpty) 'filters': filters,
        'sortBy': sortBy,
        'sortDescending': sortDescending,
        'exportTitle': exportTitle,
        'requestedBy': requestedBy,
        'includePersonalData': includePersonalData,
      };

      logDebug(
        'exportInvestorsData',
        'Eksportuję ${clientIds.length} klientów w formacie $exportFormat',
      );

      // 🔥 Wywołaj Firebase Functions
      if (kIsWeb) {
        // Use the HTTP endpoint for web to avoid callable CORS preflight issues
        final baseUrl = 'https://europe-west1-${await _getFirebaseProjectId()}.cloudfunctions.net';
        final url = Uri.parse('$baseUrl/exportInvestorsDataHttp');

        final body = {
          'data': functionData,
        };

        final resp = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
          final resultMap = decoded['result'] as Map<String, dynamic>? ?? {};
          return ExportResult.fromJson(resultMap);
        } else {
          throw Exception('HTTP export failed: ${resp.statusCode} ${resp.body}');
        }
      } else {
        final result = await FirebaseFunctions.instanceFor(
          region: 'europe-west1',
        ).httpsCallable('exportInvestorsData').call(functionData);

        // 🎯 Przetwórz wynik
        final data = result.data as Map<String, dynamic>;

        if (data['success'] == true) {
          // ♻️ Wyczyść cache po pomyślnej operacji
          clearCache(cacheKey);

          return ExportResult.fromJson(data);
        } else {
          throw Exception(
            'Eksport nie powiódł się: ${data['error'] ?? 'Nieznany błąd'}',
          );
        }
      }
      // NOTE: branches above return or throw
    } catch (e) {
      logError('exportInvestorsData', e);

      if (e.toString().contains('PERMISSION_DENIED') ||
          e.toString().contains('unauthenticated')) {
        throw Exception(
          'Brak uprawnień do eksportu danych. Zaloguj się ponownie.',
        );
      } else if (e.toString().contains('not-found')) {
        throw Exception(
          'Nie znaleziono danych spełniających kryteria eksportu.',
        );
      } else if (e.toString().contains('invalid-argument')) {
        throw Exception('Nieprawidłowe dane wejściowe: ${e.toString()}');
      } else {
        throw Exception('Błąd podczas eksportu danych: $e');
      }
    }
  }

  /// Helper: Eksportuj wybranych inwestorów z obiektu InvestorSummary
  Future<ExportResult> exportSelectedInvestors(
    List<InvestorSummary> selectedInvestors, {
    String exportFormat = 'csv',
    List<String> includeFields = const [
      'clientName',
      'totalInvestmentAmount',
      'totalRemainingCapital',
      'investmentCount',
    ],
    String exportTitle = 'Wybrani Inwestorzy',
    required String requestedBy,
    bool includePersonalData = false,
  }) async {
    final clientIds = selectedInvestors
        .map((investor) => investor.client.id)
        .toList();

    return exportInvestorsData(
      clientIds: clientIds,
      exportFormat: exportFormat,
      includeFields: includeFields,
      exportTitle: exportTitle,
      requestedBy: requestedBy,
      includePersonalData: includePersonalData,
    );
  }

  /// Eksportuje inwestorów do zaawansowanych formatów (PDF, Excel, Word)
  ///
  /// @param clientIds Lista ID klientów do eksportu
  /// @param exportFormat Format eksportu ('pdf'|'excel'|'word')
  /// @param templateType Typ szablonu ('summary'|'detailed'|'custom')
  /// @param options Opcje eksportu (includingKontakty, includeInvestycje, etc.)
  /// @param requestedBy ID użytkownika wywołującego eksport
  Future<AdvancedExportResult> exportInvestorsAdvanced({
    required List<String> clientIds,
    required String exportFormat, // 'pdf', 'excel', 'word'
    String templateType = 'summary',
    Map<String, dynamic> options = const {},
    required String requestedBy,
  }) async {
    try {
      // 🔍 Walidacja danych wejściowych
      if (clientIds.isEmpty) {
        throw Exception('Lista clientIds nie może być pusta');
      }

      if (!['pdf', 'excel', 'word'].contains(exportFormat)) {
        throw Exception('Nieobsługiwany format eksportu: $exportFormat');
      }

      if (requestedBy.isEmpty) {
        throw Exception('Wymagane jest requestedBy');
      }

      // Przygotuj dane dla funkcji Firebase
      final functionData = {
        'clientIds': clientIds,
        'exportFormat': exportFormat,
        'templateType': templateType,
        'options': options,
        'requestedBy': requestedBy,
      };

      logDebug(
        'exportInvestorsAdvanced',
        'Wywołuję funkcję: clientIds=${clientIds.length}, format=$exportFormat',
      );

      // 🔥 Wywołaj funkcję Firebase Functions
      final result = await FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('exportInvestorsAdvanced').call(functionData);

      logDebug(
        'exportInvestorsAdvanced',
        'Eksport zaawansowany zakończony pomyślnie',
      );

      return AdvancedExportResult.fromMap(result.data);
    } catch (e) {
      logError('exportInvestorsAdvanced', e);
      return AdvancedExportResult(
        success: false,
        downloadUrl: null,
        fileName: null,
        fileSize: 0,
        exportFormat: exportFormat,
        errorMessage: e.toString(),
        processingTimeMs: 0,
        totalRecords: clientIds.length,
      );
    }
  }

  String getThemedEmailTemplate({
    required String subject,
    required String content,
    required String investorName,
    String? investmentDetailsHtml,
  }) {
    final now = DateTime.now();
    final currentYear = now.year;

    return """
<!DOCTYPE html>
<html lang="pl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$subject</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      background-color: #f0f2f5;
      color: #1c1e21;
      margin: 0;
      padding: 0;
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
    }
    .email-container {
      max-width: 680px;
      margin: 20px auto;
      background-color: #ffffff;
      border-radius: 12px;
      overflow: hidden;
      border: 1px solid #dddfe2;
      box-shadow: 0 4px 12px rgba(0,0,0,0.08);
    }
    .email-header {
      background-color: #2c2c2c;
      padding: 32px;
      text-align: center;
    }
    .email-header h1 {
      color: #d4af37; /* Gold accent */
      margin: 0;
      font-size: 28px;
      font-weight: 600;
      letter-spacing: 0.5px;
    }
    .email-content {
      padding: 32px;
    }
    .email-content p {
      line-height: 1.6;
      font-size: 16px;
      margin: 1em 0;
    }
    .email-content a {
      color: #d4af37;
      text-decoration: none;
      font-weight: 500;
    }
    .email-footer {
      background-color: #f7f7f7;
      padding: 24px;
      text-align: center;
      font-size: 12px;
      color: #606770;
      border-top: 1px solid #dddfe2;
    }
    .investment-details {
      margin-top: 24px;
      border-top: 1px solid #e9e9e9;
      padding-top: 16px;
    }
    .investment-details h3 {
      font-size: 18px;
      color: #2c2c2c;
      margin-bottom: 12px;
    }
  </style>
</head>
<body>
  <div class="email-container">
    <div class="email-header">
      <h1>Metropolitan Investment</h1>
    </div>
    <div class="email-content">
      <p>Witaj $investorName,</p>
      $content
      ${investmentDetailsHtml != null && investmentDetailsHtml.isNotEmpty ? '<div class="investment-details">$investmentDetailsHtml</div>' : ''}
    </div>
    <div class="email-footer">
      <p>&copy; $currentYear Metropolitan Investment S.A. Wszelkie prawa zastrzeżone.</p>
      <p>Ta wiadomość została wygenerowana automatycznie. Prosimy na nią nie odpowiadać.</p>
    </div>
  </div>
</body>
</html>
""";
  }

  /// Wysyła niestandardowe maile HTML do wielu klientów z edytora Quill
  Future<List<EmailSendResult>> sendCustomEmailsToMultipleClients({
    required List<InvestorSummary> investors,
    String? subject,
    required String htmlContent,
    bool includeInvestmentDetails = false,
    required String senderEmail,
    String senderName = 'Metropolitan Investment',
  }) async {
    const String cacheKey = 'send_custom_emails';

    try {
      // Walidacja danych wejściowych
      if (investors.isEmpty) {
        throw Exception('Lista inwestorów nie może być pusta');
      }

      if (senderEmail.isEmpty) {
        throw Exception('Wymagany jest email wysyłającego');
      }

      if (htmlContent.isEmpty) {
        throw Exception('Treść email nie może być pusta');
      }

      // Przygotuj dane do wysłania do Firebase Functions
      final functionData = {
        'recipients': investors
            .map(
              (investor) => {
                'clientId': investor.client.id,
                'clientEmail': investor.client.email,
                'clientName': investor.client.name,
                'investmentCount': investor.investmentCount,
                'totalAmount': investor.totalRemainingCapital,
              },
            )
            .toList(),
        'htmlContent': htmlContent,
        'subject': subject ?? 'Wiadomość od $senderName',
        'includeInvestmentDetails': includeInvestmentDetails,
        'senderEmail': senderEmail,
        'senderName': senderName,
      };

      logDebug(
        'sendCustomEmailsToMultipleClients',
        'Wysyłam ${investors.length} niestandardowych maili',
      );

      // Wywołaj Firebase Functions
      final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('sendCustomHtmlEmailsToMultipleClients')
          .call(functionData);

      logDebug(
        'sendCustomEmailsToMultipleClients',
        'Maile niestandardowe wysłane pomyślnie',
      );

      // Przetwórz wynik
      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        clearCache(cacheKey);

        final results = <EmailSendResult>[];
        final resultsList = data['results'] as List<dynamic>? ?? [];

        for (final resultData in resultsList) {
          results.add(
            EmailSendResult.fromJson(resultData as Map<String, dynamic>),
          );
        }

        return results;
      } else {
        throw Exception(
          'Wysyłanie maili nie powiodło się: ${data['error'] ?? 'Nieznany błąd'}',
        );
      }
    } catch (e) {
      logError('sendCustomEmailsToMultipleClients', e);

      // Zwróć listę błędów dla każdego inwestora
      return investors
          .map(
            (investor) => EmailSendResult(
              success: false,
              messageId: '',
              clientEmail: investor.client.email,
              clientName: investor.client.name,
              investmentCount: investor.investmentCount,
              totalAmount: investor.totalRemainingCapital,
              executionTimeMs: 0,
              template: 'custom_html',
              error: e.toString(),
            ),
          )
          .toList();
    }
  }

  /// 📧 Wysyła emaile używając kompletnych, pre-generowanych HTML dla każdego odbiorcy
  ///
  /// Ta metoda używa tego samego HTML co pokazywany w podglądzie, eliminując różnice
  /// między podglądem a wysyłanymi emailami.
  Future<List<EmailSendResult>> sendPreGeneratedEmailsToMixedRecipients({
    required List<InvestorSummary> investors,
    required List<String> additionalEmails,
    String? subject,
    Map<String, String>? completeEmailHtmlByClient,
    String? aggregatedEmailHtmlForAdditionals,
    required String senderEmail,
    String senderName = 'Metropolitan Investment',
  }) async {
    const String cacheKey = 'send_pregenerated_emails';

    try {
      // Walidacja danych wejściowych
      if (investors.isEmpty && additionalEmails.isEmpty) {
        throw Exception(
          'Lista odbiorców (inwestorzy + dodatkowe emaile) nie może być pusta',
        );
      }

      if (senderEmail.isEmpty) {
        throw Exception('Wymagany jest email wysyłającego');
      }

      if (kDebugMode) {
        print('📧 [EmailService] Wysyłanie pre-generowanych emaili');
        print('   - Inwestorzy: ${investors.length}');
        print('   - Dodatkowe emaile: ${additionalEmails.length}');
        print('   - Complete HTML map size: ${completeEmailHtmlByClient?.length ?? 0}');
        print('   - Aggregated HTML length: ${aggregatedEmailHtmlForAdditionals?.length ?? 0}');
      }

      // Przygotuj dane do wysłania do Firebase Functions
      final functionData = {
        'recipients': investors.map((investor) => {
          'clientId': investor.client.id,
          'clientEmail': investor.client.email,
          'clientName': investor.client.name,
          'investmentCount': investor.investmentCount,
          'totalAmount': investor.totalRemainingCapital,
        }).toList(),
        'additionalEmails': additionalEmails,
        'subject': subject ?? 'Informacja o inwestycjach',
        'senderEmail': senderEmail,
        'senderName': senderName,
        'completeEmailHtmlByClient': completeEmailHtmlByClient,
        'aggregatedEmailHtmlForAdditionals': aggregatedEmailHtmlForAdditionals,
      };

      logDebug(
        'sendPreGeneratedEmailsToMixedRecipients',
        'Wysyłam ${investors.length} pre-generowanych emaili + ${additionalEmails.length} dodatkowych',
      );

      // Wywołaj nową Firebase Functions dla pre-generowanych emaili
      final result = await FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('sendPreGeneratedEmails').call(functionData);

      logDebug(
        'sendPreGeneratedEmailsToMixedRecipients',
        'Pre-generowane emaile wysłane pomyślnie',
      );

      // Przetwórz wynik
      final data = result.data as Map<String, dynamic>;
      if (data['success'] == true) {
        clearCache(cacheKey);

        final results = <EmailSendResult>[];
        final resultsList = data['results'] as List<dynamic>? ?? [];

        for (final resultData in resultsList) {
          final result = resultData as Map<String, dynamic>;
          results.add(
            EmailSendResult(
              success: result['success'] ?? false,
              messageId: result['messageId'] ?? '',
              clientEmail: result['recipientEmail'] ?? '',
              clientName: result['recipientName'] ?? '',
              investmentCount: result['investmentCount'] ?? 0,
              totalAmount: (result['totalAmount'] ?? 0).toDouble(),
              executionTimeMs: result['executionTimeMs'] ?? 0,
              template: result['template'] ?? 'pre_generated_html',
              error: result['error'],
            ),
          );
        }

        return results;
      } else {
        throw Exception(data['message'] ?? 'Nieznany błąd Firebase Functions');
      }
    } catch (e) {
      logError('sendPreGeneratedEmailsToMixedRecipients', e);

      // Zwróć listę błędów dla wszystkich odbiorców
      final results = <EmailSendResult>[];

      // Błędy dla inwestorów
      for (final investor in investors) {
        results.add(
          EmailSendResult(
            success: false,
            messageId: '',
            clientEmail: investor.client.email,
            clientName: investor.client.name,
            investmentCount: investor.investmentCount,
            totalAmount: investor.totalRemainingCapital,
            executionTimeMs: 0,
            template: 'pre_generated_html',
            error: e.toString(),
          ),
        );
      }

      // Błędy dla dodatkowych emaili
      for (final email in additionalEmails) {
        results.add(
          EmailSendResult(
            success: false,
            messageId: '',
            clientEmail: email,
            clientName: email,
            investmentCount: 0,
            totalAmount: 0,
            executionTimeMs: 0,
            template: 'pre_generated_html',
            error: e.toString(),
          ),
        );
      }

      return results;
    }
  }

  /// 📧 Wysyła niestandardowe maile HTML do mieszanych odbiorców (inwestorzy + dodatkowe emaile)
  Future<List<EmailSendResult>> sendCustomEmailsToMixedRecipients({
    required List<InvestorSummary> investors,
    required List<String> additionalEmails,
    String? subject,
    required String htmlContent,
    bool includeInvestmentDetails = false,
    bool isGroupEmail = false,
    Map<String, String>? investmentDetailsByClient,
    String? aggregatedInvestmentsForAdditionals,
    required String senderEmail,
    String senderName = 'Metropolitan Investment',
    List<EmailAttachment>? attachments,
  }) async {
    const String cacheKey = 'send_mixed_emails';

    try {
      // Walidacja danych wejściowych
      if (investors.isEmpty && additionalEmails.isEmpty) {
        throw Exception(
          'Lista odbiorców (inwestorzy + dodatkowe emaile) nie może być pusta',
        );
      }

      if (senderEmail.isEmpty) {
        throw Exception('Wymagany jest email wysyłającego');
      }

      if (htmlContent.isEmpty) {
        throw Exception('Treść email nie może być pusta');
      }

      // Przygotuj dane do wysłania do Firebase Functions
      final functionData = {
        'recipients': investors
            .map(
              (investor) => {
                'clientId': investor.client.id,
                'clientEmail': investor.client.email,
                'clientName': investor.client.name,
                'investmentCount': investor.investmentCount,
                'totalAmount': investor.totalRemainingCapital,
              },
            )
            .toList(),
        'additionalEmails': additionalEmails,
        'htmlContent': htmlContent,
        'subject': subject ?? 'Wiadomość od $senderName',
        'includeInvestmentDetails': includeInvestmentDetails,
        'isGroupEmail': isGroupEmail,
        'senderEmail': senderEmail,
        'senderName': senderName,
        if (investmentDetailsByClient != null && investmentDetailsByClient.isNotEmpty)
          'investmentDetailsByClient': investmentDetailsByClient,
        if (aggregatedInvestmentsForAdditionals != null && aggregatedInvestmentsForAdditionals.isNotEmpty)
          'aggregatedInvestmentsForAdditionals': aggregatedInvestmentsForAdditionals,
        if (attachments != null && attachments.isNotEmpty)
          'attachments': attachments.where((attachment) => attachment.content != null).map((attachment) => {
            'filename': attachment.fileName,
            'content': base64Encode(attachment.content!),
            'contentType': attachment.mimeType,
            'encoding': 'base64',
          }).toList(),
      };

      logDebug(
        'sendCustomEmailsToMixedRecipients',
        'Wysyłam do ${investors.length} inwestorów + ${additionalEmails.length} dodatkowych maili',
      );

      // Debug załączników
      if (attachments != null && attachments.isNotEmpty) {
        logDebug(
          'sendCustomEmailsToMixedRecipients',
          'Załączniki: ${attachments.length} plików, łączny rozmiar: ${attachments.fold(0, (sum, att) => sum + att.size)} bajtów',
        );
        for (final attachment in attachments) {
          logDebug(
            'sendCustomEmailsToMixedRecipients',
            'Załącznik: ${attachment.fileName} (${attachment.mimeType}, ${attachment.size} B)',
          );
        }
      }

      // Wywołaj nową Firebase Functions dla mieszanych odbiorców
      final result = await FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('sendEmailsToMixedRecipients').call(functionData);

      logDebug(
        'sendCustomEmailsToMixedRecipients',
        'Maile do mieszanych odbiorców wysłane pomyślnie',
      );

      // Przetwórz wynik
      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        clearCache(cacheKey);

        final results = <EmailSendResult>[];
        final resultsList = data['results'] as List<dynamic>? ?? [];

        for (final resultData in resultsList) {
          final result = resultData as Map<String, dynamic>;
          results.add(
            EmailSendResult(
              success: result['success'] ?? false,
              messageId: result['messageId'] ?? '',
              clientEmail: result['recipientEmail'] ?? '',
              clientName: result['recipientName'] ?? '',
              investmentCount: result['investmentCount'] ?? 0,
              totalAmount: (result['totalAmount'] ?? 0).toDouble(),
              executionTimeMs: result['executionTimeMs'] ?? 0,
              template: result['template'] ?? 'mixed_html',
              error: result['error'],
            ),
          );
        }

        return results;
      } else {
        throw Exception(
          'Wysyłanie maili do mieszanych odbiorców nie powiodło się: ${data['error'] ?? 'Nieznany błąd'}',
        );
      }
    } catch (e) {
      logError('sendCustomEmailsToMixedRecipients', e);

      // Zwróć listę błędów dla wszystkich odbiorców
      final results = <EmailSendResult>[];

      // Błędy dla inwestorów
      for (final investor in investors) {
        results.add(
          EmailSendResult(
            success: false,
            messageId: '',
            clientEmail: investor.client.email,
            clientName: investor.client.name,
            investmentCount: investor.investmentCount,
            totalAmount: investor.totalRemainingCapital,
            executionTimeMs: 0,
            template: 'mixed_html',
            error: e.toString(),
          ),
        );
      }

      // Błędy dla dodatkowych emaili
      for (final email in additionalEmails) {
        results.add(
          EmailSendResult(
            success: false,
            messageId: '',
            clientEmail: email,
            clientName: email,
            investmentCount: 0,
            totalAmount: 0.0,
            executionTimeMs: 0,
            template: 'mixed_html',
            error: e.toString(),
          ),
        );
      }

      return results;
    }
  }
}

/// Tries to obtain the Firebase project id from default Firebase app options.
/// Falls back to 'metropolitan-investment' if not available.
Future<String> _getFirebaseProjectId() async {
  try {
    final app = Firebase.app();
    final options = app.options;
    return options.projectId;
  } catch (e) {
    return 'metropolitan-investment';
  }
}

/// 🎯 Model wyniku wysyłania maila
class EmailSendResult {
  final bool success;
  final String messageId;
  final String clientEmail;
  final String clientName;
  final int investmentCount;
  final double totalAmount;
  final int executionTimeMs;
  final String template;
  final String? error;

  const EmailSendResult({
    required this.success,
    required this.messageId,
    required this.clientEmail,
    required this.clientName,
    required this.investmentCount,
    required this.totalAmount,
    required this.executionTimeMs,
    required this.template,
    this.error,
  });

  factory EmailSendResult.fromJson(Map<String, dynamic> json) {
    return EmailSendResult(
      success: json['success'] ?? false,
      messageId: json['messageId'] ?? '',
      clientEmail: json['clientEmail'] ?? '',
      clientName: json['clientName'] ?? '',
      investmentCount: json['investmentCount'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      executionTimeMs: json['executionTimeMs'] ?? 0,
      template: json['template'] ?? '',
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'messageId': messageId,
      'clientEmail': clientEmail,
      'clientName': clientName,
      'investmentCount': investmentCount,
      'totalAmount': totalAmount,
      'executionTimeMs': executionTimeMs,
      'template': template,
      if (error != null) 'error': error,
    };
  }

  /// Formatowany opis wyniku
  String get formattedResult {
    if (success) {
      return '✅ $clientName ($clientEmail): $investmentCount inwestycji, ${totalAmount.toStringAsFixed(2)} PLN - ${executionTimeMs}ms';
    } else {
      return '❌ $clientName ($clientEmail): ${error ?? 'Nieznany błąd'}';
    }
  }
}

/// 🎯 Model wyniku eksportu
class ExportResult {
  final bool success;
  final String format;
  final int recordCount;
  final int totalProcessed;
  final int totalErrors;
  final int executionTimeMs;
  final String exportTitle;
  final String data; // Dane eksportu lub URL
  final String filename;
  final int? size;

  const ExportResult({
    required this.success,
    required this.format,
    required this.recordCount,
    required this.totalProcessed,
    required this.totalErrors,
    required this.executionTimeMs,
    required this.exportTitle,
    required this.data,
    required this.filename,
    this.size,
  });

  factory ExportResult.fromJson(Map<String, dynamic> json) {
    return ExportResult(
      success: json['success'] ?? false,
      format: json['format'] ?? '',
      recordCount: json['recordCount'] ?? 0,
      totalProcessed: json['totalProcessed'] ?? 0,
      totalErrors: json['totalErrors'] ?? 0,
      executionTimeMs: json['executionTimeMs'] ?? 0,
      exportTitle: json['exportTitle'] ?? '',
      data: json['data'] ?? '',
      filename: json['filename'] ?? '',
      size: json['size'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'format': format,
      'recordCount': recordCount,
      'totalProcessed': totalProcessed,
      'totalErrors': totalErrors,
      'executionTimeMs': executionTimeMs,
      'exportTitle': exportTitle,
      'data': data,
      'filename': filename,
      if (size != null) 'size': size,
    };
  }

  /// Formatowane podsumowanie eksportu
  String get formattedSummary {
    final successRate = totalProcessed > 0
        ? ((totalProcessed - totalErrors) / totalProcessed * 100)
              .toStringAsFixed(1)
        : '0.0';

    return '''
Eksport: $exportTitle
• Format: ${format.toUpperCase()}
• Rekordów: $recordCount (z $totalProcessed przetworzonych)
• Błędów: $totalErrors (sukces: $successRate%)
• Plik: $filename
• Rozmiar: ${size != null ? '${(size! / 1024).toStringAsFixed(1)} KB' : 'nieznany'}
• Czas wykonania: ${executionTimeMs}ms
'''
        .trim();
  }

  /// Czy eksport miał błędy
  bool get hasErrors => totalErrors > 0;

  /// Czy eksport był w pełni udany
  bool get isFullySuccessful => success && totalErrors == 0;
}

/// Wynik zaawansowanego eksportu (PDF, Excel, Word)
class AdvancedExportResult {
  final bool success;
  final String? downloadUrl;
  final String? fileName;
  final int fileSize;
  final String exportFormat;
  final String? errorMessage;
  final int processingTimeMs;
  final int totalRecords;

  const AdvancedExportResult({
    required this.success,
    required this.downloadUrl,
    required this.fileName,
    required this.fileSize,
    required this.exportFormat,
    this.errorMessage,
    required this.processingTimeMs,
    required this.totalRecords,
  });

  factory AdvancedExportResult.fromMap(Map<String, dynamic> map) {
    return AdvancedExportResult(
      success: map['success'] ?? false,
      downloadUrl: map['fileData'], // Zmiana: używamy fileData jako downloadUrl
      fileName: map['filename'], // Zmiana: używamy filename zamiast fileName
      fileSize: map['fileSize'] ?? 0,
      exportFormat: map['format'] ?? '', // Zmiana: używamy format zamiast exportFormat
      errorMessage: map['errorMessage'] ?? map['error'],
      processingTimeMs: map['executionTimeMs'] ?? 0, // Zmiana: używamy executionTimeMs
      totalRecords: map['recordCount'] ?? 0, // Zmiana: używamy recordCount
    );
  }

  /// Formatowane info o wyniku
  String get summaryText {
    if (!success) {
      return 'Eksport niepowodzenie: ${errorMessage ?? "Nieznany błąd"}';
    }

    final sizeText = _formatFileSize(fileSize);
    final timeText = '${processingTimeMs}ms';

    return 'Eksport $exportFormat zakończony: $fileName ($sizeText) - $totalRecords rekordów w $timeText';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Czy eksport zakończył się sukcesem
  bool get isSuccessful => success && downloadUrl != null;
}
