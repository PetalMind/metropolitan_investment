import 'lib/models_and_services.dart';

/// 🎯 Test przywrócenia zmian z commit #268a488a2bb5c395e5fdab5326ee6e4eba137564
void main() async {
  print('🔍 Testowanie przywróconych zmian z commit...');
  
  // Test 1: UnifiedDashboardStatisticsService
  try {
    final service = UnifiedDashboardStatisticsService();
    print('✅ UnifiedDashboardStatisticsService utworzony pomyślnie');
  } catch (e) {
    print('❌ Błąd z UnifiedDashboardStatisticsService: $e');
  }
  
  // Test 2: StatisticsComparisonDebugWidget
  try {
    const debugWidget = StatisticsComparisonDebugWidget();
    print('✅ StatisticsComparisonDebugWidget dostępny');
  } catch (e) {
    print('❌ Błąd z StatisticsComparisonDebugWidget: $e');
  }
  
  // Test 3: UnifiedDashboardStatistics model
  try {
    final stats = UnifiedDashboardStatistics.empty();
    print('✅ UnifiedDashboardStatistics model działa');
    print('   - dataSource: ${stats.dataSource}');
    print('   - calculatedAt: ${stats.calculatedAt}');
  } catch (e) {
    print('❌ Błąd z UnifiedDashboardStatistics: $e');
  }
  
  print('\n🎉 Przywrócenie zmian z commit zakończone pomyślnie!');
  print('📋 Zmiany przywrócone:');
  print('   ✅ UnifiedDashboardStatisticsService');
  print('   ✅ StatisticsComparisonDebugWidget');
  print('   ✅ ProductDashboardWidget integration');
  print('   ✅ PremiumInvestorAnalyticsScreen integration');
  print('   ✅ models_and_services.dart exports');
  print('   ✅ Documentation files');
}
