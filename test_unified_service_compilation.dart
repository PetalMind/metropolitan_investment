import 'lib/services/unified_dashboard_statistics_service.dart';
import 'lib/models_and_services.dart';

void main() {
  print('Testing UnifiedDashboardStatisticsService compilation...');
  
  final service = UnifiedDashboardStatisticsService();
  print('Service created successfully: ${service.runtimeType}');
  
  // Test model creation
  final stats = UnifiedDashboardStatistics(
    totalRemainingCapital: 100000.0,
    totalViableRemainingCapital: 90000.0,
    totalCapitalSecured: 80000.0,
    totalCapitalForRestructuring: 10000.0,
    totalActiveInvestments: 5,
    totalActiveInvestors: 3,
    sourceType: 'investment',
    calculatedAt: DateTime.now(),
  );
  
  print('Statistics model created successfully');
  print('Total remaining capital: ${stats.totalRemainingCapital}');
  print('Source type: ${stats.sourceType}');
  
  print('✅ Compilation test passed!');
}
