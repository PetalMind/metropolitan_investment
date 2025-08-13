import '../models/client.dart';
import '../models/investor_summary.dart';

/// 📊 MANAGER ANALIZY GŁOSOWANIA
/// Zawiera logikę analizy kapitału głosującego i kontroli większościowej
class VotingAnalysisManager {
  // Rozkład kapitału według statusu głosowania
  double yesVotingCapital = 0.0;
  double noVotingCapital = 0.0;
  double abstainVotingCapital = 0.0;
  double undecidedVotingCapital = 0.0;

  // Konfiguracja
  static const double defaultMajorityThreshold = 51.0;

  /// Oblicza rozkład kapitału według statusu głosowania
  void calculateVotingCapitalDistribution(List<InvestorSummary> investors) {
    yesVotingCapital = 0.0;
    noVotingCapital = 0.0;
    abstainVotingCapital = 0.0;
    undecidedVotingCapital = 0.0;

    for (final investor in investors) {
      // Używamy viableRemainingCapital zamiast totalValue
      // aby uwzględnić tylko wykonalne inwestycje
      final capitalValue = investor.viableRemainingCapital;

      switch (investor.client.votingStatus) {
        case VotingStatus.yes:
          yesVotingCapital += capitalValue;
          break;
        case VotingStatus.no:
          noVotingCapital += capitalValue;
          break;
        case VotingStatus.abstain:
          abstainVotingCapital += capitalValue;
          break;
        case VotingStatus.undecided:
          undecidedVotingCapital += capitalValue;
          break;
      }
    }

    _logVotingDistribution();
  }

  /// Oblicza łączną wartość kapitału wykonalnych inwestycji
  double get totalViableCapital {
    return yesVotingCapital +
        noVotingCapital +
        abstainVotingCapital +
        undecidedVotingCapital;
  }

  /// Procent kapitału dla statusu głosowania TAK
  double get yesVotingPercentage {
    return totalViableCapital > 0
        ? (yesVotingCapital / totalViableCapital) * 100
        : 0.0;
  }

  /// Procent kapitału dla statusu głosowania NIE
  double get noVotingPercentage {
    return totalViableCapital > 0
        ? (noVotingCapital / totalViableCapital) * 100
        : 0.0;
  }

  /// Procent kapitału dla statusu WSTRZYMUJE SIĘ
  double get abstainVotingPercentage {
    return totalViableCapital > 0
        ? (abstainVotingCapital / totalViableCapital) * 100
        : 0.0;
  }

  /// Procent kapitału dla statusu NIEZDECYDOWANY
  double get undecidedVotingPercentage {
    return totalViableCapital > 0
        ? (undecidedVotingCapital / totalViableCapital) * 100
        : 0.0;
  }

  /// Zwraca insight o głosowaniu na podstawie obecnego rozkładu
  VotingInsight getVotingInsight({
    double majorityThreshold = defaultMajorityThreshold,
  }) {
    final yesPercentage = yesVotingPercentage;
    final noPercentage = noVotingPercentage;

    if (yesPercentage >= majorityThreshold) {
      return VotingInsight(
        message:
            'Większość głosuje ZA (${yesPercentage.toStringAsFixed(1)}% ≥ ${majorityThreshold.toStringAsFixed(0)}%)',
        type: VotingInsightType.majorityYes,
        percentage: yesPercentage,
      );
    } else if (noPercentage >= majorityThreshold) {
      return VotingInsight(
        message:
            'Większość głosuje PRZECIW (${noPercentage.toStringAsFixed(1)}% ≥ ${majorityThreshold.toStringAsFixed(0)}%)',
        type: VotingInsightType.majorityNo,
        percentage: noPercentage,
      );
    } else {
      final needed = majorityThreshold - yesPercentage;
      return VotingInsight(
        message:
            'Do większości ZA potrzeba jeszcze ${needed.toStringAsFixed(1)}%',
        type: VotingInsightType.needMore,
        percentage: needed,
      );
    }
  }

  /// Zwraca rozkład kapitału głosującego jako mapę
  Map<String, double> getVotingCapitalDistribution() {
    final total = totalViableCapital;

    return {
      'yes': total > 0 ? (yesVotingCapital / total) * 100 : 0.0,
      'no': total > 0 ? (noVotingCapital / total) * 100 : 0.0,
      'abstain': total > 0 ? (abstainVotingCapital / total) * 100 : 0.0,
      'undecided': total > 0 ? (undecidedVotingCapital / total) * 100 : 0.0,
    };
  }

  /// Oblicza odległość inwestora do progu większości
  double calculateMajorityDistance(
    InvestorSummary investor, {
    double majorityThreshold = defaultMajorityThreshold,
  }) {
    if (totalViableCapital <= 0) return 0.0;

    final investorPercentage =
        (investor.viableRemainingCapital / totalViableCapital) * 100;
    return (investorPercentage - majorityThreshold).abs();
  }

  /// Loguje rozkład głosowania do konsoli
  void _logVotingDistribution() {
    final total = totalViableCapital;

    print('   ŁĄCZNIE WYKONALNY KAPITAŁ: ${total.toStringAsFixed(2)} PLN');
  }

  /// Resetuje wszystkie wartości
  void reset() {
    yesVotingCapital = 0.0;
    noVotingCapital = 0.0;
    abstainVotingCapital = 0.0;
    undecidedVotingCapital = 0.0;
  }
}

/// Model dla insights o głosowaniu
class VotingInsight {
  final String message;
  final VotingInsightType type;
  final double percentage;

  VotingInsight({
    required this.message,
    required this.type,
    required this.percentage,
  });
}

/// Typ insight-u o głosowaniu
enum VotingInsightType { majorityYes, majorityNo, needMore }
