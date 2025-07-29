import '../services/bond_service.dart';
import '../services/loan_service.dart';
import '../services/share_service.dart';
import '../services/investment_service.dart';
import '../services/client_service.dart';
import '../services/employee_service.dart';
import '../services/data_cache_service.dart';
import 'base_service.dart';

class DashboardService extends BaseService {
  final DataCacheService _dataCacheService = DataCacheService();
  final ClientService _clientService = ClientService();
  final EmployeeService _employeeService = EmployeeService();

  // Get complete dashboard data
  Future<Map<String, dynamic>> getDashboardData() async {
    return getCachedData('dashboard_complete', () async {
      try {
        print('🎯 [Dashboard] Pobieranie danych dashboard z cache...');
        
        // Pobierz wszystkie inwestycje jednym zapytaniem z cache'a
        final allInvestments = await _dataCacheService.getAllInvestments();
        
        // Oblicz statystyki na podstawie wszystkich inwestycji
        final dashboardStats = _calculateDashboardStats(allInvestments);
        
        // Dodaj dodatkowe dane (klienci, pracownicy)
        final results = await Future.wait([
          _clientService.getClientStats(),
          _employeeService.getEmployeesCount(),
        ]);
        
        dashboardStats['clientStats'] = results[0];
        dashboardStats['employeesCount'] = results[1];
        
        print('🎯 [Dashboard] Dashboard wygenerowany z ${allInvestments.length} inwestycji');
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
    final bondInvestments = investments.where((inv) => inv.productType == ProductType.bonds).toList();
    final shareInvestments = investments.where((inv) => inv.productType == ProductType.shares).toList();
    final loanInvestments = investments.where((inv) => inv.productType == ProductType.loans).toList();
    final apartmentInvestments = investments.where((inv) => inv.productType == ProductType.apartments).toList();

    // Oblicz statystyki dla każdego typu
    final bondsStats = _calculateProductStats(bondInvestments, 'bonds');
    final sharesStats = _calculateProductStats(shareInvestments, 'shares');
    final loansStats = _calculateProductStats(loanInvestments, 'loans');
    final apartmentsStats = _calculateProductStats(apartmentInvestments, 'apartments');

    // Oblicz łączne wartości
    final totalPortfolioValue = investments.fold<double>(0.0, (sum, inv) => sum + inv.investmentAmount);
    final totalRemainingCapital = investments.fold<double>(0.0, (sum, inv) => sum + inv.remainingCapital);
    final totalRealizedCapital = investments.fold<double>(0.0, (sum, inv) => sum + inv.realizedCapital);

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
  Map<String, dynamic> _calculateProductStats(List<Investment> investments, String productType) {
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

    final totalInvestment = investments.fold<double>(0.0, (sum, inv) => sum + inv.investmentAmount);
    final totalRemaining = investments.fold<double>(0.0, (sum, inv) => sum + inv.remainingCapital);
    final totalRealized = investments.fold<double>(0.0, (sum, inv) => sum + inv.realizedCapital);
    final activeCount = investments.where((inv) => inv.status == InvestmentStatus.active).length;
    final completedCount = investments.where((inv) => inv.status == InvestmentStatus.completed).length;

    return {
      'count': investments.length,
      'total_investment_amount': totalInvestment,
      'total_remaining_capital': totalRemaining,
      'total_realized_capital': totalRealized,
      'average_investment': investments.isNotEmpty ? totalInvestment / investments.length : 0.0,
      'active_count': activeCount,
      'completed_count': completedCount,
    };
  }

  // Oblicza skład portfela według produktów
  Map<String, dynamic> _calculatePortfolioComposition(List<Investment> investments) {
    if (investments.isEmpty) return {};

    final totalValue = investments.fold<double>(0.0, (sum, inv) => sum + inv.remainingCapital);
    
    final composition = <String, Map<String, dynamic>>{};
    for (final productType in ProductType.values) {
      final productInvestments = investments.where((inv) => inv.productType == productType).toList();
      final productValue = productInvestments.fold<double>(0.0, (sum, inv) => sum + inv.remainingCapital);
      final percentage = totalValue > 0 ? (productValue / totalValue) * 100 : 0.0;
      
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
      final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      
      final monthInvestments = investments.where((inv) {
        return inv.signedDate.year == month.year && inv.signedDate.month == month.month;
      }).toList();
      
      trends[monthKey] = {
        'count': monthInvestments.length,
        'value': monthInvestments.fold<double>(0.0, (sum, inv) => sum + inv.investmentAmount),
      };
    }
    
    return trends;
  }

  // Oblicza top klientów
  List<Map<String, dynamic>> _calculateTopClients(List<Investment> investments, {int limit = 10}) {
    final clientGroups = <String, List<Investment>>{};
    
    for (final investment in investments) {
      clientGroups.putIfAbsent(investment.clientName, () => []).add(investment);
    }
    
    final clientStats = clientGroups.entries.map((entry) {
      final clientInvestments = entry.value;
      final totalValue = clientInvestments.fold<double>(0.0, (sum, inv) => sum + inv.remainingCapital);
      
      return {
        'clientName': entry.key,
        'totalValue': totalValue,
        'investmentCount': clientInvestments.length,
        'averageInvestment': totalValue / clientInvestments.length,
      };
    }).toList();
    
    clientStats.sort((a, b) => (b['totalValue'] as double).compareTo(a['totalValue'] as double));
    return clientStats.take(limit).toList();
  }

  // Get top performing investments for insights
  Future<Map<String, List<Map<String, dynamic>>>> getTopPerformingInvestments() async {
          },

          'loans': {
            'count': loansStats['total_count'] ?? 0,
            'total_value': totalLoansValue,
            'average_amount': loansStats['average_loan_amount'] ?? 0.0,
            'product_types': loansStats['product_type_counts'] ?? {},
          },

          'shares': {
            'count': sharesStats['total_count'] ?? 0,
            'total_value': totalSharesValue,
            'total_shares_count': sharesStats['total_shares_count'] ?? 0,
            'average_price_per_share':
                sharesStats['average_price_per_share'] ?? 0.0,
            'product_types': sharesStats['product_type_counts'] ?? {},
          },

          'investments': {
            'total_count': investmentStats['totalCount'] ?? 0,
            'active_count': investmentStats['activeCount'] ?? 0,
            'inactive_count': investmentStats['inactiveCount'] ?? 0,
            'total_value': totalInvestmentsValue,
            'product_types': investmentStats['productTypes'] ?? {},
          },

          'clients': {
            'total': clientStats['total_clients'] ?? 0,
            'with_email': clientStats['clients_with_email'] ?? 0,
            'with_phone': clientStats['clients_with_phone'] ?? 0,
            'with_company': clientStats['clients_with_company'] ?? 0,
            'email_percentage': clientStats['email_percentage'] ?? '0',
            'phone_percentage': clientStats['phone_percentage'] ?? '0',
            'company_percentage': clientStats['company_percentage'] ?? '0',
          },

          // Performance metrics
          'performance': {
            'total_profit_loss': (bondsStats['total_profit_loss'] ?? 0.0),
            'bonds_performance': bondsStats['total_profit_loss'] ?? 0.0,
            'portfolio_diversification': {
              'bonds_percentage': totalPortfolioValue > 0
                  ? (totalBondsValue / totalPortfolioValue * 100)
                        .toStringAsFixed(1)
                  : '0',
              'loans_percentage': totalPortfolioValue > 0
                  ? (totalLoansValue / totalPortfolioValue * 100)
                        .toStringAsFixed(1)
                  : '0',
              'shares_percentage': totalPortfolioValue > 0
                  ? (totalSharesValue / totalPortfolioValue * 100)
                        .toStringAsFixed(1)
                  : '0',
              'investments_percentage': totalPortfolioValue > 0
                  ? (totalInvestmentsValue / totalPortfolioValue * 100)
                        .toStringAsFixed(1)
                  : '0',
            },
          },

          // Timestamps
          'last_updated': DateTime.now().toIso8601String(),
          'cache_duration': 'PT5M', // 5 minutes cache
        };
      } catch (e) {
        logError('getDashboardData', e);
        return {
          'error': 'Failed to load dashboard data: $e',
          'last_updated': DateTime.now().toIso8601String(),
        };
      }
    });
  }

  // Get top performers across all asset types
  Future<Map<String, dynamic>> getTopPerformers() async {
    return getCachedData('top_performers', () async {
      try {
        final results = await Future.wait([
          _bondService.getTopPerformingBonds(limit: 5),
          _shareService.getSharesWithHighestValue(limit: 5),
          _loanService.getLargestLoans(limit: 5),
        ]);

        return {
          'top_bonds': results[0],
          'top_shares': results[1],
          'largest_loans': results[2],
          'last_updated': DateTime.now().toIso8601String(),
        };
      } catch (e) {
        logError('getTopPerformers', e);
        return {
          'error': 'Failed to load top performers: $e',
          'last_updated': DateTime.now().toIso8601String(),
        };
      }
    });
  }

  // Get summary statistics for quick overview
  Future<Map<String, dynamic>> getQuickStats() async {
    return getCachedData('quick_stats', () async {
      try {
        final dashboardData = await getDashboardData();

        return {
          'total_portfolio_value': dashboardData['total_portfolio_value'],
          'total_clients': dashboardData['total_clients'],
          'active_investments': dashboardData['total_active_investments'],
          'bonds_count': dashboardData['bonds']['count'],
          'loans_count': dashboardData['loans']['count'],
          'shares_count': dashboardData['shares']['count'],
          'profit_loss': dashboardData['performance']['total_profit_loss'],
          'last_updated': DateTime.now().toIso8601String(),
        };
      } catch (e) {
        logError('getQuickStats', e);
        return {
          'error': 'Failed to load quick stats: $e',
          'last_updated': DateTime.now().toIso8601String(),
        };
      }
    });
  }

  // Clear all dashboard caches
  Future<void> refreshDashboardData() async {
    clearCache('dashboard_complete');
    clearCache('top_performers');
    clearCache('quick_stats');
    clearCache('bonds_stats');
    clearCache('loans_stats');
    clearCache('shares_stats');
    clearCache('client_stats');
  }

  // Get alerts and notifications
  Future<List<Map<String, dynamic>>> getDashboardAlerts() async {
    try {
      final List<Map<String, dynamic>> alerts = [];

      // Check for bonds with high remaining interest
      final bondsStats = await _bondService.getBondsStatistics();
      final totalRemainingInterest =
          bondsStats['total_remaining_interest'] ?? 0.0;

      if (totalRemainingInterest > 100000) {
        alerts.add({
          'type': 'info',
          'title': 'Wysokie odsetki do realizacji',
          'message':
              'Pozostałe odsetki do realizacji: ${totalRemainingInterest.toStringAsFixed(0)} PLN',
          'action': 'bonds_view',
        });
      }

      // Check for low client engagement
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
