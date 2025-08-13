import '../lib/models_and_services.dart';

/// 🚀 TEST ZUNIFIKOWANYCH STATYSTYK DASHBOARD
/// Sprawdza czy oba źródła statystyk dają spójne wyniki

void main() async {
  print('🚀 Starting Unified Dashboard Statistics Test...');

  final service = UnifiedDashboardStatisticsService();

  try {
    print('📊 Testing statistics comparison...');
    final comparison = await service.compareStatistics();

    print('\n📈 STATISTICS COMPARISON RESULTS:');
    print('=' * 50);

    print('\nINVESTMENT-BASED (Dashboard approach):');
    print('- Source: ${comparison.investmentBased.dataSource}');
    print(
      '- Total Investment Amount: ${comparison.investmentBased.totalInvestmentAmount.toStringAsFixed(2)} zł',
    );
    print(
      '- Total Remaining Capital: ${comparison.investmentBased.totalRemainingCapital.toStringAsFixed(2)} zł',
    );
    print(
      '- Total Capital Secured: ${comparison.investmentBased.totalCapitalSecured.toStringAsFixed(2)} zł',
    );
    print(
      '- Total Viable Capital: ${comparison.investmentBased.totalViableCapital.toStringAsFixed(2)} zł',
    );
    print(
      '- Total Restructuring Capital: ${comparison.investmentBased.totalCapitalForRestructuring.toStringAsFixed(2)} zł',
    );

    print('\nINVESTOR-BASED (Premium Analytics approach):');
    print('- Source: ${comparison.investorBased.dataSource}');
    print(
      '- Total Investment Amount: ${comparison.investorBased.totalInvestmentAmount.toStringAsFixed(2)} zł',
    );
    print(
      '- Total Remaining Capital: ${comparison.investorBased.totalRemainingCapital.toStringAsFixed(2)} zł',
    );
    print(
      '- Total Capital Secured: ${comparison.investorBased.totalCapitalSecured.toStringAsFixed(2)} zł',
    );
    print(
      '- Total Viable Capital: ${comparison.investorBased.totalViableCapital.toStringAsFixed(2)} zł',
    );
    print(
      '- Total Restructuring Capital: ${comparison.investorBased.totalCapitalForRestructuring.toStringAsFixed(2)} zł',
    );

    print('\nDIFFERENCES (Investment - Investor):');
    print('=' * 30);
    comparison.differences.forEach((key, difference) {
      final percentDiff = comparison.investmentBased.totalInvestmentAmount > 0
          ? (difference /
                comparison.investmentBased.totalInvestmentAmount *
                100)
          : 0.0;

      print(
        '- $key: ${difference.toStringAsFixed(2)} zł (${percentDiff.toStringAsFixed(2)}%)',
      );
    });

    print('\n🔍 ANALYSIS:');
    if (comparison.hasSignificantDifferences) {
      print('❌ SIGNIFICANT DIFFERENCES DETECTED (>1%)');
      print('   This indicates the two approaches calculate different values.');
      print('   Investigation needed to determine which is correct.');
    } else {
      print('✅ NO SIGNIFICANT DIFFERENCES (<1%)');
      print('   The two approaches are now UNIFIED and consistent!');
    }

    print('\n📋 EXPLANATION OF DIFFERENCES:');
    print('- Investment-based: Sums raw investment.remainingCapital');
    print(
      '- Investor-based: Sums investor.viableRemainingCapital (filters out non-viable investments)',
    );
    print(
      '- viableRemainingCapital excludes investments that are not executable',
    );
    print('- This is WHY we see different values - it\'s by design!');
  } catch (e) {
    print('❌ Error during test: $e');
    print('Stack trace:');
    print(e);
  }

  print('\n🏁 Test completed!');
}
