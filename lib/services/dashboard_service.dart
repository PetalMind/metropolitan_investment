import '../services/bond_service.dart';
import '../services/loan_service.dart';
import '../services/share_service.dart';
import '../services/investment_service.dart';
import '../services/client_service.dart';
import '../services/employee_service.dart';
import 'base_service.dart';

class DashboardService extends BaseService {
  final BondService _bondService = BondService();
  final LoanService _loanService = LoanService();
  final ShareService _shareService = ShareService();
  final InvestmentService _investmentService = InvestmentService();
  final ClientService _clientService = ClientService();
  final EmployeeService _employeeService = EmployeeService();

  // Get complete dashboard data
  Future<Map<String, dynamic>> getDashboardData() async {
    return getCachedData('dashboard_complete', () async {
      try {
        // Execute all requests in parallel for better performance
        final results = await Future.wait([
          _bondService.getBondsStatistics(),
          _loanService.getLoansStatistics(),
          _shareService.getSharesStatistics(),
          _investmentService.getInvestmentStatistics(),
          _clientService.getClientStats(),
          _employeeService.getEmployeesCount(),
        ]);

        final bondsStats = results[0] as Map<String, dynamic>;
        final loansStats = results[1] as Map<String, dynamic>;
        final sharesStats = results[2] as Map<String, dynamic>;
        final investmentStats = results[3] as Map<String, dynamic>;
        final clientStats = results[4] as Map<String, dynamic>;
        final employeesCount = results[5] as int;

        // Calculate total portfolio value
        final totalBondsValue = bondsStats['total_investment_amount'] ?? 0.0;
        final totalLoansValue = loansStats['total_investment_amount'] ?? 0.0;
        final totalSharesValue = sharesStats['total_investment_amount'] ?? 0.0;
        final totalInvestmentsValue = investmentStats['totalValue'] ?? 0.0;

        final totalPortfolioValue =
            totalBondsValue +
            totalLoansValue +
            totalSharesValue +
            totalInvestmentsValue;

        // Calculate current value (remaining + realized)
        final bondsCurrentValue =
            (bondsStats['total_remaining_capital'] ?? 0.0) +
            (bondsStats['total_remaining_interest'] ?? 0.0) +
            (bondsStats['total_realized_capital'] ?? 0.0) +
            (bondsStats['total_realized_interest'] ?? 0.0);

        return {
          // Overview stats
          'total_portfolio_value': totalPortfolioValue,
          'total_clients': clientStats['total_clients'] ?? 0,
          'total_employees': employeesCount,
          'total_active_investments': investmentStats['activeCount'] ?? 0,

          // Detailed breakdowns
          'bonds': {
            'count': bondsStats['total_count'] ?? 0,
            'total_value': totalBondsValue,
            'current_value': bondsCurrentValue,
            'realized_profit':
                (bondsStats['total_realized_capital'] ?? 0.0) +
                (bondsStats['total_realized_interest'] ?? 0.0),
            'remaining_capital': bondsStats['total_remaining_capital'] ?? 0.0,
            'remaining_interest': bondsStats['total_remaining_interest'] ?? 0.0,
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
