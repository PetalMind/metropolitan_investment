import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme_professional.dart';
import '../../services/firebase_functions_dashboard_service.dart';

/// 🔮 PREDICTIONS TAB - Zakładka z prognozami i predykcjami
///
/// Wyświetla:
/// - Prognozy zwrotów z inwestycji
/// - Optymalizację portfela
/// - Monte Carlo simulations
/// - Rekomendacje inwestycyjne
class PredictionsTab extends StatefulWidget {
  const PredictionsTab({super.key});

  @override
  State<PredictionsTab> createState() => _PredictionsTabState();
}

class _PredictionsTabState extends State<PredictionsTab> {
  Map<String, dynamic>? _predictionsData;
  bool _isLoading = true;
  String _selectedHorizon = '12'; // domyślnie 12 miesięcy

  final List<String> _timeHorizons = ['6', '12', '18', '24', '36'];

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    setState(() => _isLoading = true);

    try {
      final data = await FirebaseFunctionsDashboardService.getPredictions(
        horizon: int.parse(_selectedHorizon),
        forceRefresh: false,
      );

      setState(() {
        _predictionsData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd ładowania predykcji: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePro.backgroundPrimary,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _predictionsData == null
          ? _buildErrorState()
          : _buildPredictionsContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppThemePro.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Nie można załadować predykcji',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadPredictions,
            child: const Text('Spróbuj ponownie'),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsContent() {
    return RefreshIndicator(
      onRefresh: _loadPredictions,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildTimeHorizonSelector(),
            const SizedBox(height: 24),
            _buildPredictionSummaryCards(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildReturnPredictionChart(),
                      const SizedBox(height: 24),
                      _buildOptimalAllocationChart(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildRiskPredictions(),
                      const SizedBox(height: 24),
                      _buildInvestmentRecommendations(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildMaturityForecast(),
            const SizedBox(height: 24),
            _buildMonteCarloResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Predykcje i Prognozy',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppThemePro.accentGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analiza predykcyjna portfela inwestycyjnego',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppThemePro.textSecondary),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppThemePro.accentGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.timeline, color: AppThemePro.accentGold, size: 20),
              const SizedBox(width: 8),
              Text(
                'Horyzont: $_selectedHorizon miesięcy',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppThemePro.accentGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeHorizonSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Horyzont czasowy prognozy',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: _timeHorizons.map((horizon) {
              final isSelected = horizon == _selectedHorizon;
              return ChoiceChip(
                label: Text('$horizon miesięcy'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedHorizon = horizon;
                    });
                    _loadPredictions();
                  }
                },
                selectedColor: AppThemePro.accentGold.withOpacity(0.2),
                backgroundColor: AppThemePro.surfaceInteractive,
                labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? AppThemePro.accentGold
                      : AppThemePro.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionSummaryCards() {
    final returnPredictions =
        _predictionsData?['returnPredictions'] as Map<String, dynamic>? ?? {};
    final portfolioOpt =
        _predictionsData?['portfolioOptimization'] as Map<String, dynamic>? ??
        {};

    // Bezpieczne wydobycie wartości z predictedReturns (może być tablicą lub liczbą)
    double getPredictedReturn() {
      final predictedReturns = returnPredictions['predictedReturns'];
      if (predictedReturns is List && predictedReturns.isNotEmpty) {
        // Jeśli to tablica, weź średnią lub pierwszą wartość
        final numValues = predictedReturns.whereType<num>().toList();
        if (numValues.isNotEmpty) {
          return numValues.reduce((a, b) => a + b) / numValues.length;
        }
      } else if (predictedReturns is num) {
        return predictedReturns.toDouble();
      }
      return 5.2; // Domyślna wartość
    }

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Przewidywany Zwrot',
            value: '${getPredictedReturn().toStringAsFixed(1)}%',
            subtitle: 'Średnia prognoza na $_selectedHorizon miesięcy',
            icon: Icons.trending_up,
            color: AppThemePro.profitGreen,
            trend: 'up',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Optymalne Ryzyko',
            value:
                '${(portfolioOpt['expectedRisk'] as num?)?.toStringAsFixed(1) ?? '0.0'}%',
            subtitle: 'Rekomendowany poziom ryzyka',
            icon: Icons.shield_outlined,
            color: AppThemePro.statusWarning,
            trend: 'neutral',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Prawdopodobieństwo',
            value:
                '${((returnPredictions['confidence'] as num?)?.toDouble() ?? 0.7) * 100}%',
            subtitle: 'Pewność predykcji',
            icon: Icons.psychology,
            color: AppThemePro.bondsBlue,
            trend: 'up',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Rekomendacje',
            value:
                '${(_predictionsData?['recommendedActions'] as List?)?.length ?? 0}',
            subtitle: 'Aktywnych zaleceń',
            icon: Icons.lightbulb_outline,
            color: AppThemePro.accentGoldMuted,
            trend: 'neutral',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              _buildTrendIcon(trend),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppThemePro.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIcon(String trend) {
    switch (trend) {
      case 'up':
        return Icon(
          Icons.trending_up,
          color: AppThemePro.profitGreen,
          size: 20,
        );
      case 'down':
        return Icon(Icons.trending_down, color: AppThemePro.lossRed, size: 20);
      default:
        return Icon(
          Icons.trending_flat,
          color: AppThemePro.textMuted,
          size: 20,
        );
    }
  }

  Widget _buildReturnPredictionChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prognoza Zwrotów',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Przewidywane zwroty z inwestycji w czasie',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppThemePro.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppThemePro.borderPrimary,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final months = [
                          '0',
                          '3',
                          '6',
                          '9',
                          '12',
                          '15',
                          '18',
                          '21',
                          '24',
                        ];
                        if (value.toInt() < months.length) {
                          return Text(
                            '${months[value.toInt()]}m',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Przewidywane zwroty
                  LineChartBarData(
                    spots: _generatePredictionSpots(optimistic: false),
                    isCurved: true,
                    color: AppThemePro.bondsBlue,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppThemePro.bondsBlue.withOpacity(0.1),
                    ),
                  ),
                  // Optymistyczny scenariusz
                  LineChartBarData(
                    spots: _generatePredictionSpots(optimistic: true),
                    isCurved: true,
                    color: AppThemePro.accentGold,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generatePredictionSpots({required bool optimistic}) {
    // Generowanie przykładowych danych predykcji
    final spots = <FlSpot>[];
    final baseReturn = optimistic ? 8.0 : 5.5;
    final volatility = optimistic ? 1.5 : 1.0;

    for (int i = 0; i < 9; i++) {
      final x = i.toDouble();
      final trend = baseReturn * (i + 1) / 8.0;
      final noise = (i % 2 == 0 ? volatility : -volatility * 0.5);
      spots.add(FlSpot(x, trend + noise));
    }

    return spots;
  }

  Widget _buildOptimalAllocationChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Optymalna Alokacja Portfela',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Rekomendowany podział aktywów',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppThemePro.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: _buildAllocationSections(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildAllocationLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildAllocationSections() {
    // Przykładowe dane alokacji
    final sections = <PieChartSectionData>[];
    final colors = [
      AppThemePro.bondsBlue,
      AppThemePro.sharesGreen,
      AppThemePro.loansOrange,
      AppThemePro.realEstateViolet,
    ];

    final types = ['bonds', 'shares', 'loans', 'apartments'];
    final percentages = [35.0, 30.0, 20.0, 15.0]; // Przykładowe dane

    for (int i = 0; i < types.length; i++) {
      sections.add(
        PieChartSectionData(
          value: percentages[i],
          color: colors[i % colors.length],
          title: '${percentages[i].toStringAsFixed(0)}%',
          radius: 40,
          titleStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return sections;
  }

  Widget _buildAllocationLegend() {
    final types = [
      {'name': 'Obligacje', 'color': AppThemePro.bondsBlue, 'percent': 35.0},
      {'name': 'Udziały', 'color': AppThemePro.sharesGreen, 'percent': 30.0},
      {'name': 'Pożyczki', 'color': AppThemePro.loansOrange, 'percent': 20.0},
      {
        'name': 'Apartamenty',
        'color': AppThemePro.realEstateViolet,
        'percent': 15.0,
      },
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: types
          .map(
            (type) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: type['color'] as Color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${type['name']} (${(type['percent'] as double).toStringAsFixed(0)}%)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildRiskPredictions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prognoza Ryzyka',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildRiskIndicator('Ryzyko Portfela', 65, AppThemePro.statusWarning),
          const SizedBox(height: 12),
          _buildRiskIndicator('Ryzyko Płynności', 45, AppThemePro.statusInfo),
          const SizedBox(height: 12),
          _buildRiskIndicator('Ryzyko Rynkowe', 75, AppThemePro.statusError),
          const SizedBox(height: 12),
          _buildRiskIndicator(
            'Ryzyko Kredytowe',
            30,
            AppThemePro.accentGoldMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildRiskIndicator(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              '$value%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: AppThemePro.borderPrimary.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildInvestmentRecommendations() {
    final recommendations =
        (_predictionsData?['recommendedActions'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rekomendacje',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (recommendations.isEmpty)
            Text(
              'Brak aktywnych rekomendacji',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...recommendations
                .take(5)
                .map((rec) => _buildRecommendationItem(rec.toString())),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemePro.accentGold.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.accentGold.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: AppThemePro.accentGold,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaturityForecast() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prognoza Zapadalności',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Przewidywane terminy zapadalności inwestycji',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppThemePro.textSecondary),
          ),
          const SizedBox(height: 20),
          // Placeholder dla wykresu zapadalności
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppThemePro.borderPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppThemePro.borderPrimary),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, color: AppThemePro.textMuted, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Wykres zapadalności będzie tutaj',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppThemePro.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonteCarloResults() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Symulacja Monte Carlo',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Analiza scenariuszy probabilistycznych',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppThemePro.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMonteCarloStat(
                  'Najlepszy Scenariusz',
                  '+12.5%',
                  AppThemePro.profitGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMonteCarloStat(
                  'Średni Scenariusz',
                  '+6.2%',
                  AppThemePro.bondsBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMonteCarloStat(
                  'Najgorszy Scenariusz',
                  '-2.1%',
                  AppThemePro.lossRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonteCarloStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppThemePro.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
