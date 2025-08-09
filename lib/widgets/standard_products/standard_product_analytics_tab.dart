import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/product.dart';
import '../../services/standard_product_investors_service.dart';

/// Zakładka z analityką dla standardowego produktu
class StandardProductAnalyticsTab extends StatefulWidget {
  final Product product;
  final StandardProductInvestorsService investorsService;
  final Function(bool) onLoading;
  final Function(String?) onError;

  const StandardProductAnalyticsTab({
    Key? key,
    required this.product,
    required this.investorsService,
    required this.onLoading,
    required this.onError,
  }) : super(key: key);

  @override
  State<StandardProductAnalyticsTab> createState() =>
      _StandardProductAnalyticsTabState();
}

class _StandardProductAnalyticsTabState
    extends State<StandardProductAnalyticsTab> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>>? _topInvestors;
  List<Map<String, dynamic>>? _trends;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    widget.onLoading(true);
    widget.onError(null);

    try {
      final futures = await Future.wait([
        widget.investorsService.getProductInvestmentStats(widget.product),
        widget.investorsService.getTopInvestorsForProduct(
          widget.product,
          limit: 10,
        ),
        widget.investorsService.getProductInvestmentTrends(widget.product),
      ]);

      if (mounted) {
        setState(() {
          _stats = futures[0] as Map<String, dynamic>;
          _topInvestors = futures[1] as List<Map<String, dynamic>>;
          _trends = futures[2] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      final errorMessage = 'Błąd podczas ładowania analityki: $e';

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
              'Błąd podczas ładowania analityki',
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
              onPressed: _loadAnalytics,
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
          // Statystyki ogólne
          _buildGeneralStats(context),

          const SizedBox(height: 32),

          // Wykres kapitału
          _buildCapitalChart(context),

          const SizedBox(height: 32),

          // Top inwestorzy
          _buildTopInvestors(context),

          const SizedBox(height: 32),

          // Trendy w czasie
          _buildTrendsChart(context),
        ],
      ),
    );
  }

  Widget _buildGeneralStats(BuildContext context) {
    if (_stats == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');

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
                  Icons.analytics_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Statystyki ogólne',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Siatka statystyk
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: [
                _buildStatCard(
                  context,
                  'Inwestorzy',
                  '${_stats!['totalInvestors']}',
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatCard(
                  context,
                  'Inwestycje',
                  '${_stats!['totalInvestments']}',
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Wartość całkowita',
                  formatter.format(_stats!['totalValue']),
                  Icons.monetization_on,
                  Colors.purple,
                ),
                _buildStatCard(
                  context,
                  'Średnia inwestycja',
                  formatter.format(_stats!['averageInvestment']),
                  Icons.trending_up,
                  Colors.orange,
                ),
                _buildStatCard(
                  context,
                  'Kapitał pozostały',
                  formatter.format(_stats!['remainingCapital']),
                  Icons.savings,
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Kapitał zrealizowany',
                  formatter.format(_stats!['realizedCapital']),
                  Icons.check_circle,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
        ],
      ),
    );
  }

  Widget _buildCapitalChart(BuildContext context) {
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
                    Icons.pie_chart,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Rozkład kapitału',
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
                  Icons.pie_chart,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Rozkład kapitału',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            SizedBox(
              height: 300,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
                        sections: [
                          PieChartSectionData(
                            value: remainingCapital,
                            title:
                                '${(remainingCapital / totalCapital * 100).toStringAsFixed(1)}%',
                            color: Colors.green,
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: realizedCapital,
                            title:
                                '${(realizedCapital / totalCapital * 100).toStringAsFixed(1)}%',
                            color: Colors.blue,
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem(
                          'Kapitał pozostały',
                          NumberFormat.currency(
                            locale: 'pl_PL',
                            symbol: 'zł',
                          ).format(remainingCapital),
                          Colors.green,
                        ),
                        const SizedBox(height: 16),
                        _buildLegendItem(
                          'Kapitał zrealizowany',
                          NumberFormat.currency(
                            locale: 'pl_PL',
                            symbol: 'zł',
                          ).format(realizedCapital),
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopInvestors(BuildContext context) {
    if (_topInvestors == null || _topInvestors!.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');

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
                  Icons.emoji_events,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Top inwestorzy',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _topInvestors!.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final investor = _topInvestors![index];
                final position = index + 1;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getPositionColor(position).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '$position',
                        style: TextStyle(
                          color: _getPositionColor(position),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    investor['clientName'] ?? 'Nieznany',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Pozostały: ${formatter.format(investor['remainingCapital'] ?? 0)}',
                  ),
                  trailing: Text(
                    formatter.format(investor['investmentAmount'] ?? 0),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsChart(BuildContext context) {
    if (_trends == null || _trends!.isEmpty) {
      return const SizedBox.shrink();
    }

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
                  Icons.timeline,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Trendy inwestycji (ostatnie 12 miesięcy)',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _trends!.length) {
                            final month = _trends![index]['month'] as String;
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                month.substring(5), // Pokazuj tylko miesiąc
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            value.toInt().toString(),
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.left,
                          );
                        },
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  minX: 0,
                  maxX: (_trends!.length - 1).toDouble(),
                  minY: 0,
                  maxY:
                      _trends!
                          .map((e) => (e['count'] as int).toDouble())
                          .reduce((a, b) => a > b ? a : b) +
                      1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _trends!.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          (entry.value['count'] as int).toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: theme.colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
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

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return Colors.blue;
    }
  }
}
