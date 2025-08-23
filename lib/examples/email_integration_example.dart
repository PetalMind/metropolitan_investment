import 'package:flutter/material.dart';
import '../models_and_services.dart';
import '../widgets/email_editor_widget.dart';

/// Przykład integracji EmailEditorWidget w PremiumInvestorAnalyticsScreen
///
/// Pokazuje jak łatwo dodać funkcjonalność emaili do dowolnego widoku
class EmailIntegrationExample {
  /// Dodaje przycisk email do istniejącego UI
  /// Można użyć w AppBar, FloatingActionButton lub dowolnym miejscu
  static Widget buildEmailButton({
    required BuildContext context,
    required List<InvestorSummary> selectedInvestors,
    required VoidCallback onEmailSent,
    String? buttonText,
    IconData? icon,
  }) {
    return ElevatedButton.icon(
      onPressed: selectedInvestors.isEmpty
          ? null
          : () => _showEmailEditor(context, selectedInvestors, onEmailSent),
      icon: Icon(icon ?? Icons.email),
      label: Text(buttonText ?? 'Wyślij email'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppThemePro.accentGold,
        foregroundColor: AppThemePro.textPrimary,
      ),
    );
  }

  /// Pokazuje edytor emaili jako dialog
  static void _showEmailEditor(
    BuildContext context,
    List<InvestorSummary> investors,
    VoidCallback onEmailSent,
  ) {
    EmailEditorWidget.showAsDialog(
      context: context,
      investors: investors,
      onEmailSent: onEmailSent,
      initialSubject:
          'Aktualizacja portfela inwestycyjnego - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      initialMessage: null, // Użyje domyślnego szablonu
    );
  }

  /// Integracja w PremiumInvestorAnalyticsScreen - dodaj w _buildActions
  ///
  /// Przykład użycia w metodzie _buildActions w premium_investor_analytics_screen.dart:
  /// ```dart
  /// Widget _buildActions(bool canEdit) {
  ///   return Row(
  ///     children: [
  ///       // Istniejące przyciski...
  ///
  ///       // NOWY: Przycisk email
  ///       EmailIntegrationExample.buildEmailButton(
  ///         context: context,
  ///         selectedInvestors: _selectedInvestors,
  ///         onEmailSent: () {
  ///           _exitSelectionMode();
  ///           _showSuccessSnackBar('Emaile zostały wysłane pomyślnie');
  ///         },
  ///       ),
  ///
  ///       // Pozostałe przyciski...
  ///     ],
  ///   );
  /// }
  /// ```
  static Widget buildPremiumAnalyticsIntegration({
    required BuildContext context,
    required List<InvestorSummary> selectedInvestors,
    required VoidCallback onEmailSent,
    required bool isSelectionMode,
  }) {
    if (!isSelectionMode || selectedInvestors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.accentGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.email, color: AppThemePro.accentGold, size: 20),
          const SizedBox(width: 8),
          Text(
            'Wyślij email do ${selectedInvestors.length} inwestorów',
            style: const TextStyle(
              color: AppThemePro.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          buildEmailButton(
            context: context,
            selectedInvestors: selectedInvestors,
            onEmailSent: onEmailSent,
            buttonText: 'Wyślij',
          ),
        ],
      ),
    );
  }

  /// Dodaje funkcjonalność emaili do FloatingActionButton
  ///
  /// Przykład zastąpienia istniejącego FAB:
  /// ```dart
  /// floatingActionButton: EmailIntegrationExample.buildEmailFAB(
  ///   context: context,
  ///   selectedInvestors: _selectedInvestors,
  ///   onEmailSent: () => _refreshData(),
  ///   isSelectionMode: _isSelectionMode,
  /// ),
  /// ```
  static Widget? buildEmailFAB({
    required BuildContext context,
    required List<InvestorSummary> selectedInvestors,
    required VoidCallback onEmailSent,
    required bool isSelectionMode,
  }) {
    if (!isSelectionMode || selectedInvestors.isEmpty) {
      return null;
    }

    return FloatingActionButton.extended(
      onPressed: () =>
          _showEmailEditor(context, selectedInvestors, onEmailSent),
      backgroundColor: AppThemePro.accentGold,
      foregroundColor: AppThemePro.textPrimary,
      icon: const Icon(Icons.email),
      label: Text('Email (${selectedInvestors.length})'),
    );
  }

  /// Dodaje email action do kontekstowego menu
  ///
  /// Użycie w popup menu lub action bar:
  /// ```dart
  /// PopupMenuButton<String>(
  ///   itemBuilder: (context) => [
  ///     // Istniejące elementy...
  ///     EmailIntegrationExample.buildEmailMenuItem(
  ///       context: context,
  ///       selectedInvestors: _selectedInvestors,
  ///       onEmailSent: () => _refreshData(),
  ///     ),
  ///   ],
  /// ),
  /// ```
  static PopupMenuItem<String> buildEmailMenuItem({
    required BuildContext context,
    required List<InvestorSummary> selectedInvestors,
    required VoidCallback onEmailSent,
  }) {
    return PopupMenuItem<String>(
      value: 'email',
      enabled: selectedInvestors.isNotEmpty,
      child: ListTile(
        leading: const Icon(Icons.email),
        title: const Text('Wyślij email'),
        subtitle: Text('${selectedInvestors.length} odbiorców'),
        onTap: () {
          Navigator.pop(context); // Zamknij menu
          _showEmailEditor(context, selectedInvestors, onEmailSent);
        },
      ),
    );
  }

  /// Standalone widget który można wstawić w dowolnym miejscu
  ///
  /// Przykład użycia jako pełny widget:
  /// ```dart
  /// // W metodzie build() dowolnego widget'a:
  /// if (_selectedInvestors.isNotEmpty)
  ///   EmailIntegrationExample.buildStandaloneEmailSection(
  ///     context: context,
  ///     selectedInvestors: _selectedInvestors,
  ///     onEmailSent: () => _handleEmailSent(),
  ///   ),
  /// ```
  static Widget buildStandaloneEmailSection({
    required BuildContext context,
    required List<InvestorSummary> selectedInvestors,
    required VoidCallback onEmailSent,
    String? title,
    String? subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.email, color: AppThemePro.accentGold, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? 'Komunikacja z inwestorami',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppThemePro.textPrimary,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppThemePro.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Wybranych inwestorów: ${selectedInvestors.length}',
                    style: const TextStyle(color: AppThemePro.textSecondary),
                  ),
                ),
                buildEmailButton(
                  context: context,
                  selectedInvestors: selectedInvestors,
                  onEmailSent: onEmailSent,
                  buttonText: 'Utwórz email',
                  icon: Icons.edit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Instrukcje integracji dla deweloperów
/// 
/// KROK 1: Import w pliku gdzie chcesz używać emaili
/// ```dart
/// import '../widgets/email_editor_widget.dart';
/// // lub jeśli używasz models_and_services.dart:
/// import '../models_and_services.dart';
/// ```
/// 
/// KROK 2: Dodaj przycisk email w odpowiednim miejscu
/// ```dart
/// ElevatedButton.icon(
///   onPressed: _selectedInvestors.isEmpty ? null : () {
///     EmailEditorWidget.showAsDialog(
///       context: context,
///       investors: _selectedInvestors,
///       onEmailSent: () {
///         _exitSelectionMode();
///         _showSuccessSnackBar('Emaile zostały wysłane');
///       },
///     );
///   },
///   icon: Icon(Icons.email),
///   label: Text('Wyślij email'),
/// )
/// ```
/// 
/// KROK 3: (Opcjonalnie) Używaj gotowych helper'ów z EmailIntegrationExample
/// ```dart
/// EmailIntegrationExample.buildEmailButton(
///   context: context,
///   selectedInvestors: _selectedInvestors,
///   onEmailSent: () => _handleEmailSuccess(),
/// )
/// ```
/// 
/// CECHY SYSTEMU:
/// ✅ Plug-and-play - działa wszędzie gdzie masz List<InvestorSummary>
/// ✅ Automatyczna walidacja odbiorców i SMTP
/// ✅ Rich text editor z formatowaniem
/// ✅ Podgląd emaili przed wysyłką
/// ✅ Zarządzanie dodatkowymi odbiorcami
/// ✅ Szczegółowe logowanie i debugowanie
/// ✅ Responsywny design
/// ✅ Integracja z istniejącymi serwisami
/// ✅ Zgodność z RBAC (tylko admini mogą wysyłać)
/// ✅ Professional styling z AppThemePro