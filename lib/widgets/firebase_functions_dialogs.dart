import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/firebase_functions_analytics_service.dart';
import '../services/firebase_functions_data_service.dart';
import '../utils/currency_formatter.dart';

/// 🚀 FIREBASE FUNCTIONS DIALOGS
/// Zawiera wszystkie dialogi i funkcje związane z Firebase Functions
class FirebaseFunctionsDialogs {
  static final FirebaseFunctionsAnalyticsService _functionsService =
      FirebaseFunctionsAnalyticsService();

  /// **STATYSTYKI SYSTEMU** przez Firebase Functions
  static Future<void> showSystemStats(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'Pobieranie statystyk systemu...');

      final stats = await _functionsService.getSystemStats();

      Navigator.of(context).pop(); // Zamknij dialog ładowania

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📊 Statystyki Systemu'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('👥 Liczba klientów: ${stats.totalClients}'),
                Text('💼 Liczba inwestycji: ${stats.totalInvestments}'),
                Text(
                  '💰 Kapitał zainwestowany: ${CurrencyFormatter.formatCurrency(stats.totalInvestedCapital)}',
                ),
                Text(
                  '💵 Kapitał pozostały: ${CurrencyFormatter.formatCurrency(stats.totalRemainingCapital)}',
                ),
                Text(
                  '📈 Średnia na klienta: ${CurrencyFormatter.formatCurrency(stats.averageInvestmentPerClient)}',
                ),
                const Divider(),
                const Text(
                  '📋 Podział według produktów:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...stats.productTypeBreakdown.map(
                  (breakdown) => Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${breakdown.productType}: ${breakdown.count} inwestycji',
                        ),
                        Text(
                          '  Kapitał: ${CurrencyFormatter.formatCurrency(breakdown.totalCapital)}',
                        ),
                        Text(
                          '  Pozostało: ${CurrencyFormatter.formatCurrency(breakdown.remainingCapital)}',
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Text(
                  '🕒 Ostatnia aktualizacja: ${DateFormat('dd.MM.yyyy HH:mm').format(stats.lastUpdated)}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zamknij'),
            ),
          ],
        ),
      );

    } catch (e) {
      Navigator.of(
        context,
      ).pop(); // Zamknij dialog ładowania jeśli jest otwarty

      _showErrorSnackBar(context, 'Błąd pobierania statystyk: $e');
    }
  }

  /// **ODŚWIEŻENIE CACHE** Firebase Functions
  static Future<void> refreshFirebaseCache(
    BuildContext context,
    VoidCallback onRefreshComplete,
  ) async {
    try {
      _showLoadingDialog(context, 'Odświeżanie cache...');

      await _functionsService.refreshAnalyticsCache();

      Navigator.of(context).pop(); // Zamknij dialog ładowania

      _showSuccessSnackBar(context, 'Cache został odświeżony pomyślnie');

      onRefreshComplete();

    } catch (e) {
      Navigator.of(
        context,
      ).pop(); // Zamknij dialog ładowania jeśli jest otwarty

      _showErrorSnackBar(context, 'Błąd odświeżania cache: $e');
    }
  }

  /// **WSZYSCY KLIENCI** przez Firebase Functions
  static Future<void> showAllClients(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'Pobieranie klientów...');

      final result = await FirebaseFunctionsDataService.getAllClients(
        page: 1,
        pageSize: 100, // Limit dla podglądu
      );

      Navigator.of(context).pop(); // Zamknij dialog ładowania

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('👥 Klienci (${result.totalCount} razem)'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                Text('Łączna liczba: ${result.totalCount}'),
                if (result.processingTimeMs != null)
                  Text('Czas przetwarzania: ${result.processingTimeMs}ms'),
                Text('Cache: ${result.fromCache ? 'używany' : 'odświeżony'}'),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: result.clients.length,
                    itemBuilder: (context, index) {
                      final client = result.clients[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            client.name.isNotEmpty ? client.name[0] : '?',
                          ),
                        ),
                        title: Text(client.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (client.email.isNotEmpty)
                              Text('📧 ${client.email}'),
                            if (client.phone.isNotEmpty)
                              Text('📱 ${client.phone}'),
                            Text('📊 Status: ${client.type.displayName}'),
                          ],
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zamknij'),
            ),
          ],
        ),
      );

    } catch (e) {
      Navigator.of(
        context,
      ).pop(); // Zamknij dialog ładowania jeśli jest otwarty

      _showErrorSnackBar(context, 'Błąd pobierania klientów: $e');
    }
  }

  /// **WSZYSTKIE INWESTYCJE** przez Firebase Functions
  static Future<void> showAllInvestments(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'Pobieranie inwestycji...');

      final result = await FirebaseFunctionsDataService.getAllInvestments(
        page: 1,
        pageSize: 50, // Limit dla podglądu
      );

      Navigator.of(context).pop(); // Zamknij dialog ładowania

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('💼 Inwestycje (${result.totalCount} razem)'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                Text('Łączna liczba: ${result.totalCount}'),
                if (result.processingTimeMs != null)
                  Text('Czas przetwarzania: ${result.processingTimeMs}ms'),
                Text('Cache: ${result.fromCache ? 'używany' : 'odświeżony'}'),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: result.investments.length,
                    itemBuilder: (context, index) {
                      final investment = result.investments[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryAccent,
                          child: Text(investment.productType.displayName[0]),
                        ),
                        title: Text(investment.clientName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '💰 ${CurrencyFormatter.formatCurrency(investment.investmentAmount)}',
                            ),
                            Text('📈 ${investment.productType.displayName}'),
                            Text('🏢 ${investment.productName}'),
                            Text(
                              '📅 ${DateFormat('dd.MM.yyyy').format(investment.signedDate)}',
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zamknij'),
            ),
          ],
        ),
      );

    } catch (e) {
      Navigator.of(
        context,
      ).pop(); // Zamknij dialog ładowania jeśli jest otwarty

      _showErrorSnackBar(context, 'Błąd pobierania inwestycji: $e');
    }
  }

  // Helper methods
  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  static void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.successColor),
    );
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }
}
