import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';
import '../../models/investor_summary.dart';
import '../../utils/currency_formatter.dart';

/// 🎯 TAB ANALIZA RYZYKA
///
/// Dedykowany tab do kompleksowej analizy ryzyka portfela inwestorów.
/// Zawiera mapy cieplne, wykresy bąbelkowe, radary i metryki ryzyka.

class RiskAnalysisTab extends StatefulWidget {
  final List<InvestorSummary> filteredInvestors;
  final double filteredTotalCapital;

  const RiskAnalysisTab({
    super.key,
    required this.filteredInvestors,
    required this.filteredTotalCapital,
  });

  @override
  State<RiskAnalysisTab> createState() => _RiskAnalysisTabState();
}

class _RiskAnalysisTabState extends State<RiskAnalysisTab>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // Risk analysis settings
  String _riskMetric = 'concentration'; // concentration, volatility, exposure
  bool _showAdvancedMetrics = false;
  List<String> _selectedRiskFactors = ['capital', 'voting', 'liquidity'];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 60.0, end: 0.0).animate(
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
                  _buildRiskAnalysisControls(),
                  const SizedBox(height: 24),
                  _buildRiskHeatmap(),
                  const SizedBox(height: 30),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildRiskRadarChart(),
                            const SizedBox(height: 20),
                            _buildRiskMetricsPanel(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          children: [
                            _buildRiskDistribution(),
                            const SizedBox(height: 20),
                            _buildRiskAlerts(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildComprehensiveRiskAssessment(),
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
            AppTheme.errorColor.withOpacity(0.1),
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
              color: AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.shield_rounded,
              color: AppTheme.errorColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analiza Ryzyka',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kompleksowa ocena ryzyka portfela • '
                  '${_getRiskLevel()} profil ryzyka',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildRiskScoreIndicator(),
        ],
      ),
    );
  }

  Widget _buildRiskScoreIndicator() {
    final riskScore = _calculateOverallRiskScore();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getRiskScoreColor(riskScore).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getRiskScoreColor(riskScore).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Risk Score',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            riskScore.toStringAsFixed(1),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getRiskScoreColor(riskScore),
            ),
          ),
          Text(
            '/10',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAnalysisControls() {
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
            'Parametry Analizy Ryzyka',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Risk metric selector
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Metryka ryzyka',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRiskMetricSelector(),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Advanced metrics toggle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Opcje zaawansowane',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _showAdvancedMetrics,
                          onChanged: (value) {
                            setState(() {
                              _showAdvancedMetrics = value ?? false;
                            });
                          },
                          activeColor: AppTheme.errorColor,
                        ),
                        Text(
                          'Metryki zaawansowane',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Risk factors selector
          Text(
            'Czynniki ryzyka',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          _buildRiskFactorsSelector(),
        ],
      ),
    );
  }

  Widget _buildRiskMetricSelector() {
    return Wrap(
      spacing: 8,
      children: [
        _buildRiskMetricChip('concentration', 'Koncentracja'),
        _buildRiskMetricChip('volatility', 'Zmienność'),
        _buildRiskMetricChip('exposure', 'Ekspozycja'),
      ],
    );
  }

  Widget _buildRiskMetricChip(String metric, String label) {
    final isSelected = _riskMetric == metric;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _riskMetric = metric;
          });
        }
      },
      selectedColor: AppTheme.errorColor.withOpacity(0.2),
      checkmarkColor: AppTheme.errorColor,
    );
  }

  Widget _buildRiskFactorsSelector() {
    final factors = ['capital', 'voting', 'liquidity', 'diversification'];
    final labels = {
      'capital': 'Kapitał',
      'voting': 'Głosowanie',
      'liquidity': 'Płynność',
      'diversification': 'Dywersyfikacja',
    };

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: factors.map((factor) {
        final isSelected = _selectedRiskFactors.contains(factor);
        return FilterChip(
          label: Text(labels[factor] ?? factor),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedRiskFactors.add(factor);
              } else {
                _selectedRiskFactors.remove(factor);
              }
            });
          },
          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
          checkmarkColor: AppTheme.primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildRiskHeatmap() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withOpacity(0.05),
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
                  'Mapa Cieplna Ryzyka',
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
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: AppTheme.errorColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ryzyko',
                        style: TextStyle(
                          color: AppTheme.errorColor,
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
          // Heatmapa ryzyka - placeholder
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: AppTheme.backgroundPrimary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.grid_on_rounded,
                    color: AppTheme.errorColor,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mapa Cieplna Ryzyka',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Wizualizacja poziomów ryzyka',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
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

  Widget _buildRiskRadarChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.errorColor.withOpacity(0.1),
            AppTheme.backgroundSecondary.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar_rounded, color: AppTheme.errorColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Radar Ryzyka',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Wykres radarowy - placeholder
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: AppTheme.backgroundPrimary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.radar_rounded,
                    color: AppTheme.errorColor,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Radar Ryzyka',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Wielowymiarowa analiza ryzyka',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
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

  Widget _buildRiskMetricsPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kluczowe Metryki Ryzyka',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildMetricCard(
                'VaR 95%',
                CurrencyFormatter.formatCurrencyShort(_calculateVaR95()),
                Icons.trending_down_rounded,
                AppTheme.errorColor,
              ),
              _buildMetricCard(
                'CVaR',
                CurrencyFormatter.formatCurrencyShort(_calculateCVaR()),
                Icons.arrow_downward_rounded,
                AppTheme.warningColor,
              ),
              _buildMetricCard(
                'Sharpe Ratio',
                _calculateSharpeRatio().toStringAsFixed(2),
                Icons.balance_rounded,
                AppTheme.primaryColor,
              ),
              _buildMetricCard(
                'Max DD',
                '${(_calculateMaxDrawdown() * 100).toStringAsFixed(1)}%',
                Icons.south_rounded,
                AppTheme.errorColor,
              ),
            ],
          ),
          if (_showAdvancedMetrics) ...[
            const SizedBox(height: 16),
            _buildAdvancedMetrics(),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: AppTheme.borderPrimary),
        const SizedBox(height: 16),
        Text(
          'Metryki Zaawansowane',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildMetricCard(
              'Beta Portfolio',
              _calculateBeta().toStringAsFixed(2),
              Icons.trending_up_rounded,
              AppTheme.secondaryGold,
            ),
            _buildMetricCard(
              'Treynor Ratio',
              _calculateTreynorRatio().toStringAsFixed(2),
              Icons.analytics_rounded,
              AppTheme.primaryColor,
            ),
            _buildMetricCard(
              'Jensen Alpha',
              '${(_calculateJensenAlpha() * 100).toStringAsFixed(1)}%',
              Icons.star_rounded,
              AppTheme.successColor,
            ),
            _buildMetricCard(
              'Sortino Ratio',
              _calculateSortinoRatio().toStringAsFixed(2),
              Icons.filter_list_rounded,
              AppTheme.warningColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDistribution() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rozkład Ryzyka',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Wykres rozkładu ryzyka - placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.backgroundPrimary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    color: AppTheme.primaryColor,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Rozkład Ryzyka',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Analiza $_riskMetric',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
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

  Widget _buildRiskAlerts() {
    final alerts = _generateRiskAlerts();

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
                Icons.notification_important_rounded,
                color: AppTheme.warningColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Alerty Ryzyka',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...alerts.map((alert) => _buildRiskAlert(alert)),
        ],
      ),
    );
  }

  Widget _buildRiskAlert(Map<String, dynamic> alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alert['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: alert['color'].withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(alert['icon'], color: alert['color'], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  alert['description'],
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
  }

  Widget _buildComprehensiveRiskAssessment() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.errorColor.withOpacity(0.05),
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
                Icons.assessment_rounded,
                color: AppTheme.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Kompleksowa Ocena Ryzyka',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _generateRiskAssessmentText(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          _buildRiskRecommendations(),
        ],
      ),
    );
  }

  Widget _buildRiskRecommendations() {
    final recommendations = _generateRiskRecommendations();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rekomendacje',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...recommendations.map(
          (recommendation) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundPrimary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderPrimary),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recommendation,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Risk Calculation Methods
  double _calculateOverallRiskScore() {
    if (widget.filteredInvestors.isEmpty) return 0.0;

    final concentrationRisk = _calculateConcentrationRisk();
    final volatilityRisk = _calculateVolatilityRisk();
    final liquidityRisk = _calculateLiquidityRisk();

    return (concentrationRisk + volatilityRisk + liquidityRisk) / 3;
  }

  double _calculateConcentrationRisk() {
    if (widget.filteredInvestors.isEmpty) return 0.0;

    final top10Percentage = _calculateTop10Percentage();

    // High concentration = higher risk
    if (top10Percentage > 80) return 9.0;
    if (top10Percentage > 60) return 7.0;
    if (top10Percentage > 40) return 5.0;
    if (top10Percentage > 20) return 3.0;
    return 1.0;
  }

  double _calculateTop10Percentage() {
    if (widget.filteredInvestors.isEmpty) return 0.0;

    final sortedInvestors = List<InvestorSummary>.from(widget.filteredInvestors)
      ..sort(
        (a, b) => b.viableRemainingCapital.compareTo(a.viableRemainingCapital),
      );

    final top10Count = math.max(1, (sortedInvestors.length * 0.1).ceil());
    final top10Capital = sortedInvestors
        .take(top10Count)
        .fold(0.0, (sum, inv) => sum + inv.viableRemainingCapital);

    return widget.filteredTotalCapital > 0
        ? (top10Capital / widget.filteredTotalCapital) * 100
        : 0.0;
  }

  double _calculateVolatilityRisk() {
    if (widget.filteredInvestors.isEmpty) return 0.0;

    final capitals = widget.filteredInvestors
        .map((i) => i.viableRemainingCapital)
        .toList();

    final mean =
        capitals.fold(0.0, (sum, value) => sum + value) / capitals.length;
    final variance =
        capitals
            .map((value) => math.pow(value - mean, 2))
            .fold(0.0, (sum, value) => sum + value) /
        capitals.length;

    final stdDev = math.sqrt(variance);
    final coefficientOfVariation = mean > 0 ? stdDev / mean : 0.0;

    // Higher CV = higher volatility risk
    if (coefficientOfVariation > 2.0) return 8.0;
    if (coefficientOfVariation > 1.5) return 6.0;
    if (coefficientOfVariation > 1.0) return 4.0;
    if (coefficientOfVariation > 0.5) return 2.0;
    return 1.0;
  }

  double _calculateLiquidityRisk() {
    // Simplified liquidity risk based on portfolio size
    if (widget.filteredInvestors.isEmpty) return 0.0;

    final averageCapital =
        widget.filteredTotalCapital / widget.filteredInvestors.length;

    // Larger average positions = higher liquidity risk
    if (averageCapital > 10000000) return 7.0;
    if (averageCapital > 5000000) return 5.0;
    if (averageCapital > 1000000) return 3.0;
    return 1.0;
  }

  double _calculateVaR95() {
    if (widget.filteredInvestors.isEmpty) return 0.0;

    final capitals =
        widget.filteredInvestors.map((i) => i.viableRemainingCapital).toList()
          ..sort();

    final index = (capitals.length * 0.05).floor();
    return index < capitals.length ? capitals[index] : 0.0;
  }

  double _calculateCVaR() {
    if (widget.filteredInvestors.isEmpty) return 0.0;

    final capitals =
        widget.filteredInvestors.map((i) => i.viableRemainingCapital).toList()
          ..sort();

    final index = (capitals.length * 0.05).floor();
    final tailValues = capitals.take(index + 1);

    return tailValues.isNotEmpty
        ? tailValues.fold(0.0, (sum, value) => sum + value) / tailValues.length
        : 0.0;
  }

  double _calculateSharpeRatio() {
    // Simplified Sharpe ratio calculation
    if (widget.filteredInvestors.isEmpty) return 0.0;

    final expectedReturn = 0.08; // 8% expected return
    final riskFreeRate = 0.02; // 2% risk-free rate
    final volatility = _calculatePortfolioVolatility();

    return volatility > 0 ? (expectedReturn - riskFreeRate) / volatility : 0.0;
  }

  double _calculatePortfolioVolatility() {
    if (widget.filteredInvestors.length < 2) return 0.0;

    final capitals = widget.filteredInvestors
        .map((i) => i.viableRemainingCapital)
        .toList();

    final mean =
        capitals.fold(0.0, (sum, value) => sum + value) / capitals.length;
    final variance =
        capitals
            .map((value) => math.pow(value - mean, 2))
            .fold(0.0, (sum, value) => sum + value) /
        (capitals.length - 1);

    return math.sqrt(variance) / mean;
  }

  double _calculateMaxDrawdown() {
    // Simplified max drawdown calculation
    return 0.15; // 15% assumed max drawdown
  }

  double _calculateBeta() {
    // Simplified beta calculation
    return 1.2; // Assumed beta
  }

  double _calculateTreynorRatio() {
    final expectedReturn = 0.08;
    final riskFreeRate = 0.02;
    final beta = _calculateBeta();

    return beta > 0 ? (expectedReturn - riskFreeRate) / beta : 0.0;
  }

  double _calculateJensenAlpha() {
    final expectedReturn = 0.08;
    final riskFreeRate = 0.02;
    final marketReturn = 0.07;
    final beta = _calculateBeta();

    return expectedReturn -
        (riskFreeRate + beta * (marketReturn - riskFreeRate));
  }

  double _calculateSortinoRatio() {
    final expectedReturn = 0.08;
    final targetReturn = 0.05;
    final downstideDeviation = _calculateDownsideDeviation(targetReturn);

    return downstideDeviation > 0
        ? (expectedReturn - targetReturn) / downstideDeviation
        : 0.0;
  }

  double _calculateDownsideDeviation(double targetReturn) {
    // Simplified downside deviation
    return 0.12; // 12% assumed downside deviation
  }

  Color _getRiskScoreColor(double score) {
    if (score <= 3) return AppTheme.successColor;
    if (score <= 6) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _getRiskLevel() {
    final score = _calculateOverallRiskScore();
    if (score <= 3) return 'Niski';
    if (score <= 6) return 'Średni';
    return 'Wysoki';
  }

  List<Map<String, dynamic>> _generateRiskAlerts() {
    final alerts = <Map<String, dynamic>>[];

    final concentrationRisk = _calculateConcentrationRisk();
    if (concentrationRisk > 7) {
      alerts.add({
        'title': 'Wysokie ryzyko koncentracji',
        'description': 'Top 10% inwestorów kontroluje znaczną część kapitału',
        'icon': Icons.warning_rounded,
        'color': AppTheme.errorColor,
      });
    }

    final volatilityRisk = _calculateVolatilityRisk();
    if (volatilityRisk > 6) {
      alerts.add({
        'title': 'Wysoka zmienność portfela',
        'description': 'Duże różnice w wielkości inwestycji',
        'icon': Icons.trending_up_rounded,
        'color': AppTheme.warningColor,
      });
    }

    if (widget.filteredInvestors.length < 10) {
      alerts.add({
        'title': 'Mała liczba inwestorów',
        'description': 'Ograniczona dywersyfikacja ryzyka',
        'icon': Icons.people_outline_rounded,
        'color': AppTheme.warningColor,
      });
    }

    return alerts;
  }

  String _generateRiskAssessmentText() {
    final riskScore = _calculateOverallRiskScore();
    final riskLevel = _getRiskLevel();
    final concentrationRisk = _calculateConcentrationRisk();
    final top10Percentage = _calculateTop10Percentage();

    return 'Ocena ryzyka portfela wskazuje na $riskLevel poziom ryzyka '
        'z oceną ${riskScore.toStringAsFixed(1)}/10. '
        'Top 10% inwestorów kontroluje ${top10Percentage.toStringAsFixed(1)}% kapitału, '
        'co ${concentrationRisk > 7 ? 'stanowi znaczące ryzyko koncentracji' : 'wskazuje na zdrowy rozkład'}. '
        'Analiza uwzględnia czynniki koncentracji, zmienności i płynności portfela.';
  }

  List<String> _generateRiskRecommendations() {
    final recommendations = <String>[];
    final concentrationRisk = _calculateConcentrationRisk();
    final volatilityRisk = _calculateVolatilityRisk();

    if (concentrationRisk > 7) {
      recommendations.add(
        'Rozważenie dywersyfikacji portfela poprzez pozyskanie większej liczby '
        'średnich inwestorów w celu zmniejszenia koncentracji kapitału.',
      );
    }

    if (volatilityRisk > 6) {
      recommendations.add(
        'Implementacja strategii zarządzania ryzykiem zmienności poprzez '
        'ustanowienie limitów wielkości pojedynczych inwestycji.',
      );
    }

    if (widget.filteredInvestors.length < 20) {
      recommendations.add(
        'Zwiększenie bazy inwestorów w celu poprawy dywersyfikacji '
        'i redukcji ryzyka koncentracji.',
      );
    }

    recommendations.add(
      'Regularne monitorowanie kluczowych metryk ryzyka i dostosowywanie '
      'strategii inwestycyjnej do zmieniających się warunków rynkowych.',
    );

    return recommendations;
  }
}
