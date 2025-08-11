import 'dart:developer' as developer;
import 'package:cloud_functions/cloud_functions.dart';

/// 🔥 Firebase Functions Advanced Analytics Service
/// Service for communication with Firebase Functions for advanced dashboard analytics
///
/// Replaces direct calculations with server-side analytical functions
/// aligned with new Firebase Functions architecture (dashboard-specialized.js)
class FirebaseFunctionsAdvancedAnalyticsService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  // 📊 MAIN DASHBOARD METRICS

  /// Retrieves advanced dashboard metrics from all collections
  ///
  /// Replaces legacy dashboard service with specialized functions
  /// supporting unified investment data structure
  static Future<Map<String, dynamic>?> getAdvancedDashboardMetrics({
    bool forceRefresh = false,
  }) async {
    try {
      developer.log(
        '🔥 [Advanced Analytics] Calling getAdvancedDashboardMetrics',
        name: 'FirebaseFunctionsAdvancedAnalyticsService',
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
          '✅ [Advanced Analytics] Retrieved dashboard metrics: '
          '${data['executionTime']}ms, ${data['dataPoints'] ?? 'N/A'} data points',
          name: 'FirebaseFunctionsAdvancedAnalyticsService',
        );
      }

      return data;
    } catch (e) {
      developer.log(
        '❌ [Advanced Analytics] Error retrieving dashboard metrics: $e',
        name: 'FirebaseFunctionsAdvancedAnalyticsService',
        error: e,
      );
      return null;
    }
  }

  // 📈 PERFORMANCE TAB METRICS

  /// Retrieves detailed performance metrics for Performance tab
  ///
  /// [timePeriod] - analysis period: 'all', '1m', '3m', '6m', '1y', '2y'
  static Future<Map<String, dynamic>?> getDashboardPerformanceMetrics({
    String timePeriod = 'all',
    bool forceRefresh = false,
  }) async {
    try {
      developer.log(
        '📈 [Advanced Analytics] Calling getDashboardPerformanceMetrics, period: $timePeriod',
        name: 'FirebaseFunctionsAdvancedAnalyticsService',
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
          '✅ [Advanced Analytics] Retrieved performance metrics: '
          '${data['executionTime']}ms, ${data['dataPoints']} investments',
          name: 'FirebaseFunctionsAdvancedAnalyticsService',
        );
      }

      return data;
    } catch (e) {
      developer.log(
        '❌ [Advanced Analytics] Error retrieving performance metrics: $e',
        name: 'FirebaseFunctionsAdvancedAnalyticsService',
        error: e,
      );
      return null;
    }
  }

  // ⚠️ RISK TAB METRICS

  /// Retrieves detailed risk analysis for Risk tab
  ///
  /// [riskProfile] - risk profile: 'conservative', 'moderate', 'aggressive'
  static Future<Map<String, dynamic>?> getDashboardRiskMetrics({
    String riskProfile = 'moderate',
    bool forceRefresh = false,
  }) async {
    try {
      developer.log(
        '⚠️ [Advanced Analytics] Calling getDashboardRiskMetrics, profile: $riskProfile',
        name: 'FirebaseFunctionsAdvancedAnalyticsService',
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
          '✅ [Advanced Analytics] Retrieved risk metrics: '
          '${data['executionTime']}ms',
          name: 'FirebaseFunctionsAdvancedAnalyticsService',
        );
      }

      return data;
    } catch (e) {
      developer.log(
        '❌ [Advanced Analytics] Error retrieving risk metrics: $e',
        name: 'FirebaseFunctionsAdvancedAnalyticsService',
        error: e,
      );
      return null;
    }
  }

  // 🔮 PREDICTIONS TAB METRICS

  /// Retrieves predictions and forecasts for Predictions tab
  ///
  /// [horizon] - prediction time horizon in months (default 12)
  static Future<Map<String, dynamic>?> getDashboardPredictions({
    int horizon = 12,
    bool forceRefresh = false,
  }) async {
    try {
      developer.log(
        '🔮 [Advanced Analytics] Calling getDashboardPredictions, horizon: ${horizon}m',
        name: 'FirebaseFunctionsAdvancedAnalyticsService',
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
          '✅ [Advanced Analytics] Retrieved predictions: '
          '${data['executionTime']}ms',
          name: 'FirebaseFunctionsAdvancedAnalyticsService',
        );
      }

      return data;
    } catch (e) {
      developer.log(
        '❌ [Advanced Analytics] Error retrieving predictions: $e',
        name: 'FirebaseFunctionsAdvancedAnalyticsService',
        error: e,
      );
      return null;
    }
  }

  // 📊 BENCHMARK TAB METRICS

  /// Retrieves benchmark comparisons for Benchmark tab
  ///
  /// [benchmarkType] - benchmark type: 'market', 'industry', 'custom'
  static Future<Map<String, dynamic>?> getDashboardBenchmarks({
    String benchmarkType = 'market',
    bool forceRefresh = false,
  }) async {
    try {
      developer.log(
        '📊 [Advanced Analytics] Calling getDashboardBenchmarks, type: $benchmarkType',
        name: 'FirebaseFunctionsAdvancedAnalyticsService',
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
          '✅ [Advanced Analytics] Retrieved benchmarks: '
          '${data['executionTime']}ms',
          name: 'FirebaseFunctionsAdvancedAnalyticsService',
        );
      }

      return data;
    } catch (e) {
      developer.log(
        '❌ [Advanced Analytics] Error retrieving benchmarks: $e',
        name: 'FirebaseFunctionsAdvancedAnalyticsService',
        error: e,
      );
      return null;
    }
  }

  // 🚀 BATCH OPERATIONS

  /// Retrieves all dashboard metrics in parallel
  /// Optimizes calls for full dashboard view
  static Future<Map<String, dynamic>> getAllDashboardMetrics({
    bool forceRefresh = false,
    String timePeriod = 'all',
    String riskProfile = 'moderate',
    int predictionHorizon = 12,
    String benchmarkType = 'market',
  }) async {
    try {
      developer.log(
        '🚀 [Advanced Analytics] Parallel loading of all dashboard metrics',
        name: 'FirebaseFunctionsAdvancedAnalyticsService',
      );

      final futures = [
        getAdvancedDashboardMetrics(forceRefresh: forceRefresh),
        getDashboardPerformanceMetrics(
          timePeriod: timePeriod,
          forceRefresh: forceRefresh,
        ),
        getDashboardRiskMetrics(
          riskProfile: riskProfile,
          forceRefresh: forceRefresh,
        ),
        getDashboardPredictions(
          horizon: predictionHorizon,
          forceRefresh: forceRefresh,
        ),
        getDashboardBenchmarks(
          benchmarkType: benchmarkType,
          forceRefresh: forceRefresh,
        ),
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
        '❌ [Advanced Analytics] Error during batch loading: $e',
        name: 'FirebaseFunctionsAdvancedAnalyticsService',
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

  /// Forces cache refresh for all dashboard metrics
  static Future<void> refreshAllCache() async {
    try {
      developer.log(
        '🔄 [Advanced Analytics] Forcing cache refresh',
        name: 'FirebaseFunctionsAdvancedAnalyticsService',
      );

      await getAllDashboardMetrics(forceRefresh: true);

      developer.log(
        '✅ [Advanced Analytics] Cache refreshed successfully',
        name: 'FirebaseFunctionsAdvancedAnalyticsService',
      );
    } catch (e) {
      developer.log(
        '❌ [Advanced Analytics] Error refreshing cache: $e',
        name: 'FirebaseFunctionsAdvancedAnalyticsService',
        error: e,
      );
    }
  }

  // 📋 UTILITY METHODS

  /// Checks Firebase Functions connection status
  static Future<bool> checkFunctionsHealth() async {
    try {
      // Quick test call with small timeout
      final result = await getAdvancedDashboardMetrics().timeout(
        const Duration(seconds: 10),
      );

      return result != null;
    } catch (e) {
      developer.log(
        '⚠️ [Advanced Analytics] Functions health check failed: $e',
        name: 'FirebaseFunctionsAdvancedAnalyticsService',
      );
      return false;
    }
  }

  /// Formats performance data for charts
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
        '❌ [Advanced Analytics] Error formatting chart data: $e',
        name: 'FirebaseFunctionsAdvancedAnalyticsService',
      );
      return [];
    }
  }

  /// Formats risk data for risk matrix
  static List<Map<String, dynamic>> formatRiskMatrixData(
    Map<String, dynamic>? riskData,
  ) {
    if (riskData == null) return [];

    try {
      final riskMatrix = riskData['riskMatrix'] as Map<String, dynamic>?;

      if (riskMatrix == null) return [];

      // Format risk matrix data for scatter chart visualization
      final matrixData = riskMatrix['matrix'] as List<dynamic>? ?? [];

      return matrixData.map((item) {
        final data = item as Map<String, dynamic>;
        return {
          'risk': (data['risk'] as num?)?.toDouble() ?? 0.0,
          'return': (data['return'] as num?)?.toDouble() ?? 0.0,
          'value': (data['value'] as num?)?.toDouble() ?? 0.0,
          'productType': data['productType'] ?? 'unknown',
          'clientName': data['clientName'] ?? 'N/A',
        };
      }).toList();
    } catch (e) {
      developer.log(
        '❌ [Advanced Analytics] Error formatting risk matrix data: $e',
        name: 'FirebaseFunctionsAdvancedAnalyticsService',
      );
      return [];
    }
  }

  /// Formats comprehensive analytics data for overview tab
  static Map<String, dynamic> formatOverviewData(
    Map<String, dynamic>? advancedData,
  ) {
    if (advancedData == null) {
      return {
        'portfolioMetrics': {},
        'productTypeBreakdown': {},
        'performanceSummary': {},
        'executionTime': 0,
        'dataPoints': 0,
      };
    }

    try {
      return {
        'portfolioMetrics': advancedData['portfolioMetrics'] ?? {},
        'productTypeBreakdown': advancedData['productTypeBreakdown'] ?? {},
        'performanceSummary': advancedData['performanceSummary'] ?? {},
        'riskMetrics': advancedData['riskMetrics'] ?? {},
        'concentrationAnalysis': advancedData['concentrationAnalysis'] ?? {},
        'executionTime': advancedData['executionTime'] ?? 0,
        'dataPoints': advancedData['dataPoints'] ?? 0,
        'timestamp':
            advancedData['timestamp'] ?? DateTime.now().toIso8601String(),
      };
    } catch (e) {
      developer.log(
        '❌ [Advanced Analytics] Error formatting overview data: $e',
        name: 'FirebaseFunctionsAdvancedAnalyticsService',
      );
      return {
        'portfolioMetrics': {},
        'productTypeBreakdown': {},
        'performanceSummary': {},
        'executionTime': 0,
        'dataPoints': 0,
      };
    }
  }
}

/// 📊 Model for dashboard metrics from Firebase Functions
class AdvancedDashboardMetrics {
  final Map<String, dynamic> advanced;
  final Map<String, dynamic> performance;
  final Map<String, dynamic> risk;
  final Map<String, dynamic> predictions;
  final Map<String, dynamic> benchmarks;
  final DateTime timestamp;

  const AdvancedDashboardMetrics({
    required this.advanced,
    required this.performance,
    required this.risk,
    required this.predictions,
    required this.benchmarks,
    required this.timestamp,
  });

  factory AdvancedDashboardMetrics.fromMap(Map<String, dynamic> map) {
    return AdvancedDashboardMetrics(
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

  /// Checks if data is current (not older than 5 minutes)
  bool get isValid {
    return DateTime.now().difference(timestamp).inMinutes < 5;
  }

  /// Returns total execution time for all calculations
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

  /// Returns total number of processed data points
  int get totalDataPoints {
    return (advanced['dataPoints'] as int? ?? 0) +
        (performance['dataPoints'] as int? ?? 0);
  }
}
