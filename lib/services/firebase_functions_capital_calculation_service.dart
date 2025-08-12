import 'dart:developer' as developer;
import 'package:cloud_functions/cloud_functions.dart';

/// 🔧 Firebase Functions Capital Calculation Service
/// Serwis do zarządzania obliczaniem i zapisywaniem "Kapitał zabezpieczony nieruchomością"
///
/// Komunikuje się z Firebase Functions:
/// - updateCapitalSecuredByRealEstate
/// - checkCapitalCalculationStatus
/// - scheduleCapitalRecalculation
class FirebaseFunctionsCapitalCalculationService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  /// Aktualizuje pole "Kapitał zabezpieczony nieruchomością" dla wszystkich lub wybranych inwestycji
  ///
  /// [batchSize] - rozmiar batcha przetwarzania (domyślnie 500)
  /// [dryRun] - tryb testowy bez zapisu do bazy (domyślnie false)
  /// [investmentId] - ID konkretnej inwestycji (opcjonalnie)
  /// [includeDetails] - czy zwracać szczegóły operacji (domyślnie false)
  static Future<CapitalCalculationUpdateResult?>
  updateCapitalSecuredByRealEstate({
    int batchSize = 500,
    bool dryRun = false,
    String? investmentId,
    bool includeDetails = false,
    bool forceRefresh = false,
  }) async {
    try {
      developer.log(
        '🔧 [Capital Calculation] Updating capital secured by real estate: '
        'batchSize=$batchSize, dryRun=$dryRun, investmentId=$investmentId',
        name: 'FirebaseFunctionsCapitalCalculationService',
      );

      final HttpsCallable callable = _functions.httpsCallable(
        'updateCapitalSecuredByRealEstate',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 10)),
      );

      final Map<String, dynamic> parameters = {
        'batchSize': batchSize,
        'dryRun': dryRun,
        'includeDetails': includeDetails,
      };

      if (investmentId != null && investmentId.isNotEmpty) {
        parameters['investmentId'] = investmentId;
      }

      final HttpsCallableResult result = await callable.call(parameters);

      if (result.data != null) {
        developer.log(
          '✅ [Capital Calculation] Update completed: '
          '${result.data['processed']} processed, ${result.data['updated']} updated',
          name: 'FirebaseFunctionsCapitalCalculationService',
        );

        return CapitalCalculationUpdateResult.fromMap(
          result.data as Map<String, dynamic>,
        );
      }

      return null;
    } catch (e) {
      developer.log(
        '❌ [Capital Calculation] Error updating capital: $e',
        name: 'FirebaseFunctionsCapitalCalculationService',
        error: e,
      );
      rethrow;
    }
  }

  /// Sprawdza status obliczeń kapitału zabezpieczonego nieruchomością
  /// Zwraca statystyki ile inwestycji ma poprawne/niepoprawne wartości
  static Future<CapitalCalculationStatusResult?>
  checkCapitalCalculationStatus() async {
    try {
      developer.log(
        '📊 [Capital Calculation] Checking calculation status',
        name: 'FirebaseFunctionsCapitalCalculationService',
      );

      final HttpsCallable callable = _functions.httpsCallable(
        'checkCapitalCalculationStatus',
      );

      final HttpsCallableResult result = await callable.call({});

      if (result.data != null) {
        developer.log(
          '✅ [Capital Calculation] Status check completed',
          name: 'FirebaseFunctionsCapitalCalculationService',
        );

        return CapitalCalculationStatusResult.fromMap(
          result.data as Map<String, dynamic>,
        );
      }

      return null;
    } catch (e) {
      developer.log(
        '❌ [Capital Calculation] Error checking status: $e',
        name: 'FirebaseFunctionsCapitalCalculationService',
        error: e,
      );
      rethrow;
    }
  }

  /// Uruchamia schedulowane automatyczne przeliczanie
  /// Sprawdza czy aktualizacja jest potrzebna i wykonuje ją automatycznie
  static Future<CapitalCalculationScheduleResult?>
  scheduleCapitalRecalculation() async {
    try {
      developer.log(
        '⏰ [Capital Calculation] Running scheduled recalculation',
        name: 'FirebaseFunctionsCapitalCalculationService',
      );

      final HttpsCallable callable = _functions.httpsCallable(
        'scheduleCapitalRecalculation',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 15)),
      );

      final HttpsCallableResult result = await callable.call({});

      if (result.data != null) {
        developer.log(
          '✅ [Capital Calculation] Scheduled recalculation completed',
          name: 'FirebaseFunctionsCapitalCalculationService',
        );

        return CapitalCalculationScheduleResult.fromMap(
          result.data as Map<String, dynamic>,
        );
      }

      return null;
    } catch (e) {
      developer.log(
        '❌ [Capital Calculation] Error in scheduled recalculation: $e',
        name: 'FirebaseFunctionsCapitalCalculationService',
        error: e,
      );
      rethrow;
    }
  }
}

/// Model wyniku aktualizacji kapitału zabezpieczonego nieruchomością
class CapitalCalculationUpdateResult {
  final int processed;
  final int updated;
  final int errors;
  final List<CapitalCalculationDetail> details;
  final int executionTimeMs;
  final String timestamp;
  final bool dryRun;
  final CapitalCalculationSummary? summary;

  const CapitalCalculationUpdateResult({
    required this.processed,
    required this.updated,
    required this.errors,
    required this.details,
    required this.executionTimeMs,
    required this.timestamp,
    required this.dryRun,
    this.summary,
  });

  factory CapitalCalculationUpdateResult.fromMap(Map<String, dynamic> map) {
    return CapitalCalculationUpdateResult(
      processed: map['processed'] ?? 0,
      updated: map['updated'] ?? 0,
      errors: map['errors'] ?? 0,
      details: (map['details'] as List<dynamic>? ?? [])
          .map(
            (detail) => CapitalCalculationDetail.fromMap(
              detail as Map<String, dynamic>,
            ),
          )
          .toList(),
      executionTimeMs: map['executionTimeMs'] ?? 0,
      timestamp: map['timestamp'] ?? '',
      dryRun: map['dryRun'] ?? false,
      summary: map['summary'] != null
          ? CapitalCalculationSummary.fromMap(
              map['summary'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// Wskaźnik sukcesu (bez błędów)
  double get successRate =>
      processed > 0 ? (processed - errors) / processed : 0.0;

  /// Wskaźnik aktualizacji (ile zostało faktycznie zaktualizowanych)
  double get updateRate => processed > 0 ? updated / processed : 0.0;

  /// Czy operacja przebiegła pomyślnie
  bool get isSuccessful => errors == 0;
}

/// Model szczegółu operacji na pojedynczej inwestycji
class CapitalCalculationDetail {
  final String investmentId;
  final String clientName;
  final double remainingCapital;
  final double capitalForRestructuring;
  final double oldCapitalSecuredByRealEstate;
  final double newCapitalSecuredByRealEstate;
  final bool hasChanged;
  final bool updated;
  final String? error;
  final String? dryRunNote;

  const CapitalCalculationDetail({
    required this.investmentId,
    required this.clientName,
    required this.remainingCapital,
    required this.capitalForRestructuring,
    required this.oldCapitalSecuredByRealEstate,
    required this.newCapitalSecuredByRealEstate,
    required this.hasChanged,
    required this.updated,
    this.error,
    this.dryRunNote,
  });

  factory CapitalCalculationDetail.fromMap(Map<String, dynamic> map) {
    return CapitalCalculationDetail(
      investmentId: map['investmentId'] ?? '',
      clientName: map['clientName'] ?? '',
      remainingCapital: (map['remainingCapital'] ?? 0).toDouble(),
      capitalForRestructuring: (map['capitalForRestructuring'] ?? 0).toDouble(),
      oldCapitalSecuredByRealEstate: (map['oldCapitalSecuredByRealEstate'] ?? 0)
          .toDouble(),
      newCapitalSecuredByRealEstate: (map['newCapitalSecuredByRealEstate'] ?? 0)
          .toDouble(),
      hasChanged: map['hasChanged'] ?? false,
      updated: map['updated'] ?? false,
      error: map['error'],
      dryRunNote: map['dryRunNote'],
    );
  }

  /// Różnica między starą a nową wartością
  double get difference =>
      newCapitalSecuredByRealEstate - oldCapitalSecuredByRealEstate;

  /// Czy operacja miała błąd
  bool get hasError => error != null;
}

/// Model podsumowania operacji
class CapitalCalculationSummary {
  final String successRate;
  final String updateRate;

  const CapitalCalculationSummary({
    required this.successRate,
    required this.updateRate,
  });

  factory CapitalCalculationSummary.fromMap(Map<String, dynamic> map) {
    return CapitalCalculationSummary(
      successRate: map['successRate'] ?? '0%',
      updateRate: map['updateRate'] ?? '0%',
    );
  }
}

/// Model wyniku sprawdzania statusu obliczeń
class CapitalCalculationStatusResult {
  final CapitalCalculationStatistics statistics;
  final List<CapitalCalculationSample> samples;
  final List<String> recommendations;
  final String timestamp;

  const CapitalCalculationStatusResult({
    required this.statistics,
    required this.samples,
    required this.recommendations,
    required this.timestamp,
  });

  factory CapitalCalculationStatusResult.fromMap(Map<String, dynamic> map) {
    return CapitalCalculationStatusResult(
      statistics: CapitalCalculationStatistics.fromMap(
        map['statistics'] as Map<String, dynamic>,
      ),
      samples: (map['samples'] as List<dynamic>? ?? [])
          .map(
            (sample) => CapitalCalculationSample.fromMap(
              sample as Map<String, dynamic>,
            ),
          )
          .toList(),
      recommendations: List<String>.from(map['recommendations'] ?? []),
      timestamp: map['timestamp'] ?? '',
    );
  }
}

/// Model statystyk stanu obliczeń
class CapitalCalculationStatistics {
  final int totalInvestments;
  final int withCalculatedField;
  final int withCorrectCalculation;
  final int needsUpdate;
  final String completionRate;
  final String accuracyRate;

  const CapitalCalculationStatistics({
    required this.totalInvestments,
    required this.withCalculatedField,
    required this.withCorrectCalculation,
    required this.needsUpdate,
    required this.completionRate,
    required this.accuracyRate,
  });

  factory CapitalCalculationStatistics.fromMap(Map<String, dynamic> map) {
    return CapitalCalculationStatistics(
      totalInvestments: map['totalInvestments'] ?? 0,
      withCalculatedField: map['withCalculatedField'] ?? 0,
      withCorrectCalculation: map['withCorrectCalculation'] ?? 0,
      needsUpdate: map['needsUpdate'] ?? 0,
      completionRate: map['completionRate'] ?? '0%',
      accuracyRate: map['accuracyRate'] ?? '0%',
    );
  }

  /// Czy wszystkie inwestycje są aktualne
  bool get isFullyCalculated => needsUpdate == 0;

  /// Procent inwestycji wymagających aktualizacji
  double get updateNeededPercentage =>
      totalInvestments > 0 ? needsUpdate / totalInvestments : 0.0;
}

/// Model próbki inwestycji do analizy
class CapitalCalculationSample {
  final String id;
  final String clientName;
  final double remainingCapital;
  final double capitalForRestructuring;
  final double currentValue;
  final double shouldBe;
  final bool hasField;
  final bool isCorrect;

  const CapitalCalculationSample({
    required this.id,
    required this.clientName,
    required this.remainingCapital,
    required this.capitalForRestructuring,
    required this.currentValue,
    required this.shouldBe,
    required this.hasField,
    required this.isCorrect,
  });

  factory CapitalCalculationSample.fromMap(Map<String, dynamic> map) {
    return CapitalCalculationSample(
      id: map['id'] ?? '',
      clientName: map['clientName'] ?? '',
      remainingCapital: (map['remainingCapital'] ?? 0).toDouble(),
      capitalForRestructuring: (map['capitalForRestructuring'] ?? 0).toDouble(),
      currentValue: (map['currentValue'] ?? 0).toDouble(),
      shouldBe: (map['shouldBe'] ?? 0).toDouble(),
      hasField: map['hasField'] ?? false,
      isCorrect: map['isCorrect'] ?? false,
    );
  }

  /// Różnica między obecną a prawidłową wartością
  double get difference => shouldBe - currentValue;
}

/// Model wyniku schedulowanego przeliczania
class CapitalCalculationScheduleResult {
  final bool skipped;
  final bool scheduled;
  final String message;
  final CapitalCalculationStatistics? statusBefore;
  final CapitalCalculationUpdateSummary? updateResult;
  final String timestamp;

  const CapitalCalculationScheduleResult({
    required this.skipped,
    required this.scheduled,
    required this.message,
    this.statusBefore,
    this.updateResult,
    required this.timestamp,
  });

  factory CapitalCalculationScheduleResult.fromMap(Map<String, dynamic> map) {
    return CapitalCalculationScheduleResult(
      skipped: map['skipped'] ?? false,
      scheduled: map['scheduled'] ?? false,
      message: map['message'] ?? '',
      statusBefore: map['statusBefore'] != null
          ? CapitalCalculationStatistics.fromMap(
              map['statusBefore'] as Map<String, dynamic>,
            )
          : null,
      updateResult: map['updateResult'] != null
          ? CapitalCalculationUpdateSummary.fromMap(
              map['updateResult'] as Map<String, dynamic>,
            )
          : null,
      timestamp: map['timestamp'] ?? '',
    );
  }
}

/// Model podsumowania aktualizacji (uproszczony dla schedulera)
class CapitalCalculationUpdateSummary {
  final int processed;
  final int updated;
  final int errors;
  final int executionTimeMs;

  const CapitalCalculationUpdateSummary({
    required this.processed,
    required this.updated,
    required this.errors,
    required this.executionTimeMs,
  });

  factory CapitalCalculationUpdateSummary.fromMap(Map<String, dynamic> map) {
    return CapitalCalculationUpdateSummary(
      processed: map['processed'] ?? 0,
      updated: map['updated'] ?? 0,
      errors: map['errors'] ?? 0,
      executionTimeMs: map['executionTimeMs'] ?? 0,
    );
  }
}
