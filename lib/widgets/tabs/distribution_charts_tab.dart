import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';
import '../../models/investor_summary.dart';
import '../../utils/currency_formatter.dart';
import '../premium_analytics_charts.dart';

/// 📊 TAB ANALIZA DYSTRYBUCJI KAPITAŁU
///
/// Dedykowany tab do analizy rozkładu kapitału według różnych kryteriów.
/// Zawiera wykresy słupkowe, histogramy i analizę segmentacji.

class DistributionChartsTab extends StatefulWidget {
  final List<InvestorSummary> filteredInvestors;
  final double filteredTotalCapital;

  const DistributionChartsTab({
    super.key,
    required this.filteredInvestors,
    required this.filteredTotalCapital,
  });

  @override
  State<DistributionChartsTab> createState() => _DistributionChartsTabState();
}

class _DistributionChartsTabState extends State<DistributionChartsTab>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // Distribution analysis options
  String _distributionType = 'capital'; // capital, count, percentage
  bool _showCustomThresholds = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTabHeader(),
                  const SizedBox(height: 24),
                  _buildDistributionControls(),
                  const SizedBox(height: 24),
                  _buildDistributionChart(),
                  const SizedBox(height: 30),
                  _buildDistributionStatsGrid(),
                  const SizedBox(height: 30),
                  _buildSegmentAnalysis(),
                  const SizedBox(height: 30),
                  _buildConcentrationAnalysis(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warningColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.bar_chart_rounded,
              color: AppTheme.warningColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analiza Dystrybucji',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rozkład kapitału według progów • '
                  '${widget.filteredInvestors.length} segmentów',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuickActionButton(
          icon: Icons.tune_rounded,
          label: 'Konfiguracja',
          onTap: _openCustomThresholds,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        _buildQuickActionButton(
          icon: Icons.download_rounded,
          label: 'Eksport',
          onTap: _exportDistributionData,
          color: AppTheme.secondaryGold,
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    required Color color,
  }) {
    return Tooltip(
      message: label,
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildDistributionControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Opcje Analizy',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Distribution type selector
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Typ analizy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDistributionTypeSelector(),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Custom thresholds
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progi kapitału',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _showCustomThresholds,
                          onChanged: (value) {
                            setState(() {
                              _showCustomThresholds = value ?? false;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                        Text(
                          'Niestandardowe progi',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionTypeSelector() {
    return Wrap(
      spacing: 8,
      children: [
        _buildDistributionTypeChip('capital', 'Kapitał'),
        _buildDistributionTypeChip('count', 'Liczba'),
        _buildDistributionTypeChip('percentage', 'Procent'),
      ],
    );
  }

  Widget _buildDistributionTypeChip(String type, String label) {
    final isSelected = _distributionType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _distributionType = type;
          });
        }
      },
      selectedColor: AppTheme.warningColor.withOpacity(0.2),
      checkmarkColor: AppTheme.warningColor,
    );
  }

  Widget _buildDistributionChart() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Rozkład Kapitału według Progów',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        color: AppTheme.warningColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Analiza',
                        style: TextStyle(
                          color: AppTheme.warningColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Wykres rozkładu kapitału
          PremiumCapitalDistributionChart(
            investors: widget.filteredInvestors,
            title: 'Rozkład Kapitału według Progów',
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionStatsGrid() {
    final smallInvestors = widget.filteredInvestors
        .where((i) => i.viableRemainingCapital < 100000)
        .length;
    final mediumInvestors = widget.filteredInvestors
        .where(
          (i) =>
              i.viableRemainingCapital >= 100000 &&
              i.viableRemainingCapital < 1000000,
        )
        .length;
    final largeInvestors = widget.filteredInvestors
        .where((i) => i.viableRemainingCapital >= 1000000)
        .length;

    final totalInvestors = widget.filteredInvestors.length;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Statystyki Segmentów',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2,
              children: [
                _buildStatCard(
                  'Mali (<100K)',
                  '$smallInvestors',
                  totalInvestors > 0
                      ? '${(smallInvestors / totalInvestors * 100).toStringAsFixed(0)}%'
                      : '0%',
                  Icons.people_rounded,
                  const Color(0xFF4CAF50),
                ),
                _buildStatCard(
                  'Średni (100K-1M)',
                  '$mediumInvestors',
                  totalInvestors > 0
                      ? '${(mediumInvestors / totalInvestors * 100).toStringAsFixed(0)}%'
                      : '0%',
                  Icons.business_rounded,
                  const Color(0xFF2196F3),
                ),
                _buildStatCard(
                  'Duzi (>1M)',
                  '$largeInvestors',
                  totalInvestors > 0
                      ? '${(largeInvestors / totalInvestors * 100).toStringAsFixed(0)}%'
                      : '0%',
                  Icons.account_balance_wallet_rounded,
                  const Color(0xFFFF5722),
                ),
                _buildStatCard(
                  'Gini Index',
                  _calculateGiniIndex().toStringAsFixed(3),
                  'nierówność',
                  Icons.equalizer_rounded,
                  AppTheme.textSecondary,
                ),
                _buildStatCard(
                  'Pareto 80/20',
                  _calculatePareto8020(),
                  'sprawdzenie',
                  Icons.pie_chart_rounded,
                  AppTheme.warningColor,
                ),
                _buildStatCard(
                  'Entropia',
                  _calculateEntropy().toStringAsFixed(2),
                  'różnorodność',
                  Icons.scatter_plot_rounded,
                  AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentAnalysis() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warningColor.withOpacity(0.1),
            AppTheme.backgroundSecondary.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart_rounded,
                color: AppTheme.warningColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Analiza Segmentacji',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getSegmentAnalysisText(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildSegmentBreakdown(),
        ],
      ),
    );
  }

  Widget _buildSegmentBreakdown() {
    final segments = _calculateSegments();

    return Column(
      children: segments.entries.map((entry) {
        final segmentName = entry.key;
        final segmentData = entry.value;
        final capitalPercentage = widget.filteredTotalCapital > 0
            ? (segmentData['capital']! / widget.filteredTotalCapital) * 100
            : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundPrimary.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderPrimary),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getSegmentColor(segmentName),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  segmentName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  CurrencyFormatter.formatCurrencyShort(
                    segmentData['capital']!,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getSegmentColor(segmentName),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${segmentData['count']!.toInt()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSegmentColor(segmentName).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${capitalPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: _getSegmentColor(segmentName),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConcentrationAnalysis() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.backgroundSecondary.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.center_focus_strong_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Analiza Koncentracji',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getConcentrationAnalysisText(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildConcentrationMetrics(),
        ],
      ),
    );
  }

  Widget _buildConcentrationMetrics() {
    final top10Percentage = _calculateTop10Percentage();
    final top20Percentage = _calculateTop20Percentage();
    final herfindahlIndex = _calculateHerfindahlIndex();

    return Row(
      children: [
        Expanded(
          child: _buildConcentrationMetric(
            'Top 10%',
            '${top10Percentage.toStringAsFixed(1)}%',
            'kapitału',
            Icons.star_rounded,
            AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildConcentrationMetric(
            'Top 20%',
            '${top20Percentage.toStringAsFixed(1)}%',
            'kapitału',
            Icons.star_half_rounded,
            AppTheme.warningColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildConcentrationMetric(
            'HHI',
            herfindahlIndex.toStringAsFixed(0),
            'koncentracja',
            Icons.straighten_rounded,
            AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildConcentrationMetric(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Map<String, Map<String, double>> _calculateSegments() {
    final segments = <String, Map<String, double>>{
      'Mali (<100K)': {'capital': 0.0, 'count': 0.0},
      'Średni (100K-1M)': {'capital': 0.0, 'count': 0.0},
      'Duzi (1M-10M)': {'capital': 0.0, 'count': 0.0},
      'Bardzo duzi (>10M)': {'capital': 0.0, 'count': 0.0},
    };

    for (final investor in widget.filteredInvestors) {
      final capital = investor.viableRemainingCapital;

      if (capital < 100000) {
        segments['Mali (<100K)']!['capital'] =
            segments['Mali (<100K)']!['capital']! + capital;
        segments['Mali (<100K)']!['count'] =
            segments['Mali (<100K)']!['count']! + 1;
      } else if (capital < 1000000) {
        segments['Średni (100K-1M)']!['capital'] =
            segments['Średni (100K-1M)']!['capital']! + capital;
        segments['Średni (100K-1M)']!['count'] =
            segments['Średni (100K-1M)']!['count']! + 1;
      } else if (capital < 10000000) {
        segments['Duzi (1M-10M)']!['capital'] =
            segments['Duzi (1M-10M)']!['capital']! + capital;
        segments['Duzi (1M-10M)']!['count'] =
            segments['Duzi (1M-10M)']!['count']! + 1;
      } else {
        segments['Bardzo duzi (>10M)']!['capital'] =
            segments['Bardzo duzi (>10M)']!['capital']! + capital;
        segments['Bardzo duzi (>10M)']!['count'] =
            segments['Bardzo duzi (>10M)']!['count']! + 1;
      }
    }

    return segments;
  }

  Color _getSegmentColor(String segmentName) {
    switch (segmentName) {
      case 'Mali (<100K)':
        return const Color(0xFF4CAF50);
      case 'Średni (100K-1M)':
        return const Color(0xFF2196F3);
      case 'Duzi (1M-10M)':
        return const Color(0xFFFF5722);
      case 'Bardzo duzi (>10M)':
        return const Color(0xFF9C27B0);
      default:
        return AppTheme.textSecondary;
    }
  }

  double _calculateGiniIndex() {
    if (widget.filteredInvestors.isEmpty) return 0.0;

    final capitals =
        widget.filteredInvestors.map((i) => i.viableRemainingCapital).toList()
          ..sort();

    double sum = 0.0;
    for (int i = 0; i < capitals.length; i++) {
      sum += (2 * (i + 1) - capitals.length - 1) * capitals[i];
    }

    final totalCapital = capitals.fold(0.0, (sum, value) => sum + value);
    return totalCapital > 0 ? sum / (capitals.length * totalCapital) : 0.0;
  }

  String _calculatePareto8020() {
    if (widget.filteredInvestors.isEmpty) return 'N/A';

    final sortedInvestors = List<InvestorSummary>.from(widget.filteredInvestors)
      ..sort(
        (a, b) => b.viableRemainingCapital.compareTo(a.viableRemainingCapital),
      );

    final top20Count = (sortedInvestors.length * 0.2).ceil();
    final top20Capital = sortedInvestors
        .take(top20Count)
        .fold(0.0, (sum, inv) => sum + inv.viableRemainingCapital);

    final percentage = widget.filteredTotalCapital > 0
        ? (top20Capital / widget.filteredTotalCapital) * 100
        : 0.0;

    return '${percentage.toStringAsFixed(0)}%';
  }

  double _calculateEntropy() {
    final segments = _calculateSegments();
    double entropy = 0.0;

    for (final segmentData in segments.values) {
      final proportion =
          segmentData['count']! / widget.filteredInvestors.length;
      if (proportion > 0) {
        entropy -=
            proportion *
            (proportion > 0 ? math.log(proportion) / math.log(2) : 0); // log2
      }
    }

    return entropy;
  }

  double _calculateTop10Percentage() {
    if (widget.filteredInvestors.isEmpty) return 0.0;

    final sortedInvestors = List<InvestorSummary>.from(widget.filteredInvestors)
      ..sort(
        (a, b) => b.viableRemainingCapital.compareTo(a.viableRemainingCapital),
      );

    final top10Count = (sortedInvestors.length * 0.1).ceil();
    final top10Capital = sortedInvestors
        .take(top10Count)
        .fold(0.0, (sum, inv) => sum + inv.viableRemainingCapital);

    return widget.filteredTotalCapital > 0
        ? (top10Capital / widget.filteredTotalCapital) * 100
        : 0.0;
  }

  double _calculateTop20Percentage() {
    if (widget.filteredInvestors.isEmpty) return 0.0;

    final sortedInvestors = List<InvestorSummary>.from(widget.filteredInvestors)
      ..sort(
        (a, b) => b.viableRemainingCapital.compareTo(a.viableRemainingCapital),
      );

    final top20Count = (sortedInvestors.length * 0.2).ceil();
    final top20Capital = sortedInvestors
        .take(top20Count)
        .fold(0.0, (sum, inv) => sum + inv.viableRemainingCapital);

    return widget.filteredTotalCapital > 0
        ? (top20Capital / widget.filteredTotalCapital) * 100
        : 0.0;
  }

  double _calculateHerfindahlIndex() {
    if (widget.filteredInvestors.isEmpty) return 0.0;

    double hhi = 0.0;
    for (final investor in widget.filteredInvestors) {
      final marketShare =
          investor.viableRemainingCapital / widget.filteredTotalCapital;
      hhi += marketShare * marketShare;
    }

    return hhi * 10000; // Convert to HHI scale (0-10000)
  }

  String _getSegmentAnalysisText() {
    final segments = _calculateSegments();
    final dominantSegment = segments.entries.reduce(
      (a, b) => a.value['capital']! > b.value['capital']! ? a : b,
    );

    final dominantPercentage = widget.filteredTotalCapital > 0
        ? (dominantSegment.value['capital']! / widget.filteredTotalCapital) *
              100
        : 0.0;

    return 'Dominujący segment to ${dominantSegment.key} z udziałem '
        '${dominantPercentage.toStringAsFixed(1)}% kapitału. '
        'Struktura portfela wskazuje na ${_getDistributionCharacteristic()} '
        'rozkład kapitału między inwestorami.';
  }

  String _getDistributionCharacteristic() {
    final gini = _calculateGiniIndex();
    if (gini < 0.3) {
      return 'równomierny';
    } else if (gini < 0.5) {
      return 'umiarkowanie nierówny';
    } else {
      return 'silnie nierówny';
    }
  }

  String _getConcentrationAnalysisText() {
    final top10 = _calculateTop10Percentage();
    final hhi = _calculateHerfindahlIndex();

    String concentrationLevel;
    if (hhi < 1500) {
      concentrationLevel = 'niską koncentrację';
    } else if (hhi < 2500) {
      concentrationLevel = 'umiarkowaną koncentrację';
    } else {
      concentrationLevel = 'wysoką koncentrację';
    }

    return 'Analiza wskazuje na $concentrationLevel kapitału. '
        'Top 10% inwestorów kontroluje ${top10.toStringAsFixed(1)}% '
        'całkowitego kapitału, co ${top10 > 50 ? 'może wskazywać na ryzyko koncentracji' : 'świadczy o zdrowym rozkładzie'}.';
  }

  void _openCustomThresholds() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Niestandardowe progi'),
        content: const Text('Konfiguracja progów - funkcja w przygotowaniu'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _exportDistributionData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eksport danych dystrybucji - funkcja w przygotowaniu'),
      ),
    );
  }
}
