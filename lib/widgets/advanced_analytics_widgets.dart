import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/advanced_analytics_service.dart';
import '../utils/currency_formatter.dart';

/// Zaawansowany widget metryki z animacjami i interaktywnością
class AdvancedMetricCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? trend;
  final double? trendValue;
  final VoidCallback? onTap;
  final Widget? chart;
  final List<String>? additionalInfo;
  final String? tooltip;

  const AdvancedMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.trend,
    this.trendValue,
    this.onTap,
    this.chart,
    this.additionalInfo,
    this.tooltip,
  });

  @override
  State<AdvancedMetricCard> createState() => _AdvancedMetricCardState();
}

class _AdvancedMetricCardState extends State<AdvancedMetricCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.cardDecoration.copyWith(
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: widget.color.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : AppTheme.cardDecoration.boxShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildValue(),
                    if (widget.trend != null) ...[
                      const SizedBox(height: 8),
                      _buildTrend(),
                    ],
                    if (widget.chart != null) ...[
                      const SizedBox(height: 16),
                      SizedBox(height: 60, child: widget.chart!),
                    ],
                    if (widget.additionalInfo != null) ...[
                      const SizedBox(height: 12),
                      _buildAdditionalInfo(),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (widget.tooltip != null) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: widget.tooltip!,
                  padding: const EdgeInsets.all(12),
                  textStyle: const TextStyle(fontSize: 12, color: Colors.white),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundModal,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderPrimary),
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: AppTheme.textTertiary,
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.icon, color: widget.color, size: 20),
        ),
      ],
    );
  }

  Widget _buildValue() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.color,
          ),
        ),
        if (widget.subtitle.isNotEmpty)
          Text(
            widget.subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
      ],
    );
  }

  Widget _buildTrend() {
    final isPositive = widget.trendValue != null && widget.trendValue! >= 0;
    final color = isPositive ? AppTheme.successColor : AppTheme.errorColor;

    return Row(
      children: [
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          widget.trend!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.additionalInfo!.map((info) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Widget wykresu kołowego z zaawansowanymi opcjami
class AdvancedPieChart extends StatelessWidget {
  final Map<String, double> data;
  final Map<String, Color> colors;
  final String title;
  final bool showLegend;
  final bool showPercentages;

  const AdvancedPieChart({
    super.key,
    required this.data,
    required this.colors,
    required this.title,
    this.showLegend = true,
    this.showPercentages = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState(context);
    }

    final total = data.values.reduce((a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sections: _buildSections(total),
                    centerSpaceRadius: 60,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
            if (showLegend) ...[
              const SizedBox(width: 20),
              Expanded(flex: 1, child: _buildLegend(context, total)),
            ],
          ],
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(double total) {
    return data.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final color = colors[entry.key] ?? AppTheme.primaryColor;

      return PieChartSectionData(
        value: entry.value,
        title: showPercentages ? '${percentage.toStringAsFixed(1)}%' : '',
        color: color,
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: percentage > 5 ? null : Container(),
      );
    }).toList();
  }

  Widget _buildLegend(BuildContext context, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((entry) {
        final percentage = (entry.value / total) * 100;
        final color = colors[entry.key] ?? AppTheme.primaryColor;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${_formatCurrency(entry.value)} (${percentage.toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 200,
      decoration: AppTheme.cardDecoration,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Brak danych do wyświetlenia',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return CurrencyFormatter.formatCurrencyShort(amount);
  }
}

/// Widget wykresu słupkowego z animacjami
class AdvancedBarChart extends StatelessWidget {
  final Map<String, double> data;
  final String title;
  final Color color;
  final String? yAxisLabel;

  const AdvancedBarChart({
    super.key,
    required this.data,
    required this.title,
    this.color = AppTheme.primaryColor,
    this.yAxisLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState(context);
    }

    final maxY = data.values.isNotEmpty
        ? data.values.reduce((a, b) => a > b ? a : b) * 1.1
        : 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY.toDouble(),
              barGroups: _buildBarGroups(),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _formatAxisValue(value),
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      final keys = data.keys.toList();
                      if (index >= 0 && index < keys.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _truncateLabel(keys[index]),
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppTheme.textSecondary.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.black87,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final keys = data.keys.toList();
                    final key = keys[group.x];
                    return BarTooltipItem(
                      '$key\n${_formatCurrency(rod.toY)}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return data.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final value = entry.value.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: color,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 200,
      decoration: AppTheme.cardDecoration,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Brak danych do wyświetlenia',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAxisValue(double value) {
    return CurrencyFormatter.formatAxisValue(value);
  }

  String _formatCurrency(double amount) {
    return CurrencyFormatter.formatCurrencyShort(amount);
  }

  String _truncateLabel(String label) {
    if (label.length > 10) {
      return '${label.substring(0, 8)}...';
    }
    return label;
  }
}

/// Widget wykresu liniowego dla trendów czasowych
class AdvancedLineChart extends StatelessWidget {
  final List<MonthlyData> data;
  final String title;
  final Color color;
  final String yAxisLabel;

  const AdvancedLineChart({
    super.key,
    required this.data,
    required this.title,
    this.color = AppTheme.primaryColor,
    this.yAxisLabel = 'Wartość',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState(context);
    }

    final maxY =
        data.map((d) => d.totalVolume).reduce((a, b) => a > b ? a : b) * 1.1;
    final minY =
        data.map((d) => d.totalVolume).reduce((a, b) => a < b ? a : b) * 0.9;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: _buildSpots(),
                  isCurved: true,
                  color: color,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.8), color],
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: color,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _formatAxisValue(value),
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        final monthData = data[index];
                        final parts = monthData.month.split('-');
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${parts[1]}/${parts[0].substring(2)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY - minY) / 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppTheme.textSecondary.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => Colors.black87,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final monthData = data[spot.x.toInt()];
                      return LineTooltipItem(
                        '${monthData.month}\n${_formatCurrency(spot.y)}',
                        const TextStyle(color: Colors.white),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _buildSpots() {
    return data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalVolume);
    }).toList();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 200,
      decoration: AppTheme.cardDecoration,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Brak danych do wyświetlenia',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAxisValue(double value) {
    return CurrencyFormatter.formatAxisValue(value);
  }

  String _formatCurrency(double amount) {
    return CurrencyFormatter.formatCurrencyShort(amount);
  }
}

/// Widget dla alertów i powiadomień o ryzyku
class RiskAlertWidget extends StatelessWidget {
  final String title;
  final String message;
  final RiskLevel riskLevel;
  final VoidCallback? onAction;
  final String? actionText;

  const RiskAlertWidget({
    super.key,
    required this.title,
    required this.message,
    required this.riskLevel,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getRiskColor();
    final icon = _getRiskIcon();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(left: BorderSide(color: color, width: 4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (onAction != null && actionText != null)
            TextButton(onPressed: onAction, child: Text(actionText!)),
        ],
      ),
    );
  }

  Color _getRiskColor() {
    switch (riskLevel) {
      case RiskLevel.low:
        return AppTheme.successColor;
      case RiskLevel.medium:
        return AppTheme.warningColor;
      case RiskLevel.high:
        return AppTheme.errorColor;
      case RiskLevel.critical:
        return const Color(0xFF8B0000);
    }
  }

  IconData _getRiskIcon() {
    switch (riskLevel) {
      case RiskLevel.low:
        return Icons.check_circle;
      case RiskLevel.medium:
        return Icons.warning;
      case RiskLevel.high:
        return Icons.error;
      case RiskLevel.critical:
        return Icons.dangerous;
    }
  }
}

enum RiskLevel { low, medium, high, critical }
