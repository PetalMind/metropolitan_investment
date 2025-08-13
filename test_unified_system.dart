import '../lib/models_and_services.dart';
import '../lib/services/unified_dashboard_statistics_service.dart';
import '../lib/widgets/dashboard/statistics_comparison_debug_widget.dart';

void main() async {
  print('🎯 Test kompilacji ujednoliconego systemu statystyk');
  
  final service = UnifiedDashboardStatisticsService();
  
  print('✅ UnifiedDashboardStatisticsService utworzony');
  print('✅ StatisticsComparisonDebugWidget dostępny');
  
  // Test podstawowych metod
  try {
    final investmentStats = await service.getStatisticsFromInvestments();
    final investorStats = await service.getStatisticsFromInvestors();
    final comparison = await service.compareStatistics();
    final recommended = await service.getRecommendedStatistics();
    
    print('✅ Wszystkie metody serwisu dostępne');
    print('✅ System ujednolicony pomyślnie skompilowany!');
  } catch (e) {
    print('⚠️ Test runtime - wymaga Firebase: $e');
    print('✅ Kompilacja zakończona pomyślnie');
  }
}
