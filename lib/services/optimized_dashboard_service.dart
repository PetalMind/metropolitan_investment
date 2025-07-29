import '../services/client_service.dart';
import '../services/employee_service.dart';
import '../services/data_cache_service.dart';
import '../models/investment.dart';
import '../models/product.dart';
import 'base_service.dart';

class DashboardService extends BaseService {
  final DataCacheService _dataCacheService = DataCacheService();
  final ClientService _clientService = ClientService();
  final EmployeeService _employeeService = EmployeeService();

  // Get complete dashboard data - ZOPTYMALIZOWANA WERSJA
  Future<Map<String, dynamic>> getDashboardData() async {
    return getCachedData('dashboard_complete', () async {
      try {
        print('🎯 [Dashboard] Pobieranie danych dashboard z cache...');

        // Pobierz wszystkie inwestycje jednym zapytaniem z cache'a
        final allInvestments = await _dataCacheService.getAllInvestments();

        // Oblicz statystyki na podstawie wszystkich inwestycji
        final dashboardStats = _calculateDashboardStats(allInvestments);

        // Dodaj dodatkowe dane (klienci, pracownicy) równolegle
        final results = await Future.wait([
          _clientService.getClientStats(),
          _employeeService.getEmployeesCount(),
        ]);

        dashboardStats['clientStats'] = results[0];
        dashboardStats['employeesCount'] = results[1];

        print(
          '🎯 [Dashboard] Dashboard wygenerowany z ${allInvestments.length} inwestycji',
        );
        return dashboardStats;
      } catch (e) {
        logError('getDashboardData', e);
        throw Exception('Błąd podczas pobierania danych dashboard: $e');
      }
    });
  }

  // Oblicza statystyki dashboard na podstawie wszystkich inwestycji
  Map<String, dynamic> _calculateDashboardStats(List<Investment> investments) {
    // Grupuj inwestycje według typu produktu
    final bondInvestments = investments
        .where((inv) => inv.productType == ProductType.bonds)
        .toList();
    final shareInvestments = investments
        .where((inv) => inv.productType == ProductType.shares)
        .toList();
    final loanInvestments = investments
        .where((inv) => inv.productType == ProductType.loans)
        .toList();
    final apartmentInvestments = investments
        .where((inv) => inv.productType == ProductType.apartments)
        .toList();

    // Oblicz statystyki dla każdego typu
    final bondsStats = _calculateProductStats(bondInvestments, 'bonds');
    final sharesStats = _calculateProductStats(shareInvestments, 'shares');
    final loansStats = _calculateProductStats(loanInvestments, 'loans');
    final apartmentsStats = _calculateProductStats(
      apartmentInvestments,
      'apartments',
    );

    // Oblicz łączne wartości
    final totalPortfolioValue = investments.fold<double>(
      0.0,
      (sum, inv) => sum + inv.investmentAmount,
    );
    final totalRemainingCapital = investments.fold<double>(
      0.0,
      (sum, inv) => sum + inv.remainingCapital,
    );
    final totalRealizedCapital = investments.fold<double>(
      0.0,
      (sum, inv) => sum + inv.realizedCapital,
    );

    return {
      'totalPortfolioValue': totalPortfolioValue,
      'totalRemainingCapital': totalRemainingCapital,
      'totalRealizedCapital': totalRealizedCapital,
      'totalInvestments': investments.length,
      'bondsStats': bondsStats,
      'sharesStats': sharesStats,
      'loansStats': loansStats,
      'apartmentsStats': apartmentsStats,
      'portfolioComposition': _calculatePortfolioComposition(investments),
      'monthlyTrends': _calculateMonthlyTrends(investments),
      'topClients': _calculateTopClients(investments),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  // Oblicza statystyki dla konkretnego typu produktu
  Map<String, dynamic> _calculateProductStats(
    List<Investment> investments,
    String productType,
  ) {
    if (investments.isEmpty) {
      return {
        'count': 0,
        'total_investment_amount': 0.0,
        'total_remaining_capital': 0.0,
        'total_realized_capital': 0.0,
        'average_investment': 0.0,
        'active_count': 0,
        'completed_count': 0,
      };
    }

    final totalInvestment = investments.fold<double>(
      0.0,
      (sum, inv) => sum + inv.investmentAmount,
    );
    final totalRemaining = investments.fold<double>(
      0.0,
      (sum, inv) => sum + inv.remainingCapital,
    );
    final totalRealized = investments.fold<double>(
      0.0,
      (sum, inv) => sum + inv.realizedCapital,
    );
    final activeCount = investments
        .where((inv) => inv.status == InvestmentStatus.active)
        .length;
    final completedCount = investments
        .where((inv) => inv.status == InvestmentStatus.completed)
        .length;

    return {
      'count': investments.length,
      'total_investment_amount': totalInvestment,
      'total_remaining_capital': totalRemaining,
      'total_realized_capital': totalRealized,
      'average_investment': investments.isNotEmpty
          ? totalInvestment / investments.length
          : 0.0,
      'active_count': activeCount,
      'completed_count': completedCount,
    };
  }

  // Oblicza skład portfela według produktów
  Map<String, dynamic> _calculatePortfolioComposition(
    List<Investment> investments,
  ) {
    if (investments.isEmpty) return {};

    final totalValue = investments.fold<double>(
      0.0,
      (sum, inv) => sum + inv.remainingCapital,
    );

    final composition = <String, Map<String, dynamic>>{};
    for (final productType in ProductType.values) {
      final productInvestments = investments
          .where((inv) => inv.productType == productType)
          .toList();
      final productValue = productInvestments.fold<double>(
        0.0,
        (sum, inv) => sum + inv.remainingCapital,
      );
      final percentage = totalValue > 0
          ? (productValue / totalValue) * 100
          : 0.0;

      composition[productType.displayName] = {
        'value': productValue,
        'percentage': percentage,
        'count': productInvestments.length,
      };
    }

    return composition;
  }

  // Oblicza trendy miesięczne
  Map<String, dynamic> _calculateMonthlyTrends(List<Investment> investments) {
    final now = DateTime.now();
    final trends = <String, Map<String, dynamic>>{};

    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey =
          '${month.year}-${month.month.toString().padLeft(2, '0')}';

      final monthInvestments = investments.where((inv) {
        return inv.signedDate.year == month.year &&
            inv.signedDate.month == month.month;
      }).toList();

      trends[monthKey] = {
        'count': monthInvestments.length,
        'value': monthInvestments.fold<double>(
          0.0,
          (sum, inv) => sum + inv.investmentAmount,
        ),
      };
    }

    return trends;
  }

  // Oblicza top klientów
  List<Map<String, dynamic>> _calculateTopClients(
    List<Investment> investments, {
    int limit = 10,
  }) {
    final clientGroups = <String, List<Investment>>{};

    for (final investment in investments) {
      clientGroups.putIfAbsent(investment.clientName, () => []).add(investment);
    }

    final clientStats = clientGroups.entries.map((entry) {
      final clientInvestments = entry.value;
      final totalValue = clientInvestments.fold<double>(
        0.0,
        (sum, inv) => sum + inv.remainingCapital,
      );

      return {
        'clientName': entry.key,
        'totalValue': totalValue,
        'investmentCount': clientInvestments.length,
        'averageInvestment': totalValue / clientInvestments.length,
      };
    }).toList();

    clientStats.sort(
      (a, b) =>
          (b['totalValue'] as double).compareTo(a['totalValue'] as double),
    );
    return clientStats.take(limit).toList();
  }

  // Get top performing investments for insights - ZOPTYMALIZOWANA WERSJA
  Future<Map<String, List<Map<String, dynamic>>>>
  getTopPerformingInvestments() async {
    return getCachedData('top_performing_investments', () async {
      try {
        final allInvestments = await _dataCacheService.getAllInvestments();

        // Sortuj według wartości
        final topByValue = List<Investment>.from(allInvestments)
          ..sort((a, b) => b.remainingCapital.compareTo(a.remainingCapital));

        return {
          'top_bonds': topByValue
              .where((inv) => inv.productType == ProductType.bonds)
              .take(5)
              .map(
                (inv) => {
                  'clientName': inv.clientName,
                  'productName': inv.productName,
                  'remainingCapital': inv.remainingCapital,
                  'realizedCapital': inv.realizedCapital,
                },
              )
              .toList(),
          'top_shares': topByValue
              .where((inv) => inv.productType == ProductType.shares)
              .take(5)
              .map(
                (inv) => {
                  'clientName': inv.clientName,
                  'productName': inv.productName,
                  'remainingCapital': inv.remainingCapital,
                  'sharesCount': inv.sharesCount ?? 0,
                },
              )
              .toList(),
          'top_loans': topByValue
              .where((inv) => inv.productType == ProductType.loans)
              .take(5)
              .map(
                (inv) => {
                  'clientName': inv.clientName,
                  'productName': inv.productName,
                  'remainingCapital': inv.remainingCapital,
                  'paidAmount': inv.paidAmount,
                },
              )
              .toList(),
        };
      } catch (e) {
        logError('getTopPerformingInvestments', e);
        return {
          'top_bonds': <Map<String, dynamic>>[],
          'top_shares': <Map<String, dynamic>>[],
          'top_loans': <Map<String, dynamic>>[],
        };
      }
    });
  }

  // Czyści cache dashboard
  void clearDashboardCache() {
    clearCache('dashboard_complete');
    clearCache('top_performing_investments');
    clearCache('portfolio_growth');
    _dataCacheService.invalidateCache();
    print('🎯 [Dashboard] Cache wyczyszczony');
  }

  // Pobiera wzrost portfela w czasie - ZOPTYMALIZOWANA WERSJA
  Future<Map<String, dynamic>> getPortfolioGrowth() async {
    return getCachedData('portfolio_growth', () async {
      try {
        final allInvestments = await _dataCacheService.getAllInvestments();

        // Grupuj według miesięcy
        final monthlyData = <String, Map<String, dynamic>>{};
        final now = DateTime.now();

        for (int i = 0; i < 12; i++) {
          final month = DateTime(now.year, now.month - i, 1);
          final monthKey =
              '${month.year}-${month.month.toString().padLeft(2, '0')}';

          final monthInvestments = allInvestments.where((inv) {
            return inv.signedDate.year == month.year &&
                inv.signedDate.month == month.month;
          }).toList();

          final totalInvested = monthInvestments.fold<double>(
            0.0,
            (sum, inv) => sum + inv.investmentAmount,
          );
          final totalRemaining = monthInvestments.fold<double>(
            0.0,
            (sum, inv) => sum + inv.remainingCapital,
          );

          monthlyData[monthKey] = {
            'month': monthKey,
            'new_investments': monthInvestments.length,
            'total_invested': totalInvested,
            'total_remaining': totalRemaining,
            'growth_rate': totalInvested > 0
                ? (totalRemaining / totalInvested) * 100
                : 0.0,
          };
        }

        return {
          'monthly_data': monthlyData,
          'total_growth': _calculateTotalGrowth(allInvestments),
        };
      } catch (e) {
        logError('getPortfolioGrowth', e);
        return {'monthly_data': {}, 'total_growth': 0.0};
      }
    });
  }

  // Oblicza łączny wzrost portfela
  double _calculateTotalGrowth(List<Investment> investments) {
    final totalInvested = investments.fold<double>(
      0.0,
      (sum, inv) => sum + inv.investmentAmount,
    );
    final totalCurrent = investments.fold<double>(
      0.0,
      (sum, inv) => sum + inv.remainingCapital + inv.realizedCapital,
    );

    return totalInvested > 0
        ? ((totalCurrent - totalInvested) / totalInvested) * 100
        : 0.0;
  }

  // Pobiera alerty dashboard - ZOPTYMALIZOWANA WERSJA
  Future<List<Map<String, dynamic>>> getDashboardAlerts() async {
    try {
      final allInvestments = await _dataCacheService.getAllInvestments();
      final alerts = <Map<String, dynamic>>[];

      // Sprawdź inwestycje z dużymi kwotami niezrealizowanych odsetek
      final highInterestInvestments = allInvestments
          .where(
            (inv) =>
                inv.remainingInterest > 100000, // 100k+ pozostałych odsetek
          )
          .toList();

      if (highInterestInvestments.isNotEmpty) {
        final totalRemainingInterest = highInterestInvestments.fold<double>(
          0.0,
          (sum, inv) => sum + inv.remainingInterest,
        );

        alerts.add({
          'type': 'info',
          'title': 'Wysokie odsetki do realizacji',
          'message':
              'Pozostałe odsetki do realizacji: ${totalRemainingInterest.toStringAsFixed(0)} PLN',
          'action': 'investments_view',
        });
      }

      // Sprawdź zaangażowanie klientów (email)
      final clientStats = await _clientService.getClientStats();
      final emailPercentage =
          double.tryParse(clientStats['email_percentage'] ?? '0') ?? 0;

      if (emailPercentage < 50) {
        alerts.add({
          'type': 'warning',
          'title': 'Niska dostępność emaili klientów',
          'message':
              'Tylko ${emailPercentage.toStringAsFixed(1)}% klientów ma podany email',
          'action': 'clients_view',
        });
      }

      return alerts;
    } catch (e) {
      logError('getDashboardAlerts', e);
      return [];
    }
  }
}
