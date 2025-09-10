import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/investor_summary.dart';
import 'base_service.dart';

/// 🎯 UJEDNOLICONY SERWIS EMAIL - Konsoliduje wszystkie funkcjonalności email
/// 
/// Zastępuje: email_and_export_service, email_service, email_editor_service_v2
/// oraz inne zduplikowane serwisy email.
/// 
/// 🚀 KLUCZOWE FUNKCJONALNOŚCI:
/// • Wysyłanie maili do mieszanych odbiorców (inwestorzy + dodatkowe emaile)  
/// • Unified recipient handling (jedna logika dla wszystkich typów)
/// • Cache dla optymalizacji wydajności
/// • Wsparcie dla schedulingu emaili
/// • Export danych inwestorów
class UnifiedEmailService extends BaseService {
  
  // 📋 TYPY ODBIORCÓW - zunifikowane dla całego systemu
  static const String RECIPIENT_TYPE_MAIN = 'main';
  static const String RECIPIENT_TYPE_ADDITIONAL = 'additional';
  static const String RECIPIENT_TYPE_PREVIEW = 'preview';

  /// 📧 GŁÓWNA FUNKCJA - Wysyła maile do mieszanych odbiorców
  /// 
  /// Zastępuje: sendCustomEmailsToMixedRecipients z email_and_export_service
  /// 
  /// @param mainRecipients Główni odbiorcy (inwestorzy) - otrzymują spersonalizowane dane
  /// @param additionalEmails Dodatkowi odbiorcy - otrzymują zagregowane dane wszystkich
  /// @param subject Temat maila
  /// @param htmlContent Treść HTML maila
  /// @param includeInvestmentDetails Czy dołączyć szczegóły inwestycji
  /// @param isGroupEmail Czy to email grupowy
  /// @param senderEmail Email wysyłającego
  /// @param senderName Nazwa wysyłającego
  /// @param aggregatedInvestmentsForAdditionals Pre-wygenerowane dane dla dodatkowych odbiorców
  Future<List<EmailSendResult>> sendUnifiedEmail({
    required List<InvestorSummary> mainRecipients,
    required List<String> additionalEmails,
    required String subject,
    required String htmlContent,
    bool includeInvestmentDetails = false,
    bool isGroupEmail = false,
    required String senderEmail,
    String senderName = 'Metropolitan Investment',
    String? aggregatedInvestmentsForAdditionals,
  }) async {
    const String cacheKey = 'send_unified_emails';

    try {
      // 🔍 UNIFIED VALIDATION
      final totalRecipients = mainRecipients.length + additionalEmails.length;
      if (totalRecipients == 0) {
        throw Exception('Lista odbiorców nie może być pusta');
      }

      if (senderEmail.isEmpty) {
        throw Exception('Email wysyłającego jest wymagany');
      }

      if (subject.isEmpty) {
        throw Exception('Temat maila jest wymagany');
      }

      if (htmlContent.isEmpty) {
        throw Exception('Treść HTML nie może być pusta');
      }

      // 📊 PREPARE UNIFIED DATA for Firebase Functions
      final functionData = {
        'recipients': mainRecipients.map((investor) => {
          'clientId': investor.client.id,
          'clientName': investor.client.name,
          'clientEmail': investor.client.email,
          'investmentCount': investor.investmentCount,
          'totalAmount': investor.totalRemainingCapital,
        }).toList(),
        'additionalEmails': additionalEmails,
        'subject': subject,
        'htmlContent': htmlContent,
        'includeInvestmentDetails': includeInvestmentDetails,
        'isGroupEmail': isGroupEmail,
        'senderEmail': senderEmail,
        'senderName': senderName,
        if (aggregatedInvestmentsForAdditionals != null && 
            aggregatedInvestmentsForAdditionals.isNotEmpty)
          'aggregatedInvestmentsForAdditionals': aggregatedInvestmentsForAdditionals,
      };

      logDebug(
        'sendUnifiedEmail',
        'Wysyłam do ${mainRecipients.length} głównych + ${additionalEmails.length} dodatkowych odbiorców',
      );

      // 🚀 CALL FIREBASE FUNCTIONS - europe-west1 region for performance
      final result = await FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('sendEmailsToMixedRecipients').call(functionData);

      logDebug('sendUnifiedEmail', 'Maile wysłane pomyślnie');

      // 📊 PROCESS RESULTS
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
              template: result['template'] ?? 'unified_html',
              error: result['error'],
            ),
          );
        }

        return results;
      } else {
        throw Exception(
          'Wysyłanie maili nie powiodło się: ${data['error'] ?? 'Nieznany błąd'}',
        );
      }
    } catch (e) {
      logError('sendUnifiedEmail', e);

      // 📋 RETURN ERROR RESULTS for all recipients
      final results = <EmailSendResult>[];

      // Main recipients errors
      for (final investor in mainRecipients) {
        results.add(
          EmailSendResult(
            success: false,
            messageId: '',
            clientEmail: investor.client.email,
            clientName: investor.client.name,
            investmentCount: investor.investmentCount,
            totalAmount: investor.totalRemainingCapital,
            executionTimeMs: 0,
            template: 'unified_html',
            error: e.toString(),
          ),
        );
      }

      // Additional emails errors
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
            template: 'unified_html',
            error: e.toString(),
          ),
        );
      }

      return results;
    }
  }

  /// 🎯 UNIFIED RECIPIENT PROCESSOR - Jedna logika dla wszystkich typów odbiorców
  /// 
  /// Zastępuje różne logiki filtrowania w różnych serwisach
  /// 
  /// @param allInvestors Wszyscy dostępni inwestorzy
  /// @param enabledMap Mapa włączonych odbiorców (clientId -> bool)
  /// @param recipientType Typ odbiorców (main/additional/preview)
  List<InvestorSummary> processRecipients({
    required List<InvestorSummary> allInvestors,
    required Map<String, bool> enabledMap,
    required String recipientType,
  }) {
    switch (recipientType) {
      case RECIPIENT_TYPE_ADDITIONAL:
      case RECIPIENT_TYPE_PREVIEW:
        // For additional recipients and preview - always return all
        return allInvestors;
      
      case RECIPIENT_TYPE_MAIN:
      default:
        // For main recipients - only enabled ones
        return allInvestors
            .where((investor) => enabledMap[investor.client.id] ?? false)
            .toList();
    }
  }

  /// 📊 VALIDATE EMAIL FORMAT - Unified validation
  /// 
  /// @param email Email to validate
  /// @return true if email format is valid
  bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  /// 🎯 VALIDATE RECIPIENTS - Unified recipient validation
  /// 
  /// @param mainRecipients List of main recipients (investors)
  /// @param additionalEmails List of additional email addresses
  /// @return Map with validation results
  Map<String, dynamic> validateRecipients({
    required List<InvestorSummary> mainRecipients,
    required List<String> additionalEmails,
  }) {
    final invalidEmails = <String>[];
    final validMainCount = mainRecipients
        .where((investor) => isValidEmail(investor.client.email))
        .length;

    // Validate main recipients emails
    for (final investor in mainRecipients) {
      if (!isValidEmail(investor.client.email)) {
        invalidEmails.add('${investor.client.name}: ${investor.client.email}');
      }
    }

    // Validate additional emails
    for (final email in additionalEmails) {
      if (!isValidEmail(email)) {
        invalidEmails.add('Dodatkowy: $email');
      }
    }

    final totalValidRecipients = validMainCount + 
        additionalEmails.where((email) => isValidEmail(email)).length;

    return {
      'isValid': invalidEmails.isEmpty && totalValidRecipients > 0,
      'invalidEmails': invalidEmails,
      'validMainCount': validMainCount,
      'validAdditionalCount': additionalEmails.where((email) => isValidEmail(email)).length,
      'totalValidRecipients': totalValidRecipients,
      'errors': invalidEmails.isEmpty 
          ? null 
          : 'Nieprawidłowe adresy email:\n${invalidEmails.join('\n')}',
    };
  }

  /// 📈 GET RECIPIENTS SUMMARY - Unified status message generation
  /// 
  /// @param mainRecipients All main recipients (investors)
  /// @param enabledMap Map of enabled recipients (clientId -> bool) 
  /// @param additionalEmails List of additional emails
  /// @return Human-readable status message
  String getRecipientsSummary({
    required List<InvestorSummary> mainRecipients,
    required Map<String, bool> enabledMap,
    required List<String> additionalEmails,
  }) {
    final enabledCount = mainRecipients
        .where((inv) => enabledMap[inv.client.id] ?? false)
        .length;
    final additionalCount = additionalEmails.length;
    final totalSelected = mainRecipients.length;

    if (enabledCount == 0 && additionalCount == 0) {
      return 'Brak odbiorców - dodaj odbiorców lub sprawdź adresy email';
    } else if (enabledCount < totalSelected) {
      final disabled = totalSelected - enabledCount;
      final total = enabledCount + additionalCount;
      if (additionalCount > 0) {
        return '$enabledCount odbiorców z checkboxów + $additionalCount dodatkowych = $total łącznie ($disabled wyłączonych)';
      } else {
        return '$enabledCount odbiorców gotowych ($disabled wyłączonych z powodu błędnych adresów email)';
      }
    } else {
      final total = enabledCount + additionalCount;
      if (additionalCount > 0) {
        return '$enabledCount odbiorców z checkboxów + $additionalCount dodatkowych = $total łącznie';
      } else {
        return '$total odbiorców gotowych do wysłania';
      }
    }
  }
}

/// 📧 EMAIL SEND RESULT - Unified result model
/// 
/// Używane przez wszystkie funkcje wysyłania email
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

  EmailSendResult({
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

  Map<String, dynamic> toJson() => {
    'success': success,
    'messageId': messageId,
    'clientEmail': clientEmail,
    'clientName': clientName,
    'investmentCount': investmentCount,
    'totalAmount': totalAmount,
    'executionTimeMs': executionTimeMs,
    'template': template,
    'error': error,
  };

  factory EmailSendResult.fromJson(Map<String, dynamic> json) => EmailSendResult(
    success: json['success'] ?? false,
    messageId: json['messageId'] ?? '',
    clientEmail: json['clientEmail'] ?? '',
    clientName: json['clientName'] ?? '',
    investmentCount: json['investmentCount'] ?? 0,
    totalAmount: (json['totalAmount'] ?? 0).toDouble(),
    executionTimeMs: json['executionTimeMs'] ?? 0,
    template: json['template'] ?? 'unified_html',
    error: json['error'],
  );
}