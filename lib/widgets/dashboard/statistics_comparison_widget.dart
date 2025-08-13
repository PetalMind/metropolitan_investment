import 'package:flutter/material.dart';
import '../../theme/app_theme_professional.dart';
import '../../models_and_services.dart';

/// 🔍 WIDGET PORÓWNANIA STATYSTYK
/// Debuguje różnice między statystykami z inwestycji a inwestorów
class StatisticsComparisonWidget extends StatelessWidget {
  const StatisticsComparisonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppThemePro.premiumCardDecoration,
      child: Card(
        child: ExpansionTile(
          title: const Text(
          '🔍 Debug: Porównanie źródeł statystyk',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppThemePro.textMuted,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<StatisticsComparison>(
              future: UnifiedDashboardStatisticsService().compareStatistics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text(
                    'Błąd: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  );
                }

                final comparison = snapshot.data!;
                return _buildComparison(comparison);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparison(StatisticsComparison comparison) {
    final investmentStats = comparison.investmentBased;
    final investorStats = comparison.investorBased;
    final differences = comparison.differences;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Źródło: Investment vs Investor',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppThemePro.textPrimary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        
        _buildStatRow('Kwota inwestycji', 
          investmentStats.totalInvestmentAmount, 
          investorStats.totalInvestmentAmount,
          differences['totalInvestmentAmount']!),
        
        _buildStatRow('Kapitał pozostały', 
          investmentStats.totalRemainingCapital, 
          investorStats.totalRemainingCapital,
          differences['totalRemainingCapital']!),
        
        _buildStatRow('Kapitał zabezpieczony', 
          investmentStats.totalCapitalSecured, 
          investorStats.totalCapitalSecured,
          differences['totalCapitalSecured']!),
        
        _buildStatRow('Kapitał wykonalny', 
          investmentStats.totalViableCapital, 
          investorStats.totalViableCapital,
          differences['totalViableCapital']!),
        
        _buildStatRow('Kapitał w restrukturyzacji', 
          investmentStats.totalCapitalForRestructuring, 
          investorStats.totalCapitalForRestructuring,
          differences['totalCapitalForRestructuring']!),

        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: comparison.hasSignificantDifferences 
              ? Colors.red.withOpacity(0.1)
              : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                comparison.hasSignificantDifferences 
                  ? Icons.warning 
                  : Icons.check_circle,
                color: comparison.hasSignificantDifferences 
                  ? Colors.red 
                  : Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  comparison.hasSignificantDifferences
                    ? 'UWAGA: Wykryto znaczące różnice (>1%)'
                    : 'OK: Różnice są nieznaczące (<1%)',
                  style: TextStyle(
                    color: comparison.hasSignificantDifferences 
                      ? Colors.red 
                      : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, double investmentValue, double investorValue, double difference) {
    final hasDifference = difference.abs() > 0.01; // 1 grosz różnicy
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${investmentValue.toStringAsFixed(2)} zł',
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${investorValue.toStringAsFixed(2)} zł',
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${difference >= 0 ? '+' : ''}${difference.toStringAsFixed(2)} zł',
              style: TextStyle(
                fontSize: 11, 
                fontFamily: 'monospace',
                color: hasDifference 
                  ? (difference.abs() > investmentValue * 0.01 ? Colors.red : Colors.orange)
                  : Colors.green,
                fontWeight: hasDifference ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
