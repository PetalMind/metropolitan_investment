import '../models/investment.dart';
import '../services/firebase_functions_data_service.dart';

/// Uproszczony serwis analityczny dla web z lepszą wydajnością
class WebAnalyticsService {
  final FirebaseFunctionsDataService _dataService = FirebaseFunctionsDataService();

  /// Pobiera podstawowe metryki dashboard
  Future<DashboardMetrics> getDashboardMetrics() async {
    try {
      final result = await _dataService.getEnhancedInvestments(
        page: 1, 
        pageSize: 10000,
        forceRefresh: false,
      );
      final investments = result.investments;

      return DashboardMetrics(
        totalInvestments: investments.length,
        totalValue: _sum(investments, (inv) => inv.totalValue),
        totalInvestmentAmount: _sum(investments, (inv) => inv.investmentAmount),
        totalRealizedCapital: _sum(investments, (inv) => inv.realizedCapital),
        totalRemainingCapital: _sum(investments, (inv) => inv.remainingCapital),
        totalRealizedInterest: _sum(investments, (inv) => inv.realizedInterest),
        totalRemainingInterest: _sum(
          investments,
          (inv) => inv.remainingInterest,
        ),
        activeInvestments: investments
            .where((inv) => inv.status == InvestmentStatus.active)
            .length,
        completedInvestments: investments
            .where((inv) => inv.status == InvestmentStatus.completed)
            .length,
        roi: _calculateROI(investments),
        averageInvestmentAmount: investments.isNotEmpty
            ? _sum(investments, (inv) => inv.investmentAmount) /
                  investments.length
            : 0.0,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('❌ [WebAnalytics] Błąd obliczania metryk: $e');
      return DashboardMetrics.empty();
    }
  }

  /// Pobiera metryki dla konkretnego klienta
  Future<ClientMetrics> getClientMetrics(String clientId) async {
    try {
      final result = await _dataService.getEnhancedInvestments(page: 1, pageSize: 10000);
      final allInvestments = result.investments;
      final clientInvestments = allInvestments
          .where((inv) => inv.clientId == clientId)
          .toList();

      return ClientMetrics(
        clientId: clientId,
        clientName: clientInvestments.isNotEmpty
            ? clientInvestments.first.clientName
            : '',
        totalInvestments: clientInvestments.length,
        totalValue: _sum(clientInvestments, (inv) => inv.totalValue),
        totalInvestmentAmount: _sum(
          clientInvestments,
          (inv) => inv.investmentAmount,
        ),
        totalProfit: _sum(
          clientInvestments,
          (inv) => inv.realizedInterest + inv.remainingInterest,
        ),
        activeInvestments: clientInvestments
            .where((inv) => inv.status == InvestmentStatus.active)
            .length,
        investments: clientInvestments,
      );
    } catch (e) {
      print('❌ [WebAnalytics] Błąd obliczania metryk klienta: $e');
      return ClientMetrics.empty(clientId);
    }
  }

  /// Pobiera top klientów
  Future<List<ClientSummary>> getTopClients({int limit = 10}) async {
    try {
      final result = await _dataService.getEnhancedInvestments(page: 1, pageSize: 10000);
      final investments = result.investments;
      final clientGroups = <String, List<Investment>>{};

      // Grupuj po klientach
      for (final investment in investments) {
        final clientId = investment.clientId;
        clientGroups.putIfAbsent(clientId, () => []).add(investment);
      }

      // Stwórz podsumowania i posortuj
      final summaries = clientGroups.entries.map((entry) {
        final clientInvestments = entry.value;
        final totalValue = _sum(clientInvestments, (inv) => inv.totalValue);

        return ClientSummary(
          clientId: entry.key,
          clientName: clientInvestments.first.clientName,
          totalInvestments: clientInvestments.length,
          totalValue: totalValue,
          totalProfit: _sum(
            clientInvestments,
            (inv) => inv.realizedInterest + inv.remainingInterest,
          ),
        );
      }).toList();

      summaries.sort((a, b) => b.totalValue.compareTo(a.totalValue));
      return summaries.take(limit).toList();
    } catch (e) {
      print('❌ [WebAnalytics] Błąd pobierania top klientów: $e');
      return [];
    }
  }

  /// Pobiera inwestycje wymagające uwagi
  Future<List<Investment>> getInvestmentsRequiringAttention() async {
    try {
      final result = await _dataService.getEnhancedInvestments(page: 1, pageSize: 10000);
      final investments = result.investments;
      final now = DateTime.now();

      return investments.where((inv) {
        // Inwestycje kończące się w ciągu 30 dni
        if (inv.redemptionDate != null) {
          final daysToRedemption = inv.redemptionDate!.difference(now).inDays;
          if (daysToRedemption <= 30 && daysToRedemption >= 0) return true;
        }

        // Duże kwoty (powyżej 100k)
        if (inv.investmentAmount > 100000) return true;

        // Długo trwające inwestycje (powyżej 2 lat)
        if (inv.entryDate != null) {
          final daysSinceEntry = now.difference(inv.entryDate!).inDays;
          if (daysSinceEntry > 730) return true;
        }

        return false;
      }).toList();
    } catch (e) {
      print(
        '❌ [WebAnalytics] Błąd pobierania inwestycji wymagających uwagi: $e',
      );
      return [];
    }
  }

  /// Pobiera ostatnie inwestycje
  Future<List<Investment>> getRecentInvestments({int limit = 10}) async {
    try {
      final result = await _dataService.getEnhancedInvestments(page: 1, pageSize: 10000);
      final investments = result.investments;
      investments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return investments.take(limit).toList();
    } catch (e) {
      print('❌ [WebAnalytics] Błąd pobierania ostatnich inwestycji: $e');
      return [];
    }
  }

  // Metody pomocnicze
  double _sum(
    List<Investment> investments,
    double Function(Investment) getValue,
  ) {
    return investments.fold<double>(0.0, (sum, inv) => sum + getValue(inv));
  }

  double _calculateROI(List<Investment> investments) {
    final totalInvested = _sum(investments, (inv) => inv.investmentAmount);
    final totalProfit = _sum(
      investments,
      (inv) =>
          inv.realizedCapital + inv.realizedInterest - inv.investmentAmount,
    );

    return totalInvested > 0 ? (totalProfit / totalInvested) * 100 : 0.0;
  }
}

/// Podstawowe metryki dashboard
class DashboardMetrics {
  final int totalInvestments;
  final double totalValue;
  final double totalInvestmentAmount;
  final double totalRealizedCapital;
  final double totalRemainingCapital;
  final double totalRealizedInterest;
  final double totalRemainingInterest;
  final int activeInvestments;
  final int completedInvestments;
  final double roi;
  final double averageInvestmentAmount;
  final DateTime lastUpdated;

  DashboardMetrics({
    required this.totalInvestments,
    required this.totalValue,
    required this.totalInvestmentAmount,
    required this.totalRealizedCapital,
    required this.totalRemainingCapital,
    required this.totalRealizedInterest,
    required this.totalRemainingInterest,
    required this.activeInvestments,
    required this.completedInvestments,
    required this.roi,
    required this.averageInvestmentAmount,
    required this.lastUpdated,
  });

  factory DashboardMetrics.empty() {
    return DashboardMetrics(
      totalInvestments: 0,
      totalValue: 0.0,
      totalInvestmentAmount: 0.0,
      totalRealizedCapital: 0.0,
      totalRemainingCapital: 0.0,
      totalRealizedInterest: 0.0,
      totalRemainingInterest: 0.0,
      activeInvestments: 0,
      completedInvestments: 0,
      roi: 0.0,
      averageInvestmentAmount: 0.0,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Metryki klienta
class ClientMetrics {
  final String clientId;
  final String clientName;
  final int totalInvestments;
  final double totalValue;
  final double totalInvestmentAmount;
  final double totalProfit;
  final int activeInvestments;
  final List<Investment> investments;

  ClientMetrics({
    required this.clientId,
    required this.clientName,
    required this.totalInvestments,
    required this.totalValue,
    required this.totalInvestmentAmount,
    required this.totalProfit,
    required this.activeInvestments,
    required this.investments,
  });

  factory ClientMetrics.empty(String clientId) {
    return ClientMetrics(
      clientId: clientId,
      clientName: '',
      totalInvestments: 0,
      totalValue: 0.0,
      totalInvestmentAmount: 0.0,
      totalProfit: 0.0,
      activeInvestments: 0,
      investments: [],
    );
  }
}

/// Podsumowanie klienta dla list
class ClientSummary {
  final String clientId;
  final String clientName;
  final int totalInvestments;
  final double totalValue;
  final double totalProfit;

  ClientSummary({
    required this.clientId,
    required this.clientName,
    required this.totalInvestments,
    required this.totalValue,
    required this.totalProfit,
  });
}
