import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
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

  /// Konwertuje dokument Quill na HTML - UŻYWA STANDARDOWEJ BIBLIOTEKI
  String convertDocumentToHtml(Document document) {
    try {
      // ⭐ ROZSZERZONA KONWERSJA - pełna obsługa formatowania Quill
      final converter = QuillDeltaToHtmlConverter(
        document.toDelta().toJson(),
        _createEnhancedConverterOptions(),
      );
      
      final htmlResult = converter.convert();
      
      // DEBUG - pokaż delta i HTML dla sprawdzenia formatowania
      if (kDebugMode) {
        final delta = document.toDelta();
        print('🎨 [ENHANCED FORMATTING] Delta operations:');
        for (var op in delta.toJson()) {
          print('  📝 $op');
        }
        print('🎨 [ENHANCED FORMATTING] Generated HTML:');
        print('  🔗 ${htmlResult.substring(0, htmlResult.length > 500 ? 500 : htmlResult.length)}${htmlResult.length > 500 ? "..." : ""}');
      }
      
      return htmlResult;
    } catch (e) {
      logError('convertDocumentToHtml', e);
      // Fallback - zwróć plain text w prostym HTML
      return '<p>${_escapeHtml(document.toPlainText())}</p>';
    }
  }

  /// Tworzy zaawansowane opcje konwersji obsługujące wszystkie elementy flutter_quill
  ConverterOptions _createEnhancedConverterOptions() {
    return ConverterOptions(
      converterOptions: OpConverterOptions(
        // Używaj stylów inline dla lepszej kompatybilności z emailami
        inlineStylesFlag: true,
        
        // Zaawansowane style inline obsługujące wszystkie elementy formatowania
        inlineStyles: InlineStyles({
          // === PODSTAWOWE FORMATOWANIE ===
          'bold': InlineStyleType(
            fn: (value, _) => 'font-weight: bold',
          ),
          'italic': InlineStyleType(
            fn: (value, _) => 'font-style: italic',
          ),
          'underline': InlineStyleType(
            fn: (value, _) => 'text-decoration: underline',
          ),
          'strike': InlineStyleType(
            fn: (value, _) => 'text-decoration: line-through',
          ),
          
          // === KOLORY ===
          'color': InlineStyleType(
            fn: (value, _) => 'color: $value',
          ),
          'background': InlineStyleType(
            fn: (value, _) => 'background-color: $value',
          ),
          
          // === CZCIONKI ===
          'font': InlineStyleType(
            fn: (value, _) => 'font-family: $value',
          ),
          
          // === ROZMIARY CZCIONKI ===
          'size': InlineStyleType(
            fn: (value, _) {
              // Obsługa różnych formatów rozmiaru z flutter_quill
              if (value is String) {
                if (value == 'small') return 'font-size: 0.75em';
                if (value == 'large') return 'font-size: 1.5em';
                if (value == 'huge') return 'font-size: 2.5em';
                // Numeryczne wartości jako px
                final numValue = double.tryParse(value);
                if (numValue != null) {
                  return 'font-size: ${numValue}px';
                }
                return 'font-size: $value';
              } else if (value is num) {
                return 'font-size: ${value}px';
              }
              return 'font-size: $value';
            },
          ),
          
          // === WYRÓWNANIE TEKSTU ===
          'align': InlineStyleType(
            fn: (value, _) => 'text-align: $value',
          ),
          
          // === KIERUNEK TEKSTU ===
          'direction': InlineStyleType(
            fn: (value, _) => 'direction: $value',
          ),
          
          // === WCIĘCIA ===
          'indent': InlineStyleType(
            fn: (value, _) {
              final indentValue = value is String ? int.tryParse(value) ?? 0 : (value as num).toInt();
              return 'margin-left: ${indentValue * 30}px'; // 30px na poziom wcięcia
            },
          ),
          
          // === SKRYPTY (sub/superscript) ===
          'script': InlineStyleType(
            fn: (value, _) {
              if (value == 'sub') return 'vertical-align: sub; font-size: smaller';
              if (value == 'super') return 'vertical-align: super; font-size: smaller';
              return '';
            },
          ),
          
          // === LISTY ===
          'list': InlineStyleType(
            fn: (value, _) => '', // Listy są obsługiwane przez znaczniki HTML
          ),
          
          // === DODATKOWE STYLE ===
          'code-block': InlineStyleType(
            fn: (value, _) => 'background-color: #f4f4f4; padding: 10px; border-radius: 4px; font-family: monospace; white-space: pre-wrap',
          ),
        }),
        
        // Konfiguracja linków
        linkRel: 'noopener noreferrer',
        linkTarget: '_blank',
        
        // Enkodowanie HTML dla bezpieczeństwa
        encodeHtml: true,
        
        // Znaczniki dla akapitów
        paragraphTag: 'p',
        
        // Prefix dla klas CSS (jeśli nie używamy inline styles)
        classPrefix: 'ql-',
        
        // Niestandardowe znaczniki list są obsługiwane automatycznie
      ),
      
      // Opcje sanityzacji
      sanitizerOptions: OpAttributeSanitizerOptions(
        // Pozwól na 8-cyfrowe kolory hex (np. z flutter_quill)
        allow8DigitHexColors: true,
      ),
    );
  }

  /// Escape HTML w tekście - HELPER METHOD
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
  /// Zwraca EmailEditorResult z podsumowaniem operacji
  Future<EmailEditorResult> sendEmails({
    required List<InvestorSummary> investors,
    required String subject,
    required String htmlContent,
    required bool includeInvestmentDetails,
    required String senderEmail,
    required String senderName,
    Function(String message)? onProgress,
    Function(String log)? onDebugLog,
  }) async {
    final startTime = DateTime.now();
    _emailSendStartTime = startTime;
    _debugLogs.clear();

    try {
      _addDebugLog('🚀 Rozpoczynam proces wysyłania maili', onDebugLog);

      // Walidacja konfiguracji SMTP
      onProgress?.call('Sprawdzam konfigurację SMTP...');
      _addDebugLog('🔧 Sprawdzam ustawienia SMTP...', onDebugLog);

      final smtpSettings = await _smtpService.getSmtpSettings();
      if (smtpSettings == null) {
        _addDebugLog('❌ Brak konfiguracji SMTP', onDebugLog);
        return EmailEditorResult(
          success: false,
          message:
              'Brak konfiguracji serwera SMTP. Skonfiguruj ustawienia email w aplikacji.',
          totalSent: 0,
          totalFailed: 0,
          detailedResults: [],
          duration: DateTime.now().difference(startTime),
        );
      }

      _addDebugLog(
        '✅ Konfiguracja SMTP znaleziona: ${smtpSettings.host}:${smtpSettings.port}',
        onDebugLog,
      );

      // Walidacja danych
      if (senderEmail.trim().isEmpty) {
        _addDebugLog('❌ Brak email wysyłającego', onDebugLog);
        return EmailEditorResult(
          success: false,
          message: 'Podaj email wysyłającego',
          totalSent: 0,
          totalFailed: 0,
          detailedResults: [],
          duration: DateTime.now().difference(startTime),
        );
      }

      if (htmlContent.trim().isEmpty) {
        _addDebugLog('❌ Brak treści emaila', onDebugLog);
        return EmailEditorResult(
          success: false,
          message: 'Treść emaila nie może być pusta',
          totalSent: 0,
          totalFailed: 0,
          detailedResults: [],
          duration: DateTime.now().difference(startTime),
        );
      }

      _addDebugLog('📧 Email wysyłającego: $senderEmail', onDebugLog);
      _addDebugLog(
        '📝 Długość treści HTML: ${htmlContent.length} znaków',
        onDebugLog,
      );

      // Przygotowanie odbiorców
      onProgress?.call('Przygotowywanie listy odbiorców...');
      final enabledRecipients = getEnabledRecipients(investors);
      _addDebugLog(
        '👥 Znaleziono ${enabledRecipients.length} aktywnych odbiorców',
        onDebugLog,
      );

      if (enabledRecipients.isEmpty) {
        _addDebugLog('❌ Brak prawidłowych odbiorców', onDebugLog);
        return EmailEditorResult(
          success: false,
          message: 'Brak odbiorców z prawidłowymi adresami email',
          totalSent: 0,
          totalFailed: 0,
          detailedResults: [],
          duration: DateTime.now().difference(startTime),
        );
      }

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
      final duration = DateTime.now().difference(startTime);

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
      return EmailEditorResult(
        success: failed == 0,
        message: failed == 0
            ? '✅ Wysłano $successful maili pomyślnie'
            : '⚠️ Wysłano $successful maili, błędów: $failed',
        totalSent: successful,
        totalFailed: failed,
        detailedResults: results,
        duration: duration,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      _addDebugLog(
        '💥 KRYTYCZNY BŁĄD po ${duration.inSeconds}s: ${e.toString()}',
        onDebugLog,
      );

      return EmailEditorResult(
        success: false,
        message: 'Błąd podczas wysyłania maili: ${e.toString()}',
        totalSent: 0,
        totalFailed: 0,
        detailedResults: [],
        duration: duration,
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
