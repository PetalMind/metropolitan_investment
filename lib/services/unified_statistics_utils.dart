/// Zunifikowane narzędzia statystyczne zgodnie z STATISTICS_UNIFICATION_GUIDE
/// Zapewnia jedną prawdę dla wszystkich statystyk w systemie
library;

/// Zunifikowane definicje statystyk zgodnie z STATISTICS_UNIFICATION_GUIDE
class UnifiedStatisticsDefinitions {
  /// Zunifikowana definicja totalValue
  /// TOTAL_VALUE = remainingCapital + remainingInterest
  static double calculateTotalValue(
    double remainingCapital,
    double remainingInterest,
  ) {
    return remainingCapital + remainingInterest;
  }

  /// Zunifikowana definicja viableCapital
  /// VIABLE_CAPITAL = remainingCapital WHERE productStatus = 'Aktywny'
  static double calculateViableCapital(
    double remainingCapital,
    String productStatus,
  ) {
    if (productStatus != 'Aktywny') {
      return 0.0;
    }
    return remainingCapital;
  }

  /// Zunifikowana definicja majorityThreshold
  /// MAJORITY_THRESHOLD = viableCapital * 0.51
  static double calculateMajorityThreshold(double viableCapital) {
    return viableCapital * 0.51;
  }
}

/// Mapowanie pól zgodnie z konfiguracją statystyk
class UnifiedFieldMapping {
  static const Map<String, List<String>> fieldMap = {
    'remainingCapital': ['kapital_pozostaly', 'remainingCapital'],
    'remainingInterest': ['odsetki_pozostale', 'remainingInterest'],
    'investmentAmount': ['kwota_inwestycji', 'investmentAmount'],
    'productStatus': ['productStatus', 'status_produktu'],
  };

  /// Pobiera wartość z mapowanego pola
  static dynamic getFieldValue(Map<String, dynamic> data, String fieldKey) {
    final possibleFields = fieldMap[fieldKey] ?? [fieldKey];

    for (final field in possibleFields) {
      if (data.containsKey(field) && data[field] != null) {
        return data[field];
      }
    }

    return null;
  }

  /// Pomocnicza funkcja do parsowania wartości kapitału
  static double parseCapitalValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.isEmpty ||
          value.trim().isEmpty ||
          value.toUpperCase() == 'NULL') {
        return 0.0;
      }
      // Handle string values like "200,000.00" from Firebase
      final cleaned = value.toString().replaceAll(',', '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }
}

/// Model dla zunifikowanych statystyk systemu
class UnifiedSystemStats {
  final double totalValue;
  final double viableCapital;
  final double majorityThreshold;
  final DateTime calculatedAt;

  const UnifiedSystemStats({
    required this.totalValue,
    required this.viableCapital,
    required this.majorityThreshold,
    required this.calculatedAt,
  });

  factory UnifiedSystemStats.empty() {
    return UnifiedSystemStats(
      totalValue: 0.0,
      viableCapital: 0.0,
      majorityThreshold: 0.0,
      calculatedAt: DateTime.now(),
    );
  }

  /// Oblicza statystyki na podstawie listy inwestycji
  factory UnifiedSystemStats.fromInvestments(
    List<Map<String, dynamic>> investments,
  ) {
    double totalValue = 0.0;
    double totalViableCapital = 0.0;

    for (final investment in investments) {
      final remainingCapital = UnifiedFieldMapping.parseCapitalValue(
        UnifiedFieldMapping.getFieldValue(investment, 'remainingCapital'),
      );

      final remainingInterest = UnifiedFieldMapping.parseCapitalValue(
        UnifiedFieldMapping.getFieldValue(investment, 'remainingInterest'),
      );

      final productStatus =
          UnifiedFieldMapping.getFieldValue(
            investment,
            'productStatus',
          )?.toString() ??
          '';

      // Zunifikowane obliczenia
      totalValue += UnifiedStatisticsDefinitions.calculateTotalValue(
        remainingCapital,
        remainingInterest,
      );
      totalViableCapital += UnifiedStatisticsDefinitions.calculateViableCapital(
        remainingCapital,
        productStatus,
      );
    }

    final majorityThreshold =
        UnifiedStatisticsDefinitions.calculateMajorityThreshold(
          totalViableCapital,
        );

    return UnifiedSystemStats(
      totalValue: totalValue,
      viableCapital: totalViableCapital,
      majorityThreshold: majorityThreshold,
      calculatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalValue': totalValue,
      'viableCapital': viableCapital,
      'majorityThreshold': majorityThreshold,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UnifiedSystemStats('
        'totalValue: ${totalValue.toStringAsFixed(2)}, '
        'viableCapital: ${viableCapital.toStringAsFixed(2)}, '
        'majorityThreshold: ${majorityThreshold.toStringAsFixed(2)}'
        ')';
  }
}

/// Enum dla typów statystyk do debugowania niespójności
enum StatisticType {
  totalValue,
  viableCapital,
  majorityThreshold,
  investmentCount,
}

/// Model dla reportów niespójności statystyk
class StatisticsInconsistencyReport {
  final List<StatisticsInconsistency> inconsistencies;
  final DateTime generatedAt;

  const StatisticsInconsistencyReport({
    required this.inconsistencies,
    required this.generatedAt,
  });

  bool get hasInconsistencies => inconsistencies.isNotEmpty;

  factory StatisticsInconsistencyReport.empty() {
    return StatisticsInconsistencyReport(
      inconsistencies: [],
      generatedAt: DateTime.now(),
    );
  }
}

/// Model dla pojedynczej niespójności statystyk
class StatisticsInconsistency {
  final StatisticType metric;
  final String source1;
  final String source2;
  final double value1;
  final double value2;
  final double difference;
  final String explanation;

  const StatisticsInconsistency({
    required this.metric,
    required this.source1,
    required this.source2,
    required this.value1,
    required this.value2,
    required this.difference,
    required this.explanation,
  });

  double get percentageDifference {
    if (value1 == 0 && value2 == 0) return 0.0;
    if (value1 == 0) return 100.0;
    return (difference / value1).abs() * 100;
  }

  bool get isSignificant => percentageDifference > 1.0; // >1% różnicy
}
