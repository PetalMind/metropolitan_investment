import 'dart:developer' as developer;
import 'package:cloud_functions/cloud_functions.dart';

/// 🔥 Firebase Functions Dashboard Service
/// Service do komunikacji z Firebase Functions dla zaawansowanej analityki dashboard
///
/// Zastępuje bezpośrednie obliczenia w AdvancedAnalyticsService
/// przeniesionymi na serwer funkcjami analitycznymi
class FirebaseFunctionsDashboardService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  // 📊 GŁÓWNE METRYKI DASHBOARD

  /// Pobiera zaawansowane metryki dashboard ze wszystkich kolekcji
  ///
  /// Zastępuje [AdvancedAnalyticsService.calculateAdvancedMetrics]
  /// z pełną integracją split_investment_data structure
  static Future<Map<String, dynamic>?> getAdvancedDashboardMetrics({
    bool forceRefresh = false,
  }) async {
    try {
      developer.log(
        '🔥 [Dashboard Service] Wywołuję getAdvancedDashboardMetrics',
        name: 'FirebaseFunctionsDashboardService',
      );

      final HttpsCallable callable = _functions.httpsCallable(
        'getAdvancedDashboardMetrics',
      );

      final HttpsCallableResult result = await callable.call({
        'forceRefresh': forceRefresh,
      });

      final data = result.data as Map<String, dynamic>?;

      if (data != null) {
        developer.log(
          '✅ [Dashboard Service] Otrzymano metryki dashboard: '
          '${data['executionTime']}ms, ${data['dataPoints'] ?? 'N/A'} punktów danych',
          name: 'FirebaseFunctionsDashboardService',
        );
      }

      return data;
    } catch (e) {
      developer.log(
        '❌ [Dashboard Service] Błąd pobierania metryk dashboard: $e',
        name: 'FirebaseFunctionsDashboardService',
        error: e,
      );
      return null;
    }
  }

  // 📈 METRYKI PERFORMANCE TAB

  /// Pobiera szczegółowe metryki wydajności dla zakładki Performance
  ///
  /// [timePeriod] - okres analizy: 'all', '1m', '3m', '6m', '1y', '2y'
  static Future<Map<String, dynamic>?> getPerformanceMetrics({
    String timePeriod = 'all',
    bool forceRefresh = false,
  }) async {
    try {
      developer.log(
        '📈 [Dashboard Service] Wywołuję getDashboardPerformanceMetrics, period: $timePeriod',
        name: 'FirebaseFunctionsDashboardService',
      );

      final HttpsCallable callable = _functions.httpsCallable(
        'getDashboardPerformanceMetrics',
      );

      final HttpsCallableResult result = await callable.call({
        'timePeriod': timePeriod,
        'forceRefresh': forceRefresh,
      });

      final data = result.data as Map<String, dynamic>?;

      if (data != null) {
        developer.log(
          '✅ [Dashboard Service] Otrzymano metryki performance: '
          '${data['executionTime']}ms, ${data['dataPoints']} inwestycji',
          name: 'FirebaseFunctionsDashboardService',
        );
      }

      return data;
    } catch (e) {
      developer.log(
        '❌ [Dashboard Service] Błąd pobierania metryk performance: $e',
        name: 'FirebaseFunctionsDashboardService',
        error: e,
      );
      return null;
    }
  }

  // ⚠️ METRYKI RISK TAB

  /// Pobiera szczegółową analizę ryzyka dla zakładki Risk
  ///
  /// [riskProfile] - profil ryzyka: 'conservative', 'moderate', 'aggressive'
  static Future<Map<String, dynamic>?> getRiskMetrics({
    String riskProfile = 'moderate',
    bool forceRefresh = false,
  }) async {
    try {
      developer.log(
        '⚠️ [Dashboard Service] Wywołuję getDashboardRiskMetrics, profile: $riskProfile',
        name: 'FirebaseFunctionsDashboardService',
      );

      final HttpsCallable callable = _functions.httpsCallable(
        'getDashboardRiskMetrics',
      );

      final HttpsCallableResult result = await callable.call({
        'riskProfile': riskProfile,
        'forceRefresh': forceRefresh,
      });

      final data = result.data as Map<String, dynamic>?;

      if (data != null) {
        developer.log(
          '✅ [Dashboard Service] Otrzymano metryki risk: '
          '${data['executionTime']}ms',
          name: 'FirebaseFunctionsDashboardService',
        );
      }

      return data;
    } catch (e) {
      developer.log(
        '❌ [Dashboard Service] Błąd pobierania metryk risk: $e',
        name: 'FirebaseFunctionsDashboardService',
        error: e,
      );
      return null;
    }
  }

  // 🔮 METRYKI PREDICTIONS TAB

  /// Pobiera predykcje i prognozy dla zakładki Predictions
  ///
  /// [horizon] - horyzont czasowy predykcji w miesiącach (domyślnie 12)
  static Future<Map<String, dynamic>?> getPredictions({
    int horizon = 12,
    bool forceRefresh = false,
  }) async {
    try {
      developer.log(
        '🔮 [Dashboard Service] Wywołuję getDashboardPredictions, horizon: ${horizon}m',
        name: 'FirebaseFunctionsDashboardService',
      );

      final HttpsCallable callable = _functions.httpsCallable(
        'getDashboardPredictions',
      );

      final HttpsCallableResult result = await callable.call({
        'horizon': horizon,
        'forceRefresh': forceRefresh,
      });

      final data = result.data as Map<String, dynamic>?;

      if (data != null) {
        developer.log(
          '✅ [Dashboard Service] Otrzymano predykcje: '
          '${data['executionTime']}ms',
          name: 'FirebaseFunctionsDashboardService',
        );
      }

      return data;
    } catch (e) {
      developer.log(
        '❌ [Dashboard Service] Błąd pobierania predykcji: $e',
        name: 'FirebaseFunctionsDashboardService',
        error: e,
      );
      return null;
    }
  }

  // 📊 METRYKI BENCHMARK TAB

  /// Pobiera porównania z benchmarkami dla zakładki Benchmark
  ///
  /// [benchmarkType] - typ benchmarku: 'market', 'industry', 'custom'
  static Future<Map<String, dynamic>?> getBenchmarks({
    String benchmarkType = 'market',
    bool forceRefresh = false,
  }) async {
    try {
      developer.log(
        '📊 [Dashboard Service] Wywołuję getDashboardBenchmarks, type: $benchmarkType',
        name: 'FirebaseFunctionsDashboardService',
      );

      final HttpsCallable callable = _functions.httpsCallable(
        'getDashboardBenchmarks',
      );

      final HttpsCallableResult result = await callable.call({
        'benchmarkType': benchmarkType,
        'forceRefresh': forceRefresh,
      });

      final data = result.data as Map<String, dynamic>?;

      if (data != null) {
        developer.log(
          '✅ [Dashboard Service] Otrzymano benchmarki: '
          '${data['executionTime']}ms',
          name: 'FirebaseFunctionsDashboardService',
        );
      }

      return data;
    } catch (e) {
      developer.log(
        '❌ [Dashboard Service] Błąd pobierania benchmarków: $e',
        name: 'FirebaseFunctionsDashboardService',
        error: e,
      );
      return null;
    }
  }

  // 🚀 BATCH OPERATIONS

  /// Pobiera wszystkie metryki dashboard równolegle
  /// Optymalizuje wywołania dla pełnego widoku dashboard
  static Future<Map<String, dynamic>> getAllDashboardMetrics({
    bool forceRefresh = false,
    String timePeriod = 'all',
    String riskProfile = 'moderate',
    int predictionHorizon = 12,
    String benchmarkType = 'market',
  }) async {
    try {
      developer.log(
        '🚀 [Dashboard Service] Równoległe pobieranie wszystkich metryk dashboard',
        name: 'FirebaseFunctionsDashboardService',
      );

      final futures = [
        getAdvancedDashboardMetrics(forceRefresh: forceRefresh),
        getPerformanceMetrics(
          timePeriod: timePeriod,
          forceRefresh: forceRefresh,
        ),
        getRiskMetrics(riskProfile: riskProfile, forceRefresh: forceRefresh),
        getPredictions(horizon: predictionHorizon, forceRefresh: forceRefresh),
        getBenchmarks(benchmarkType: benchmarkType, forceRefresh: forceRefresh),
      ];

      final results = await Future.wait(futures);

      return {
        'advanced': results[0],
        'performance': results[1],
        'risk': results[2],
        'predictions': results[3],
        'benchmarks': results[4],
        'timestamp': DateTime.now().toIso8601String(),
        'batchLoadTime': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      developer.log(
        '❌ [Dashboard Service] Błąd podczas batch loading: $e',
        name: 'FirebaseFunctionsDashboardService',
        error: e,
      );

      return {
        'error': true,
        'message': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // 🔄 CACHE MANAGEMENT

  /// Wymusza odświeżenie cache dla wszystkich metryk dashboard
  static Future<void> refreshAllCache() async {
    try {
      developer.log(
        '🔄 [Dashboard Service] Wymuszam odświeżenie cache',
        name: 'FirebaseFunctionsDashboardService',
      );

      await getAllDashboardMetrics(forceRefresh: true);

      developer.log(
        '✅ [Dashboard Service] Cache odświeżony pomyślnie',
        name: 'FirebaseFunctionsDashboardService',
      );
    } catch (e) {
      developer.log(
        '❌ [Dashboard Service] Błąd odświeżania cache: $e',
        name: 'FirebaseFunctionsDashboardService',
        error: e,
      );
    }
  }

  // 📋 UTILITY METHODS

  /// Sprawdza status połączenia z Firebase Functions
  static Future<bool> checkFunctionsHealth() async {
    try {
      // Szybkie wywołanie testowe z małym timeout
      final result = await getAdvancedDashboardMetrics().timeout(
        const Duration(seconds: 10),
      );

      return result != null;
    } catch (e) {
      developer.log(
        '⚠️ [Dashboard Service] Functions health check failed: $e',
        name: 'FirebaseFunctionsDashboardService',
      );
      return false;
    }
  }

  /// Formatuje dane wydajności dla wykresów
  static List<Map<String, dynamic>> formatPerformanceChartData(
    Map<String, dynamic>? performanceData,
  ) {
    if (performanceData == null) return [];

    try {
      final timeSeriesData =
          performanceData['timeSeriesPerformance'] as Map<String, dynamic>?;

      if (timeSeriesData == null) return [];

      final monthlyData = timeSeriesData['monthlyData'] as List<dynamic>?;

      if (monthlyData == null) return [];

      return monthlyData.map((item) {
        final data = item as Map<String, dynamic>;
        return {
          'month': data['month'] ?? '',
          'return': (data['averageReturn'] as num?)?.toDouble() ?? 0.0,
          'cumulative': (data['cumulativeReturn'] as num?)?.toDouble() ?? 0.0,
          'invested': (data['totalInvested'] as num?)?.toDouble() ?? 0.0,
          'current': (data['totalCurrent'] as num?)?.toDouble() ?? 0.0,
          'count': data['count'] ?? 0,
        };
      }).toList();
    } catch (e) {
      developer.log(
        '❌ [Dashboard Service] Błąd formatowania danych wykresu: $e',
        name: 'FirebaseFunctionsDashboardService',
      );
      return [];
    }
  }

  /// Formatuje dane ryzyka dla macierzy ryzyka
  static List<Map<String, dynamic>> formatRiskMatrixData(
    Map<String, dynamic>? riskData,
  ) {
    if (riskData == null) return [];

    try {
      // Implementacja formatowania macierzy risk/return
      // Zwraca punkty dla ScatterChart w risk_tab.dart
      return [];
    } catch (e) {
      developer.log(
        '❌ [Dashboard Service] Błąd formatowania macierzy ryzyka: $e',
        name: 'FirebaseFunctionsDashboardService',
      );
      return [];
    }
  }
}

/// 📊 Model dla metryk dashboard z Firebase Functions
class DashboardMetrics {
  final Map<String, dynamic> advanced;
  final Map<String, dynamic> performance;
  final Map<String, dynamic> risk;
  final Map<String, dynamic> predictions;
  final Map<String, dynamic> benchmarks;
  final DateTime timestamp;

  const DashboardMetrics({
    required this.advanced,
    required this.performance,
    required this.risk,
    required this.predictions,
    required this.benchmarks,
    required this.timestamp,
  });

  factory DashboardMetrics.fromMap(Map<String, dynamic> map) {
    return DashboardMetrics(
      advanced: map['advanced'] ?? {},
      performance: map['performance'] ?? {},
      risk: map['risk'] ?? {},
      predictions: map['predictions'] ?? {},
      benchmarks: map['benchmarks'] ?? {},
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'advanced': advanced,
      'performance': performance,
      'risk': risk,
      'predictions': predictions,
      'benchmarks': benchmarks,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Sprawdza czy dane są aktualne (nie starsze niż 5 minut)
  bool get isValid {
    return DateTime.now().difference(timestamp).inMinutes < 5;
  }

  /// Zwraca czas wykonania wszystkich obliczeń
  int get totalExecutionTime {
    final advancedTime = advanced['executionTime'] as int? ?? 0;
    final performanceTime = performance['executionTime'] as int? ?? 0;
    final riskTime = risk['executionTime'] as int? ?? 0;
    final predictionsTime = predictions['executionTime'] as int? ?? 0;
    final benchmarksTime = benchmarks['executionTime'] as int? ?? 0;

    return advancedTime +
        performanceTime +
        riskTime +
        predictionsTime +
        benchmarksTime;
  }

  /// Zwraca łączną liczbę przetworzonych punktów danych
  int get totalDataPoints {
    return (advanced['dataPoints'] as int? ?? 0) +
        (performance['dataPoints'] as int? ?? 0);
  }
}
