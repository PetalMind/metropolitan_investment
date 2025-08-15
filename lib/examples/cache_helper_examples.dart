// 🚀 PRZYKŁAD UŻYCIA CacheHelper w różnych ekranach
//
// Ten plik pokazuje jak łatwo zintegrować zarządzanie cache
// w różnych miejscach aplikacji używając CacheHelper

import 'package:flutter/material.dart';
import '../models_and_services.dart';

/// 📊 PRZYKŁAD 1: Dodanie cache management do Dashboard
class DashboardScreenWithCache extends StatelessWidget {
  const DashboardScreenWithCache({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // 🧹 GOTOWY PRZYCISK - jedna linijka kodu!
          CacheHelper.buildCacheActionButton(
            context,
            onCacheCleared: () {
              // Opcjonalnie: przeładuj dane po wyczyszczeniu cache
              print('Cache wyczyszczony - można przeładować dane');
            },
          ),
        ],
      ),
      body: const Center(child: Text('Dashboard Content')),
    );
  }
}

/// 📈 PRZYKŁAD 2: Ekran analytics z prostym cache management
class AnalyticsScreenWithCache extends StatefulWidget {
  const AnalyticsScreenWithCache({super.key});

  @override
  State<AnalyticsScreenWithCache> createState() =>
      _AnalyticsScreenWithCacheState();
}

class _AnalyticsScreenWithCacheState extends State<AnalyticsScreenWithCache> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          // Prosty przycisk odświeżania z cache management
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshWithCacheManagement,
            tooltip: 'Odśwież dane',
          ),
          // Status cache
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () => CacheHelper.showQuickStatus(context),
            tooltip: 'Status cache',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : const Center(child: Text('Analytics Content')),
      floatingActionButton: FloatingActionButton(
        onPressed: _clearCacheAndReload,
        child: const Icon(Icons.cleaning_services),
        tooltip: 'Wyczyść cache',
      ),
    );
  }

  /// 🔄 Odświeżanie z inteligentnym cache management
  Future<void> _refreshWithCacheManagement() async {
    setState(() => _isLoading = true);

    // Odśwież tylko analytics cache
    final success = await CacheHelper.quickRefresh(
      context,
      refreshProducts: false, // Nie odświeżaj produktów
      refreshStatistics: false, // Nie odświeżaj statystyk
      refreshAnalytics: true, // Tylko analytics
    );

    if (success) {
      // Tutaj załaduj nowe dane analytics
      await Future.delayed(const Duration(seconds: 1)); // Symulacja ładowania
    }

    setState(() => _isLoading = false);
  }

  /// 🧹 Czyszczenie cache i przeładowanie
  Future<void> _clearCacheAndReload() async {
    setState(() => _isLoading = true);

    final success = await CacheHelper.quickClearCache(context);

    if (success) {
      // Tutaj załaduj dane od nowa
      await Future.delayed(const Duration(seconds: 1)); // Symulacja ładowania
    }

    setState(() => _isLoading = false);
  }
}

/// 👥 PRZYKŁAD 3: Lista klientów z cache preload
class ClientsListWithCache extends StatefulWidget {
  const ClientsListWithCache({super.key});

  @override
  State<ClientsListWithCache> createState() => _ClientsListWithCacheState();
}

class _ClientsListWithCacheState extends State<ClientsListWithCache> {
  @override
  void initState() {
    super.initState();

    // 🎯 Automatyczny preload cache przy starcie
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CacheHelper.quickPreload(context, showSnackbar: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Klienci'),
        actions: [
          // Menu z opcjami cache
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) async {
              switch (value) {
                case 'cache_status':
                  await CacheHelper.showQuickStatus(context);
                  break;
                case 'cache_refresh':
                  await CacheHelper.quickRefresh(context);
                  break;
                case 'cache_clear':
                  await CacheHelper.quickClearCache(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'cache_status',
                child: Row(
                  children: [
                    Icon(Icons.info, size: 20),
                    SizedBox(width: 8),
                    Text('Status cache'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'cache_refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Odśwież cache'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'cache_clear',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Wyczyść cache', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: const Center(child: Text('Lista klientów')),
    );
  }
}

/// ⚙️ PRZYKŁAD 4: Ustawienia z zarządzaniem cache
class SettingsScreenWithCache extends StatelessWidget {
  const SettingsScreenWithCache({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Ogólne'),
            subtitle: Text('Podstawowe ustawienia aplikacji'),
          ),
          const Divider(),

          // Sekcja Cache Management
          const ListTile(
            title: Text('Zarządzanie Cache'),
            subtitle: Text('Optymalizacja wydajności aplikacji'),
            leading: Icon(Icons.cleaning_services),
          ),

          ListTile(
            title: const Text('Status cache'),
            subtitle: const Text('Sprawdź aktualny stan cache'),
            leading: const Icon(Icons.info),
            onTap: () => CacheHelper.showQuickStatus(context),
          ),

          ListTile(
            title: const Text('Odśwież cache'),
            subtitle: const Text('Inteligentne odświeżanie danych'),
            leading: const Icon(Icons.refresh),
            onTap: () => CacheHelper.quickRefresh(context),
          ),

          ListTile(
            title: const Text('Preload cache'),
            subtitle: const Text('Rozgrzej cache dla lepszej wydajności'),
            leading: const Icon(Icons.flash_on),
            onTap: () => CacheHelper.quickPreload(context),
          ),

          ListTile(
            title: const Text('Wyczyść cache'),
            subtitle: const Text('Usuń wszystkie dane z cache'),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () => CacheHelper.quickClearCache(context),
          ),

          const Divider(),
          const ListTile(
            title: Text('Inne ustawienia'),
            subtitle: Text('Dodatkowe opcje'),
          ),
        ],
      ),
    );
  }
}

/// 💡 WSKAZÓWKI UŻYCIA:
/// 
/// 1. Użyj CacheHelper.buildCacheActionButton() dla szybkiego dodania 
///    kompletnego menu cache do toolbar
/// 
/// 2. Użyj pojedynczych metod (quickClearCache, quickRefresh, etc.) 
///    dla konkretnych akcji
/// 
/// 3. quickPreload() z showSnackbar: false jest idealne dla inicjalizacji
/// 
/// 4. showQuickStatus() dla debugowania problemów z cache
/// 
/// 5. Wszystkie metody obsługują automatyczne snackbar z feedback
