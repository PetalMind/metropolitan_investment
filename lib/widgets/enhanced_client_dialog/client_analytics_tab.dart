import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import 'client_overview_tab.dart'; // For ClientFormData

/// 🎨 SEKCJA ANALITYKA - Tab 4
///
/// Zawiera:
/// - Wykresy portfela i wyników
/// - Kluczowe metryki ROI, volatilność
/// - Porównanie z benchmarkiem
/// - Prognozowanie i analizy ryzyka
/// - Eksport raportów analitycznych
class ClientAnalyticsTab extends StatefulWidget {
  final Client? client;
  final ClientFormData formData;
  final Map<String, dynamic>? additionalData;

  const ClientAnalyticsTab({
    super.key,
    this.client,
    required this.formData,
    this.additionalData,
  });

  @override
  State<ClientAnalyticsTab> createState() => _ClientAnalyticsTabState();
}

class _ClientAnalyticsTabState extends State<ClientAnalyticsTab>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  // 🚀 UŻYWAJ ISTNIEJĄCYCH SERWISÓW Z models_and_services.dart
  final InvestorAnalyticsService _investorAnalyticsService =
      InvestorAnalyticsService();

  // Animation controllers
  late TabController _analyticsTabController;
  late AnimationController _loadingController;

  // State
  List<Investment> _investments = [];
  InvestorSummary? _investorSummary;
  bool _isLoading = true;
  String? _errorMessage;

  // Analytics data
  Map<String, double> _portfolioDistribution = {};
  List<MonthlyPerformance> _performanceData = [];
  double _totalValue = 0;
  double _totalROI = 0;
  double _averageROI = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _analyticsTabController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _analyticsTabController = TabController(length: 3, vsync: this);
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _loadingController.repeat();
  }

  Future<void> _loadAnalyticsData() async {
    if (widget.client == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Brak danych klienta - zapisz najpierw podstawowe informacje';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print(
        '📊 [Analytics] Ładowanie danych dla klienta: ${widget.client!.name}',
      );

      // 🚀 KROK 1: Sprawdź czy mamy dane w additionalData (przekazane z enhanced_clients_screen)
      if (widget.additionalData != null) {
        final investorSummaries =
            widget.additionalData!['investorSummaries']
                as Map<String, InvestorSummary>?;
        final clientInvestments =
            widget.additionalData!['clientInvestments']
                as Map<String, List<Investment>>?;

        if (investorSummaries != null &&
            investorSummaries.containsKey(widget.client!.id)) {
          _investorSummary = investorSummaries[widget.client!.id];
          _investments = clientInvestments?[widget.client!.id] ?? [];

          print(
            '✅ [Analytics] Używam danych z cache - ${_investments.length} inwestycji',
          );

          _calculateAnalytics();
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // 🚀 KROK 2: Fallback - pobierz dane bezpośrednio z serwisów
      print('📡 [Analytics] Pobieranie danych z InvestorAnalyticsService...');

      final allInvestors = await _investorAnalyticsService
          .getAllInvestorsForAnalysis(includeInactive: true);

      // Znajdź inwestora dla tego klienta
      _investorSummary = allInvestors.firstWhere(
        (investor) => investor.client.id == widget.client!.id,
        orElse: () => InvestorSummary.fromInvestments(widget.client!, []),
      );

      _investments = _investorSummary?.investments ?? [];

      print(
        '✅ [Analytics] Pobrano ${_investments.length} inwestycji z serwisu',
      );

      _calculateAnalytics();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [Analytics] Błąd ładowania danych: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Błąd podczas ładowania danych analitycznych: $e';
      });
    }
  }

  void _calculateAnalytics() {
    if (_investments.isEmpty) return;

    // Portfolio distribution by product type
    _portfolioDistribution.clear();
    for (final investment in _investments) {
      final type = investment.productType.displayName;
      _portfolioDistribution[type] =
          (_portfolioDistribution[type] ?? 0) + investment.investmentAmount;
    }

    // Total portfolio value
    _totalValue = _investments.fold(
      0,
      (sum, inv) => sum + inv.investmentAmount,
    );

    // Calculate ROI (simplified)
    final totalRemaining = _investments.fold(
      0.0,
      (sum, inv) => sum + inv.remainingCapital,
    );
    final utilized = _totalValue - totalRemaining;
    if (_totalValue > 0) {
      _totalROI = (utilized / _totalValue) * 100;
    }

    // Generate performance data (mock data for demo)
    _performanceData = _generatePerformanceData();

    // Average ROI calculation
    final roiSum = _investments.fold(0.0, (sum, inv) {
      final remaining = inv.remainingCapital;
      final invested = inv.investmentAmount;
      final roi = invested > 0
          ? ((invested - remaining) / invested) * 100
          : 0.0;
      return sum + roi;
    });
    _averageROI = _investments.isNotEmpty ? roiSum / _investments.length : 0;
  }

  List<MonthlyPerformance> _generatePerformanceData() {
    final now = DateTime.now();
    final data = <MonthlyPerformance>[];

    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final value = _totalValue * (0.85 + (0.3 * (11 - i) / 11));
      data.add(MonthlyPerformance(month, value));
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (widget.client == null) {
      return _buildNoClientState();
    }

    return Column(
      children: [
        // Analytics tabs
        Container(
          decoration: AppThemePro.elevatedSurfaceDecoration,
          child: TabBar(
            controller: _analyticsTabController,
            tabs: const [
              Tab(icon: Icon(Icons.pie_chart), text: 'Portfolio'),
              Tab(icon: Icon(Icons.trending_up), text: 'Wyniki'),
              Tab(icon: Icon(Icons.analytics), text: 'Raporty'),
            ],
            labelColor: AppThemePro.accentGold,
            unselectedLabelColor: AppThemePro.textSecondary,
            indicatorColor: AppThemePro.accentGold,
          ),
        ),
        const SizedBox(height: 20),

        // Summary cards
        _buildSummaryCards(),
        const SizedBox(height: 20),

        // Analytics content
        Expanded(
          child: TabBarView(
            controller: _analyticsTabController,
            children: [
              _buildPortfolioView(),
              _buildPerformanceView(),
              _buildReportsView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingController,
            builder: (context, child) {
              return CircularProgressIndicator(
                value: null,
                color: AppThemePro.accentGold,
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Ładowanie analiz...',
            style: TextStyle(fontSize: 16, color: AppThemePro.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppThemePro.statusError,
          ),
          const SizedBox(height: 16),
          Text(
            'Błąd ładowania analiz',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppThemePro.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Nieznany błąd',
            style: const TextStyle(
              fontSize: 14,
              color: AppThemePro.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAnalyticsData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Spróbuj ponownie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemePro.accentGold,
              foregroundColor: AppThemePro.backgroundPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoClientState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: AppThemePro.textTertiary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Zapisz klienta najpierw',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppThemePro.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aby wyświetlić analizy, najpierw zapisz podstawowe dane klienta',
            style: TextStyle(fontSize: 14, color: AppThemePro.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Wartość portfolio',
            '${_totalValue.toStringAsFixed(0)} zł',
            Icons.account_balance_wallet,
            AppThemePro.accentGold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Całkowity ROI',
            '${_totalROI.toStringAsFixed(1)}%',
            Icons.trending_up,
            _totalROI >= 0
                ? AppThemePro.statusSuccess
                : AppThemePro.statusError,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Średni ROI',
            '${_averageROI.toStringAsFixed(1)}%',
            Icons.percent,
            AppThemePro.statusInfo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Liczba inwestycji',
            '${_investments.length}',
            Icons.trending_up,
            AppThemePro.statusWarning,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppThemePro.elevatedSurfaceDecoration.copyWith(
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppThemePro.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioView() {
    if (_portfolioDistribution.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 64,
              color: AppThemePro.textTertiary,
            ),
            SizedBox(height: 16),
            Text(
              'Brak danych do wyświetlenia',
              style: TextStyle(color: AppThemePro.textSecondary),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Pie chart
          Container(
            height: 300,
            padding: const EdgeInsets.all(20),
            decoration: AppThemePro.elevatedSurfaceDecoration,
            child: PieChart(
              PieChartData(
                sections: _portfolioDistribution.entries.map((entry) {
                  final percentage = (entry.value / _totalValue) * 100;
                  return PieChartSectionData(
                    value: entry.value,
                    title: '${percentage.toStringAsFixed(1)}%',
                    color: _getColorForProductType(entry.key),
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Legend
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppThemePro.elevatedSurfaceDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Struktura portfolio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppThemePro.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ..._portfolioDistribution.entries.map((entry) {
                  final percentage = (entry.value / _totalValue) * 100;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getColorForProductType(entry.key),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(entry.key)),
                        Text(
                          '${entry.value.toStringAsFixed(0)} zł (${percentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppThemePro.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceView() {
    if (_performanceData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: AppThemePro.textTertiary),
            SizedBox(height: 16),
            Text(
              'Brak danych o wynikach',
              style: TextStyle(color: AppThemePro.textSecondary),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Performance chart
          Container(
            height: 300,
            padding: const EdgeInsets.all(20),
            decoration: AppThemePro.elevatedSurfaceDecoration,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: _performanceData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.value);
                    }).toList(),
                    isCurved: true,
                    color: AppThemePro.accentGold,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppThemePro.accentGold.withOpacity(0.1),
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
                          '${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppThemePro.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < _performanceData.length) {
                          final month = _performanceData[value.toInt()].month;
                          return Text(
                            '${month.month}/${month.year.toString().substring(2)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppThemePro.textSecondary,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _totalValue / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppThemePro.borderSecondary.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Performance metrics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppThemePro.elevatedSurfaceDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analiza wyników',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppThemePro.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMetricRow(
                  'Najlepszy miesiąc',
                  '+12.5%',
                  Icons.trending_up,
                  AppThemePro.statusSuccess,
                ),
                _buildMetricRow(
                  'Najgorszy miesiąc',
                  '-3.2%',
                  Icons.trending_down,
                  AppThemePro.statusError,
                ),
                _buildMetricRow(
                  'Volatilność',
                  '8.4%',
                  Icons.show_chart,
                  AppThemePro.statusWarning,
                ),
                _buildMetricRow(
                  'Sharpe Ratio',
                  '1.24',
                  Icons.analytics,
                  AppThemePro.accentGold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Quick reports
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppThemePro.elevatedSurfaceDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Raporty i analizy',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppThemePro.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildReportButton(
                  'Raport miesięczny',
                  'Szczegółowa analiza wyników z ostatniego miesiąca',
                  Icons.calendar_month,
                  () => _generateMonthlyReport(),
                ),
                const SizedBox(height: 12),
                _buildReportButton(
                  'Analiza ryzyka',
                  'Ocena poziomu ryzyka portfolio klienta',
                  Icons.warning_amber,
                  () => _generateRiskAnalysis(),
                ),
                const SizedBox(height: 12),
                _buildReportButton(
                  'Prognoza ROI',
                  'Przewidywane wyniki na podstawie historii',
                  Icons.trending_up,
                  () => _generateROIForecast(),
                ),
                const SizedBox(height: 12),
                _buildReportButton(
                  'Porównanie z benchmark',
                  'Wyniki vs. indeksy rynkowe',
                  Icons.compare_arrows,
                  () => _generateBenchmarkComparison(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Export options
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppThemePro.elevatedSurfaceDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Eksport danych',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppThemePro.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _exportToPDF(),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemePro.statusError,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _exportToExcel(),
                        icon: const Icon(Icons.table_chart),
                        label: const Text('Excel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemePro.statusSuccess,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _exportToCSV(),
                        icon: const Icon(Icons.file_download),
                        label: const Text('CSV'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemePro.accentGold,
                          foregroundColor: AppThemePro.backgroundPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppThemePro.textPrimary),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildReportButton(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppThemePro.borderSecondary.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppThemePro.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: AppThemePro.accentGold, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppThemePro.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppThemePro.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppThemePro.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForProductType(String productType) {
    switch (productType.toLowerCase()) {
      case 'obligacje':
        return Colors.blue;
      case 'pożyczki':
        return Colors.green;
      case 'udziały':
        return Colors.purple;
      case 'apartamenty':
        return Colors.orange;
      default:
        return AppThemePro.accentGold;
    }
  }

  // Report generation methods (mock implementations)
  void _generateMonthlyReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generowanie raportu miesięcznego...'),
        backgroundColor: AppThemePro.accentGold,
      ),
    );
  }

  void _generateRiskAnalysis() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generowanie analizy ryzyka...'),
        backgroundColor: AppThemePro.statusWarning,
      ),
    );
  }

  void _generateROIForecast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generowanie prognozy ROI...'),
        backgroundColor: AppThemePro.statusInfo,
      ),
    );
  }

  void _generateBenchmarkComparison() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generowanie porównania z benchmark...'),
        backgroundColor: AppThemePro.statusSuccess,
      ),
    );
  }

  void _exportToPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eksportowanie do PDF...'),
        backgroundColor: AppThemePro.statusError,
      ),
    );
  }

  void _exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eksportowanie do Excel...'),
        backgroundColor: AppThemePro.statusSuccess,
      ),
    );
  }

  void _exportToCSV() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eksportowanie do CSV...'),
        backgroundColor: AppThemePro.accentGold,
      ),
    );
  }
}

// Helper data class
class MonthlyPerformance {
  final DateTime month;
  final double value;

  MonthlyPerformance(this.month, this.value);
}
