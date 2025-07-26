// ignore_for_file: unused_local_variable, unused_element, unused_import
/// 📊 Przykłady użycia zoptymalizowanych serwisów Firebase
/// 
/// Ten plik zawiera praktyczne przykłady jak używać nowych, zoptymalizowanych
/// serwisów Firebase z paginacją, cache i limitami dla lepszej wydajności.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// Import modeli
import '../models/client.dart';
import '../models/investment.dart';
import '../models/product.dart'; 

// Import serwisów  
import 'base_service.dart';
import 'client_service.dart';
import 'optimized_investment_service.dart';
import 'optimized_product_service.dart';

/// 🚀 Klasa z przykładami użycia zoptymalizowanych serwisów
class OptimizedServicesExamples {
  
  /// 1. PAGINACJA - Lista klientów z infinite scroll
  Future<void> examplePaginatedClients() async {
    final clientService = ClientService();
    
    // Pierwsza strona
    var params = const PaginationParams(limit: 20);
    var result = await clientService.getClientsPaginated(params: params);
    
    List<Client> allClients = result.items;
    DocumentSnapshot? lastDocument = result.lastDocument;
    bool hasMore = result.hasMore;
    
    print('Pierwsza strona: ${allClients.length} klientów');
    
    // Kolejne strony w pętli
    while (hasMore && allClients.length < 100) { // Maksymalnie 100 dla przykładu
      params = PaginationParams(
        limit: 20,
        startAfter: lastDocument,
      );
      result = await clientService.getClientsPaginated(params: params);
      
      allClients.addAll(result.items);
      lastDocument = result.lastDocument;
      hasMore = result.hasMore;
      
      print('Załadowano łącznie: ${allClients.length} klientów');
    }
  }

  /// 2. FILTROWANIE - Inwestycje z określonymi kryteriami
  Future<void> exampleFilteredInvestments() async {
    final service = OptimizedInvestmentService();
    
    // Filtr: aktywne inwestycje z 2024 roku
    final filters = FilterParams(
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 12, 31),
      dateField: 'data_podpisania',
      whereConditions: {'status_produktu': 'Aktywny'},
    );
    
    final params = const PaginationParams(
      limit: 50,
      orderBy: 'data_podpisania',
      descending: true,
    );
    
    final result = await service.getInvestmentsPaginated(
      params: params,
      filters: filters,
    );
    
    print('Znaleziono ${result.items.length} aktywnych inwestycji z 2024');
    
    for (final investment in result.items.take(5)) { // Pokaż pierwszych 5
      print('- ${investment.clientName}: ${investment.investmentAmount} PLN');
    }
  }

  /// 3. CACHE - Wykorzystanie automatycznego cache
  Future<void> exampleCacheUsage() async {
    final service = OptimizedInvestmentService();
    
    print('=== TEST CACHE ===');
    
    // Pierwsze wywołanie - dane z Firebase
    final stopwatch1 = Stopwatch()..start();
    var stats = await service.getInvestmentStatistics();
    stopwatch1.stop();
    print('1. Pierwsze pobranie: ${stopwatch1.elapsedMilliseconds}ms');
    print('   Aktywne: ${stats['activeCount']}');
    
    // Drugie wywołanie - dane z cache (powinno być szybsze)
    final stopwatch2 = Stopwatch()..start();
    stats = await service.getInvestmentStatistics();
    stopwatch2.stop();
    print('2. Drugie pobranie (cache): ${stopwatch2.elapsedMilliseconds}ms');
    print('   Aktywne: ${stats['activeCount']}');
    
    // Ręczne czyszczenie cache
    service.clearCache('investment_stats');
    print('3. Cache wyczyszczony');
    
    // Trzecie wywołanie - ponownie z Firebase
    final stopwatch3 = Stopwatch()..start();
    stats = await service.getInvestmentStatistics();
    stopwatch3.stop();
    print('4. Po czyszczeniu cache: ${stopwatch3.elapsedMilliseconds}ms');
    print('   Aktywne: ${stats['activeCount']}');
  }

  /// 4. WYSZUKIWANIE Z LIMITAMI
  Future<void> exampleSearchWithLimits() async {
    final clientService = ClientService();
    final query = 'Kowalski';
    
    print('=== WYSZUKIWANIE: "$query" ===');
    
    // Strumień wyszukiwania z limitem 20 wyników
    final searchStream = clientService.searchClients(query, limit: 20);
    
    await for (final clients in searchStream) {
      print('Znaleziono ${clients.length} klientów:');
      for (final client in clients.take(5)) { // Pokaż pierwszych 5
        print('- ${client.name}');
      }
      break; // Tylko pierwszy wynik dla przykładu
    }
  }

  /// 5. STATYSTYKI Z PRÓBKOWANIEM
  Future<void> exampleStatisticsWithSampling() async {
    final service = OptimizedInvestmentService();
    
    print('=== STATYSTYKI INWESTYCJI ===');
    
    // Pobierz statystyki (używa cache i próbkowania)
    final stats = await service.getInvestmentStatistics();
    
    print('📊 Podsumowanie:');
    print('   Aktywne: ${stats['activeCount']}');
    print('   Nieaktywne: ${stats['inactiveCount']}');
    
    if (stats['averageAmount'] != null) {
      print('   Średnia kwota: ${stats['averageAmount']?.toStringAsFixed(2)} PLN');
    }
    
    if (stats['totalValue'] != null) {
      print('   Łączna wartość: ${stats['totalValue']?.toStringAsFixed(2)} PLN');
    }
    
    print('   Ostatnia aktualizacja: ${stats['lastUpdated']}');
  }

  /// 6. PRODUKTY WEDŁUG TYPU
  Future<void> exampleProductsByType() async {
    final productService = OptimizedProductService();
    
    print('=== PRODUKTY WEDŁUG TYPU ===');
    
    // Obligacje z limitem
    final bondsStream = productService.getProductsByType(
      ProductType.bonds, 
      limit: 25,
    );
    
    await for (final bonds in bondsStream) {
      print('📋 Dostępne obligacje (${bonds.length}):');
      for (final bond in bonds.take(5)) {
        print('   - ${bond.name}');
      }
      break;
    }
    
    // Obligacje bliskie wykupu
    try {
      final nearMaturity = await productService.getBondsNearMaturity(
        30, // 30 dni
        limit: 10,
      );
      
      print('⏰ Obligacje z wykupem w ciągu 30 dni: ${nearMaturity.length}');
      for (final bond in nearMaturity) {
        print('   - ${bond.name} (wykup: ${bond.maturityDate})');
      }
    } catch (e) {
      print('Błąd przy pobieraniu obligacji bliskich wykupu: $e');
    }
  }

  /// 7. OBSŁUGA BŁĘDÓW
  Future<void> exampleErrorHandling() async {
    final service = OptimizedInvestmentService();
    
    print('=== TEST OBSŁUGI BŁĘDÓW ===');
    
    try {
      final result = await service.getInvestmentsPaginated(
        params: const PaginationParams(limit: 100),
      );
      print('✅ Sukces: ${result.items.length} inwestycji');
    } catch (e) {
      print('❌ Błąd podczas pobierania inwestycji: $e');
      
      // W prawdziwej aplikacji pokażesz user-friendly wiadomość:
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Nie można pobrać danych. Spróbuj ponownie.')),
      // );
    }
  }

  /// 8. MONITOROWANIE WYDAJNOŚCI
  Future<void> examplePerformanceMonitoring() async {
    final service = OptimizedInvestmentService();
    
    print('=== MONITORING WYDAJNOŚCI ===');
    
    final stopwatch = Stopwatch()..start();
    
    final result = await service.getInvestmentsPaginated(
      params: const PaginationParams(limit: 50),
    );
    
    stopwatch.stop();
    
    print('📈 Wyniki:');
    print('   Załadowane elementy: ${result.items.length}');
    print('   Czas ładowania: ${stopwatch.elapsedMilliseconds}ms');
    print('   Używane reads: ~${result.items.length}');
    
    // Alert jeśli za wolno
    if (stopwatch.elapsedMilliseconds > 3000) {
      print('⚠️  UWAGA: Wolne zapytanie!');
      print('   Rozważ zmniejszenie limitu lub dodanie indeksów');
    } else {
      print('✅ Wydajność OK');
    }
  }

  /// 9. POŁĄCZENIE CACHE Z PAGINACJĄ
  Future<void> exampleOptimizedDataFlow() async {
    final investmentService = OptimizedInvestmentService();
    final clientService = ClientService();
    
    print('=== ZOPTYMALIZOWANY PRZEPŁYW DANYCH ===');
    
    // 1. Pobierz statystyki z cache
    final stats = await investmentService.getInvestmentStatistics();
    print('1. Stats (cached): ${stats['activeCount']} aktywnych inwestycji');

    // 2. Pobierz pierwszą stronę inwestycji
    final investmentParams = const PaginationParams(limit: 20);
    final investmentResult = await investmentService.getInvestmentsPaginated(
      params: investmentParams,
    );

    // 3. Pobierz paginowane klientów dla porównania
    final clientParams = const PaginationParams(limit: 50);
    final clientResult = await clientService.getClientsPaginated(
      params: clientParams,
    );

    print('2. Załadowano:');
    print('   - ${investmentResult.items.length} inwestycji');
    print('   - ${clientResult.items.length} klientów');

    // 4. Wyczyść cache tylko jeśli potrzeba
    if (DateTime.now().hour == 6) {
      // Codzienny refresh o 6:00
      investmentService.clearAllCache();
      clientService.clearAllCache();
      print('3. Cache wyczyszczony (codzienny refresh)');
    } else {
      print('3. Cache pozostawiony (nie jest 6:00)');
    }
  }

  /// 10. STREAM Z LIMITAMI - Przykład widget
  Widget buildLimitedStreamWidget() {
    final service = OptimizedInvestmentService();
    
    return StreamBuilder<List<Investment>>(
      stream: service.getAllInvestments(limit: 30), // MAX 30 elementów!
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Błąd: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Restart stream
                  },
                  child: const Text('Spróbuj ponownie'),
                ),
              ],
            ),
          );
        }
        
        if (!snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Ładowanie inwestycji...'),
              ],
            ),
          );
        }
        
        final investments = snapshot.data!;
        
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Najnowsze inwestycje (${investments.length}/30)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: investments.length,
                itemBuilder: (context, index) {
                  final investment = investments[index];
                  return ListTile(
                    title: Text(investment.clientName),
                    subtitle: Text('${investment.investmentAmount} PLN'),
                    trailing: Chip(
                      label: Text(investment.status.displayName),
                      backgroundColor: investment.status == InvestmentStatus.active 
                          ? Colors.green[100] 
                          : Colors.orange[100],
                    ),
                    onTap: () {
                      // Przejdź do szczegółów inwestycji
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// 📋 BEST PRACTICES SUMMARY
  void printBestPractices() {
    print('''
🚀 NAJLEPSZE PRAKTYKI OPTYMALIZACJI FIREBASE:

✅ ZAWSZE RÓB:
   • Używaj limitów w Stream queries (20-50 elementów)
   • Implementuj paginację dla list > 50 elementów  
   • Cache statystyki i dane referencyjne (getCachedData)
   • Monitoruj czas odpowiedzi (<3s dla dobrego UX)
   • Obsługuj błędy gracefully z fallback
   • Używaj próbkowania dla dużych zbiorów danych
   • Implementuj loading states i progress indicators
   • Dodaj pull-to-refresh dla odświeżania danych

❌ NIGDY NIE:
   • Pobieraj wszystkich danych naraz (bez limitów)
   • Używaj Stream bez ograniczeń ilości
   • Ignoruj błędów sieci lub Firebase
   • Rób częstych zapytań bez cache
   • Blokuj UI podczas długich operacji

💡 ZALECANE LIMITY:
   📱 Mobile UI:
      - Lista główna: 20-30 elementów na stronę
      - Search results: 15-30 wyników
      - Dropdown/Autocomplete: 5-15 opcji
   
   🖥️ Desktop UI:
      - Lista główna: 50-100 elementów na stronę  
      - Search results: 30-50 wyników
      - Dropdown: 10-20 opcji
   
   📊 Statystyki:
      - Próbkowanie: 1000-5000 dokumentów
      - Cache timeout: 5-10 minut
      - Count queries zamiast pełnego skanowania

🔧 OPTYMALIZACJE WYDAJNOŚCI:
   • BaseService z automatycznym cache (5 min timeout)
   • DocumentSnapshot cursor-based pagination
   • Firebase composite indexes dla złożonych zapytań
   • Lazy loading dla szczegółowych widoków
   • Background refresh dla krytycznych danych

📊 OCZEKIWANE WYNIKI:
   Before: 10,000+ reads per query (wszystkie dane)
   After:  20-50 reads per query (paginacja)
   Improvement: 99% redukcja kosztów Firebase!
   
   Before: 5-15s loading time
   After:  0.5-2s loading time  
   Improvement: 80-90% szybciej!
    ''');
  }

  /// 🧪 URUCHOM WSZYSTKIE PRZYKŁADY
  Future<void> runAllExamples() async {
    print('🚀 Uruchamianie wszystkich przykładów optymalizacji...\n');
    
    try {
      await examplePaginatedClients();
      print('\n' + '='*50 + '\n');
      
      await exampleFilteredInvestments();
      print('\n' + '='*50 + '\n');
      
      await exampleCacheUsage();
      print('\n' + '='*50 + '\n');
      
      await exampleSearchWithLimits();
      print('\n' + '='*50 + '\n');
      
      await exampleStatisticsWithSampling();
      print('\n' + '='*50 + '\n');
      
      await exampleProductsByType();
      print('\n' + '='*50 + '\n');
      
      await exampleErrorHandling();
      print('\n' + '='*50 + '\n');
      
      await examplePerformanceMonitoring();
      print('\n' + '='*50 + '\n');
      
      await exampleOptimizedDataFlow();
      print('\n' + '='*50 + '\n');
      
      printBestPractices();
      
      print('\n✅ Wszystkie przykłady zakończone pomyślnie!');
      print('🎉 Twoja aplikacja jest teraz zoptymalizowana dla dużych zbiorów danych!');
      
    } catch (e) {
      print('❌ Błąd podczas uruchamiania przykładów: $e');
    }
  }
}

/// 📱 PRZYKŁAD KOMPLETNEGO WIDGET Z INFINITE SCROLL
class OptimizedInvestmentListWidget extends StatefulWidget {
  const OptimizedInvestmentListWidget({Key? key}) : super(key: key);

  @override
  State<OptimizedInvestmentListWidget> createState() => _OptimizedInvestmentListWidgetState();
}

class _OptimizedInvestmentListWidgetState extends State<OptimizedInvestmentListWidget> {
  final OptimizedInvestmentService _service = OptimizedInvestmentService();
  final ScrollController _scrollController = ScrollController();
  
  List<Investment> _investments = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final params = const PaginationParams(limit: 20);
      final result = await _service.getInvestmentsPaginated(params: params);
      
      setState(() {
        _investments = result.items;
        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (!_hasMore || _isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final params = PaginationParams(
        limit: 20,
        startAfter: _lastDocument,
      );
      final result = await _service.getInvestmentsPaginated(params: params);
      
      setState(() {
        _investments.addAll(result.items);
        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      
      // Pokaż snackbar z błędem
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd ładowania: $e'),
            action: SnackBarAction(
              label: 'Spróbuj ponownie',
              onPressed: _loadMoreData,
            ),
          ),
        );
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) { // Load 200px before end
      _loadMoreData();
    }
  }

  Future<void> _refreshData() async {
    // Clear cache and reload
    _service.clearAllCache();
    setState(() {
      _investments.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _investments.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inwestycje')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Błąd: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitialData,
                child: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Inwestycje (${_investments.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _investments.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Loading indicator at the end
            if (index == _investments.length) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Koniec listy'),
                ),
              );
            }
            
            final investment = _investments[index];
            return ListTile(
              title: Text(investment.clientName),
              subtitle: Text('${investment.investmentAmount.toStringAsFixed(2)} PLN'),
              trailing: Chip(
                label: Text(investment.status.displayName),
                backgroundColor: investment.status == InvestmentStatus.active
                    ? Colors.green[100]
                    : Colors.orange[100],
              ),
              onTap: () {
                // Navigate to investment details
                // Navigator.push(context, MaterialPageRoute(
                //   builder: (context) => InvestmentDetailsScreen(investment: investment),
                // ));
              },
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
