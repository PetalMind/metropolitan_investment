import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models_and_services.dart';
import '../models/email_template.dart';

/// 📧 EMAIL TEMPLATE SERVICE - ZARZĄDZANIE SZABLONAMI
///
/// Główne funkcjonalności:
/// - CRUD operacje na szablonach email
/// - Kategoryzacja szablonów
/// - System placeholders z automatyczną detekcją
/// - Personalizacja treści dla konkretnych inwestorów
/// - Zarządzanie domyślnymi szablonami systemowymi
/// - Cache dla popularnych szablonów
class EmailTemplateService {
  static const String _collectionName = 'email_templates';
  static const String _logTag = 'EmailTemplateService';

  final FirebaseFirestore _firestore;
  final Map<String, dynamic> _cache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheTtl = Duration(minutes: 5);

  EmailTemplateService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Sprawdza czy cache jest aktualny
  bool get _isCacheValid {
    return _lastCacheUpdate != null &&
           DateTime.now().difference(_lastCacheUpdate!) < _cacheTtl;
  }

  /// Czysci cache
  void clearCache() {
    _cache.clear();
    _lastCacheUpdate = null;
  }

  /// Pobiera dane z cache lub wykonuje query
  Future<T?> getCachedData<T>(String key, Future<T?> Function() query) async {
    if (_isCacheValid && _cache.containsKey(key)) {
      debugPrint('📧 [$_logTag] Cache hit for: $key');
      return _cache[key] as T?;
    }

    debugPrint('📧 [$_logTag] Cache miss for: $key');
    final result = await query();
    if (result != null) {
      _cache[key] = result;
      _lastCacheUpdate = DateTime.now();
    }
    return result;
  }

  /// Log błędów
  void logError(String message, dynamic error) {
    debugPrint('❌ [$_logTag] $message: $error');
  }

  /// Pobiera wszystkie aktywne szablony
  Future<List<EmailTemplateModel>?> getAllTemplates({bool activeOnly = true}) async {
    return await getCachedData('all_templates_$activeOnly', () async {
      try {
        debugPrint('📧 [$_logTag] Fetching all templates (activeOnly: $activeOnly)');
        
        Query query = _firestore
            .collection(_collectionName)
            .orderBy('category')
            .orderBy('name');

        if (activeOnly) {
          query = query.where('isActive', isEqualTo: true);
        }

        final snapshot = await query.get();
        final templates = snapshot.docs
            .map((doc) => EmailTemplateModel.fromFirestore(doc))
            .toList();

        debugPrint('📧 [$_logTag] Found ${templates.length} templates');
        return templates;
      } catch (e) {
        logError('Error fetching templates', e);
        return null;
      }
    });
  }

  /// Pobiera szablony według kategorii
  Future<List<EmailTemplateModel>?> getTemplatesByCategory(
    EmailTemplateCategory category, {
    bool activeOnly = true,
  }) async {
    return await getCachedData('templates_${category.name}_$activeOnly', () async {
      try {
        debugPrint('📧 [$_logTag] Fetching templates for category: ${category.displayName}');
        
        Query query = _firestore
            .collection(_collectionName)
            .where('category', isEqualTo: category.name)
            .orderBy('name');

        if (activeOnly) {
          query = query.where('isActive', isEqualTo: true);
        }

        final snapshot = await query.get();
        final templates = snapshot.docs
            .map((doc) => EmailTemplateModel.fromFirestore(doc))
            .toList();

        debugPrint('📧 [$_logTag] Found ${templates.length} templates in category ${category.displayName}');
        return templates;
      } catch (e) {
        logError('Error fetching templates by category', e);
        return null;
      }
    });
  }

  /// Pobiera szablon według ID
  Future<EmailTemplateModel?> getTemplate(String templateId) async {
    return await getCachedData('template_$templateId', () async {
      try {
        debugPrint('📧 [$_logTag] Fetching template: $templateId');
        
        final doc = await _firestore
            .collection(_collectionName)
            .doc(templateId)
            .get();

        if (!doc.exists) {
          debugPrint('📧 [$_logTag] Template not found: $templateId');
          return null;
        }

        return EmailTemplateModel.fromFirestore(doc);
      } catch (e) {
        logError('Error fetching template', e);
        return null;
      }
    });
  }

  /// Tworzy nowy szablon
  Future<String?> createTemplate(EmailTemplateModel template) async {
    try {
      debugPrint('📧 [$_logTag] Creating template: ${template.name}');
      
      final templateWithTimestamps = template.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Auto-detect placeholders
      final detectedPlaceholders = templateWithTimestamps.extractPlaceholders();
      final finalTemplate = templateWithTimestamps.copyWith(
        placeholders: detectedPlaceholders,
      );

      final docRef = await _firestore
          .collection(_collectionName)
          .add(finalTemplate.toFirestore());

      // Clear cache
      clearCache();

      debugPrint('📧 [$_logTag] Template created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      logError('Error creating template', e);
      return null;
    }
  }

  /// Aktualizuje szablon
  Future<bool> updateTemplate(String templateId, EmailTemplateModel template) async {
    try {
      debugPrint('📧 [$_logTag] Updating template: $templateId');
      
      final updatedTemplate = template.copyWith(
        id: templateId,
        updatedAt: DateTime.now(),
      );
      
      // Auto-detect placeholders
      final detectedPlaceholders = updatedTemplate.extractPlaceholders();
      final finalTemplate = updatedTemplate.copyWith(
        placeholders: detectedPlaceholders,
      );

      await _firestore
          .collection(_collectionName)
          .doc(templateId)
          .update(finalTemplate.toFirestore());

      // Clear cache
      clearCache();

      debugPrint('📧 [$_logTag] Template updated: $templateId');
      return true;
    } catch (e) {
      logError('Error updating template', e);
      return false;
    }
  }

  /// Usuwa szablon (soft delete - oznacza jako nieaktywny)
  Future<bool> deleteTemplate(String templateId) async {
    try {
      debugPrint('📧 [$_logTag] Soft deleting template: $templateId');
      
      await _firestore
          .collection(_collectionName)
          .doc(templateId)
          .update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Clear cache
      clearCache();

      debugPrint('📧 [$_logTag] Template soft deleted: $templateId');
      return true;
    } catch (e) {
      logError('Error deleting template', e);
      return false;
    }
  }

  /// Hard delete szablon (trwałe usunięcie)
  Future<bool> permanentlyDeleteTemplate(String templateId) async {
    try {
      debugPrint('📧 [$_logTag] Permanently deleting template: $templateId');
      
      await _firestore
          .collection(_collectionName)
          .doc(templateId)
          .delete();

      // Clear cache
      clearCache();

      debugPrint('📧 [$_logTag] Template permanently deleted: $templateId');
      return true;
    } catch (e) {
      logError('Error permanently deleting template', e);
      return false;
    }
  }

  /// Duplikuje szablon
  Future<String?> duplicateTemplate(String templateId, {String? newName}) async {
    try {
      final original = await getTemplate(templateId);
      if (original == null) {
        debugPrint('📧 [$_logTag] Cannot duplicate - template not found: $templateId');
        return null;
      }

      final duplicate = original.copyWith(
        id: '', // Firestore wygeneruje nowe ID
        name: newName ?? '${original.name} (kopia)',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: {
          ...original.metadata,
          'duplicatedFrom': templateId,
          'duplicatedAt': DateTime.now().toIso8601String(),
        },
      );

      return await createTemplate(duplicate);
    } catch (e) {
      logError('Error duplicating template', e);
      return null;
    }
  }

  /// Renderuje szablon dla konkretnego inwestora
  EmailTemplateModel renderTemplateForInvestor(
    EmailTemplateModel template,
    InvestorSummary investor, {
    Map<String, String>? customValues,
  }) {
    try {
      debugPrint('📧 [$_logTag] Rendering template for investor: ${investor.client.name}');
      
      // Podstawowe wartości dla inwestora
      final values = <String, String>{
        '{{client_name}}': investor.client.name,
        '{{client_email}}': investor.client.email,
        '{{client_phone}}': investor.client.phone.isNotEmpty ? investor.client.phone : 'Brak',
        '{{total_investment_amount}}': CurrencyFormatter.formatCurrencyForEmail(investor.totalInvestmentAmount),
        '{{total_remaining_capital}}': CurrencyFormatter.formatCurrencyForEmail(investor.totalRemainingCapital),
        '{{total_realized}}': CurrencyFormatter.formatCurrencyForEmail(investor.totalRealizedCapital),
        '{{investment_count}}': investor.investmentCount.toString(),
        '{{current_date}}': _formatDate(DateTime.now()),
        '{{current_time}}': _formatTime(DateTime.now()),
        '{{current_datetime}}': _formatDateTime(DateTime.now()),
        '{{greeting_time}}': _getGreeting(),
      };

      // Dodaj custom values jeśli podano
      if (customValues != null) {
        values.addAll(customValues);
      }

      return template.renderWithData(values);
    } catch (e) {
      logError('Error rendering template for investor', e);
      return template; // Zwróć oryginalny template w przypadku błędu
    }
  }

  /// Tworzy domyślne szablony systemowe
  Future<void> createDefaultTemplates() async {
    try {
      debugPrint('📧 [$_logTag] Creating default templates');

      final defaultTemplates = [
        // Szablon powitalny
        EmailTemplateModel(
          id: '',
          name: 'Powitanie nowego inwestora',
          subject: 'Witamy w Metropolitan Investment, {{client_name}}!',
          content: '''
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #d4af37;">{{greeting_time}}, {{client_name}}!</h2>
              
              <p>Serdecznie witamy w gronie inwestorów Metropolitan Investment.</p>
              
              <p>Dziękujemy za zaufanie, jakim nas Państwo obdarzyli. Nasz zespół dołoży wszelkich starań, aby Państwa inwestycja była jak najbardziej rentowna.</p>
              
              <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <h3 style="color: #2c2c2c; margin-top: 0;">Dane kontaktowe:</h3>
                <p><strong>Email:</strong> {{client_email}}</p>
                <p><strong>Telefon:</strong> {{client_phone}}</p>
              </div>
              
              <p>W razie jakichkolwiek pytań, prosimy o kontakt.</p>
              
              <p>Pozdrawiamy,<br>
              Zespół Metropolitan Investment</p>
            </div>
          ''',
          description: 'Szablon powitalny dla nowych inwestorów',
          category: EmailTemplateCategory.welcome,
          includeInvestmentDetails: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'system',
        ),
        
        // Szablon raportu inwestycji
        EmailTemplateModel(
          id: '',
          name: 'Miesięczny raport inwestycji',
          subject: 'Raport inwestycyjny za {{current_date}} - {{client_name}}',
          content: '''
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #d4af37;">Miesięczny Raport Inwestycyjny</h2>
              
              <p>{{greeting_time}}, {{client_name}}!</p>
              
              <p>Przedstawiamy Państwa miesięczny raport inwestycyjny na dzień {{current_date}}.</p>
              
              <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <h3 style="color: #2c2c2c; margin-top: 0;">Podsumowanie portfela:</h3>
                <p><strong>Łączna wartość inwestycji:</strong> {{total_investment_amount}}</p>
                <p><strong>Kapitał pozostały:</strong> {{total_remaining_capital}}</p>
                <p><strong>Kapitał zrealizowany:</strong> {{total_realized}}</p>
                <p><strong>Liczba aktywnych inwestycji:</strong> {{investment_count}}</p>
              </div>
              
              <p>Szczegółowe informacje o poszczególnych inwestycjach znajdą Państwo poniżej.</p>
              
              <p>Pozdrawiamy,<br>
              Zespół Metropolitan Investment</p>
            </div>
          ''',
          description: 'Szablon miesięcznego raportu inwestycji',
          category: EmailTemplateCategory.report,
          includeInvestmentDetails: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'system',
        ),

        // Szablon przypomnienia
        EmailTemplateModel(
          id: '',
          name: 'Przypomnienie o terminie',
          subject: 'Przypomnienie - ważne informacje dotyczące Państwa inwestycji',
          content: '''
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #d4af37;">Przypomnienie</h2>
              
              <p>{{greeting_time}}, {{client_name}}!</p>
              
              <p>Informujemy o ważnych datach związanych z Państwa inwestycjami.</p>
              
              <div style="background: #fff3cd; padding: 15px; border-left: 4px solid #ffc107; margin: 20px 0;">
                <p style="margin: 0;"><strong>⏰ Proszę pamiętać o:</strong></p>
                <p style="margin: 5px 0 0 0;">[Tutaj wprowadź szczegóły przypomnienia]</p>
              </div>
              
              <p>W razie pytań, prosimy o kontakt pod numerem telefonu lub adresem email.</p>
              
              <p>Pozdrawiamy,<br>
              Zespół Metropolitan Investment</p>
            </div>
          ''',
          description: 'Szablon przypomnień o ważnych terminach',
          category: EmailTemplateCategory.reminder,
          includeInvestmentDetails: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'system',
        ),
      ];

      // Sprawdź, czy szablony już istnieją
      final existingTemplates = await getAllTemplates(activeOnly: false);
      final existingNames = existingTemplates?.map((t) => t.name).toSet() ?? <String>{};

      int created = 0;
      for (final template in defaultTemplates) {
        if (!existingNames.contains(template.name)) {
          final templateId = await createTemplate(template);
          if (templateId != null) {
            created++;
            debugPrint('📧 [$_logTag] Created default template: ${template.name}');
          }
        }
      }

      debugPrint('📧 [$_logTag] Created $created new default templates');
    } catch (e) {
      logError('Error creating default templates', e);
    }
  }

  /// Pobiera dostępne placeholders
  static List<String> getAvailablePlaceholders() {
    return [
      '{{client_name}}',
      '{{client_email}}',
      '{{client_phone}}',
      '{{total_investment_amount}}',
      '{{total_remaining_capital}}',
      '{{total_realized}}',
      '{{investment_count}}',
      '{{current_date}}',
      '{{current_time}}',
      '{{current_datetime}}',
      '{{greeting_time}}',
    ];
  }

  /// Pobiera opis placeholders
  static Map<String, String> getPlaceholderDescriptions() {
    return {
      '{{client_name}}': 'Imię i nazwisko klienta',
      '{{client_email}}': 'Adres email klienta',
      '{{client_phone}}': 'Numer telefonu klienta',
      '{{total_investment_amount}}': 'Łączna kwota inwestycji',
      '{{total_remaining_capital}}': 'Kapitał pozostały',
      '{{total_realized}}': 'Kapitał zrealizowany',
      '{{investment_count}}': 'Liczba inwestycji',
      '{{current_date}}': 'Aktualna data (DD.MM.RRRR)',
      '{{current_time}}': 'Aktualna godzina (HH:MM)',
      '{{current_datetime}}': 'Aktualna data i godzina',
      '{{greeting_time}}': 'Pozdrowienie w zależności od pory dnia',
    };
  }

  // Helper methods for formatting
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${_formatTime(date)}';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Dzień dobry';
    if (hour < 18) return 'Dzień dobry';
    return 'Dobry wieczór';
  }

  /// Stream szablonów w czasie rzeczywistym
  Stream<List<EmailTemplateModel>> getTemplatesStream({bool activeOnly = true}) {
    Query query = _firestore
        .collection(_collectionName)
        .orderBy('category')
        .orderBy('name');

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => EmailTemplateModel.fromFirestore(doc)).toList();
    });
  }

  /// Importuje szablon z pliku JSON
  Future<String?> importTemplate(Map<String, dynamic> templateData) async {
    try {
      final template = EmailTemplateModel.fromJson({
        ...templateData,
        'id': '', // Firestore wygeneruje nowe ID
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'createdBy': 'import',
      });

      return await createTemplate(template);
    } catch (e) {
      logError('Error importing template', e);
      return null;
    }
  }

  /// Eksportuje szablon do JSON
  Map<String, dynamic>? exportTemplate(EmailTemplateModel template) {
    try {
      final data = template.toJson();
      
      // Usuń pola specyficzne dla bazy danych
      data.remove('id');
      data.remove('createdAt');
      data.remove('updatedAt');
      data.remove('createdBy');
      
      return data;
    } catch (e) {
      logError('Error exporting template', e);
      return null;
    }
  }
}