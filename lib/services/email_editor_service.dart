import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../models_and_services.dart';

/// Wynik wysyłki emaili z serwisu edytora
class EmailEditorResult {
  final bool success;
  final String message;
  final int totalSent;
  final int totalFailed;
  final List<EmailSendResult> detailedResults;
  final Duration duration;

  EmailEditorResult({
    required this.success,
    required this.message,
    required this.totalSent,
    required this.totalFailed,
    required this.detailedResults,
    required this.duration,
  });
}

/// Serwis zarządzający logiką biznesową edytora emaili
///
/// Obsługuje:
/// - Zarządzanie odbiorcami (inwestorzy + dodatkowe emaile)
/// - Walidację danych przed wysyłką
/// - Konwersję treści Quill do HTML
/// - Wysyłanie emaili z wykorzystaniem EmailAndExportService
/// - Logowanie procesu wysyłki z debugowaniem
/// - Zarządzanie szablonami (przyszłość)
class EmailEditorService extends BaseService {
  final EmailAndExportService _emailAndExportService = EmailAndExportService();
  final SmtpService _smtpService = SmtpService();

  /// Stan odbiorców - mapowanie ID klienta na status włączenia/wyłączenia
  final Map<String, bool> _recipientEnabled = {};

  /// Stan emaili odbiorców - mapowanie ID klienta na aktualny email
  final Map<String, String> _recipientEmails = {};

  /// Lista dodatkowych emaili poza inwestorami
  final List<String> _additionalEmails = [];

  /// Lista logów debugowania dla bieżącej operacji
  final List<String> _debugLogs = [];

  /// Czas rozpoczęcia wysyłki emaili
  DateTime? _emailSendStartTime;

  // === GETTERS FOR STATE ===

  Map<String, bool> get recipientEnabled => Map.unmodifiable(_recipientEnabled);
  Map<String, String> get recipientEmails => Map.unmodifiable(_recipientEmails);
  List<String> get additionalEmails => List.unmodifiable(_additionalEmails);
  List<String> get debugLogs => List.unmodifiable(_debugLogs);
  DateTime? get emailSendStartTime => _emailSendStartTime;

  // === RECIPIENT MANAGEMENT ===

  /// Inicjalizuje stan odbiorców na podstawie listy inwestorów
  void initializeRecipients(List<InvestorSummary> investors) {
    _recipientEnabled.clear();
    _recipientEmails.clear();

    for (final investor in investors) {
      final clientId = investor.client.id;
      final email = investor.client.email;

      // Włącz odbiorcę tylko jeśli ma prawidłowy email
      _recipientEnabled[clientId] =
          email.isNotEmpty &&
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
      _recipientEmails[clientId] = email;
    }
  }

  /// Przełącza status włączenia odbiorcy
  void toggleRecipientEnabled(String clientId, bool enabled) {
    _recipientEnabled[clientId] = enabled;
  }

  /// Aktualizuje email odbiorcy
  void updateRecipientEmail(String clientId, String email) {
    _recipientEmails[clientId] = email;

    // Automatycznie włącz/wyłącz w zależności od poprawności emaila
    final isValidEmail =
        email.isNotEmpty &&
        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    _recipientEnabled[clientId] = isValidEmail;
  }

  /// Dodaje nowy dodatkowy email
  void addAdditionalEmail([String email = '']) {
    _additionalEmails.add(email);
  }

  /// Aktualizuje dodatkowy email na określonym indeksie
  void updateAdditionalEmail(int index, String email) {
    if (index >= 0 && index < _additionalEmails.length) {
      _additionalEmails[index] = email;
    }
  }

  /// Usuwa dodatkowy email na określonym indeksie
  void removeAdditionalEmail(int index) {
    if (index >= 0 && index < _additionalEmails.length) {
      _additionalEmails.removeAt(index);
    }
  }

  /// Sprawdza czy istnieją prawidłowi odbiorcy
  bool hasValidRecipients(List<InvestorSummary> investors) {
    // Sprawdź inwestorów z prawidłowymi emailami
    final hasValidInvestorEmails = investors.any((investor) {
      final clientId = investor.client.id;
      final email = _recipientEmails[clientId] ?? investor.client.email;
      return _recipientEnabled[clientId] == true &&
          email.isNotEmpty &&
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    });

    // Sprawdź dodatkowe emaile
    final hasValidAdditionalEmails = _additionalEmails.any(
      (email) =>
          email.isNotEmpty &&
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email),
    );

    return hasValidInvestorEmails || hasValidAdditionalEmails;
  }

  /// Pobiera listę aktywnych odbiorców z ich danymi
  List<Map<String, String>> getEnabledRecipients(
    List<InvestorSummary> investors,
  ) {
    final recipients = <Map<String, String>>[];

    // Dodaj aktywnych inwestorów
    for (final investor in investors) {
      final clientId = investor.client.id;
      if (_recipientEnabled[clientId] == true) {
        final email = _recipientEmails[clientId] ?? investor.client.email;
        recipients.add({
          'id': clientId,
          'email': email,
          'name': investor.client.name,
          'type': 'investor',
        });
      }
    }

    // Dodaj dodatkowe emaile
    for (int i = 0; i < _additionalEmails.length; i++) {
      final email = _additionalEmails[i];
      if (email.isNotEmpty &&
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
        recipients.add({
          'id': 'additional_$i',
          'email': email,
          'name': 'Dodatkowy odbiorca',
          'type': 'additional',
        });
      }
    }

    return recipients;
  }

  // === SMTP CONFIGURATION ===

  /// Pobiera domyślny email wysyłającego z konfiguracji SMTP
  Future<String?> getSmtpSenderEmail() async {
    try {
      final smtpSettings = await _smtpService.getSmtpSettings();
      return smtpSettings?.username;
    } catch (e) {
      logError('getSmtpSenderEmail', e);
      return null;
    }
  }

  /// Sprawdza czy konfiguracja SMTP jest dostępna
  Future<bool> isSmtpConfigured() async {
    try {
      final smtpSettings = await _smtpService.getSmtpSettings();
      return smtpSettings != null && smtpSettings.host.isNotEmpty;
    } catch (e) {
      logError('isSmtpConfigured', e);
      return false;
    }
  }

  // === CONTENT CONVERSION ===

  /// Konwertuje dokument Quill na HTML
  String convertDocumentToHtml(Document document) {
    try {
      // Próbuj użyć standardowej konwersji (jeśli dostępna)
      return _customDocumentToHtml(document);
    } catch (e) {
      logError('convertDocumentToHtml', e);
      // Fallback - zwróć plain text w prostym HTML
      return '<p>${_escapeHtml(document.toPlainText())}</p>';
    }
  }

  /// Niestandardowa konwersja dokumentu Quill do HTML
  String _customDocumentToHtml(Document document) {
    try {
      final buffer = StringBuffer();

      for (final delta in document.toDelta().toList()) {
        if (delta.data is String) {
          final text = delta.data as String;
          final attributes = delta.attributes;

          // Obsłuż nowe linie
          if (text.contains('\n')) {
            final lines = text.split('\n');
            for (int i = 0; i < lines.length; i++) {
              if (lines[i].isNotEmpty) {
                buffer.write(_applyFormattingToText(lines[i], attributes));
              }
              if (i < lines.length - 1) {
                buffer.write('<br>');
              }
            }
          } else {
            buffer.write(_applyFormattingToText(text, attributes));
          }
        }
      }

      return buffer.toString();
    } catch (e) {
      logError('_customDocumentToHtml', e);
      return '<p>${_escapeHtml(document.toPlainText())}</p>';
    }
  }

  /// Aplikuje formatowanie HTML na podstawie atrybutów Quill
  String _applyFormattingToText(String text, Map<String, dynamic>? attributes) {
    if (attributes == null || attributes.isEmpty) {
      return _escapeHtml(text);
    }

    String result = _escapeHtml(text);

    // Formatowanie tekstu
    if (attributes['bold'] == true) {
      result = '<strong>$result</strong>';
    }

    if (attributes['italic'] == true) {
      result = '<em>$result</em>';
    }

    if (attributes['underline'] == true) {
      result = '<u>$result</u>';
    }

    // Kolor tekstu
    if (attributes['color'] != null) {
      result = '<span style="color: ${attributes['color']}">$result</span>';
    }

    // Kolor tła
    if (attributes['background'] != null) {
      result =
          '<span style="background-color: ${attributes['background']}">$result</span>';
    }

    // Rozmiar czcionki
    if (attributes['size'] != null) {
      result = '<span style="font-size: ${attributes['size']}">$result</span>';
    }

    // Wyrównanie (zastosowane na poziomie akapitu)
    if (attributes['align'] != null) {
      result = '<div style="text-align: ${attributes['align']}">$result</div>';
    }

    // Nagłówki
    if (attributes['header'] != null) {
      final level = attributes['header'] as int;
      if (level >= 1 && level <= 6) {
        result = '<h$level>$result</h$level>';
      }
    }

    // Listy
    if (attributes['list'] != null) {
      final listType = attributes['list'] as String;
      if (listType == 'ordered') {
        result = '<ol><li>$result</li></ol>';
      } else if (listType == 'bullet') {
        result = '<ul><li>$result</li></ul>';
      }
    }

    // Cytaty
    if (attributes['blockquote'] == true) {
      result = '<blockquote>$result</blockquote>';
    }

    return result;
  }

  /// Escape HTML w tekście
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  // === EMAIL SENDING ===

  /// Wysyła emaile do wybranych odbiorców
  ///
  /// [investors] - lista inwestorów do wysyłki
  /// [subject] - temat emaila
  /// [htmlContent] - treść w formacie HTML
  /// [includeInvestmentDetails] - czy dołączyć szczegóły inwestycji
  /// [senderEmail] - email wysyłającego
  /// [senderName] - nazwa wysyłającego
  /// [onProgress] - callback postępu wysyłki (opcjonalny)
  Future<EmailSendResult> sendEmails({
    required List<InvestorSummary> investors,
    required String subject,
    required String htmlContent,
    required bool includeInvestmentDetails,
    required String senderEmail,
    required String senderName,
    Function(String message)? onProgress,
    Function(String log)? onDebugLog,
  }) async {
    try {
      // Reset stanu debugowania
      _emailSendStartTime = DateTime.now();
      _debugLogs.clear();
      _addDebugLog('🚀 Rozpoczynam proces wysyłania maili', onDebugLog);

      // Walidacja konfiguracji SMTP
      onProgress?.call('Sprawdzam konfigurację SMTP...');
      _addDebugLog('🔧 Sprawdzam ustawienia SMTP...', onDebugLog);

      final smtpSettings = await _smtpService.getSmtpSettings();
      if (smtpSettings == null) {
        _addDebugLog('❌ Brak konfiguracji SMTP', onDebugLog);
        return EmailSendResult(
          success: false,
          messageId: '',
          clientEmail: '',
          clientName: '',
          investmentCount: 0,
          totalAmount: 0.0,
          executionTimeMs: 0,
          template: '',
          error:
              'Brak konfiguracji serwera SMTP. Skonfiguruj ustawienia email w aplikacji.',
        );
      }

      _addDebugLog(
        '✅ Konfiguracja SMTP znaleziona: ${smtpSettings.host}:${smtpSettings.port}',
        onDebugLog,
      );

      // Walidacja email wysyłającego
      if (senderEmail.trim().isEmpty) {
        _addDebugLog('❌ Brak email wysyłającego', onDebugLog);
        return EmailSendResult(
          success: false,
          messageId: '',
          clientEmail: '',
          clientName: '',
          investmentCount: 0,
          totalAmount: 0.0,
          executionTimeMs: 0,
          template: '',
          error: 'Podaj email wysyłającego',
        );
      }

      _addDebugLog('📧 Email wysyłającego: $senderEmail', onDebugLog);

      // Przygotowanie odbiorców
      onProgress?.call('Przygotowywanie listy odbiorców...');
      final enabledRecipients = getEnabledRecipients(investors);
      _addDebugLog(
        '👥 Znaleziono ${enabledRecipients.length} aktywnych odbiorców',
        onDebugLog,
      );

      if (enabledRecipients.isEmpty) {
        _addDebugLog('❌ Brak prawidłowych odbiorców', onDebugLog);
        return EmailSendResult(
          success: false,
          clientEmail: '',
          error: 'Brak odbiorców z prawidłowymi adresami email',
        );
      }

      // Walidacja treści
      onProgress?.call('Sprawdzam treść emaila...');
      if (htmlContent.trim().isEmpty) {
        _addDebugLog('❌ Brak treści emaila', onDebugLog);
        return EmailSendResult(
          success: false,
          clientEmail: '',
          error: 'Treść emaila nie może być pusta',
        );
      }

      _addDebugLog(
        '📝 Długość treści HTML: ${htmlContent.length} znaków',
        onDebugLog,
      );

      // Segregacja odbiorców
      onProgress?.call('Przetwarzam odbiorców...');
      final recipientsWithInvestmentData = <InvestorSummary>[];
      final additionalEmailAddresses = <String>[];

      for (final recipient in enabledRecipients) {
        final recipientId = recipient['id']!;

        if (recipientId.startsWith('additional_')) {
          additionalEmailAddresses.add(recipient['email']!);
        } else {
          final investor = investors.firstWhere(
            (inv) => inv.client.id == recipientId,
            orElse: () => investors.first,
          );
          recipientsWithInvestmentData.add(investor);
        }
      }

      _addDebugLog(
        '📊 Inwestorów: ${recipientsWithInvestmentData.length}, Dodatkowych: ${additionalEmailAddresses.length}',
        onDebugLog,
      );

      // Wysyłanie emaili
      onProgress?.call('Wysyłam emaile...');
      List<EmailSendResult> results = [];

      // Emaile do inwestorów z szczegółami inwestycji
      if (recipientsWithInvestmentData.isNotEmpty) {
        _addDebugLog(
          '📤 Wysyłam emaile do ${recipientsWithInvestmentData.length} inwestorów z szczegółami inwestycji',
          onDebugLog,
        );

        final investorResults = await _emailAndExportService
            .sendCustomEmailsToMultipleClients(
              investors: recipientsWithInvestmentData,
              subject: subject.isNotEmpty
                  ? subject
                  : 'Wiadomość od $senderName',
              htmlContent: htmlContent,
              includeInvestmentDetails: includeInvestmentDetails,
              senderEmail: senderEmail,
              senderName: senderName,
            );
        results.addAll(investorResults);
      }

      // Emaile do dodatkowych odbiorców BEZ szczegółów inwestycji
      if (additionalEmailAddresses.isNotEmpty) {
        _addDebugLog(
          '📤 Wysyłam emaile do ${additionalEmailAddresses.length} dodatkowych odbiorców BEZ szczegółów inwestycji',
          onDebugLog,
        );

        final additionalResults = await _emailAndExportService
            .sendCustomEmailsToMixedRecipients(
              investors: [],
              additionalEmails: additionalEmailAddresses,
              subject: subject.isNotEmpty
                  ? subject
                  : 'Wiadomość od $senderName',
              htmlContent: htmlContent,
              includeInvestmentDetails: false,
              senderEmail: senderEmail,
              senderName: senderName,
            );
        results.addAll(additionalResults);
      }

      // Analiza wyników
      final successful = results.where((r) => r.success).length;
      final failed = results.length - successful;
      final duration = DateTime.now().difference(_emailSendStartTime!);

      _addDebugLog(
        '✅ Zakończono wysyłanie w ${duration.inSeconds}s',
        onDebugLog,
      );
      _addDebugLog(
        '📊 Podsumowanie: $successful sukces, $failed błędów',
        onDebugLog,
      );

      // Loguj błędy
      for (final result in results.where((r) => !r.success)) {
        _addDebugLog(
          '❌ Błąd dla ${result.clientEmail}: ${result.error}',
          onDebugLog,
        );
      }

      onProgress?.call('Zakończono wysyłanie');

      // Zwróć zbiorczy wynik
      return EmailSendResult(
        success: failed == 0,
        clientEmail: 'Grupowa wysyłka',
        error: failed > 0
            ? 'Niepowodzenie $failed z ${results.length} emaili'
            : null,
        additionalData: {
          'total': results.length,
          'successful': successful,
          'failed': failed,
          'results': results,
          'duration': duration.inSeconds,
        },
      );
    } catch (e) {
      final duration = _emailSendStartTime != null
          ? DateTime.now().difference(_emailSendStartTime!)
          : Duration.zero;

      _addDebugLog(
        '💥 KRYTYCZNY BŁĄD po ${duration.inSeconds}s: ${e.toString()}',
        onDebugLog,
      );

      return EmailSendResult(
        success: false,
        clientEmail: '',
        error: 'Błąd podczas wysyłania maili: ${e.toString()}',
      );
    }
  }

  // === DEBUG LOGGING ===

  /// Dodaje wpis do logów debugowania
  void _addDebugLog(String message, [Function(String)? onDebugLog]) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logEntry = '[$timestamp] $message';
    _debugLogs.add(logEntry);

    // Wyślij do callbacka jeśli dostępny
    onDebugLog?.call(logEntry);

    // Wydrukuj w trybie debugowania
    if (kDebugMode) {
      debugPrint('EmailEditorService: $logEntry');
    }
  }

  /// Czyści logi debugowania
  void clearDebugLogs() {
    _debugLogs.clear();
  }

  // === TEMPLATES (FUTURE) ===

  /// Zapisuje szablon emaila (funkcjonalność na przyszłość)
  Future<void> saveTemplate({
    required String name,
    required String subject,
    required String content,
  }) async {
    // TODO: Implementacja zapisywania szablonów
    logError('saveTemplate', 'Funkcja nie została jeszcze zaimplementowana');
    throw UnimplementedError('Zapisywanie szablonów będzie dostępne wkrótce');
  }

  /// Pobiera dostępne szablony (funkcjonalność na przyszłość)
  Future<List<EmailTemplate>> getTemplates() async {
    // TODO: Implementacja pobierania szablonów
    return [];
  }

  // === RESET STATE ===

  /// Resetuje stan serwisu
  void reset() {
    _recipientEnabled.clear();
    _recipientEmails.clear();
    _additionalEmails.clear();
    _debugLogs.clear();
    _emailSendStartTime = null;
  }
}

/// Model szablonu emaila (przyszłość)
class EmailTemplate {
  final String id;
  final String name;
  final String subject;
  final String content;
  final DateTime createdAt;

  EmailTemplate({
    required this.id,
    required this.name,
    required this.subject,
    required this.content,
    required this.createdAt,
  });
}
