import 'package:flutter/foundation.dart';
import '../services/bond_service.dart';
import '../services/loan_service.dart';
import '../services/share_service.dart';
import '../services/apartment_service.dart';
import '../services/investment_service.dart';
import '../services/client_service.dart';
import '../services/employee_service.dart';
import '../services/firebase_functions_data_service.dart';
import 'base_service.dart';

class DashboardService extends BaseService {
  final BondService _bondService = BondService();
  final LoanService _loanService = LoanService();
  final ShareService _shareService = ShareService();
  final ApartmentService _apartmentService = ApartmentService();
  final InvestmentService _investmentService = InvestmentService();
  final ClientService _clientService = ClientService();
  final EmployeeService _employeeService = EmployeeService();
  final FirebaseFunctionsDataService _dataService =
      FirebaseFunctionsDataService();

  // Get dashboard data using Firebase Functions (optimized for large datasets)
  Future<Map<String, dynamic>> getOptimizedDashboardData() async {
    return getCachedData('optimized_dashboard_complete', () async {
      try {
        if (kDebugMode) {
          print(
            '[DashboardService] Pobieranie zoptymalizowanych danych dashboard z Firebase Functions',
          );
        }

        // Get product type statistics from Firebase Functions
        final productStats = await _dataService.getProductTypeStatistics();

        // Get legacy client stats
        final clientStats = await _clientService.getClientStats();
        final employeesCount = await _employeeService.getEmployeesCount();

        // Calculate totals from Firebase Functions data
        final totalPortfolioValue = productStats.summary.totalValue;
        final totalInvestmentAmount =
            productStats.summary.totalInvestmentAmount;

        return {
          'portfolio': {
            'total_value': totalPortfolioValue,
            'total_investment_amount': totalInvestmentAmount,
            'bonds': {
              'count': productStats.bonds.count,
              'total_value': productStats.bonds.totalValue,
              'total_investment_amount':
                  productStats.bonds.totalInvestmentAmount,
              'average_value': productStats.bonds.averageValue,
            },
            'shares': {
              'count': productStats.shares.count,
              'total_value': productStats.shares.totalValue,
              'total_investment_amount':
                  productStats.shares.totalInvestmentAmount,
              'average_value': productStats.shares.averageValue,
            },
            'loans': {
              'count': productStats.loans.count,
              'total_value': productStats.loans.totalValue,
              'total_investment_amount':
                  productStats.loans.totalInvestmentAmount,
              'average_value': productStats.loans.averageValue,
            },
            'apartments': {
              'count': productStats.apartments.count,
              'total_value': productStats.apartments.totalValue,
              'total_investment_amount':
                  productStats.apartments.totalInvestmentAmount,
              'average_value': productStats.apartments.averageValue,
              'total_area': productStats.apartments.totalArea,
              'average_area': productStats.apartments.averageArea,
            },
          },
          'clients': clientStats,
          'employees_count': employeesCount,
          'system_summary': {
            'total_products': productStats.summary.totalCount,
            'data_source': 'firebase_functions_optimized',
            'last_updated': DateTime.now().toIso8601String(),
          },
        };
      } catch (e) {
        logError('getOptimizedDashboardData', e);

        // Fallback to legacy method
        if (kDebugMode) {
          print('[DashboardService] Fallback do legacy dashboard data');
        }
        return await getDashboardData();
      }
    });
  }

  // Legacy method - get complete dashboard data
  Future<Map<String, dynamic>> getDashboardData() async {
    return getCachedData('dashboard_complete', () async {
      try {
        // Execute all requests in parallel for better performance
        final results = await Future.wait([
          _bondService.getBondsStatistics(),
          _loanService.getLoansStatistics(),
          _shareService.getSharesStatistics(),
          _apartmentService.getApartmentStatistics(),
          _investmentService.getInvestmentStatistics(),
          _clientService.getClientStats(),
          _employeeService.getEmployeesCount(),
        ]);

        final bondsStats = results[0] as Map<String, dynamic>;
        final loansStats = results[1] as Map<String, dynamic>;
        final sharesStats = results[2] as Map<String, dynamic>;
        final apartmentsStats = results[3] as Map<String, dynamic>;
        final investmentStats = results[4] as Map<String, dynamic>;
        final clientStats = results[5] as Map<String, dynamic>;
        final employeesCount = results[6] as int;

        // Calculate total portfolio value - tylko kapital_pozostaly
        final totalBondsValue = bondsStats['total_remaining_capital'] ?? 0.0;
        final totalLoansValue = loansStats['total_investment_amount'] ?? 0.0;
        final totalSharesValue = sharesStats['total_investment_amount'] ?? 0.0;
        final totalApartmentsValue = apartmentsStats['totalValue'] ?? 0.0;
        final totalInvestmentsValue = investmentStats['totalValue'] ?? 0.0;

        final totalPortfolioValue =
            totalBondsValue +
            totalLoansValue +
            totalSharesValue +
            totalApartmentsValue +
            totalInvestmentsValue;

        // Calculate current value - tylko kapital_pozostaly dla obligacji
        final bondsCurrentValue = bondsStats['total_remaining_capital'] ?? 0.0;
        final apartmentsCurrentValue =
            apartmentsStats['totalRemainingCapital'] ??
            apartmentsStats['totalValue'] ??
            0.0;

        return {
          // Overview stats
          'total_portfolio_value': totalPortfolioValue,
          'total_clients': clientStats['total_clients'] ?? 0,
          'total_employees': employeesCount,
          'total_active_investments': investmentStats['activeCount'] ?? 0,

          // Detailed breakdowns
          'bonds': {
            'count': bondsStats['total_count'] ?? 0,
            'total_value': totalBondsValue, // tylko kapital_pozostaly
            'current_value': bondsCurrentValue, // tylko kapital_pozostaly
            'realized_profit': 0.0, // nie uwzględniamy zrealizowanych zysków
            'remaining_capital': bondsStats['total_remaining_capital'] ?? 0.0,
            'remaining_interest': 0.0, // nie uwzględniamy odsetek
            'product_types': bondsStats['product_type_counts'] ?? {},
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

          'apartments': {
            'count': apartmentsStats['totalApartments'] ?? 0,
            'total_value': totalApartmentsValue,
            'current_value': apartmentsCurrentValue,
            'average_area': apartmentsStats['averageArea'] ?? 0.0,
            'status_distribution': apartmentsStats['statusDistribution'] ?? {},
            'type_distribution': apartmentsStats['typeDistribution'] ?? {},
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

          // Performance metrics - tylko kapital_pozostaly dla obligacji
          'performance': {
            'total_profit_loss': 0.0, // nie uwzględniamy profit/loss
            'bonds_performance': 0.0, // nie uwzględniamy performance
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
              'apartments_percentage': totalPortfolioValue > 0
                  ? (totalApartmentsValue / totalPortfolioValue * 100)
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

      // Check for bonds with remaining capital - zmienione z wysokich odsetek na kapitał pozostały
      final bondsStats = await _bondService.getBondsStatistics();
      final totalRemainingCapital =
          bondsStats['total_remaining_capital'] ?? 0.0;

      if (totalRemainingCapital > 100000) {
        alerts.add({
          'type': 'info',
          'title': 'Wysoki kapitał pozostały',
          'message':
              'Kapitał pozostały do dyspozycji: ${totalRemainingCapital.toStringAsFixed(0)} PLN',
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
