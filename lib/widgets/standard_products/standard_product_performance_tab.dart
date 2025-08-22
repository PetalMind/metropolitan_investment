import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../services/standard_product_investors_service.dart';

/// Zakładka z wydajnością dla standardowego produktu
class StandardProductPerformanceTab extends StatefulWidget {
  final Product product;
  final StandardProductInvestorsService investorsService;
  final Function(bool) onLoading;
  final Function(String?) onError;

  const StandardProductPerformanceTab({
    super.key,
    required this.product,
    required this.investorsService,
    required this.onLoading,
    required this.onError,
  });

  @override
  State<StandardProductPerformanceTab> createState() =>
      _StandardProductPerformanceTabState();
}

class _StandardProductPerformanceTabState
    extends State<StandardProductPerformanceTab> {
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    widget.onLoading(true);
    widget.onError(null);

    try {
      final stats = await widget.investorsService.getProductInvestmentStats(
        widget.product,
      );

      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      final errorMessage = 'Błąd podczas ładowania danych wydajności: $e';

      if (mounted) {
        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }

      widget.onError(errorMessage);
    } finally {
      widget.onLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Błąd podczas ładowania wydajności',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPerformanceData,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wskaźniki wydajności
          _buildPerformanceMetrics(context),

          const SizedBox(height: 32),

          // Wykres realizacji
          _buildRealizationChart(context),

          const SizedBox(height: 32),

          // Analiza ryzyka
          _buildRiskAnalysis(context),

          const SizedBox(height: 32),

          // Prognoza
          _buildForecast(context),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(BuildContext context) {
    if (_stats == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');

    final totalValue = _stats!['totalValue'] as double;
    final remainingCapital = _stats!['remainingCapital'] as double;
    final realizedCapital = _stats!['realizedCapital'] as double;
    final activeInvestments = _stats!['activeInvestments'] as int;
    final totalInvestments = _stats!['totalInvestments'] as int;

    final realizationRate = totalValue > 0
        ? (realizedCapital / totalValue * 100)
        : 0.0;
    final activeRate = totalInvestments > 0
        ? (activeInvestments / totalInvestments * 100)
        : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Wskaźniki wydajności',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Główne wskaźniki
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
              children: [
                _buildMetricCard(
                  context,
                  'Stopień realizacji',
                  '${realizationRate.toStringAsFixed(1)}%',
                  Icons.pie_chart,
                  _getPerformanceColor(realizationRate),
                  subtitle: formatter.format(realizedCapital),
                ),
                _buildMetricCard(
                  context,
                  'Aktywne inwestycje',
                  '${activeRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  _getPerformanceColor(activeRate),
                  subtitle: '$activeInvestments z $totalInvestments',
                ),
                _buildMetricCard(
                  context,
                  'Kapitał w toku',
                  formatter.format(remainingCapital),
                  Icons.hourglass_empty,
                  Colors.orange,
                  subtitle: 'Do realizacji',
                ),
                _buildMetricCard(
                  context,
                  'Efektywność',
                  _calculateEfficiency(),
                  Icons.analytics,
                  _getEfficiencyColor(),
                  subtitle: 'Ocena ogólna',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRealizationChart(BuildContext context) {
    if (_stats == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final remainingCapital = _stats!['remainingCapital'] as double;
    final realizedCapital = _stats!['realizedCapital'] as double;
    final totalCapital = remainingCapital + realizedCapital;

    if (totalCapital == 0) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.donut_large,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Realizacja kapitału',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                'Brak danych o kapitale',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final realizationPercent = (realizedCapital / totalCapital * 100);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.donut_large,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Realizacja kapitału',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getPerformanceColor(
                      realizationPercent,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${realizationPercent.toStringAsFixed(1)}% zrealizowane',
                    style: TextStyle(
                      color: _getPerformanceColor(realizationPercent),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Pasek postępu
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Postęp realizacji',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${realizationPercent.toStringAsFixed(1)}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getPerformanceColor(realizationPercent),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: realizationPercent / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getPerformanceColor(realizationPercent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildProgressLegend(
                        'Zrealizowany',
                        NumberFormat.currency(
                          locale: 'pl_PL',
                          symbol: 'zł',
                        ).format(realizedCapital),
                        _getPerformanceColor(realizationPercent),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProgressLegend(
                        'Pozostały',
                        NumberFormat.currency(
                          locale: 'pl_PL',
                          symbol: 'zł',
                        ).format(remainingCapital),
                        Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressLegend(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRiskAnalysis(BuildContext context) {
    final theme = Theme.of(context);
    final riskLevel = _calculateRiskLevel();
    final riskColor = _getRiskColor(riskLevel);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Analiza ryzyka',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Poziom ryzyka produktu',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: riskColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          riskLevel,
                          style: TextStyle(
                            color: riskColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Płynność',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getLiquidityLevel(),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: _getLiquidityColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Czynniki ryzyka
            Text(
              'Główne czynniki ryzyka:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            ..._getRiskFactors().map(
              (factor) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(factor, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecast(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Prognoza i rekomendacje',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Prognoza czasowa
            if (widget.product.maturityDate != null) ...[
              _buildForecastItem(
                context,
                Icons.event,
                'Przewidywany czas realizacji',
                _getTimeToMaturity(),
                Colors.blue,
              ),
              const SizedBox(height: 16),
            ],

            _buildForecastItem(
              context,
              Icons.trending_up,
              'Potencjał wzrostu',
              _getGrowthPotential(),
              Colors.green,
            ),

            const SizedBox(height: 16),

            _buildForecastItem(
              context,
              Icons.recommend,
              'Rekomendacja',
              _getRecommendation(),
              _getRecommendationColor(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 50) return Colors.amber;
    if (percentage >= 25) return Colors.orange;
    return Colors.red;
  }

  String _calculateEfficiency() {
    if (_stats == null) return 'Brak danych';

    final totalValue = _stats!['totalValue'] as double;
    final realizedCapital = _stats!['realizedCapital'] as double;
    final activeInvestments = _stats!['activeInvestments'] as int;
    final totalInvestments = _stats!['totalInvestments'] as int;

    if (totalValue == 0 || totalInvestments == 0) return 'Niedostępne';

    final realizationRate = (realizedCapital / totalValue * 100);
    final activeRate = (activeInvestments / totalInvestments * 100);
    final efficiency = (realizationRate + activeRate) / 2;

    if (efficiency >= 80) return 'Wysoka';
    if (efficiency >= 60) return 'Średnia';
    if (efficiency >= 40) return 'Niska';
    return 'Bardzo niska';
  }

  Color _getEfficiencyColor() {
    final efficiency = _calculateEfficiency();
    switch (efficiency) {
      case 'Wysoka':
        return Colors.green;
      case 'Średnia':
        return Colors.amber;
      case 'Niska':
        return Colors.orange;
      case 'Bardzo niska':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _calculateRiskLevel() {
    switch (widget.product.type) {
      case ProductType.bonds:
        return 'Niskie';
      case ProductType.shares:
        return 'Wysokie';
      case ProductType.loans:
        return 'Średnie';
      case ProductType.apartments:
        return 'Średnie';
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'Niskie':
        return Colors.green;
      case 'Średnie':
        return Colors.orange;
      case 'Wysokie':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getLiquidityLevel() {
    switch (widget.product.type) {
      case ProductType.bonds:
        return 'Wysoka';
      case ProductType.shares:
        return 'Wysoka';
      case ProductType.loans:
        return 'Niska';
      case ProductType.apartments:
        return 'Bardzo niska';
    }
  }

  Color _getLiquidityColor() {
    final liquidity = _getLiquidityLevel();
    switch (liquidity) {
      case 'Bardzo niska':
        return Colors.red;
      case 'Niska':
        return Colors.orange;
      case 'Średnia':
        return Colors.amber;
      case 'Wysoka':
        return Colors.lightGreen;
      default:
        return Colors.grey;
    }
  }

  List<String> _getRiskFactors() {
    switch (widget.product.type) {
      case ProductType.bonds:
        return [
          'Ryzyko stopy procentowej',
          'Ryzyko kredytowe emitenta',
          'Ryzyko płynności rynku',
        ];
      case ProductType.shares:
        return [
          'Ryzyko rynkowe',
          'Ryzyko specyficzne spółki',
          'Ryzyko płynności',
          'Ryzyko regulacyjne',
        ];
      case ProductType.loans:
        return [
          'Ryzyko kredytowe pożyczkobiorcy',
          'Ryzyko braku zabezpieczeń',
          'Ryzyko przedterminowej spłaty',
        ];
      case ProductType.apartments:
        return [
          'Ryzyko rynku nieruchomości',
          'Ryzyko lokalizacji',
          'Ryzyko płynności',
          'Ryzyko kosztów utrzymania',
        ];
    }
  }

  String _getTimeToMaturity() {
    if (widget.product.maturityDate == null) return 'Brak daty zapadalności';

    final now = DateTime.now();
    final difference = widget.product.maturityDate!.difference(now);

    if (difference.isNegative) {
      return 'Produkt przedawniony';
    }

    final days = difference.inDays;
    if (days < 30) {
      return '$days dni';
    } else if (days < 365) {
      final months = (days / 30).round();
      return '$months miesięcy';
    } else {
      final years = (days / 365).round();
      return '$years lat';
    }
  }

  String _getGrowthPotential() {
    if (_stats == null) return 'Brak danych';

    final activeInvestments = _stats!['activeInvestments'] as int;
    final totalInvestments = _stats!['totalInvestments'] as int;

    if (totalInvestments == 0) return 'Niedostępne';

    final activeRate = (activeInvestments / totalInvestments * 100);

    if (activeRate >= 75) return 'Wysoki';
    if (activeRate >= 50) return 'Średni';
    if (activeRate >= 25) return 'Niski';
    return 'Bardzo niski';
  }

  String _getRecommendation() {
    if (_stats == null) return 'Brak danych';

    final totalValue = _stats!['totalValue'] as double;
    final realizedCapital = _stats!['realizedCapital'] as double;
    final activeInvestments = _stats!['activeInvestments'] as int;
    final totalInvestments = _stats!['totalInvestments'] as int;

    if (totalValue == 0 || totalInvestments == 0) return 'Monitoring';

    final realizationRate = (realizedCapital / totalValue * 100);
    final activeRate = (activeInvestments / totalInvestments * 100);

    if (realizationRate >= 75 && activeRate >= 75) {
      return 'Silnie rekomendowany';
    }
    if (realizationRate >= 50 && activeRate >= 50) return 'Rekomendowany';
    if (realizationRate >= 25 || activeRate >= 25) {
      return 'Ostrożnie rekomendowany';
    }
    return 'Nie rekomendowany';
  }

  Color _getRecommendationColor() {
    final recommendation = _getRecommendation();
    switch (recommendation) {
      case 'Silnie rekomendowany':
        return Colors.green;
      case 'Rekomendowany':
        return Colors.lightGreen;
      case 'Ostrożnie rekomendowany':
        return Colors.orange;
      case 'Nie rekomendowany':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
