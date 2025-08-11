import 'package:flutter/foundation.dart';
import '../models_and_services.dart';
import '../services/investment_service.dart';
import '../services/client_service.dart';
import '../services/employee_service.dart';
import '../services/firebase_functions_data_service.dart';
import 'base_service.dart';

class DashboardService extends BaseService {
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

  // Legacy method - get complete dashboard data (now uses unified services)
  Future<Map<String, dynamic>> getDashboardData() async {
    return getCachedData('dashboard_complete', () async {
      try {
        // Execute all requests in parallel for better performance
        // Now using unified investment service for all product types
        final results = await Future.wait([
          _investmentService.getInvestmentStatistics(),
          _clientService.getClientStats(),
          _employeeService.getEmployeesCount(),
        ]);

        final investmentStats = results[0] as Map<String, dynamic>;
        final clientStats = results[1] as Map<String, dynamic>;
        final employeesCount = results[2] as int;

        // Calculate total portfolio value from unified investment stats
        final totalPortfolioValue = investmentStats['totalValue'] ?? 0.0;

        // Calculate current value from unified investment stats
        final currentValue = investmentStats['totalRemainingCapital'] ?? 0.0;
        0.0;

        return {
          // Overview stats - now from unified investment statistics
          'total_portfolio_value': totalPortfolioValue,
          'total_clients': clientStats['total_clients'] ?? 0,
          'total_employees': employeesCount,
          'total_active_investments': investmentStats['activeCount'] ?? 0,

          // Unified investments (replaces individual product type stats)
          'investments': {
            'total_count': investmentStats['totalCount'] ?? 0,
            'active_count': investmentStats['activeCount'] ?? 0,
            'total_value': totalPortfolioValue,
            'current_value': currentValue,
            'product_type_distribution':
                investmentStats['productTypeDistribution'] ?? {},
            'status_distribution': investmentStats['statusDistribution'] ?? {},
          },

          // Legacy sections (maintained for backward compatibility - now use unified data)
          'bonds': {
            'count': investmentStats['bondCount'] ?? 0,
            'total_value': investmentStats['bondValue'] ?? 0.0,
            'current_value': investmentStats['bondRemainingCapital'] ?? 0.0,
            'remaining_capital': investmentStats['bondRemainingCapital'] ?? 0.0,
          },

          'loans': {
            'count': investmentStats['loanCount'] ?? 0,
            'total_value': investmentStats['loanValue'] ?? 0.0,
            'average_amount': investmentStats['averageLoanAmount'] ?? 0.0,
          },

          'shares': {
            'count': investmentStats['shareCount'] ?? 0,
            'total_value': investmentStats['shareValue'] ?? 0.0,
            'total_shares_count': investmentStats['totalSharesCount'] ?? 0,
            'average_price_per_share':
                investmentStats['averageSharePrice'] ?? 0.0,
          },

          'apartments': {
            'count': investmentStats['apartmentCount'] ?? 0,
            'total_value': investmentStats['apartmentValue'] ?? 0.0,
            'current_value':
                investmentStats['apartmentRemainingCapital'] ?? 0.0,
            'average_area': investmentStats['averageApartmentArea'] ?? 0.0,
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

          // Performance metrics - unified approach
          'performance': {
            'total_profit_loss': 0.0, // Simplified - not tracking detailed P&L
            'portfolio_diversification':
                investmentStats['productTypeDistribution'] ?? {},
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

  // Get top performers across all asset types (now unified)
  Future<Map<String, dynamic>> getTopPerformers() async {
    return getCachedData('top_performers', () async {
      try {
        // Get active investments and sort by remaining capital
        final investmentsStream = _investmentService.getInvestmentsByStatus(
          InvestmentStatus.active,
        );
        final allInvestments = await investmentsStream.first;

        // Sort by remaining capital descending and take top 15
        allInvestments.sort(
          (a, b) => b.remainingCapital.compareTo(a.remainingCapital),
        );
        final topInvestments = allInvestments.take(15).toList();

        // Group by product type
        final topBonds = topInvestments
            .where(
              (inv) =>
                  inv.productType.toString().toLowerCase().contains('bond'),
            )
            .take(5)
            .toList();
        final topShares = topInvestments
            .where(
              (inv) =>
                  inv.productType.toString().toLowerCase().contains('share'),
            )
            .take(5)
            .toList();
        final topLoans = topInvestments
            .where(
              (inv) =>
                  inv.productType.toString().toLowerCase().contains('loan'),
            )
            .take(5)
            .toList();

        return {
          'top_bonds': topBonds
              .map(
                (inv) => {
                  'id': inv.id,
                  'clientName': inv.clientName,
                  'remainingCapital': inv.remainingCapital,
                  'productName': inv.productName,
                },
              )
              .toList(),
          'top_shares': topShares
              .map(
                (inv) => {
                  'id': inv.id,
                  'clientName': inv.clientName,
                  'remainingCapital': inv.remainingCapital,
                  'productName': inv.productName,
                },
              )
              .toList(),
          'largest_loans': topLoans
              .map(
                (inv) => {
                  'id': inv.id,
                  'clientName': inv.clientName,
                  'remainingCapital': inv.remainingCapital,
                  'productName': inv.productName,
                },
              )
              .toList(),
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

      // Check investment statistics (now unified)
      final investmentStats = await _investmentService
          .getInvestmentStatistics();
      final totalRemainingCapital =
          investmentStats['totalRemainingCapital'] ?? 0.0;

      if (totalRemainingCapital > 100000) {
        alerts.add({
          'type': 'info',
          'title': 'Wysoki kapitał pozostały',
          'message':
              'Kapitał pozostały do dyspozycji: ${totalRemainingCapital.toStringAsFixed(0)} PLN',
          'action': 'investments_view',
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
