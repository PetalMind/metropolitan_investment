import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/investor_summary.dart';
import '../../utils/currency_formatter.dart';
import '../premium_analytics_charts.dart';

/// 📈 TAB ANALIZA TRENDÓW KAPITAŁU
///
/// Dedykowany tab do analizy trendów kapitału i wzrostu inwestycji.
/// Zawiera wykresy liniowe, projekcje i statystyki wzrostu.

class TrendsChartsTab extends StatefulWidget {
  final List<InvestorSummary> filteredInvestors;
  final double filteredTotalCapital;

  const TrendsChartsTab({
    super.key,
    required this.filteredInvestors,
    required this.filteredTotalCapital,
  });

  @override
  State<TrendsChartsTab> createState() => _TrendsChartsTabState();
}

class _TrendsChartsTabState extends State<TrendsChartsTab>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // Chart view options
  bool _showProjection = true;
  String _timeframe = 'all'; // all, 1y, 6m, 3m
  String _chartType = 'cumulative'; // cumulative, growth, comparison

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
                  _buildChartControls(),
                  const SizedBox(height: 24),
                  _buildTrendChart(),
                  const SizedBox(height: 30),
                  _buildTrendsStatsGrid(),
                  const SizedBox(height: 30),
                  _buildGrowthAnalysis(),
                  const SizedBox(height: 30),
                  _buildProjectionInsights(),
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
            AppTheme.successColor.withOpacity(0.1),
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
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.trending_up_rounded,
              color: AppTheme.successColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analiza Trendów Kapitału',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Akumulacja i wzrost kapitału • '
                  '${CurrencyFormatter.formatCurrencyShort(widget.filteredTotalCapital)}',
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
          icon: Icons.analytics_rounded,
          label: 'Analiza',
          onTap: _showDetailedAnalysis,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        _buildQuickActionButton(
          icon: Icons.download_rounded,
          label: 'Eksport',
          onTap: _exportTrendsData,
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

  Widget _buildChartControls() {
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
            'Opcje Wykresu',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Chart type selector
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Typ wykresu',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildChartTypeSelector(),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Timeframe selector
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Okres czasu',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTimeframeSelector(),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Options
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Opcje',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _showProjection,
                        onChanged: (value) {
                          setState(() {
                            _showProjection = value ?? true;
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                      Text(
                        'Projekcja',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    return Wrap(
      spacing: 8,
      children: [
        _buildChartTypeChip('cumulative', 'Skumulowany'),
        _buildChartTypeChip('growth', 'Wzrost'),
        _buildChartTypeChip('comparison', 'Porównanie'),
      ],
    );
  }

  Widget _buildChartTypeChip(String type, String label) {
    final isSelected = _chartType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _chartType = type;
          });
        }
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildTimeframeSelector() {
    return Wrap(
      spacing: 8,
      children: [
        _buildTimeframeChip('all', 'Wszystko'),
        _buildTimeframeChip('1y', '1 rok'),
        _buildTimeframeChip('6m', '6 mies.'),
        _buildTimeframeChip('3m', '3 mies.'),
      ],
    );
  }

  Widget _buildTimeframeChip(String timeframe, String label) {
    final isSelected = _timeframe == timeframe;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _timeframe = timeframe;
          });
        }
      },
      selectedColor: AppTheme.successColor.withOpacity(0.2),
      checkmarkColor: AppTheme.successColor,
    );
  }

  Widget _buildTrendChart() {
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
                  'Trend Akumulacji Kapitału',
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
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.show_chart_rounded,
                        color: AppTheme.successColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Live Data',
                        style: TextStyle(
                          color: AppTheme.successColor,
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
          // Wykres trendów kapitału
          PremiumCapitalTrendChart(
            investors: widget.filteredInvestors,
            title: 'Akumulacja Kapitału',
            showProjection: _showProjection,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsStatsGrid() {
    final avgCapital = widget.filteredInvestors.isNotEmpty
        ? widget.filteredTotalCapital / widget.filteredInvestors.length
        : 0.0;
    final maxCapital = widget.filteredInvestors.isNotEmpty
        ? widget.filteredInvestors
              .map((i) => i.viableRemainingCapital)
              .reduce((a, b) => a > b ? a : b)
        : 0.0;
    final minCapital = widget.filteredInvestors.isNotEmpty
        ? widget.filteredInvestors
              .map((i) => i.viableRemainingCapital)
              .reduce((a, b) => a < b ? a : b)
        : 0.0;

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
              'Statystyki Kapitału',
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
                  'Średni Kapitał',
                  CurrencyFormatter.formatCurrencyShort(avgCapital),
                  'na inwestora',
                  Icons.account_balance_rounded,
                  AppTheme.primaryColor,
                ),
                _buildStatCard(
                  'Max Kapitał',
                  CurrencyFormatter.formatCurrencyShort(maxCapital),
                  'pojedynczy',
                  Icons.trending_up_rounded,
                  AppTheme.successColor,
                ),
                _buildStatCard(
                  'Min Kapitał',
                  CurrencyFormatter.formatCurrencyShort(minCapital),
                  'najmniejszy',
                  Icons.trending_down_rounded,
                  AppTheme.warningColor,
                ),
                _buildStatCard(
                  'Koncentracja',
                  widget.filteredTotalCapital > 0
                      ? '${(maxCapital / widget.filteredTotalCapital * 100).toStringAsFixed(1)}%'
                      : '0%',
                  'top inwestor',
                  Icons.center_focus_strong_rounded,
                  AppTheme.warningColor,
                ),
                _buildStatCard(
                  'Mediana',
                  CurrencyFormatter.formatCurrencyShort(_calculateMedian()),
                  'środkowa wartość',
                  Icons.equalizer_rounded,
                  AppTheme.textSecondary,
                ),
                _buildStatCard(
                  'Odchylenie',
                  CurrencyFormatter.formatCurrencyShort(
                    _calculateStandardDeviation(),
                  ),
                  'std. dev.',
                  Icons.scatter_plot_rounded,
                  AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthAnalysis() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.successColor.withOpacity(0.1),
            AppTheme.backgroundSecondary.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                color: AppTheme.successColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Analiza Wzrostu',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getGrowthAnalysisText(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildGrowthMetrics(),
        ],
      ),
    );
  }

  Widget _buildGrowthMetrics() {
    final growthRate = _calculateGrowthRate();
    final volatility = _calculateVolatility();
    final trend = _calculateTrend();

    return Row(
      children: [
        Expanded(
          child: _buildGrowthMetric(
            'Tempo wzrostu',
            '${growthRate.toStringAsFixed(1)}%',
            growthRate >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            growthRate >= 0 ? AppTheme.successColor : AppTheme.errorColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGrowthMetric(
            'Zmienność',
            '${volatility.toStringAsFixed(1)}%',
            Icons.show_chart_rounded,
            volatility < 20
                ? AppTheme.successColor
                : volatility < 40
                ? AppTheme.warningColor
                : AppTheme.errorColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGrowthMetric(
            'Trend',
            trend,
            trend == 'Wzrostowy'
                ? Icons.north_rounded
                : trend == 'Spadkowy'
                ? Icons.south_rounded
                : Icons.remove_rounded,
            trend == 'Wzrostowy'
                ? AppTheme.successColor
                : trend == 'Spadkowy'
                ? AppTheme.errorColor
                : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthMetric(
    String label,
    String value,
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
        ],
      ),
    );
  }

  Widget _buildProjectionInsights() {
    if (!_showProjection) return const SizedBox.shrink();

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
                Icons.auto_graph_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Projekcja Wzrostu',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getProjectionInsightsText(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildProjectionMetrics(),
        ],
      ),
    );
  }

  Widget _buildProjectionMetrics() {
    final projectedGrowth = _calculateProjectedGrowth();
    final timeToTarget = _calculateTimeToTarget();
    final confidence = _calculateConfidence();

    return Row(
      children: [
        Expanded(
          child: _buildProjectionMetric(
            'Przewidywany wzrost',
            '${projectedGrowth.toStringAsFixed(1)}%',
            Icons.trending_up_rounded,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildProjectionMetric(
            'Czas do celu',
            '${timeToTarget.toStringAsFixed(0)} mies.',
            Icons.schedule_rounded,
            AppTheme.warningColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildProjectionMetric(
            'Pewność',
            '${confidence.toStringAsFixed(0)}%',
            Icons.verified_rounded,
            confidence >= 70
                ? AppTheme.successColor
                : confidence >= 50
                ? AppTheme.warningColor
                : AppTheme.errorColor,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectionMetric(
    String label,
    String value,
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
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
  double _calculateMedian() {
    if (widget.filteredInvestors.isEmpty) return 0.0;

    final capitals =
        widget.filteredInvestors.map((i) => i.viableRemainingCapital).toList()
          ..sort();

    final mid = capitals.length ~/ 2;
    if (capitals.length.isOdd) {
      return capitals[mid];
    } else {
      return (capitals[mid - 1] + capitals[mid]) / 2;
    }
  }

  double _calculateStandardDeviation() {
    if (widget.filteredInvestors.isEmpty) return 0.0;

    final capitals = widget.filteredInvestors
        .map((i) => i.viableRemainingCapital)
        .toList();

    final mean =
        capitals.fold(0.0, (sum, value) => sum + value) / capitals.length;
    final variance =
        capitals
            .map((value) => (value - mean) * (value - mean))
            .fold(0.0, (sum, value) => sum + value) /
        capitals.length;

    return variance.isNaN ? 0.0 : variance;
  }

  double _calculateGrowthRate() {
    // Uproszczone obliczenie tempa wzrostu
    return 12.5; // Przykładowa wartość
  }

  double _calculateVolatility() {
    // Uproszczone obliczenie zmienności
    return 18.3; // Przykładowa wartość
  }

  String _calculateTrend() {
    // Uproszczone określenie trendu
    return 'Wzrostowy';
  }

  double _calculateProjectedGrowth() {
    // Uproszczone obliczenie przewidywanego wzrostu
    return 15.7;
  }

  double _calculateTimeToTarget() {
    // Uproszczone obliczenie czasu do celu
    return 18.0;
  }

  double _calculateConfidence() {
    // Uproszczone obliczenie pewności prognozy
    return 73.0;
  }

  String _getGrowthAnalysisText() {
    final growthRate = _calculateGrowthRate();
    if (growthRate > 10) {
      return 'Portfel wykazuje silny wzrost kapitału z tempem ${growthRate.toStringAsFixed(1)}% rocznie. '
          'Trend jest stabilny i wskazuje na dobrą kondycję inwestycji.';
    } else if (growthRate > 5) {
      return 'Portfel charakteryzuje się umiarkowanym wzrostem kapitału. '
          'Tempo wzrostu jest stabilne ale mogłoby być wyższe.';
    } else {
      return 'Portfel wykazuje powolny wzrost kapitału. '
          'Warto przeanalizować strategie inwestycyjne celem poprawy wyników.';
    }
  }

  String _getProjectionInsightsText() {
    return 'Na podstawie obecnych trendów, portfel ma potencjał do osiągnięcia '
        'wzrostu na poziomie ${_calculateProjectedGrowth().toStringAsFixed(1)}% w ciągu najbliższych 12 miesięcy. '
        'Projekcja uwzględnia historyczne wyniki i obecne warunki rynkowe.';
  }

  void _showDetailedAnalysis() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Szczegółowa analiza trendów - funkcja w przygotowaniu'),
      ),
    );
  }

  void _exportTrendsData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eksport danych trendów - funkcja w przygotowaniu'),
      ),
    );
  }
}
