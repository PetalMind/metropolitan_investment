import 'base_service.dart';
import '../models/unified_product.dart';
import '../models/investor_summary.dart';
import '../models/investment.dart';

/// 🚀 ZUNIFIKOWANY SERWIS STATYSTYK
/// Zgodnie z STATISTICS_UNIFICATION_GUIDE.md
/// Jeden punkt prawdy dla wszystkich statystyk w aplikacji
class UnifiedStatisticsService extends BaseService {
  /// ZUNIFIKOWANE DEFINICJE STATYSTYK zgodnie z guide

  /// Oblicza zunifikowaną wartość totalValue
  /// DEFINICJA: remainingCapital + remainingInterest
  static double calculateUnifiedTotalValue(Investment investment) {
    final remainingCapital = investment.remainingCapital;
    final remainingInterest = investment.remainingInterest;

    // ZUNIFIKOWANA DEFINICJA: totalValue = remainingCapital + remainingInterest
    return remainingCapital + remainingInterest;
  }

  /// Oblicza zunifikowany viable capital
  /// DEFINICJA: remainingCapital WHERE productStatus = 'Aktywny'
  static double calculateViableCapital(Investment investment) {
    // Sprawdź status produktu z additionalInfo
    final productStatus =
        investment.additionalInfo['productStatus'] as String? ??
        investment.additionalInfo['status_produktu'] as String? ??
        'Nieznany';

    // ZUNIFIKOWANE FILTROWANIE: tylko aktywne inwestycje
    if (productStatus != 'Aktywny') {
      return 0.0;
    }

    return investment.remainingCapital;
  }

  /// Oblicza zunifikowaną wartość totalValue dla UnifiedProduct
  /// DEFINICJA: dla obligacji = remainingCapital + remainingInterest
  static double calculateUnifiedProductValue(UnifiedProduct product) {
    switch (product.productType) {
      case UnifiedProductType.bonds:
        final remainingCapital = product.remainingCapital ?? 0.0;
        final remainingInterest = product.remainingInterest ?? 0.0;
        return remainingCapital + remainingInterest;
      case UnifiedProductType.shares:
        return product.investmentAmount;
      case UnifiedProductType.loans:
        return product.remainingCapital ?? product.investmentAmount;
      case UnifiedProductType.apartments:
        // Dla apartamentów: powierzchnia * cena za m² lub kwota inwestycji
        if (product.additionalInfo['area'] != null &&
            product.additionalInfo['pricePerSquareMeter'] != null) {
          final area = product.additionalInfo['area'] as num?;
          final pricePerM2 =
              product.additionalInfo['pricePerSquareMeter'] as num?;
          if (area != null &&
              pricePerM2 != null &&
              area > 0 &&
              pricePerM2 > 0) {
            return (area * pricePerM2).toDouble();
          }
        }
        return product.investmentAmount;
      case UnifiedProductType.other:
        return product.investmentAmount;
    }
  }

  /// Oblicza statystyki dla produktu na podstawie inwestorów
  /// Używa zunifikowanych definicji
  UnifiedProductStatistics calculateProductStatistics(
    UnifiedProduct product,
    List<InvestorSummary> investors,
  ) {
    if (investors.isEmpty) {
      // Fallback na dane produktu z zunifikowaną definicją
      return UnifiedProductStatistics(
        totalInvestmentAmount: product.investmentAmount,
        totalRemainingCapital: calculateUnifiedProductValue(product),
        totalCapitalSecuredByRealEstate: 0.0,
        viableCapital: product.status == ProductStatus.active
            ? calculateUnifiedProductValue(product)
            : 0.0,
        majorityThreshold: calculateUnifiedProductValue(product) * 0.51,
        investorsCount: 0,
        source: UnifiedStatisticsSource.productFallback,
      );
    }

    // Oblicz na podstawie danych inwestorów (najbardziej precyzyjne)
    final totalInvestmentAmount = investors.fold(
      0.0,
      (sum, investor) => sum + investor.totalInvestmentAmount,
    );

    final totalRemainingCapital = investors.fold(
      0.0,
      (sum, investor) => sum + investor.totalRemainingCapital,
    );

    // 🏠 ZABEZPIECZENIE NIERUCHOMOŚCIAMI - zastosuj poprawny algorytm
    // Zgodnie z KAPITAŁ_ZABEZPIECZONY_ANALIZA.md
    final totalCapitalSecuredByRealEstate = investors.fold(0.0, (
      sum,
      investor,
    ) {
      // Sprawdź wartość z Firebase
      final firebaseValue = investor.capitalSecuredByRealEstate;

      // 🐛 DEBUG - śledzenie obliczeń
      print('🏠 [UnifiedStatisticsService] Zabezpieczenie dla inwestora:');
      print('  - Firebase capitalSecuredByRealEstate: $firebaseValue');
      print('  - remainingCapital: ${investor.totalRemainingCapital}');
      print('  - capitalForRestructuring: ${investor.capitalForRestructuring}');

      // Jeśli Firebase zwraca wartość > 0, użyj jej
      if (firebaseValue > 0) {
        print('  - ✅ Używam wartości z Firebase: $firebaseValue');
        return sum + firebaseValue;
      }

      // W przeciwnym razie użyj algorytmu fallback
      // capitalSecuredByRealEstate = remainingCapital - capitalForRestructuring
      final calculatedValue =
          investor.totalRemainingCapital - investor.capitalForRestructuring;
      final securedValue = calculatedValue > 0 ? calculatedValue : 0.0;

      print(
        '  - 🧮 Obliczam fallback: $calculatedValue (max 0: $securedValue)',
      );
      print('  - 💰 Dodaję do sumy: $securedValue');

      return sum + securedValue;
    });

    // Viable capital - tylko dla aktywnych inwestycji
    final viableCapital = investors.fold(0.0, (sum, investor) {
      return sum + investor.viableRemainingCapital;
    });

    final majorityThreshold = viableCapital * 0.51;

    // 🐛 DEBUG - końcowe statystyki
    print('📊 [UnifiedStatisticsService] KOŃCOWE ZUNIFIKOWANE STATYSTYKI:');
    print('  - totalInvestmentAmount: $totalInvestmentAmount');
    print('  - totalRemainingCapital: $totalRemainingCapital');
    print(
      '  - ⭐ totalCapitalSecuredByRealEstate: $totalCapitalSecuredByRealEstate',
    );
    print('  - viableCapital: $viableCapital');
    print('  - investorsCount: ${investors.length}');

    return UnifiedProductStatistics(
      totalInvestmentAmount: totalInvestmentAmount,
      totalRemainingCapital: totalRemainingCapital,
      totalCapitalSecuredByRealEstate: totalCapitalSecuredByRealEstate,
      viableCapital: viableCapital,
      majorityThreshold: majorityThreshold,
      investorsCount: investors.length,
      source: UnifiedStatisticsSource.investorsData,
    );
  }

  /// Sprawdza spójność statystyk między różnymi źródłami
  Future<UnifiedStatisticsReport> diagnoseInconsistencies() async {
    // TODO: Implementacja diagnostyki zgodnie z guide
    return UnifiedStatisticsReport(
      inconsistencies: [],
      totalChecks: 0,
      passedChecks: 0,
      timestamp: DateTime.now(),
    );
  }
}

/// Zunifikowane statystyki produktu
class UnifiedProductStatistics {
  final double totalInvestmentAmount;
  final double totalRemainingCapital;
  final double totalCapitalSecuredByRealEstate;
  final double viableCapital;
  final double majorityThreshold;
  final int investorsCount;
  final UnifiedStatisticsSource source;

  const UnifiedProductStatistics({
    required this.totalInvestmentAmount,
    required this.totalRemainingCapital,
    required this.totalCapitalSecuredByRealEstate,
    required this.viableCapital,
    required this.majorityThreshold,
    required this.investorsCount,
    required this.source,
  });

  /// Wartość całkowita (zunifikowana definicja)
  double get totalValue => totalRemainingCapital;
}

/// Źródło statystyk
enum UnifiedStatisticsSource {
  investorsData('Dane inwestorów'),
  productFallback('Fallback produktu'),
  cached('Cache'),
  serverSide('Server-side');

  const UnifiedStatisticsSource(this.displayName);
  final String displayName;
}

/// Raport diagnostyczny statystyk
class UnifiedStatisticsReport {
  final List<UnifiedStatisticsInconsistency> inconsistencies;
  final int totalChecks;
  final int passedChecks;
  final DateTime timestamp;

  const UnifiedStatisticsReport({
    required this.inconsistencies,
    required this.totalChecks,
    required this.passedChecks,
    required this.timestamp,
  });

  bool get hasInconsistencies => inconsistencies.isNotEmpty;
  double get consistencyPercentage =>
      totalChecks > 0 ? (passedChecks / totalChecks) * 100 : 100.0;
}

/// Niespójność statystyk
class UnifiedStatisticsInconsistency {
  final String metric;
  final dynamic expectedValue;
  final dynamic actualValue;
  final String source;
  final String explanation;

  const UnifiedStatisticsInconsistency({
    required this.metric,
    required this.expectedValue,
    required this.actualValue,
    required this.source,
    required this.explanation,
  });
}
