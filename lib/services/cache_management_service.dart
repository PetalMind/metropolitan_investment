import 'package:flutter/foundation.dart';
import 'product_management_service.dart';
import 'unified_dashboard_statistics_service.dart';
import 'investor_analytics_service.dart';
import 'investor_edit_service.dart';
import 'server_side_statistics_service.dart';

/// 🚀 CENTRALNY SERWIS ZARZĄDZANIA CACHE
///
/// Ten serwis zapewnia jednolite zarządzanie cache dla wszystkich serwisów
/// korzystających z ProductManagementService. Umożliwia:
/// - Centralne czyszczenie cache wszystkich serwisów
/// - Monitoring statusu cache
/// - Optymalizację wydajności przez inteligentne odświeżanie
/// - Diagnostykę problemów z cache
class CacheManagementService {
  // Instancje serwisów
  final ProductManagementService _productManagementService;
  final UnifiedDashboardStatisticsService _dashboardService;
  final InvestorAnalyticsService _analyticsService;
  final InvestorEditService _editService;

  CacheManagementService()
    : _productManagementService = ProductManagementService(),
      _dashboardService = UnifiedDashboardStatisticsService(),
      _analyticsService = InvestorAnalyticsService(),
      _editService = InvestorEditService();

  /// 🧹 MASOWE CZYSZCZENIE CACHE - wszystkie serwisy
  Future<CacheClearResult> clearAllCaches() async {
    if (kDebugMode) {
      print(
        '🧹 [CacheManagementService] Rozpoczynam masowe czyszczenie cache...',
      );
    }

    final stopwatch = Stopwatch()..start();
    final errors = <String>[];

    // ProductManagementService (główny)
    try {
      await _productManagementService.clearAllCache();
      if (kDebugMode) {
        print(
          '✅ [CacheManagementService] ProductManagementService - cache wyczyszczony',
        );
      }
    } catch (e) {
      errors.add('ProductManagementService: $e');
    }

    // UnifiedDashboardStatisticsService
    try {
      await _dashboardService.refreshStatistics();
      if (kDebugMode) {
        print(
          '✅ [CacheManagementService] UnifiedDashboardStatisticsService - cache wyczyszczony',
        );
      }
    } catch (e) {
      errors.add('UnifiedDashboardStatisticsService: $e');
    }

    // InvestorAnalyticsService
    try {
      _analyticsService.clearAnalyticsCache();
      if (kDebugMode) {
        print(
          '✅ [CacheManagementService] InvestorAnalyticsService - cache wyczyszczony',
        );
      }
    } catch (e) {
      errors.add('InvestorAnalyticsService: $e');
    }

    // InvestorEditService
    try {
      await _editService.clearAllCache();
      if (kDebugMode) {
        print(
          '✅ [CacheManagementService] InvestorEditService - cache wyczyszczony',
        );
      }
    } catch (e) {
      errors.add('InvestorEditService: $e');
    }

    // ServerSideStatisticsService (static)
    try {
      await ServerSideStatisticsService.clearAllCache();
      if (kDebugMode) {
        print(
          '✅ [CacheManagementService] ServerSideStatisticsService - cache wyczyszczony',
        );
      }
    } catch (e) {
      errors.add('ServerSideStatisticsService: $e');
    }

    stopwatch.stop();

    if (kDebugMode) {
      print(
        '🎯 [CacheManagementService] Masowe czyszczenie zakończone w ${stopwatch.elapsedMilliseconds}ms',
      );
      if (errors.isNotEmpty) {
        print('⚠️ [CacheManagementService] Błędy: ${errors.length}');
        for (final error in errors) {
          print('   - $error');
        }
      }
    }

    return CacheClearResult(
      success: errors.isEmpty,
      duration: stopwatch.elapsedMilliseconds,
      errors: errors,
      clearedServices: [
        'ProductManagementService',
        'UnifiedDashboardStatisticsService',
        'InvestorAnalyticsService',
        'InvestorEditService',
        'ServerSideStatisticsService',
      ],
    );
  }

  /// 📊 STATUS CACHE - diagnostyka wszystkich serwisów
  Future<GlobalCacheStatus> getCacheStatus() async {
    if (kDebugMode) {
      print('📊 [CacheManagementService] Sprawdzam status cache...');
    }

    final stopwatch = Stopwatch()..start();

    // ProductManagementService status
    final productCacheStatus = await _productManagementService.getCacheStatus();

    // Dashboard statistics status
    final dashboardStats = await _dashboardService.getStatisticsFromProducts();

    stopwatch.stop();

    return GlobalCacheStatus(
      productManagementCache: productCacheStatus,
      dashboardCacheActive: dashboardStats.dataSource.contains('cache'),
      lastGlobalRefresh: DateTime.now(),
      diagnosticTime: stopwatch.elapsedMilliseconds,
      servicesIntegrated: [
        'ProductManagementService',
        'UnifiedDashboardStatisticsService',
        'InvestorAnalyticsService',
        'InvestorEditService',
        'ServerSideStatisticsService',
      ],
    );
  }

  /// 🔄 INTELIGENTNE ODŚWIEŻANIE - selektywne czyszczenie cache
  Future<CacheRefreshResult> smartRefresh({
    bool refreshProducts = true,
    bool refreshStatistics = true,
    bool refreshAnalytics = false,
  }) async {
    if (kDebugMode) {
      print('🔄 [CacheManagementService] Inteligentne odświeżanie...');
    }

    final stopwatch = Stopwatch()..start();
    final refreshedServices = <String>[];
    final errors = <String>[];

    if (refreshProducts) {
      try {
        await _productManagementService.refreshCache();
        refreshedServices.add('ProductManagementService');
      } catch (e) {
        errors.add('ProductManagementService: $e');
      }
    }

    if (refreshStatistics) {
      try {
        await _dashboardService.refreshStatistics();
        refreshedServices.add('UnifiedDashboardStatisticsService');
      } catch (e) {
        errors.add('UnifiedDashboardStatisticsService: $e');
      }
    }

    if (refreshAnalytics) {
      try {
        _analyticsService.clearAnalyticsCache();
        refreshedServices.add('InvestorAnalyticsService');
      } catch (e) {
        errors.add('InvestorAnalyticsService: $e');
      }
    }

    stopwatch.stop();

    return CacheRefreshResult(
      success: errors.isEmpty,
      duration: stopwatch.elapsedMilliseconds,
      refreshedServices: refreshedServices,
      errors: errors,
    );
  }

  /// 🎯 PRELOAD CACHE - rozgrzewanie cache dla lepszej wydajności
  Future<CachePreloadResult> preloadCache() async {
    if (kDebugMode) {
      print('🎯 [CacheManagementService] Rozgrzewanie cache...');
    }

    final stopwatch = Stopwatch()..start();
    final preloadedServices = <String>[];
    final errors = <String>[];

    // Preload ProductManagementService
    try {
      await _productManagementService.loadOptimizedData(
        forceRefresh: false,
        includeStatistics: true,
      );
      preloadedServices.add('ProductManagementService');
    } catch (e) {
      errors.add('ProductManagementService: $e');
    }

    // Preload Dashboard Statistics
    try {
      await _dashboardService.getStatisticsFromProducts();
      preloadedServices.add('UnifiedDashboardStatisticsService');
    } catch (e) {
      errors.add('UnifiedDashboardStatisticsService: $e');
    }

    stopwatch.stop();

    if (kDebugMode) {
      print(
        '🎯 [CacheManagementService] Preload zakończony w ${stopwatch.elapsedMilliseconds}ms',
      );
    }

    return CachePreloadResult(
      success: errors.isEmpty,
      duration: stopwatch.elapsedMilliseconds,
      preloadedServices: preloadedServices,
      errors: errors,
    );
  }
}

// 🚀 KLASY POMOCNICZE

class CacheClearResult {
  final bool success;
  final int duration;
  final List<String> errors;
  final List<String> clearedServices;

  CacheClearResult({
    required this.success,
    required this.duration,
    required this.errors,
    required this.clearedServices,
  });
}

class GlobalCacheStatus {
  final CacheStatus productManagementCache;
  final bool dashboardCacheActive;
  final DateTime lastGlobalRefresh;
  final int diagnosticTime;
  final List<String> servicesIntegrated;

  GlobalCacheStatus({
    required this.productManagementCache,
    required this.dashboardCacheActive,
    required this.lastGlobalRefresh,
    required this.diagnosticTime,
    required this.servicesIntegrated,
  });
}

class CacheRefreshResult {
  final bool success;
  final int duration;
  final List<String> refreshedServices;
  final List<String> errors;

  CacheRefreshResult({
    required this.success,
    required this.duration,
    required this.refreshedServices,
    required this.errors,
  });
}

class CachePreloadResult {
  final bool success;
  final int duration;
  final List<String> preloadedServices;
  final List<String> errors;

  CachePreloadResult({
    required this.success,
    required this.duration,
    required this.preloadedServices,
    required this.errors,
  });
}
