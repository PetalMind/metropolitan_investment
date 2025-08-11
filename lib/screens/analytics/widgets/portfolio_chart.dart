import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';
import '../../../models/analytics/overview_analytics_models.dart';
import '../../../utils/currency_formatter.dart';

/// Widget wykresu rozkładu portfela
class PortfolioChart extends StatefulWidget {
  final List<ProductBreakdownItem> productBreakdown;

  const PortfolioChart({super.key, required this.productBreakdown});

  @override
  State<PortfolioChart> createState() => _PortfolioChartState();
}

class _PortfolioChartState extends State<PortfolioChart> {
  int? _hoveredSection;

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
                'Rozkład portfela',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                '${widget.productBreakdown.length} typów',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.productBreakdown.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.pie_chart_outline,
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
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _hoveredSection = null;
                                    return;
                                  }
                                  _hoveredSection = pieTouchResponse
                                      .touchedSection!
                                      .touchedSectionIndex;
                                });
                              },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(flex: 1, child: _buildLegend()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryGold,
      AppTheme.successColor,
      AppTheme.infoColor,
      AppTheme.warningColor,
      AppTheme.errorColor,
    ];

    return widget.productBreakdown.asMap().entries.map((entry) {
      final index = entry.key;
      final product = entry.value;
      final isHovered = _hoveredSection == index;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: product.percentage,
        title: isHovered ? '${product.percentage.toStringAsFixed(1)}%' : '',
        radius: isHovered ? 90 : 80,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: isHovered ? _buildBadge(product) : null,
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

  Widget _buildBadge(ProductBreakdownItem product) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            product.productName,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(
            CurrencyFormatter.formatCurrencyShort(product.value),
            style: const TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryGold,
      AppTheme.successColor,
      AppTheme.infoColor,
      AppTheme.warningColor,
      AppTheme.errorColor,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.productBreakdown.asMap().entries.map((entry) {
        final index = entry.key;
        final product = entry.value;
        final color = colors[index % colors.length];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${product.count} inwestycji • ${product.percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 10,
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
}
