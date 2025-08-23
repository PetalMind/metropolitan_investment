import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/investor_summary.dart';
import 'base_service.dart';

/// Serwis obsługi email i eksportu danych
///
/// Zapewnia funkcjonalności wysyłania maili do klientów
/// oraz eksportu danych inwestorów do różnych formatów.
class EmailAndExportService extends BaseService {
  /// Wysyła email z listą inwestycji do klienta
  ///
  /// @param clientId ID klienta
  /// @param clientEmail Email klienta
  /// @param clientName Nazwa klienta
  /// @param investmentIds Lista ID konkretnych inwestycji (opcjonalnie)
  /// @param emailTemplate Typ szablonu ('summary'|'detailed'|'custom')
  /// @param subject Temat maila (opcjonalnie)
  /// @param customMessage Dodatkowa wiadomość (opcjonalnie)
  /// @param senderEmail Email wysyłającego
  /// @param senderName Nazwa wysyłającego (opcjonalnie)
  Future<EmailSendResult> sendInvestmentEmailToClient({
    required String clientId,
    required String clientEmail,
    required String clientName,
    List<String>? investmentIds,
    String emailTemplate = 'summary',
    String? subject,
    String? customMessage,
    required String senderEmail,
    String senderName = 'Metropolitan Investment',
  }) async {
    const String cacheKey = 'send_investment_email';

    try {
      // 🔍 Walidacja danych wejściowych
      if (clientId.isEmpty || clientEmail.isEmpty || clientName.isEmpty) {
        throw Exception('Wymagane są: clientId, clientEmail, clientName');
      }

      if (senderEmail.isEmpty) {
        throw Exception('Wymagany jest senderEmail');
      }

      // Walidacja formatu email
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(clientEmail)) {
        throw Exception('Nieprawidłowy format email klienta');
      }
      if (!emailRegex.hasMatch(senderEmail)) {
        throw Exception('Nieprawidłowy format email wysyłającego');
      }

      // 🔄 Przygotuj dane do wysłania do Firebase Functions
      final functionData = {
        'clientId': clientId,
        'clientEmail': clientEmail,
        'clientName': clientName,
        if (investmentIds != null && investmentIds.isNotEmpty)
          'investmentIds': investmentIds,
        'emailTemplate': emailTemplate,
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        if (customMessage != null && customMessage.isNotEmpty)
          'customMessage': customMessage,
        'senderEmail': senderEmail,
        'senderName': senderName,
      };

      logDebug(
        'sendInvestmentEmailToClient',
        'Wysyłam email przez Firebase Functions: ${functionData.keys}',
      );

      // 🔥 Wywołaj Firebase Functions
      final result = await FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('sendInvestmentEmailToClient').call(functionData);

      logDebug('sendInvestmentEmailToClient', 'Email wysłany pomyślnie');

      // 🎯 Przetwórz wynik
      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        // ♻️ Wyczyść cache po pomyślnej operacji
        clearCache(cacheKey);

        return EmailSendResult.fromJson(data);
      } else {
        throw Exception(
          'Wysyłanie maila nie powiodło się: ${data['error'] ?? 'Nieznany błąd'}',
        );
      }
    } catch (e) {
      logError('sendInvestmentEmailToClient', e);

      if (e.toString().contains('PERMISSION_DENIED') ||
          e.toString().contains('unauthenticated')) {
        throw Exception(
          'Brak uprawnień do wysyłania maili. Zaloguj się ponownie.',
        );
      } else if (e.toString().contains('not-found')) {
        throw Exception('Nie znaleziono inwestycji dla podanego klienta.');
      } else if (e.toString().contains('invalid-argument')) {
        throw Exception('Nieprawidłowe dane wejściowe: ${e.toString()}');
      } else if (e.toString().contains('EAUTH') ||
          e.toString().contains('ENOTFOUND')) {
        throw Exception(
          'Błąd konfiguracji serwera email. Skontaktuj się z administratorem.',
        );
      } else {
        throw Exception('Błąd podczas wysyłania maila: $e');
      }
    }
  }

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

      const supportedFormats = ['csv', 'json', 'excel'];
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
      final result = await FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('exportInvestorsData').call(functionData);

      logDebug('exportInvestorsData', 'Eksport zakończony pomyślnie');

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

  /// Helper: Wysyłaj email do wielu klientów (batch)
  Future<List<EmailSendResult>> sendEmailsToMultipleClients({
    required List<InvestorSummary> investors,
    String emailTemplate = 'summary',
    String? subject,
    String? customMessage,
    required String senderEmail,
    String senderName = 'Metropolitan Investment',
  }) async {
    final results = <EmailSendResult>[];

    for (final investor in investors) {
      try {
        final result = await sendInvestmentEmailToClient(
          clientId: investor.client.id,
          clientEmail: investor.client.email ?? '',
          clientName: investor.client.name,
          emailTemplate: emailTemplate,
          subject: subject,
          customMessage: customMessage,
          senderEmail: senderEmail,
          senderName: senderName,
        );
        results.add(result);
      } catch (e) {
        logError(
          'sendEmailsToMultipleClients',
          'Błąd wysyłania do ${investor.client.name}: $e',
        );
        // Dodaj wynik błędu
        results.add(
          EmailSendResult(
            success: false,
            messageId: '',
            clientEmail: investor.client.email ?? '',
            clientName: investor.client.name,
            investmentCount: 0,
            totalAmount: 0,
            executionTimeMs: 0,
            template: emailTemplate,
            error: e.toString(),
          ),
        );
      }
    }

    return results;
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
                'clientEmail': investor.client.email ?? '',
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
              clientEmail: investor.client.email ?? '',
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

  /// 📧 Wysyła niestandardowe maile HTML do mieszanych odbiorców (inwestorzy + dodatkowe emaile)
  Future<List<EmailSendResult>> sendCustomEmailsToMixedRecipients({
    required List<InvestorSummary> investors,
    required List<String> additionalEmails,
    String? subject,
    required String htmlContent,
    bool includeInvestmentDetails = false,
    required String senderEmail,
    String senderName = 'Metropolitan Investment',
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
                'clientEmail': investor.client.email ?? '',
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
        'senderEmail': senderEmail,
        'senderName': senderName,
      };

      logDebug(
        'sendCustomEmailsToMixedRecipients',
        'Wysyłam do ${investors.length} inwestorów + ${additionalEmails.length} dodatkowych maili',
      );

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
            clientEmail: investor.client.email ?? '',
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

      if (kDebugMode) {
        print(
          '[EmailAndExportService] exportInvestorsAdvanced: '
          'clientIds=${clientIds.length}, format=$exportFormat',
        );
      }

      // 🔥 Wywołaj funkcję Firebase Functions
      final result = await FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('exportInvestorsAdvanced').call(functionData);

      if (kDebugMode) {
        print(
          '[EmailAndExportService] Eksport zaawansowany zakończony pomyślnie',
        );
      }

      return AdvancedExportResult.fromMap(result.data);
    } catch (e) {
      if (kDebugMode) {
        print('[EmailAndExportService] Błąd exportInvestorsAdvanced: $e');
      }
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
      downloadUrl: map['downloadUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'] ?? 0,
      exportFormat: map['exportFormat'] ?? '',
      errorMessage: map['errorMessage'],
      processingTimeMs: map['processingTimeMs'] ?? 0,
      totalRecords: map['totalRecords'] ?? 0,
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
