import 'package:flutter/material.dart';
import '../models_and_services.dart';

/// 🧹 CACHE MANAGEMENT HELPER - Utility klasa dla łatwego zarządzania cache
///
/// Zapewnia proste metody do integracji zarządzania cache w różnych ekranach
/// bez konieczności implementowania pełnych dialogów za każdym razem.
class CacheHelper {
  static final CacheManagementService _cacheService = CacheManagementService();

  /// 🚀 SZYBKIE CZYSZCZENIE CACHE - z prostym snackbar feedback
  static Future<bool> quickClearCache(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Czyszczenie cache...'),
            ],
          ),
          duration: Duration(seconds: 10), // Dłuższy czas dla długich operacji
        ),
      );

      final result = await _cacheService.clearAllCaches();

      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? '✅ Cache wyczyszczony (${result.duration}ms)'
                : '❌ Błędy podczas czyszczenia: ${result.errors.length}',
          ),
          backgroundColor: result.success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      return result.success;
    } catch (e) {
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('❌ Błąd: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return false;
    }
  }

  /// 🔄 SZYBKIE ODŚWIEŻANIE - z opcjonalnymi parametrami
  static Future<bool> quickRefresh(
    BuildContext context, {
    bool refreshProducts = true,
    bool refreshStatistics = true,
    bool refreshAnalytics = false,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Odświeżanie cache...'),
            ],
          ),
          duration: Duration(seconds: 8),
        ),
      );

      final result = await _cacheService.smartRefresh(
        refreshProducts: refreshProducts,
        refreshStatistics: refreshStatistics,
        refreshAnalytics: refreshAnalytics,
      );

      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? '✅ Cache odświeżony (${result.duration}ms, ${result.refreshedServices.length} serwisów)'
                : '❌ Błędy podczas odświeżania: ${result.errors.length}',
          ),
          backgroundColor: result.success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      return result.success;
    } catch (e) {
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('❌ Błąd: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return false;
    }
  }

  /// 🎯 SZYBKI PRELOAD - rozgrzanie cache w tle
  static Future<bool> quickPreload(
    BuildContext context, {
    bool showSnackbar = true,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (showSnackbar) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Rozgrzewanie cache...'),
              ],
            ),
            duration: Duration(seconds: 6),
          ),
        );
      }

      final result = await _cacheService.preloadCache();

      if (showSnackbar) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? '✅ Cache rozgrzany (${result.duration}ms)'
                  : '❌ Błędy podczas preload: ${result.errors.length}',
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      return result.success;
    } catch (e) {
      if (showSnackbar) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('❌ Błąd: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return false;
    }
  }

  /// 📊 SZYBKI STATUS - prosty dialog ze statusem cache
  static Future<void> showQuickStatus(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<GlobalCacheStatus>(
          future: _cacheService.getCacheStatus(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                title: Text('Status Cache'),
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Sprawdzam status...'),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Błąd'),
                content: Text(
                  'Nie można pobrać statusu cache: ${snapshot.error}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              );
            }

            final status = snapshot.data!;
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Status Cache'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎯 Cache optimized: ${status.productManagementCache.optimizedCacheHit ? "✅" : "❌"}',
                  ),
                  Text(
                    '📊 Cache deduplikowany: ${status.productManagementCache.deduplicatedCacheActive ? "✅" : "❌"}',
                  ),
                  Text(
                    '🔄 Wersja: ${status.productManagementCache.cacheVersion}',
                  ),
                  Text('⏱️ Diagnostyka: ${status.diagnosticTime}ms'),
                  Text('🔧 Serwisy: ${status.servicesIntegrated.length}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 🔧 CACHE MANAGEMENT ACTION BUTTON - gotowy przycisk do toolbar
  static Widget buildCacheActionButton(
    BuildContext context, {
    VoidCallback? onCacheCleared,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.cleaning_services),
      tooltip: 'Zarządzanie cache',
      onSelected: (String value) async {
        switch (value) {
          case 'clear':
            final success = await quickClearCache(context);
            if (success && onCacheCleared != null) {
              onCacheCleared();
            }
            break;
          case 'refresh':
            final success = await quickRefresh(context);
            if (success && onCacheCleared != null) {
              onCacheCleared();
            }
            break;
          case 'preload':
            await quickPreload(context);
            break;
          case 'status':
            await showQuickStatus(context);
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'status',
          child: Row(
            children: [
              Icon(Icons.info, size: 20),
              SizedBox(width: 8),
              Text('Status cache'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'preload',
          child: Row(
            children: [
              Icon(Icons.flash_on, size: 20),
              SizedBox(width: 8),
              Text('Preload cache'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'refresh',
          child: Row(
            children: [
              Icon(Icons.refresh, size: 20),
              SizedBox(width: 8),
              Text('Odśwież cache'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'clear',
          child: Row(
            children: [
              Icon(Icons.delete_forever, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Wyczyść cache', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}
