import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firebase_functions_analytics_service_updated.dart';
import '../utils/currency_formatter.dart';

/// 🚀 ZAKTUALIZOWANE FIREBASE FUNCTIONS DIALOGS
/// Używa nowych modularnych funkcji Firebase Functions
///
/// DOSTĘPNE FUNKCJE:
/// - Statystyki produktów (getUnifiedProductStatistics)
/// - Debug test (debugClientsTest)
/// - Informacje o klientach (getAllClients)
/// - Czyszczenie cache
class FirebaseFunctionsDialogsUpdated {
  static final FirebaseFunctionsAnalyticsServiceUpdated _functionsService =
      FirebaseFunctionsAnalyticsServiceUpdated();

  /// **STATYSTYKI PRODUKTÓW** przez Firebase Functions 📦
  /// Wykorzystuje getUnifiedProductStatistics z statistics-service.js
  static Future<void> showProductStatistics(BuildContext context) async {
    try {
      print('📊 [Updated Functions] Pobieranie statystyk produktów...');

      _showLoadingDialog(context, 'Pobieranie statystyk produktów...');

      final stats = await _functionsService.getUnifiedProductStatistics();

      Navigator.of(context).pop(); // Zamknij dialog ładowania

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📦 Statystyki Produktów'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📦 Wszystkich produktów: ${stats.totalProducts}'),
                Text(
                  '💰 Wartość całkowita: ${CurrencyFormatter.formatCurrency(stats.totalValue)}',
                ),
                const Divider(),
                const Text(
                  '📋 Podział według typów:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...stats.productTypeBreakdown.map(
                  (breakdown) => Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                    child: Card(
                      color: AppTheme.surfaceCard,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${breakdown.typeName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('📊 Liczba: ${breakdown.count}'),
                            Text(
                              '💰 Wartość: ${CurrencyFormatter.formatCurrency(breakdown.totalValue)}',
                            ),
                            Text(
                              '📈 Średnia: ${CurrencyFormatter.formatCurrency(breakdown.averageValue)}',
                            ),
                            Text(
                              '📊 Udział: ${breakdown.percentage.toStringAsFixed(1)}%',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(),
                if (stats.metadata.timestamp != null)
                  Text('🕒 Timestamp: ${stats.metadata.timestamp}'),
                if (stats.metadata.executionTime != null)
                  Text('⚡ Czas wykonania: ${stats.metadata.executionTime}ms'),
                Text('💾 Z cache: ${stats.metadata.cacheUsed ? "Tak" : "Nie"}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zamknij'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                showProductStatistics(context); // Odśwież
              },
              child: const Text('Odśwież'),
            ),
          ],
        ),
      );

      print('✅ [Updated Functions] Wyświetlono statystyki produktów');
    } catch (e) {
      Navigator.of(context).pop(); // Zamknij dialog ładowania
      print('❌ [Updated Functions] Błąd statystyk produktów: $e');
      _showErrorSnackBar(context, 'Błąd pobierania statystyk produktów: $e');
    }
  }

  /// **INFORMACJE O KLIENTACH** przez Firebase Functions 👥
  /// Wykorzystuje getAllClients z clients-service.js
  static Future<void> showClientsInfo(BuildContext context) async {
    try {
      print('👥 [Updated Functions] Pobieranie informacji o klientach...');

      _showLoadingDialog(context, 'Pobieranie informacji o klientach...');

      final clientsResult = await _functionsService.getAllClients(
        page: 1,
        pageSize: 10, // Tylko próbka
      );

      Navigator.of(context).pop(); // Zamknij dialog ładowania

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('👥 Informacje o klientach'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('👥 Wszystkich klientów: ${clientsResult.totalCount}'),
                Text('📄 Strona: ${clientsResult.currentPage}'),
                Text('📦 Rozmiar strony: ${clientsResult.pageSize}'),
                Text(
                  '➡️ Ma następną: ${clientsResult.hasNextPage ? "Tak" : "Nie"}',
                ),
                Text(
                  '⬅️ Ma poprzednią: ${clientsResult.hasPreviousPage ? "Tak" : "Nie"}',
                ),
                if (clientsResult.processingTime != null)
                  Text(
                    '⚡ Czas przetwarzania: ${clientsResult.processingTime}ms',
                  ),
                const Divider(),
                const Text(
                  '👤 Przykładowi klienci:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...clientsResult.clients
                    .take(3)
                    .map(
                      (client) => Padding(
                        padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                        child: Card(
                          color: AppTheme.surfaceCard,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('📋 ${client.name}'),
                                if (client.email.isNotEmpty)
                                  Text('📧 ${client.email}'),
                                if (client.phone.isNotEmpty)
                                  Text('📞 ${client.phone}'),
                                Text(
                                  '🗳️ Status głosowania: ${client.votingStatus.name}',
                                ),
                              ],
                            ),
                          ),
                        ),
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

      print('✅ [Updated Functions] Wyświetlono informacje o klientach');
    } catch (e) {
      Navigator.of(context).pop(); // Zamknij dialog ładowania
      print('❌ [Updated Functions] Błąd informacji o klientach: $e');
      _showErrorSnackBar(context, 'Błąd pobierania informacji o klientach: $e');
    }
  }

  /// **DEBUG TEST** Firebase Functions 🧪
  /// Wykorzystuje debugClientsTest z debug-service.js
  static Future<void> showDebugTest(BuildContext context) async {
    try {
      print('🧪 [Updated Functions] Uruchamianie testu debug...');

      _showLoadingDialog(context, 'Uruchamianie testu debug...');

      final debugResult = await _functionsService.debugClientsTest();

      Navigator.of(context).pop(); // Zamknij dialog ładowania

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🧪 Wynik testu debug'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🚀 Status funkcji: ${debugResult.functionStatus}'),
                Text('📖 Wersja: ${debugResult.version}'),
                if (debugResult.message != null)
                  Text('💬 Wiadomość: ${debugResult.message}'),
                const Divider(),
                const Text(
                  '🔍 Dodatkowe informacje:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...debugResult.additionalInfo.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 2.0),
                    child: Text('${entry.key}: ${entry.value}'),
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

      print('✅ [Updated Functions] Wyświetlono wynik testu debug');
    } catch (e) {
      Navigator.of(context).pop(); // Zamknij dialog ładowania
      print('❌ [Updated Functions] Błąd testu debug: $e');
      _showErrorSnackBar(context, 'Błąd testu debug: $e');
    }
  }

  /// **WYSZUKIWANIE INWESTORÓW PRODUKTU** 🔍
  /// Wykorzystuje getProductInvestorsOptimized z product-investors-optimization.js
  static Future<void> showProductInvestorsSearch(
    BuildContext context, {
    String? productName,
    String? productType,
  }) async {
    try {
      print('🔍 [Updated Functions] Wyszukiwanie inwestorów produktu...');

      _showLoadingDialog(context, 'Wyszukiwanie inwestorów...');

      final result = await _functionsService.getProductInvestorsOptimized(
        productName: productName,
        productType: productType,
      );

      Navigator.of(context).pop(); // Zamknij dialog ładowania

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🔍 Inwestorzy produktu'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('👥 Znalezionych inwestorów: ${result.totalCount}'),
                Text('💾 Z cache: ${result.fromCache ? "Tak" : "Nie"}'),
                Text('⚡ Czas wykonania: ${result.executionTime}ms'),
                const Divider(),
                Text('📦 Produkt: ${result.productInfo.name}'),
                Text('🏷️ Typ: ${result.productInfo.type}'),
                Text(
                  '💰 Kapitał całkowity: ${CurrencyFormatter.formatCurrency(result.productInfo.totalCapital)}',
                ),
                const Divider(),
                Text('🔍 Typ wyszukiwania: ${result.searchResults.searchType}'),
                Text(
                  '📦 Dopasowanych produktów: ${result.searchResults.matchingProducts}',
                ),
                Text(
                  '💼 Całkowita liczba inwestycji: ${result.searchResults.totalInvestments}',
                ),
                if (result.investors.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    '👥 Przykładowi inwestorzy:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...result.investors
                      .take(3)
                      .map(
                        (investor) => Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                          child: Card(
                            color: AppTheme.surfaceCard,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('👤 ${investor.client.name}'),
                                  Text(
                                    '💰 Kapitał: ${CurrencyFormatter.formatCurrency(investor.totalValue)}',
                                  ),
                                  Text(
                                    '📊 Inwestycji: ${investor.investmentCount}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
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

      print('✅ [Updated Functions] Wyświetlono inwestorów produktu');
    } catch (e) {
      Navigator.of(context).pop(); // Zamknij dialog ładowania
      print('❌ [Updated Functions] Błąd wyszukiwania inwestorów: $e');
      _showErrorSnackBar(context, 'Błąd wyszukiwania inwestorów produktu: $e');
    }
  }

  /// **CZYSZCZENIE CACHE** Firebase Functions 🗑️
  static Future<void> clearCache(
    BuildContext context,
    VoidCallback onClearComplete,
  ) async {
    try {
      print('🗑️ [Updated Functions] Czyszczenie cache...');

      _showLoadingDialog(context, 'Czyszczenie cache...');

      await _functionsService.clearAnalyticsCache();

      Navigator.of(context).pop(); // Zamknij dialog ładowania

      _showSuccessSnackBar(context, 'Cache został wyczyszczony');
      onClearComplete();

      print('✅ [Updated Functions] Cache wyczyszczony');
    } catch (e) {
      Navigator.of(context).pop(); // Zamknij dialog ładowania
      print('❌ [Updated Functions] Błąd czyszczenia cache: $e');
      _showErrorSnackBar(context, 'Błąd czyszczenia cache: $e');
    }
  }

  /// **MENU GŁÓWNE AKCJI** 🎛️
  /// Wyświetla menu z wszystkimi dostępnymi akcjami
  static void showMainActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundPrimary,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🚀 Firebase Functions - Nowe Funkcje',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _buildActionTile(
              context,
              '📦 Statystyki produktów',
              'Wyświetl szczegółowe statystyki wszystkich produktów',
              Icons.bar_chart_rounded,
              AppTheme.successPrimary,
              () => showProductStatistics(context),
            ),
            _buildActionTile(
              context,
              '👥 Informacje o klientach',
              'Pobierz informacje o klientach z serwera',
              Icons.people_rounded,
              AppTheme.primaryColor,
              () => showClientsInfo(context),
            ),
            _buildActionTile(
              context,
              '🔍 Wyszukaj inwestorów',
              'Znajdź inwestorów konkretnego produktu',
              Icons.search_rounded,
              AppTheme.warningPrimary,
              () => _showProductSearchDialog(context),
            ),
            _buildActionTile(
              context,
              '🧪 Test debug',
              'Uruchom test diagnostyczny funkcji',
              Icons.bug_report_rounded,
              AppTheme.infoPrimary,
              () => showDebugTest(context),
            ),
            _buildActionTile(
              context,
              '🗑️ Wyczyść cache',
              'Wyczyść cache analityczny',
              Icons.clear_all_rounded,
              AppTheme.errorPrimary,
              () => clearCache(context, () {}),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// **DIALOG WYSZUKIWANIA PRODUKTU** 🔍
  static void _showProductSearchDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController typeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 Wyszukaj inwestorów produktu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nazwa produktu (opcjonalne)',
                hintText: 'np. "Obligacje XYZ"',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: 'Typ produktu (opcjonalne)',
                hintText: 'np. "bonds", "shares", "apartments"',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              showProductInvestorsSearch(
                context,
                productName: nameController.text.trim().isEmpty
                    ? null
                    : nameController.text.trim(),
                productType: typeController.text.trim().isEmpty
                    ? null
                    : typeController.text.trim(),
              );
            },
            child: const Text('Szukaj'),
          ),
        ],
      ),
    );
  }

  // 🛠️ HELPER METHODS

  static Widget _buildActionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).pop(); // Zamknij bottom sheet
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[600],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  static void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $message'),
        backgroundColor: AppTheme.successPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: AppTheme.errorPrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
