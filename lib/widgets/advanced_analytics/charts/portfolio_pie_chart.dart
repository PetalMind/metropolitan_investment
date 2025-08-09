import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';
import '../../../models/product.dart';

/// 🥧 PORTFOLIO PIE CHART COMPONENT
/// Displays portfolio distribution by product type or status
class PortfolioPieChart extends StatefulWidget {
  final Map<String, dynamic> data;
  final String title;
  final String? subtitle;
  final bool showLegend;
  final bool isLoading;

  const PortfolioPieChart({
    super.key,
    required this.data,
    required this.title,
    this.subtitle,
    this.showLegend = true,
    this.isLoading = false,
  });

  @override
  State<PortfolioPieChart> createState() => _PortfolioPieChartState();
}

class _PortfolioPieChartState extends State<PortfolioPieChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          if (widget.isLoading)
            _buildLoadingState()
          else if (widget.data.isEmpty)
            _buildEmptyState()
          else
            _buildChart(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Ładowanie danych...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Brak danych do wyświetlenia',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return SizedBox(
      height: 300,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = null;
                        return;
                      }
                      touchedIndex = pieTouchResponse
                          .touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: _buildPieSections(),
                centerSpaceRadius: 50,
                sectionsSpace: 2,
              ),
            ),
          ),
          if (widget.showLegend) ...[
            const SizedBox(width: 20),
            Expanded(
              flex: 1,
              child: _buildLegend(),
            ),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final entries = widget.data.entries.toList();
    final total = entries.fold<double>(0, (sum, entry) {
      final value = entry.value;
      if (value is num) return sum + value.toDouble();
      return sum;
    });

    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final dataEntry = entry.value;
      final isTouched = index == touchedIndex;
      final value = dataEntry.value is num ? dataEntry.value.toDouble() : 0.0;
      final percentage = total > 0 ? (value / total * 100) : 0.0;
      
      return PieChartSectionData(
        color: _getColorForIndex(index),
        value: value,
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 90 : 80,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.data.entries.toList().asMap().entries.map((entry) {
        final index = entry.key;
        final dataEntry = entry.value;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getColorForIndex(index),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatLegendLabel(dataEntry.key),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getColorForIndex(int index) {
    const colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryGold,
      AppTheme.successColor,
      AppTheme.infoColor,
      AppTheme.warningColor,
      AppTheme.errorColor,
      Color(0xFF8E24AA),
      Color(0xFF00ACC1),
      Color(0xFF8BC34A),
      Color(0xFFFF7043),
    ];
    return colors[index % colors.length];
  }

  String _formatLegendLabel(String key) {
    // Convert enum-like keys to readable labels
    if (key.contains('InvestmentStatus.')) {
      return key.replaceAll('InvestmentStatus.', '').replaceAll('_', ' ');
    }
    if (key.contains('ProductType.')) {
      return _getProductTypeName(key);
    }
    return key;
  }

  String _getProductTypeName(String enumValue) {
    switch (enumValue) {
      case 'ProductType.bonds':
      case 'bonds':
        return 'Obligacje';
      case 'ProductType.shares':
      case 'shares':
        return 'Udziały';
      case 'ProductType.apartments':
      case 'apartments':
        return 'Apartamenty';
      case 'ProductType.loans':
      case 'loans':
        return 'Pożyczki';
      default:
        return enumValue.replaceAll('ProductType.', '');
    }
  }
}