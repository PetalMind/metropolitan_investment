import 'package:flutter/material.dart';
import '../models_and_services.dart';

/// Przykład integracji nowego systemu emaili w PremiumInvestorAnalyticsScreen
///
/// Ten plik pokazuje dokładnie jak zintegrować EmailEditorWidget z istniejącym kodem
/// Zastępuje stary _sendEmailToSelectedInvestors() nowym modularnym systemem

class PremiumAnalyticsEmailIntegration {
  /// KROK 1: Zastąp metodę _sendEmailToSelectedInvestors w premium_investor_analytics_screen.dart
  ///
  /// STARA WERSJA (usuń):
  /// ```dart
  /// Future<void> _sendEmailToSelectedInvestors() async {
  ///   // ... skomplikowana logika ...
  /// }
  /// ```
  ///
  /// NOWA WERSJA (dodaj):
  static Future<void> sendEmailToSelectedInvestors({
    required BuildContext context,
    required List<InvestorSummary> selectedInvestors,
    required VoidCallback onEmailSent,
  }) async {
    // Sprawdź czy są wybrani inwestorzy
    if (selectedInvestors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wybierz inwestorów do wysyłki emaili'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Pokaż dialog z edytorem emaili
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: EmailEditorWidget(
          investors: selectedInvestors,
          onEmailSent: onEmailSent,
          initialSubject:
              'Aktualizacja portfela inwestycyjnego - ${_getCurrentDate()}',
          initialMessage: null, // Użyje domyślnego szablonu
          showAsDialog: true,
        ),
      ),
    );
  }

  /// KROK 2: Aktualizuj przycisk email w metodie _buildExportModeBanner
  ///
  /// ZNAJDŹ ten kod w premium_investor_analytics_screen.dart:
  /// ```dart
  /// ElevatedButton.icon(
  ///   onPressed: _sendEmailToSelectedInvestors,
  ///   icon: const Icon(Icons.email),
  ///   label: const Text('Email'),
  /// ),
  /// ```
  ///
  /// ZASTĄP tym:
  static Widget buildEmailButton({
    required BuildContext context,
    required List<InvestorSummary> selectedInvestors,
    required VoidCallback onEmailSent,
  }) {
    return ElevatedButton.icon(
      onPressed: selectedInvestors.isEmpty
          ? null
          : () => sendEmailToSelectedInvestors(
              context: context,
              selectedInvestors: selectedInvestors,
              onEmailSent: onEmailSent,
            ),
      icon: const Icon(Icons.email),
      label: Text('Email (${selectedInvestors.length})'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD700), // AppThemePro.accentGold
        foregroundColor: const Color(0xFFFFFFFF), // AppThemePro.textPrimary
      ),
    );
  }

  /// KROK 3: Dodaj helper method do premium_investor_analytics_screen.dart
  static String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  /// KROK 4: Opcjonalnie dodaj FAB dla emaili
  ///
  /// W metodzie build() znajdź:
  /// ```dart
  /// floatingActionButton: _isSelectionMode ? /* existing FAB */ : null,
  /// ```
  ///
  /// Zastąp tym:
  static Widget? buildEmailFloatingActionButton({
    required BuildContext context,
    required List<InvestorSummary> selectedInvestors,
    required VoidCallback onEmailSent,
    required bool isSelectionMode,
  }) {
    if (!isSelectionMode || selectedInvestors.isEmpty) {
      return null;
    }

    return FloatingActionButton.extended(
      onPressed: () => sendEmailToSelectedInvestors(
        context: context,
        selectedInvestors: selectedInvestors,
        onEmailSent: onEmailSent,
      ),
      backgroundColor: const Color(0xFFFFD700), // AppThemePro.accentGold
      foregroundColor: const Color(0xFFFFFFFF), // AppThemePro.textPrimary
      icon: const Icon(Icons.email),
      label: Text('Email (${selectedInvestors.length})'),
    );
  }
}

/// INSTRUKCJA IMPLEMENTACJI KROK PO KROK:
/// 
/// 1. DODAJ IMPORT na górze premium_investor_analytics_screen.dart:
/// ```dart
/// import '../examples/premium_analytics_email_integration.dart';
/// ```
/// 
/// 2. USUŃ STARĄ METODĘ _sendEmailToSelectedInvestors i _ensureFullClientDataThenShowEmailDialog
/// 
/// 3. W METODZIE _buildExportModeBanner ZNAJDŹ:
/// ```dart
/// ElevatedButton.icon(
///   onPressed: _sendEmailToSelectedInvestors,
///   // ...
/// ),
/// ```
/// ZASTĄP tym:
/// ```dart
/// PremiumAnalyticsEmailIntegration.buildEmailButton(
///   context: context,
///   selectedInvestors: _selectedInvestors,
///   onEmailSent: () {
///     _exitSelectionMode();
///     _showSuccessSnackBar('Emaile zostały wysłane pomyślnie');
///   },
/// ),
/// ```
/// 
/// 4. W METODZIE build() ZASTĄP floatingActionButton:
/// ```dart
/// floatingActionButton: PremiumAnalyticsEmailIntegration.buildEmailFloatingActionButton(
///   context: context,
///   selectedInvestors: _selectedInvestors,
///   onEmailSent: () {
///     _exitSelectionMode();
///     _showSuccessSnackBar('Emaile zostały wysłane pomyślnie');
///   },
///   isSelectionMode: _isSelectionMode,
/// ),
/// ```
/// 
/// 5. USUŃ NIEUŻYWANE METODY:
/// - _sendEmailToSelectedInvestors
/// - _ensureFullClientDataThenShowEmailDialog
/// - _showEmailDialog (jeśli nie używana gdzie indziej)
/// 
/// KORZYŚCI PO MIGRACJI:
/// ✅ Znacznie mniej kodu w premium_investor_analytics_screen.dart
/// ✅ Reusable funkcjonalność email dla innych ekranów
/// ✅ Lepszy rich text editor z formatowaniem
/// ✅ Zarządzanie dodatkowymi odbiorcami
/// ✅ Lepsze debugowanie i logowanie
/// ✅ Responsywny design
/// ✅ Podgląd emaili przed wysyłką
/// ✅ Jednolity system walidacji

/// MIGRACJA KROK PO KROK - DOKŁADNE ZMIANY W KODZIE:

/*
ZNAJDŹ w premium_investor_analytics_screen.dart linie podobne do:

```dart
ElevatedButton.icon(
  onPressed: _isEmailMode 
      ? _sendEmailToSelectedInvestors 
      : _exportSelectedInvestors,
  icon: Icon(_isEmailMode ? Icons.email : Icons.download),
  label: Text(_isEmailMode ? 'Wyślij email' : 'Eksportuj'),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppThemePro.accentGold,
  ),
),
```

ZASTĄP tym:

```dart
if (_isEmailMode) 
  PremiumAnalyticsEmailIntegration.buildEmailButton(
    context: context,
    selectedInvestors: _selectedInvestors,
    onEmailSent: () {
      _exitSelectionMode();
      _showSuccessSnackBar('Emaile zostały wysłane pomyślnie');
    },
  )
else
  ElevatedButton.icon(
    onPressed: _exportSelectedInvestors,
    icon: const Icon(Icons.download),
    label: const Text('Eksportuj'),
    style: ElevatedButton.styleFrom(
      backgroundColor: AppThemePro.accentGold,
    ),
  ),
```

USUŃ te metody z premium_investor_analytics_screen.dart:
- Future<void> _sendEmailToSelectedInvestors() async { ... }
- Future<void> _ensureFullClientDataThenShowEmailDialog() async { ... }
- void _showEmailDialog() { ... } (jeśli istnieje)

DODAJ na górze pliku import:
```dart
import '../examples/premium_analytics_email_integration.dart';
```

GOTOWE! Nowy system emaili jest zintegrowany.
*/