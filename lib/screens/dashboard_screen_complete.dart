import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/investment.dart';
import '../models/product.dart';
import '../services/investment_service.dart';
import '../services/advanced_analytics_service.dart';
import '../widgets/advanced_analytics_widgets.dart';
import '../utils/currency_formatter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final InvestmentService _investmentService = InvestmentService();
  final AdvancedAnalyticsService _analyticsService = AdvancedAnalyticsService();

  // Dane podstawowe
  List<Investment> _recentInvestments = [];
  List<Investment> _investmentsRequiringAttention = [];

  // Zaawansowane metryki
  AdvancedDashboardMetrics? _advancedMetrics;

  bool _isLoading = true;
  String _selectedTimeFrame = '12M';
  int _selectedDashboardTab = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // === RESPONSYWNE FUNKCJE POMOCNICZE ===

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;
  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < 1024;
  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  double _getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  double _getHorizontalPadding(BuildContext context) =>
      _isMobile(context) ? 16.0 : 24.0;
  double _getVerticalSpacing(BuildContext context) =>
      _isMobile(context) ? 16.0 : 24.0;

  int _getCrossAxisCountForCards(BuildContext context) {
    if (_isMobile(context)) return 1;
    if (_isTablet(context)) return 2;
    return 4;
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Ładuj dane równolegle dla lepszej wydajności
      final results = await Future.wait([
        _analyticsService.getAdvancedDashboardMetrics(),
      ]);

      setState(() {
        _advancedMetrics = results[0];
        _isLoading = false;
      });

      // Start animation after data is loaded
      _fadeController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Błąd podczas ładowania danych: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ładowanie danych...',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildDashboardHeader(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  // === HEADER SECTION ===
  Widget _buildDashboardHeader() {
    return Container(
      padding: EdgeInsets.all(_getHorizontalPadding(context)),
      decoration: AppTheme.gradientDecoration,
      child: _isMobile(context) ? _buildMobileHeader() : _buildDesktopHeader(),
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Dashboard Inwestycyjny',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textOnPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildRefreshButton(),
          ],
        ),
        const SizedBox(height: 16),
        _buildTimeFrameSelector(),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Dashboard Inwestycyjny',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppTheme.textOnPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildTimeFrameSelector(),
        const SizedBox(width: 16),
        _buildRefreshButton(),
      ],
    );
  }

  Widget _buildTimeFrameSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedTimeFrame,
        dropdownColor: AppTheme.surfaceCard,
        underline: const SizedBox(),
        style: const TextStyle(color: AppTheme.textOnPrimary),
        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textOnPrimary),
        items: ['1M', '3M', '6M', '12M', '24M'].map((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedTimeFrame = newValue;
            });
            _loadDashboardData();
          }
        },
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: _loadDashboardData,
        icon: const Icon(Icons.refresh, color: AppTheme.textOnPrimary),
        tooltip: 'Odśwież dane',
      ),
    );
  }

  // === TAB BAR SECTION ===
  Widget _buildTabBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getHorizontalPadding(context),
        vertical: 16,
      ),
      child: _isMobile(context) ? _buildMobileTabBar() : _buildDesktopTabBar(),
    );
  }

  Widget _buildMobileTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCompactTabButton(0, 'Przegląd', Icons.dashboard),
          const SizedBox(width: 8),
          _buildCompactTabButton(1, 'Wydajność', Icons.trending_up),
          const SizedBox(width: 8),
          _buildCompactTabButton(2, 'Ryzyko', Icons.security),
          const SizedBox(width: 8),
          _buildCompactTabButton(3, 'Prognozy', Icons.insights),
          const SizedBox(width: 8),
          _buildCompactTabButton(4, 'Benchmarki', Icons.compare_arrows),
        ],
      ),
    );
  }

  Widget _buildDesktopTabBar() {
    return Row(
      children: [
        _buildTabButton(0, 'Przegląd', Icons.dashboard),
        _buildTabButton(1, 'Wydajność', Icons.trending_up),
        _buildTabButton(2, 'Ryzyko', Icons.security),
        _buildTabButton(3, 'Prognozy', Icons.insights),
        _buildTabButton(4, 'Benchmarki', Icons.compare_arrows),
      ],
    );
  }

  Widget _buildCompactTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedDashboardTab == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedDashboardTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.borderSecondary,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedDashboardTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDashboardTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === TAB CONTENT SECTION ===
  Widget _buildTabContent() {
    switch (_selectedDashboardTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildPerformanceTab();
      case 2:
        return _buildRiskTab();
      case 3:
        return _buildPredictionsTab();
      case 4:
        return _buildBenchmarkTab();
      default:
        return _buildOverviewTab();
    }
  }

  // === OVERVIEW TAB ===
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_getHorizontalPadding(context)),
      child: Column(
        children: [
          _isMobile(context) ? _buildMobileLayout() : _buildDesktopLayout(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildAdvancedSummaryCards(),
        const SizedBox(height: 24),
        _buildPortfolioComposition(),
        const SizedBox(height: 24),
        _buildQuickMetrics(),
        const SizedBox(height: 24),
        _buildRiskAlerts(),
        const SizedBox(height: 24),
        _buildRecentInvestments(),
        const SizedBox(height: 24),
        _buildAttentionRequired(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildAdvancedSummaryCards(),
              const SizedBox(height: 24),
              _buildQuickMetrics(),
              const SizedBox(height: 24),
              _buildRiskAlerts(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildPortfolioComposition(),
              const SizedBox(height: 24),
              _buildRecentInvestments(),
              const SizedBox(height: 24),
              _buildAttentionRequired(),
            ],
          ),
        ),
      ],
    );
  }

  // === HELPER METHODS ===
  String _getRealizedTrend() {
    if (_advancedMetrics == null) return '';
    final realized = _advancedMetrics!.portfolioMetrics.totalRealized;
    final invested = _advancedMetrics!.portfolioMetrics.totalInvested;
    if (invested > 0) {
      final trend = (realized / invested) * 100;
      return '${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(1)}%';
    }
    return '';
  }

  String _getProductTypeName(ProductType type) {
    switch (type) {
      case ProductType.shares:
        return 'Akcje';
      case ProductType.bonds:
        return 'Obligacje';
      case ProductType.apartments:
        return 'Nieruchomości';
      case ProductType.loans:
        return 'Pożyczki';
      default:
        return 'Inne';
    }
  }

  String _formatCurrency(double amount) {
    return CurrencyFormatter.formatCurrency(amount);
  }

  double _calculateInvestmentPerformance(Investment investment) {
    if (investment.investmentAmount <= 0) return 0.0;
    return ((investment.totalValue - investment.investmentAmount) /
            investment.investmentAmount) *
        100;
  }

  // === OVERVIEW TAB COMPONENTS ===

  Widget _buildAdvancedSummaryCards() {
    if (_advancedMetrics == null) return const SizedBox();

    final metrics = _advancedMetrics!.portfolioMetrics;

    if (_isMobile(context)) {
      return Column(
        children: [
          _buildSummaryCard(
            title: 'Łączna Wartość Portfela',
            value: _formatCurrency(metrics.totalValue),
            subtitle: 'Wszystkie inwestycje',
            icon: Icons.account_balance_wallet,
            color: AppTheme.primaryColor,
            trend:
                '${metrics.portfolioGrowthRate >= 0 ? '+' : ''}${metrics.portfolioGrowthRate.toStringAsFixed(1)}%',
            trendValue: metrics.portfolioGrowthRate,
            additionalInfo: [
              'ROI portfela: ${metrics.roi.toStringAsFixed(2)}%',
              'Średnia inwestycja: ${_formatCurrency(metrics.averageInvestmentSize)}',
            ],
            tooltip:
                'Całkowita wartość portfela = Aktywne inwestycje + Zrealizowane zyski. ROI = ((Aktualna wartość - Zainwestowany kapitał) / Zainwestowany kapitał) * 100%',
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            title: 'Zainwestowany Kapitał',
            value: _formatCurrency(metrics.totalInvested),
            subtitle: 'Całkowite wpłaty',
            icon: Icons.trending_up,
            color: AppTheme.infoColor,
            additionalInfo: [
              'Mediana: ${_formatCurrency(metrics.medianInvestmentSize)}',
              'Aktywne: ${metrics.activeInvestmentsCount}/${metrics.totalInvestmentsCount}',
            ],
            tooltip:
                'Suma wszystkich zainwestowanych kwot. Mediana to wartość środkowa wszystkich inwestycji. Aktywne to inwestycje, które jeszcze nie zostały w pełni zrealizowane.',
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            title: 'Zrealizowane Zyski',
            value: _formatCurrency(metrics.totalRealized),
            subtitle: 'Wypłacone środki',
            icon: Icons.monetization_on,
            color: AppTheme.successColor,
            trend: _getRealizedTrend(),
            additionalInfo: [
              'Odsetki: ${_formatCurrency(metrics.totalInterest)}',
              'Zysk całkowity: ${_formatCurrency(metrics.totalProfit)}',
            ],
            tooltip:
                'Kwoty już wypłacone z inwestycji. Odsetki to naliczone zyski. Zysk całkowity = Zrealizowane zyski + Niezrealizowane zyski z aktywnych inwestycji.',
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            title: 'Koncentracja Ryzyka',
            value:
                '${_advancedMetrics!.riskMetrics.concentrationRisk.toStringAsFixed(1)}%',
            subtitle: 'Wskaźnik dywersyfikacji',
            icon: Icons.pie_chart,
            color: AppTheme.getRiskColor(
              _getRiskLevel(_advancedMetrics!.riskMetrics.concentrationRisk),
            ),
            additionalInfo: [
              'VaR 95%: ${_advancedMetrics!.riskMetrics.valueAtRisk.toStringAsFixed(2)}%',
              'Sharpe: ${_advancedMetrics!.performanceMetrics.sharpeRatio.toStringAsFixed(3)}',
            ],
            tooltip:
                'Koncentracja ryzyka mierzy jak bardzo portfel jest skoncentrowany na pojedynczych inwestycjach. VaR 95% to maksymalna strata z 95% prawdopodobieństwem. Wskaźnik Sharpe\'a = (Zwrot - Stopa wolna od ryzyka) / Zmienność.',
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Łączna Wartość Portfela',
                value: _formatCurrency(metrics.totalValue),
                subtitle: 'Wszystkie inwestycje',
                icon: Icons.account_balance_wallet,
                color: AppTheme.primaryColor,
                trend:
                    '${metrics.portfolioGrowthRate >= 0 ? '+' : ''}${metrics.portfolioGrowthRate.toStringAsFixed(1)}%',
                trendValue: metrics.portfolioGrowthRate,
                additionalInfo: [
                  'ROI portfela: ${metrics.roi.toStringAsFixed(2)}%',
                  'Średnia inwestycja: ${_formatCurrency(metrics.averageInvestmentSize)}',
                ],
                tooltip:
                    'Całkowita wartość portfela = Aktywne inwestycje + Zrealizowane zyski. ROI = ((Aktualna wartość - Zainwestowany kapitał) / Zainwestowany kapitał) * 100%',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                title: 'Zainwestowany Kapitał',
                value: _formatCurrency(metrics.totalInvested),
                subtitle: 'Całkowite wpłaty',
                icon: Icons.trending_up,
                color: AppTheme.infoColor,
                additionalInfo: [
                  'Mediana: ${_formatCurrency(metrics.medianInvestmentSize)}',
                  'Aktywne: ${metrics.activeInvestmentsCount}/${metrics.totalInvestmentsCount}',
                ],
                tooltip:
                    'Suma wszystkich zainwestowanych kwot. Mediana to wartość środkowa wszystkich inwestycji. Aktywne to inwestycje, które jeszcze nie zostały w pełni zrealizowane.',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                title: 'Zrealizowane Zyski',
                value: _formatCurrency(metrics.totalRealized),
                subtitle: 'Wypłacone środki',
                icon: Icons.monetization_on,
                color: AppTheme.successColor,
                trend: _getRealizedTrend(),
                additionalInfo: [
                  'Odsetki: ${_formatCurrency(metrics.totalInterest)}',
                  'Zysk całkowity: ${_formatCurrency(metrics.totalProfit)}',
                ],
                tooltip:
                    'Kwoty już wypłacone z inwestycji. Odsetki to naliczone zyski. Zysk całkowity = Zrealizowane zyski + Niezrealizowane zyski z aktywnych inwestycji.',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                title: 'Koncentracja Ryzyka',
                value:
                    '${_advancedMetrics!.riskMetrics.concentrationRisk.toStringAsFixed(1)}%',
                subtitle: 'Wskaźnik dywersyfikacji',
                icon: Icons.pie_chart,
                color: AppTheme.getRiskColor(
                  _getRiskLevel(
                    _advancedMetrics!.riskMetrics.concentrationRisk,
                  ),
                ),
                additionalInfo: [
                  'VaR 95%: ${_advancedMetrics!.riskMetrics.valueAtRisk.toStringAsFixed(2)}%',
                  'Sharpe: ${_advancedMetrics!.performanceMetrics.sharpeRatio.toStringAsFixed(3)}',
                ],
                tooltip:
                    'Koncentracja ryzyka mierzy jak bardzo portfel jest skoncentrowany na pojedynczych inwestycjach. VaR 95% to maksymalna strata z 95% prawdopodobieństwem. Wskaźnik Sharpe\'a = (Zwrot - Stopa wolna od ryzyka) / Zmienność.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? trend,
    double? trendValue,
    List<String>? additionalInfo,
    String? tooltip,
  }) {
    return AdvancedMetricCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      color: color,
      trend: trend,
      trendValue: trendValue,
      additionalInfo: additionalInfo,
      tooltip: tooltip,
    );
  }

  Widget _buildQuickMetrics() {
    if (_advancedMetrics == null) return const SizedBox();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AdvancedMetricCard(
                title: 'Całkowity zwrot',
                value:
                    '${_advancedMetrics!.performanceMetrics.totalROI.toStringAsFixed(2)}%',
                subtitle: 'ROI',
                icon: Icons.trending_up,
                color: Colors.green,
                trend: _advancedMetrics!.performanceMetrics.totalROI > 0
                    ? 'up'
                    : 'down',
                trendValue: _advancedMetrics!.performanceMetrics.totalROI,
                additionalInfo: [
                  'CAGR: ${_advancedMetrics!.performanceMetrics.annualizedReturn.toStringAsFixed(2)}%',
                  'Sharpe: ${_advancedMetrics!.performanceMetrics.sharpeRatio.toStringAsFixed(2)}',
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AdvancedMetricCard(
                title: 'Momentum portfela',
                value:
                    '${_advancedMetrics!.portfolioMetrics.portfolioGrowthRate.toStringAsFixed(1)}%',
                subtitle: '3M trend',
                icon: Icons.speed,
                color: _getMomentumColor(
                  _advancedMetrics!.portfolioMetrics.portfolioGrowthRate,
                ),
                additionalInfo: [
                  'Liczba inwestycji: ${_advancedMetrics!.portfolioMetrics.totalInvestmentsCount}',
                  'Aktywne: ${_advancedMetrics!.portfolioMetrics.activeInvestmentsCount}',
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPortfolioComposition() {
    if (_advancedMetrics == null) return const SizedBox();

    final productData = <String, double>{};
    final productColors = <String, Color>{};

    _advancedMetrics!.productAnalytics.productPerformance.forEach((
      type,
      performance,
    ) {
      productData[_getProductTypeName(type)] = performance.totalValue;
      productColors[_getProductTypeName(type)] = AppTheme.getProductTypeColor(
        type.name,
      );
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: AdvancedPieChart(
        title: 'Skład Portfela',
        data: productData,
        colors: productColors,
        showPercentages: true,
      ),
    );
  }

  Widget _buildRiskAlerts() {
    if (_advancedMetrics == null) return const SizedBox();

    final riskMetrics = _advancedMetrics!.riskMetrics;
    final alerts = <Widget>[];

    // Sprawdź różne poziomy ryzyka
    if (riskMetrics.concentrationRisk > 25) {
      alerts.add(
        RiskAlertWidget(
          title: 'Wysoka koncentracja ryzyka',
          message:
              'Portfel jest zbyt skoncentrowany (${riskMetrics.concentrationRisk.toStringAsFixed(1)}%)',
          riskLevel: RiskLevel.high,
        ),
      );
    }

    if (riskMetrics.volatility > 15) {
      alerts.add(
        RiskAlertWidget(
          title: 'Podwyższona zmienność',
          message:
              'Portfel charakteryzuje się wysoką zmiennością (${riskMetrics.volatility.toStringAsFixed(1)}%)',
          riskLevel: RiskLevel.medium,
        ),
      );
    }

    if (riskMetrics.liquidityRisk > 70) {
      alerts.add(
        RiskAlertWidget(
          title: 'Ryzyko płynności',
          message:
              'Wysoki udział inwestycji o niskiej płynności (${riskMetrics.liquidityRisk.toStringAsFixed(1)}%)',
          riskLevel: RiskLevel.low,
        ),
      );
    }

    if (alerts.isEmpty) {
      alerts.add(
        RiskAlertWidget(
          title: 'Poziom ryzyka kontrolowany',
          message: 'Nie wykryto znaczących zagrożeń ryzyka',
          riskLevel: RiskLevel.low,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alerty Ryzyka',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...alerts,
        ],
      ),
    );
  }

  Widget _buildRecentInvestments() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Najnowsze Inwestycje',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_recentInvestments.isEmpty)
            const Text('Brak ostatnich inwestycji')
          else
            ...(_recentInvestments
                .take(5)
                .map((investment) => _buildInvestmentListItem(investment))),
        ],
      ),
    );
  }

  Widget _buildAttentionRequired() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wymagają Uwagi',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_investmentsRequiringAttention.isEmpty)
            const Text('Wszystkie inwestycje w normie')
          else
            ...(_investmentsRequiringAttention
                .take(5)
                .map((investment) => _buildAttentionItem(investment))),
        ],
      ),
    );
  }

  Widget _buildInvestmentListItem(Investment investment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.getProductTypeColor(investment.productType.name),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getProductIcon(investment.productType.toString()),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investment.productName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Klient: ${investment.clientName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(investment.totalValue),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '${_calculateInvestmentPerformance(investment) >= 0 ? '+' : ''}${_calculateInvestmentPerformance(investment).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: _calculateInvestmentPerformance(investment) >= 0
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionItem(Investment investment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: AppTheme.warningColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investment.productName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Spadek wartości: ${_calculateInvestmentPerformance(investment).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(investment.totalValue),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // === TABS PLACEHOLDERS (będą implementowane później) ===
  Widget _buildPerformanceTab() {
    if (_advancedMetrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final performance = _advancedMetrics!.performanceMetrics;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceHeader(),
          const SizedBox(height: 24),

          // Główne metryki wydajności
          _buildPerformanceOverview(performance),
          const SizedBox(height: 24),

          // Wykres wydajności w czasie
          _buildPerformanceChart(),
          const SizedBox(height: 24),

          // Analiza produktów
          _buildProductPerformanceAnalysis(performance),
          const SizedBox(height: 24),

          // Ranking najlepszych inwestycji
          _buildTopPerformersSection(performance),
        ],
      ),
    );
  }

  Widget _buildRiskTab() {
    if (_advancedMetrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final risk = _advancedMetrics!.riskMetrics;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRiskHeader(),
          const SizedBox(height: 24),

          // Główne metryki ryzyka
          _buildRiskOverview(risk),
          const SizedBox(height: 24),

          // Macierz ryzyka
          _buildRiskMatrix(),
          const SizedBox(height: 24),

          // Koncentracja ryzyka
          _buildRiskConcentration(risk),
          const SizedBox(height: 24),

          // Analiza VaR
          _buildVaRAnalysis(risk),
        ],
      ),
    );
  }

  Widget _buildPredictionsTab() {
    if (_advancedMetrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final predictions = _advancedMetrics!.predictionMetrics;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPredictionsHeader(),
          const SizedBox(height: 24),

          // Główne prognozy
          _buildPredictionsOverview(predictions),
          const SizedBox(height: 24),

          // Wykres prognozy
          _buildPredictionChart(),
          const SizedBox(height: 24),

          // Scenariusze
          _buildScenarioAnalysis(),
          const SizedBox(height: 24),

          // Rekomendacje
          _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildBenchmarkTab() {
    if (_advancedMetrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final benchmark = _advancedMetrics!.benchmarkMetrics;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBenchmarkHeader(),
          const SizedBox(height: 24),

          // Główne metryki porównawcze
          _buildBenchmarkOverview(benchmark),
          const SizedBox(height: 24),

          // Wykres porównawczy
          _buildBenchmarkChart(),
          const SizedBox(height: 24),

          // Tabela benchmarków
          _buildBenchmarkTable(),
          const SizedBox(height: 24),

          // Analiza outperformance
          _buildOutperformanceAnalysis(benchmark),
        ],
      ),
    );
  }

  // === HELPER METHODS ===

  // === PERFORMANCE TAB METHODS ===
  Widget _buildPerformanceHeader() {
    return Row(
      children: [
        Icon(Icons.trending_up, color: AppTheme.secondaryGold, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analiza Wydajności',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kompleksowa analiza zwrotów i efektywności portfela',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        _buildPerformanceTooltip(),
      ],
    );
  }

  Widget _buildPerformanceTooltip() {
    return Tooltip(
      message:
          'Analiza wydajności opiera się na:\n'
          '• ROI = (Wartość obecna - Wartość początkowa) / Wartość początkowa\n'
          '• CAGR = (Wartość końcowa / Wartość początkowa)^(1/lata) - 1\n'
          '• Współczynnik Sharpe = (Zwrot - Zwrot bezryzyczny) / Odchylenie standardowe\n'
          '• Maksymalny spadek = Największy spadek od szczytu do dołka',
      padding: const EdgeInsets.all(16),
      textStyle: const TextStyle(fontSize: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundModal,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Icon(Icons.help_outline, color: AppTheme.textSecondary, size: 20),
    );
  }

  Widget _buildPerformanceOverview(PerformanceMetrics performance) {
    final cards = [
      AdvancedMetricCard(
        title: 'ROI Całkowity',
        value: '${performance.totalROI.toStringAsFixed(2)}%',
        subtitle: 'Zwrot z inwestycji',
        icon: Icons.trending_up,
        color: AppTheme.getPerformanceColor(performance.totalROI),
      ),
      AdvancedMetricCard(
        title: 'CAGR',
        value: '${performance.annualizedReturn.toStringAsFixed(2)}%',
        subtitle: 'Roczny zwrot składany',
        icon: Icons.show_chart,
        color: AppTheme.getPerformanceColor(performance.annualizedReturn),
      ),
      AdvancedMetricCard(
        title: 'Współczynnik Sharpe',
        value: performance.sharpeRatio.toStringAsFixed(3),
        subtitle: 'Stosunek zysku do ryzyka',
        icon: Icons.balance,
        color: AppTheme.getPerformanceColor(performance.sharpeRatio * 10),
      ),
      AdvancedMetricCard(
        title: 'Maksymalny Spadek',
        value: '${performance.maxDrawdown.toStringAsFixed(2)}%',
        subtitle: 'Największa strata',
        icon: Icons.trending_down,
        color: AppTheme.getPerformanceColor(-performance.maxDrawdown),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }

  Widget _buildPerformanceChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wydajność w czasie',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(show: true),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generatePerformanceData(),
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withOpacity(0.1),
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

  List<FlSpot> _generatePerformanceData() {
    // Generowanie przykładowych danych wydajności
    final List<FlSpot> spots = [];
    for (int i = 0; i < 12; i++) {
      spots.add(FlSpot(i.toDouble(), (i * 2.5 + (i % 3) * 1.2).toDouble()));
    }
    return spots;
  }

  Widget _buildProductPerformanceAnalysis(PerformanceMetrics performance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analiza wydajności według produktów',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Szczegółowa analiza zostanie wdrożona w następnej iteracji',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersSection(PerformanceMetrics performance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Najlepsze inwestycje',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Ranking najlepszych inwestycji zostanie wdrożony w następnej iteracji',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // === RISK TAB METHODS ===
  Widget _buildRiskHeader() {
    return Row(
      children: [
        Icon(Icons.security, color: AppTheme.warningColor, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analiza Ryzyka',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kompleksowa ocena poziomu ryzyka portfela',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        _buildRiskTooltip(),
      ],
    );
  }

  Widget _buildRiskTooltip() {
    return Tooltip(
      message:
          'Analiza ryzyka obejmuje:\n'
          '• VaR (Value at Risk) - maksymalna strata przy 95% prawdopodobieństwa\n'
          '• Współczynnik Beta - wrażliwość na ruchy rynku\n'
          '• Odchylenie standardowe - zmienność zwrotów\n'
          '• Koncentracja - udział największych pozycji w portfelu\n'
          '• Korelacja - zależności między inwestycjami',
      padding: const EdgeInsets.all(16),
      textStyle: const TextStyle(fontSize: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundModal,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Icon(Icons.help_outline, color: AppTheme.textSecondary, size: 20),
    );
  }

  Widget _buildRiskOverview(RiskMetrics risk) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        AdvancedMetricCard(
          title: 'VaR (95%)',
          value: '${risk.valueAtRisk.toStringAsFixed(2)}%',
          subtitle: 'Maksymalna strata',
          icon: Icons.warning,
          color: AppTheme.getRiskColor(_getRiskLevel(risk.valueAtRisk)),
        ),
        AdvancedMetricCard(
          title: 'Beta Portfela',
          value: risk.beta.toStringAsFixed(3),
          subtitle: 'Wrażliwość na rynek',
          icon: Icons.analytics,
          color: _getBetaColor(risk.beta),
        ),
        AdvancedMetricCard(
          title: 'Odchylenie Std.',
          value: '${risk.volatility.toStringAsFixed(2)}%',
          subtitle: 'Zmienność zwrotów',
          icon: Icons.show_chart,
          color: _getVolatilityColor(risk.volatility),
        ),
        AdvancedMetricCard(
          title: 'Koncentracja',
          value: '${risk.concentrationRisk.toStringAsFixed(1)}%',
          subtitle: 'Top 5 pozycji',
          icon: Icons.pie_chart,
          color: _getConcentrationColor(risk.concentrationRisk),
        ),
      ],
    );
  }

  Widget _buildRiskMatrix() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Macierz Ryzyko vs Zwrot',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Tooltip(
                message:
                    'Wykres pokazuje rozmieszczenie inwestycji względem osi ryzyka i zwrotu',
                child: Icon(Icons.info_outline, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: ScatterChart(
              ScatterChartData(
                backgroundColor: Colors.transparent,
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(show: true),
                borderData: FlBorderData(show: true),
                scatterSpots: _generateRiskReturnSpots(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskConcentration(RiskMetrics risk) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Koncentracja Ryzyka',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: _generateRiskConcentrationSections(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRiskLegendItem(
                        'Obligacje',
                        AppTheme.bondsColor,
                        '35%',
                      ),
                      _buildRiskLegendItem(
                        'Udziały',
                        AppTheme.sharesColor,
                        '30%',
                      ),
                      _buildRiskLegendItem(
                        'Pożyczki',
                        AppTheme.loansColor,
                        '20%',
                      ),
                      _buildRiskLegendItem(
                        'Apartamenty',
                        AppTheme.apartmentsColor,
                        '15%',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaRAnalysis(RiskMetrics risk) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analiza Value at Risk',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildVaRItem(
                  'VaR 95%',
                  '${risk.valueAtRisk.toStringAsFixed(2)}%',
                  AppTheme.errorColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildVaRItem(
                  'VaR 99%',
                  '${(risk.valueAtRisk * 1.5).toStringAsFixed(2)}%',
                  AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildVaRItem(
                  'Expected Shortfall',
                  '${(risk.valueAtRisk * 1.3).toStringAsFixed(2)}%',
                  AppTheme.infoColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVaRItem(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskLegendItem(String label, Color color, String percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            percentage,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _getRiskLevel(double var95) {
    if (var95 <= 2) return 'low';
    if (var95 <= 5) return 'medium';
    if (var95 <= 10) return 'high';
    return 'very_high';
  }

  Color _getMomentumColor(double momentum) {
    if (momentum > 5) return AppTheme.successColor;
    if (momentum > 0) return AppTheme.infoColor;
    if (momentum > -5) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Color _getBetaColor(double beta) {
    if (beta >= 0.8 && beta <= 1.2) return AppTheme.successColor;
    if (beta >= 0.5 && beta <= 1.5) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Color _getVolatilityColor(double volatility) {
    if (volatility <= 10) return AppTheme.successColor;
    if (volatility <= 20) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Color _getConcentrationColor(double concentration) {
    if (concentration <= 30) return AppTheme.successColor;
    if (concentration <= 50) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  List<ScatterSpot> _generateRiskReturnSpots() {
    // Generowanie przykładowych danych ryzyko vs zwrot
    final List<ScatterSpot> spots = [];
    for (int i = 0; i < 15; i++) {
      final risk = 5 + (i % 3) * 5.0; // 5-15% ryzyko
      final returnValue = 2 + (i * 0.8); // 2-14% zwrot
      spots.add(ScatterSpot(risk, returnValue));
    }
    return spots;
  }

  List<PieChartSectionData> _generateRiskConcentrationSections() {
    return [
      PieChartSectionData(
        color: AppTheme.bondsColor,
        value: 35,
        title: '',
        radius: 60,
      ),
      PieChartSectionData(
        color: AppTheme.sharesColor,
        value: 30,
        title: '',
        radius: 60,
      ),
      PieChartSectionData(
        color: AppTheme.loansColor,
        value: 20,
        title: '',
        radius: 60,
      ),
      PieChartSectionData(
        color: AppTheme.apartmentsColor,
        value: 15,
        title: '',
        radius: 60,
      ),
    ];
  }

  IconData _getProductIcon(String productType) {
    switch (productType.toLowerCase()) {
      case 'shares':
        return Icons.trending_up;
      case 'bonds':
        return Icons.account_balance;
      case 'apartments':
        return Icons.home;
      case 'loans':
        return Icons.attach_money;
      default:
        return Icons.pie_chart;
    }
  }

  // === PREDICTIONS TAB METHODS ===
  Widget _buildPredictionsHeader() {
    return Row(
      children: [
        Icon(Icons.insights, color: AppTheme.infoPrimary, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prognozy i Analiza Predykcyjna',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Przewidywania przyszłej wydajności portfela',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        _buildPredictionsTooltip(),
      ],
    );
  }

  Widget _buildPredictionsTooltip() {
    return Tooltip(
      message:
          'Prognozy opierają się na:\n'
          '• Analizie historycznych trendów\n'
          '• Modelach regresji liniowej i Monte Carlo\n'
          '• Cykliczności rynkowej\n'
          '• Korelacji z indeksami rynkowymi\n'
          '• Analiza scenariuszy: optymistyczny, bazowy, pesymistyczny',
      padding: const EdgeInsets.all(16),
      textStyle: const TextStyle(fontSize: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundModal,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Icon(Icons.help_outline, color: AppTheme.textSecondary, size: 20),
    );
  }

  Widget _buildPredictionsOverview(PredictionMetrics predictions) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        AdvancedMetricCard(
          title: 'Prognoza 12M',
          value: '${predictions.projectedReturns.toStringAsFixed(2)}%',
          subtitle: 'Przewidywany zwrot',
          icon: Icons.trending_up,
          color: AppTheme.getPerformanceColor(predictions.projectedReturns),
        ),
        AdvancedMetricCard(
          title: 'Wartość docelowa',
          value: _formatCurrency(predictions.expectedMaturityValue),
          subtitle: 'Za 12 miesięcy',
          icon: Icons.account_balance_wallet,
          color: AppTheme.secondaryGold,
        ),
        AdvancedMetricCard(
          title: 'Ryzyko skorygowany',
          value: '${predictions.riskAdjustedReturns.toStringAsFixed(2)}%',
          subtitle: 'Skorygowany o ryzyko',
          icon: Icons.security,
          color: AppTheme.getPerformanceColor(predictions.riskAdjustedReturns),
        ),
        AdvancedMetricCard(
          title: 'Optymalizacja',
          value: predictions.portfolioOptimization,
          subtitle: 'Rekomendacja',
          icon: Icons.analytics,
          color: AppTheme.infoColor,
        ),
      ],
    );
  }

  // Dodajemy pozostałe metody pomocnicze
  List<FlSpot> _generateOptimisticScenario() {
    final List<FlSpot> spots = [];
    double baseValue = 100;
    for (int i = 0; i < 13; i++) {
      baseValue *= 1.015; // 1.5% miesięcznie
      spots.add(FlSpot(i.toDouble(), baseValue));
    }
    return spots;
  }

  List<FlSpot> _generateBaseScenario() {
    final List<FlSpot> spots = [];
    double baseValue = 100;
    for (int i = 0; i < 13; i++) {
      baseValue *= 1.007; // 0.7% miesięcznie
      spots.add(FlSpot(i.toDouble(), baseValue));
    }
    return spots;
  }

  List<FlSpot> _generatePessimisticScenario() {
    final List<FlSpot> spots = [];
    double baseValue = 100;
    for (int i = 0; i < 13; i++) {
      baseValue *= 1.002; // 0.2% miesięcznie
      spots.add(FlSpot(i.toDouble(), baseValue));
    }
    return spots;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPredictionChart() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prognozy rozwoju portfela',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Wykres prognoz zostanie wdrożony w następnej iteracji',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioAnalysis() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analiza Scenariuszy',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Szczegółowa analiza scenariuszy zostanie wdrożona w następnej iteracji',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rekomendacje',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'System rekomendacji zostanie wdrożony w następnej iteracji',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkHeader() {
    return Row(
      children: [
        Icon(Icons.compare_arrows, color: AppTheme.infoPrimary, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analiza Benchmarków',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Porównanie wydajności z rynkowymi wskaźnikami',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenchmarkOverview(BenchmarkMetrics benchmark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        AdvancedMetricCard(
          title: 'vs Rynek',
          value: '${benchmark.vsMarketReturn.toStringAsFixed(2)}%',
          subtitle: 'Względem rynku',
          icon: Icons.trending_up,
          color: AppTheme.getPerformanceColor(benchmark.vsMarketReturn),
        ),
        AdvancedMetricCard(
          title: 'Wydajność Względna',
          value: '${benchmark.relativePerfomance.toStringAsFixed(2)}%',
          subtitle: 'Outperformance',
          icon: Icons.analytics,
          color: AppTheme.getPerformanceColor(benchmark.relativePerfomance),
        ),
        AdvancedMetricCard(
          title: 'Korelacja',
          value: benchmark.benchmarkCorrelation.toStringAsFixed(3),
          subtitle: 'Z benchmarkiem',
          icon: Icons.show_chart,
          color: AppTheme.primaryColor,
        ),
        AdvancedMetricCard(
          title: 'Przewyższające',
          value: '${benchmark.outperformingInvestments}',
          subtitle: 'Lepsze od benchmarku',
          icon: Icons.star,
          color: AppTheme.successColor,
        ),
      ],
    );
  }

  Widget _buildBenchmarkChart() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Porównanie wydajności',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Wykres porównawczy zostanie wdrożony w następnej iteracji',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkTable() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tabela benchmarków',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Tabela porównawcza zostanie wdrożona w następnej iteracji',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildOutperformanceAnalysis(BenchmarkMetrics benchmark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analiza Outperformance',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Analiza outperformance zostanie wdrożona w następnej iteracji',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generatePortfolioPerformance() {
    final List<FlSpot> spots = [];
    for (int i = 0; i < 12; i++) {
      final performance = 2 + (i * 0.9);
      spots.add(FlSpot(i.toDouble(), performance));
    }
    return spots;
  }
}
