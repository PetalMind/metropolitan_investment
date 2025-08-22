import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../../../theme/app_theme.dart';
import '../../../models/analytics/overview_analytics_models.dart';

/// Widget wykresu wydajności miesięcznej
class PerformanceChart extends StatefulWidget {
  final List<MonthlyPerformanceItem> monthlyData;

  const PerformanceChart({super.key, required this.monthlyData});

  @override
  State<PerformanceChart> createState() => _PerformanceChartState();
}

class _PerformanceChartState extends State<PerformanceChart> {
  bool _showVolume = true;
  List<FlSpot>? _touchedSpots;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trend miesięczny',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Row(
                children: [
                  _buildToggleButton('Wolumen', _showVolume, () {
                    setState(() => _showVolume = true);
                  }),
                  const SizedBox(width: 8),
                  _buildToggleButton('Zwrot', !_showVolume, () {
                    setState(() => _showVolume = false);
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.monthlyData.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 64,
                    color: AppTheme.textTertiary,
                  ),
                  SizedBox(height: 16),
                  Text('Brak danych do wyświetlenia'),
                ],
              ),
            )
          else
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  lineBarsData: _buildLineBarsData(),
                  titlesData: _buildTitlesData(),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calculateInterval(),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.textTertiary.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => AppTheme.surfaceCard,
                      getTooltipItems: _buildTooltipItems,
                    ),
                    touchCallback:
                        (FlTouchEvent event, LineTouchResponse? touchResponse) {
                          setState(() {
                            _touchedSpots = touchResponse?.lineBarSpots
                                ?.map((e) => FlSpot(e.x, e.y))
                                .toList();
                          });
                        },
                    handleBuiltInTouches: true,
                  ),
                  minY: _calculateMinY(),
                  maxY: _calculateMaxY(),
                ),
              ),
            ),
          const SizedBox(height: 16),
          _buildSummaryStats(),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData() {
    final spots = widget.monthlyData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final yValue = _showVolume
          ? data.totalVolume /
                1000000 // Convert to millions
          : data.averageReturn;
      return FlSpot(index.toDouble(), yValue);
    }).toList();

    return [
      LineChartBarData(
        spots: spots,
        isCurved: true,
        color: AppTheme.primaryColor,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            final isHovered =
                _touchedSpots?.any((s) => s.x == spot.x && s.y == spot.y) ??
                false;
            return FlDotCirclePainter(
              radius: isHovered ? 6 : 4,
              color: AppTheme.primaryColor,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.3),
              AppTheme.primaryColor.withValues(alpha: 0.1),
            ],
          ),
        ),
      ),
    ];
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: _calculateInterval(),
          getTitlesWidget: (value, meta) {
            final suffix = _showVolume ? 'M' : '%';
            return Text(
              '${value.toStringAsFixed(0)}$suffix',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: math.max(1, widget.monthlyData.length / 6),
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= widget.monthlyData.length) {
              return const SizedBox();
            }
            final monthData = widget.monthlyData[index];
            final parts = monthData.month.split('-');
            final month = parts.length > 1 ? parts[1] : '';
            return Text(
              month,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  List<LineTooltipItem> _buildTooltipItems(List<LineBarSpot> touchedSpots) {
    return touchedSpots.map((LineBarSpot touchedSpot) {
      final index = touchedSpot.x.toInt();
      if (index < 0 || index >= widget.monthlyData.length) {
        return const LineTooltipItem('', TextStyle());
      }

      final data = widget.monthlyData[index];
      final value = _showVolume ? data.totalVolume : data.averageReturn;
      final suffix = _showVolume ? 'zł' : '%';

      return LineTooltipItem(
        '${data.month}\n${_formatValue(value)}$suffix\n${data.transactionCount} transakcji',
        const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }).toList();
  }

  double _calculateMinY() {
    if (widget.monthlyData.isEmpty) return 0;

    final values = widget.monthlyData.map((data) {
      return _showVolume ? data.totalVolume / 1000000 : data.averageReturn;
    }).toList();

    final min = values.reduce((a, b) => a < b ? a : b);
    return min * 0.9; // Add some padding
  }

  double _calculateMaxY() {
    if (widget.monthlyData.isEmpty) return 100;

    final values = widget.monthlyData.map((data) {
      return _showVolume ? data.totalVolume / 1000000 : data.averageReturn;
    }).toList();

    final max = values.reduce((a, b) => a > b ? a : b);
    return max * 1.1; // Add some padding
  }

  double _calculateInterval() {
    final range = _calculateMaxY() - _calculateMinY();
    return range / 5; // 5 intervals
  }

  String _formatValue(double value) {
    if (_showVolume) {
      return '${(value / 1000000).toStringAsFixed(1)}M ';
    } else {
      return value.toStringAsFixed(1);
    }
  }

  Widget _buildSummaryStats() {
    if (widget.monthlyData.isEmpty) return const SizedBox();

    final totalVolume = widget.monthlyData.fold<double>(
      0,
      (sum, data) => sum + data.totalVolume,
    );
    final avgReturn =
        widget.monthlyData.fold<double>(
          0,
          (sum, data) => sum + data.averageReturn,
        ) /
        widget.monthlyData.length;
    final totalTransactions = widget.monthlyData.fold<int>(
      0,
      (sum, data) => sum + data.transactionCount,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          'Łączny wolumen',
          '${(totalVolume / 1000000).toStringAsFixed(1)}M zł',
        ),
        _buildStatItem('Średni zwrot', '${avgReturn.toStringAsFixed(1)}%'),
        _buildStatItem('Transakcje', '$totalTransactions'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
