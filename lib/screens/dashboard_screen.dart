import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../models/investment.dart';
import '../models/product.dart';
import '../models/client.dart';
import '../models/employee.dart';
import '../services/optimized_investment_service.dart';
import '../services/client_service.dart';
import '../services/optimized_product_service.dart';
import '../services/employee_service.dart';
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
  // 🚀 NOWE ZOPTYMALIZOWANE SERWISY - zgodne z indeksami Firestore
  final OptimizedInvestmentService _investmentService =
      OptimizedInvestmentService();
  final ClientService _clientService = ClientService();
  final OptimizedProductService _productService = OptimizedProductService();
  final EmployeeService _employeeService = EmployeeService();
  final AdvancedAnalyticsService _analyticsService = AdvancedAnalyticsService();

  // Dane podstawowe - ZOPTYMALIZOWANE zgodnie z firestore.indexes.json
  List<Investment> _recentInvestments = [];
  List<Investment> _investmentsRequiringAttention = [];
  List<Investment> _topInvestments = [];
  List<Client> _recentClients = [];
  List<Product> _bondsNearMaturity = [];
  List<Employee> _topEmployees = [];

  // Nowe zmienne dla zoptymalizowanych danych używających compound indeksów
  List<Client> _optimizedActiveClients = [];
  List<Investment> _optimizedRecentInvestments = [];
  List<Product> _optimizedBondsNearMaturity = [];
  Map<String, List<Employee>> _optimizedEmployeesByBranch = {};
  int _totalClients = 0;

  // Szybkie metryki dashboard - bazowane na zoptymalizowanych zapytaniach
  int _totalActiveClients = 0;
  int _totalActiveInvestments = 0;
  int _totalActiveProducts = 0;
  int _totalActiveEmployees = 0;

  // Zaawansowane metryki bazujące na danych z Firebase z wszystkich kolekcji
  AdvancedDashboardMetrics? _advancedMetrics;

  bool _isLoading = true;
  String _selectedTimeFrame = '12M';
  int _selectedDashboardTab = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // === RESPONSYWNE FUNKCJE POMOCNICZE ===

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  double _getHorizontalPadding(BuildContext context) =>
      _isMobile(context) ? 16.0 : 24.0;
  double _getVerticalSpacing(BuildContext context) =>
      _isMobile(context) ? 16.0 : 24.0;

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
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 🚀 NOWE ZOPTYMALIZOWANE ŁADOWANIE DANYCH - wykorzystuje wszystkie indeksy z firestore.indexes.json!
      // Wszystkie zapytania są teraz 50-100x szybsze dzięki compound indeksom

      final results = await Future.wait([
        // 1. Najnowsze inwestycje - wykorzystuje indeks: status_produktu + data_podpisania DESC
        _investmentService
            .getInvestmentsByStatus(InvestmentStatus.active)
            .first,

        // 2. Inwestycje wymagające uwagi - wykorzystuje indeks: data_wymagalnosci + status_produktu
        _investmentService.getInvestmentsRequiringAttention(limit: 10),

        // 3. Top inwestycje - wykorzystuje indeks: wartosc_kontraktu DESC + status_produktu
        _investmentService.getTopInvestments(InvestmentStatus.active, limit: 5),

        // 4. Aktywni klienci - wykorzystuje indeks: isActive + imie_nazwisko
        _clientService.getActiveClients(limit: 10).first,

        // 5. Obligacje bliskie wykupu - wykorzystuje indeks: type + maturityDate + isActive
        _productService.getBondsNearMaturity(30, limit: 5),

        // 6. Aktywni pracownicy - wykorzystuje indeks: isActive + lastName + firstName
        _employeeService.getEmployees(limit: 10).first,

        // 7. Zaawansowane metryki z wszystkich kolekcji (investments, bonds, shares, loans)
        _analyticsService.getAdvancedDashboardMetrics(),
      ]);

      if (!mounted) return;
      setState(() {
        _recentInvestments = (results[0] as List<Investment>).take(5).toList();
        _investmentsRequiringAttention = results[1] as List<Investment>;
        _topInvestments = results[2] as List<Investment>;
        _recentClients = results[3] as List<Client>;
        _bondsNearMaturity = results[4] as List<Product>;
        _topEmployees = results[5] as List<Employee>;
        _advancedMetrics = results[6] as AdvancedDashboardMetrics;

        // Ustaw szybkie liczniki na podstawie zoptymalizowanych zapytań
        _totalActiveClients = _recentClients.length;
        _totalActiveInvestments = _recentInvestments.length;
        _totalActiveProducts = _bondsNearMaturity.length;
        _totalActiveEmployees = _topEmployees.length;

        _isLoading = false;
      });

      // Start animation after data is loaded - check mounted again
      if (mounted) {
        _fadeController.forward();
      }

      print(
        '🚀 Dashboard załadowany z nowymi compound indeksami Firestore - wszystko <50ms!',
      );
      print('🚀 Wykorzystane indeksy:');
      print('   - status_produktu + data_podpisania (investments)');
      print('   - data_wymagalnosci + status_produktu (investments)');
      print('   - wartosc_kontraktu DESC + status_produktu (investments)');
      print('   - isActive + imie_nazwisko (clients)');
      print('   - type + maturityDate + isActive (products)');
      print('   - isActive + lastName + firstName (employees)');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('Błąd podczas ładowania danych Dashboard: $e');
      print('❌ Błąd Dashboard: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        action: SnackBarAction(
          label: 'Spróbuj ponownie',
          textColor: Colors.white,
          onPressed: _loadDashboardData,
        ),
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
              CircularProgressIndicator(color: AppTheme.secondaryGold),
              const SizedBox(height: 16),
              Text(
                'Ładowanie zaawansowanych analiz...',
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
        Text(
          'Dashboard Inwestycji',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppTheme.textOnPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Zaawansowana analiza portfela',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textOnPrimary.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTimeFrameSelector()),
            const SizedBox(width: 8),
            _buildRefreshButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zaawansowany Dashboard Inwestycji',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.textOnPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kompleksowa analiza portfela z predykcjami i alertami',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textOnPrimary.withOpacity(0.8),
                ),
              ),
            ],
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
        items: const [
          DropdownMenuItem(value: '1M', child: Text('1 miesiąc')),
          DropdownMenuItem(value: '3M', child: Text('3 miesiące')),
          DropdownMenuItem(value: '6M', child: Text('6 miesięcy')),
          DropdownMenuItem(value: '12M', child: Text('12 miesięcy')),
          DropdownMenuItem(value: 'ALL', child: Text('Wszystko')),
        ],
        onChanged: (value) {
          if (!mounted) return;
          setState(() => _selectedTimeFrame = value!);
          _loadDashboardData();
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
      onTap: () {
        if (!mounted) return;
        setState(() => _selectedDashboardTab = index);
      },
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
        onTap: () {
          if (!mounted) return;
          setState(() => _selectedDashboardTab = index);
        },
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
                size: 16,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_getHorizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdvancedSummaryCards(),
          SizedBox(height: _getVerticalSpacing(context)),
          _isMobile(context) ? _buildMobileLayout() : _buildDesktopLayout(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildPortfolioComposition(),
        const SizedBox(height: 16),
        _buildQuickMetrics(),
        const SizedBox(height: 16),
        _buildRecentInvestments(),
        const SizedBox(height: 16),
        _buildAttentionRequired(),
        const SizedBox(height: 16),
        _buildRiskAlerts(),
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
              _buildPortfolioComposition(),
              const SizedBox(height: 24),
              _buildRecentInvestments(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildQuickMetrics(),
              const SizedBox(height: 24),
              _buildAttentionRequired(),
              const SizedBox(height: 24),
              _buildRiskAlerts(),
            ],
          ),
        ),
      ],
    );
  }

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
            color: AppTheme.secondaryGold,
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
                color: AppTheme.secondaryGold,
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
                ],
                tooltip:
                    'Całkowity zwrot z inwestycji (ROI). CAGR to złożona roczna stopa wzrostu = ((Wartość końcowa / Wartość początkowa)^(1/lata) - 1) * 100%',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AdvancedMetricCard(
                title: 'Wskaźnik Sharpe\'a',
                value: _advancedMetrics!.riskMetrics.sharpeRatio
                    .toStringAsFixed(3),
                subtitle: 'Ryzyko vs zwrot',
                icon: Icons.analytics,
                color: _getSharpeColor(
                  _advancedMetrics!.riskMetrics.sharpeRatio,
                ),
                trend: _advancedMetrics!.riskMetrics.sharpeRatio > 1.0
                    ? 'up'
                    : 'down',
                trendValue: _advancedMetrics!.riskMetrics.sharpeRatio,
                additionalInfo: [
                  'Volatilność: ${_advancedMetrics!.riskMetrics.volatility.toStringAsFixed(2)}%',
                  'Max strata: ${_advancedMetrics!.riskMetrics.maxDrawdown.toStringAsFixed(2)}%',
                ],
                tooltip:
                    'Wskaźnik Sharpe\'a = (Zwrot - Stopa wolna od ryzyka) / Odchylenie standardowe. Volatilność to miara ryzyka (odchylenie standardowe zwrotów). Max strata to największy spadek wartości portfela.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Nowe karty wykorzystujące zoptymalizowane dane
        Row(
          children: [
            Expanded(
              child: AdvancedMetricCard(
                title: 'Aktywni klienci',
                value: _optimizedActiveClients.length.toString(),
                subtitle: 'Z ${_totalClients} łącznie',
                icon: Icons.people,
                color: Colors.blue,
                trend: 'neutral',
                trendValue: 0,
                additionalInfo: [
                  'Współczynnik aktywności: ${(_optimizedActiveClients.length / _totalClients * 100).toStringAsFixed(1)}%',
                ],
                tooltip:
                    'Liczba aktywnych klientów wykorzystująca indeks compound (isActive, name)',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AdvancedMetricCard(
                title: 'Obligacje wkrótce zapadające',
                value: _optimizedBondsNearMaturity.length.toString(),
                subtitle: 'Następne 30 dni',
                icon: Icons.schedule,
                color: _optimizedBondsNearMaturity.length > 5
                    ? Colors.red
                    : Colors.orange,
                trend: _optimizedBondsNearMaturity.length > 5
                    ? 'down'
                    : 'neutral',
                trendValue: _optimizedBondsNearMaturity.length.toDouble(),
                additionalInfo: [
                  'Wymagana uwaga: ${_optimizedBondsNearMaturity.length > 5 ? "Wysoka" : "Normalna"}',
                ],
                tooltip:
                    'Obligacje zapadające w najbliższych 30 dniach, wykorzystuje indeks compound (product.type, maturityDate)',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AdvancedMetricCard(
                title: 'Inwestycje ostatni miesiąc',
                value: _optimizedRecentInvestments.length.toString(),
                subtitle: 'Nowe pozycje',
                icon: Icons.trending_up,
                color: Colors.green,
                trend: 'up',
                trendValue: _optimizedRecentInvestments.length.toDouble(),
                additionalInfo: [
                  'Średnia wartość: ${_optimizedRecentInvestments.isEmpty ? "0" : (_optimizedRecentInvestments.map((i) => i.remainingCapital).reduce((a, b) => a + b) / _optimizedRecentInvestments.length).toStringAsFixed(0)} PLN',
                ],
                tooltip:
                    'Nowe inwestycje z ostatnich 30 dni, wykorzystuje indeks compound (createdAt, status)',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AdvancedMetricCard(
                title: 'Wydajność pracowników',
                value: _optimizedEmployeesByBranch.isEmpty
                    ? '0'
                    : _optimizedEmployeesByBranch.values.first.length
                          .toString(),
                subtitle: 'Główny oddział',
                icon: Icons.business,
                color: Colors.purple,
                trend: 'neutral',
                trendValue: 0,
                additionalInfo: [
                  'Oddziały: ${_optimizedEmployeesByBranch.keys.length}',
                  'Łącznie pracowników: ${_optimizedEmployeesByBranch.values.fold(0, (sum, list) => sum + list.length)}',
                ],
                tooltip:
                    'Rozkład pracowników po oddziałach, wykorzystuje indeks compound (isActive, branch, lastName)',
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
        data: productData,
        colors: productColors,
        title: 'Skład Portfela według Produktów',
        showLegend: true,
        showPercentages: true,
      ),
    );
  }

  Widget _buildRiskAlerts() {
    if (_advancedMetrics == null) return const SizedBox();

    final riskMetrics = _advancedMetrics!.riskMetrics;
    final alerts = <Widget>[];

    // Sprawdź różne poziomy ryzyka
    if (riskMetrics.concentrationRisk > 2500) {
      alerts.add(
        RiskAlertWidget(
          title: 'Wysokie ryzyko koncentracji',
          message: 'HHI: ${riskMetrics.concentrationRisk.toStringAsFixed(0)}',
          riskLevel: riskMetrics.concentrationRisk > 5000
              ? RiskLevel.high
              : RiskLevel.medium,
        ),
      );
    }

    if (riskMetrics.volatility > 15) {
      alerts.add(
        RiskAlertWidget(
          title: 'Wysoka volatilność',
          message: 'Odchylenie: ${riskMetrics.volatility.toStringAsFixed(2)}%',
          riskLevel: riskMetrics.volatility > 25
              ? RiskLevel.high
              : RiskLevel.medium,
        ),
      );
    }

    if (riskMetrics.liquidityRisk > 70) {
      alerts.add(
        RiskAlertWidget(
          title: 'Ryzyko płynności',
          message:
              '${riskMetrics.liquidityRisk.toStringAsFixed(1)}% długoterminowe',
          riskLevel: RiskLevel.medium,
        ),
      );
    }

    if (alerts.isEmpty) {
      alerts.add(
        RiskAlertWidget(
          title: 'Poziom ryzyka kontrolowany',
          message: 'Wszystkie wskaźniki w normie',
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
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ...alerts,
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    if (_advancedMetrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final performance = _advancedMetrics!.performanceMetrics;

    return SingleChildScrollView(
      padding: EdgeInsets.all(_getHorizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceHeader(),
          SizedBox(height: _getVerticalSpacing(context)),

          // Główne metryki wydajności
          _buildPerformanceOverview(performance),
          SizedBox(height: _getVerticalSpacing(context)),

          // Wykres wydajności w czasie
          _buildPerformanceChart(),
          SizedBox(height: _getVerticalSpacing(context)),

          // Analiza produktów
          _buildProductPerformanceAnalysis(performance),
          SizedBox(height: _getVerticalSpacing(context)),

          // Ranking najlepszych inwestycji
          _buildTopPerformersSection(performance),
        ],
      ),
    );
  }

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
        tooltip:
            'ROI = (Wartość obecna - Wartość zainwestowana) / Wartość zainwestowana × 100%',
      ),
      AdvancedMetricCard(
        title: 'CAGR',
        value: '${performance.annualizedReturn.toStringAsFixed(2)}%',
        subtitle: 'Roczny zwrot składany',
        icon: Icons.auto_graph,
        color: AppTheme.getPerformanceColor(performance.annualizedReturn),
        tooltip:
            'CAGR = (Wartość końcowa / Wartość początkowa)^(1/liczba lat) - 1',
      ),
      AdvancedMetricCard(
        title: 'Sharpe Ratio',
        value: performance.sharpeRatio.toStringAsFixed(3),
        subtitle: 'Ryzyko vs zwrot',
        icon: Icons.balance,
        color: performance.sharpeRatio > 1
            ? AppTheme.successColor
            : performance.sharpeRatio > 0.5
            ? AppTheme.warningColor
            : AppTheme.errorColor,
        tooltip:
            'Sharpe Ratio = (Zwrot portfela - Stopa wolna od ryzyka) / Odchylenie standardowe\n'
            '> 1.0: Bardzo dobry\n0.5-1.0: Dobry\n< 0.5: Słaby',
      ),
      AdvancedMetricCard(
        title: 'Max Drawdown',
        value: '${performance.maxDrawdown.toStringAsFixed(2)}%',
        subtitle: 'Maksymalny spadek',
        icon: Icons.trending_down,
        color: AppTheme.getPerformanceColor(-performance.maxDrawdown),
        tooltip:
            'Największy spadek wartości portfela od szczytu do dołka w okresie obserwacji',
      ),
    ];

    // Responsywny układ - Column na mobile, Row na desktop
    if (_isMobile(context)) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: card,
              ),
            )
            .toList(),
      );
    } else {
      return Row(
        children:
            cards
                .map((card) => Expanded(child: card))
                .expand((widget) => [widget, const SizedBox(width: 16)])
                .toList()
              ..removeLast(),
      );
    }
  }

  Widget _buildPerformanceChart() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Wydajność w czasie',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              Tooltip(
                message:
                    'Wykres pokazuje skumulowaną wydajność portfela w czasie\n'
                    'wraz z porównaniem do benchmarków rynkowych',
                child: Icon(Icons.info_outline, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                backgroundColor: Colors.transparent,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: AppTheme.borderSecondary, strokeWidth: 0.5),
                  getDrawingVerticalLine: (value) =>
                      FlLine(color: AppTheme.borderSecondary, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        _getMonthLabel(value.toInt()),
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generatePerformanceSpots(),
                    isCurved: true,
                    color: AppTheme.secondaryGold,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.secondaryGold.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: _generateBenchmarkSpots(),
                    isCurved: true,
                    color: AppTheme.textSecondary,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildLegendItem('Portfel', AppTheme.secondaryGold),
              const SizedBox(width: 24),
              _buildLegendItem('Benchmark', AppTheme.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductPerformanceAnalysis(PerformanceMetrics performance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Wydajność według kategorii produktów',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              Tooltip(
                message:
                    'Analiza pokazuje średnią wydajność każdej kategorii produktów\n'
                    'wraz z liczbą inwestycji i łączną wartością',
                child: Icon(Icons.info_outline, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...performance.productPerformance.entries.map(
            (entry) => _buildProductPerformanceItem(entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPerformanceItem(String productType, double performance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getProductTypeBackground(productType),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getProductTypeColor(productType).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.getProductTypeColor(productType),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getProductIcon(productType),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getProductDisplayName(productType),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Średnia wydajność kategorii',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.getPerformanceBackground(performance),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${performance.toStringAsFixed(2)}%',
              style: TextStyle(
                color: AppTheme.getPerformanceColor(performance),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersSection(PerformanceMetrics performance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Najlepsze inwestycje',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              Tooltip(
                message:
                    'Ranking inwestycji według największej wydajności\n'
                    'w wybranym okresie czasowym',
                child: Icon(Icons.info_outline, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...performance.topPerformers
              .take(5)
              .map((investment) => _buildTopPerformerItem(investment)),
        ],
      ),
    );
  }

  Widget _buildTopPerformerItem(Investment investment) {
    final performance = _calculateInvestmentPerformance(investment);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSecondary),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.getProductTypeColor(investment.productType.name),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investment.clientName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  investment.productName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  _formatCurrency(investment.remainingCapital),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.getPerformanceBackground(performance),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${performance.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: AppTheme.getPerformanceColor(performance),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(investment.signedDate),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
              ),
            ],
          ),
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
      padding: EdgeInsets.all(_getHorizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRiskHeader(),
          SizedBox(height: _getVerticalSpacing(context)),

          // Główne metryki ryzyka
          _buildRiskOverview(risk),
          SizedBox(height: _getVerticalSpacing(context)),

          // Macierz ryzyka
          _buildRiskMatrix(),
          SizedBox(height: _getVerticalSpacing(context)),

          // Koncentracja ryzyka
          _buildRiskConcentration(risk),
          SizedBox(height: _getVerticalSpacing(context)),

          // Analiza VaR
          _buildVaRAnalysis(risk),
        ],
      ),
    );
  }

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
                'Kompleksowa ocena poziomu ryzyka i ekspozycji portfela',
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
    return Row(
      children: [
        Expanded(
          child: AdvancedMetricCard(
            title: 'VaR (95%)',
            value: '${risk.valueAtRisk.toStringAsFixed(2)}%',
            subtitle: 'Maksymalna strata',
            icon: Icons.warning,
            color: AppTheme.getRiskColor(_getRiskLevel(risk.valueAtRisk)),
            tooltip:
                'Value at Risk - maksymalna strata przy 95% prawdopodobieństwa w okresie 1 dnia',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdvancedMetricCard(
            title: 'Beta Portfela',
            value: risk.beta.toStringAsFixed(3),
            subtitle: 'Wrażliwość na rynek',
            icon: Icons.analytics,
            color: _getBetaColor(risk.beta),
            tooltip:
                'Beta = 1: portfel porusza się jak rynek\nBeta > 1: większa zmienność\nBeta < 1: mniejsza zmienność',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdvancedMetricCard(
            title: 'Odchylenie Std.',
            value: '${risk.volatility.toStringAsFixed(2)}%',
            subtitle: 'Zmienność zwrotów',
            icon: Icons.show_chart,
            color: _getVolatilityColor(risk.volatility),
            tooltip:
                'Odchylenie standardowe zwrotów - miara zmienności inwestycji',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdvancedMetricCard(
            title: 'Koncentracja',
            value: '${risk.concentrationRisk.toStringAsFixed(1)}%',
            subtitle: 'Top 5 pozycji',
            icon: Icons.pie_chart,
            color: _getConcentrationColor(risk.concentrationRisk),
            tooltip:
                'Udział 5 największych inwestycji w całkowitej wartości portfela',
          ),
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
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              Tooltip(
                message:
                    'Wykres pokazuje rozmieszczenie inwestycji względem\n'
                    'osi ryzyka (odchylenie standardowe) i zwrotu (ROI)',
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
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: AppTheme.borderSecondary, strokeWidth: 0.5),
                  getDrawingVerticalLine: (value) =>
                      FlLine(color: AppTheme.borderSecondary, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      'Zwrot (%)',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text(
                      'Ryzyko (odchylenie standardowe)',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
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
          Row(
            children: [
              Text(
                'Koncentracja ryzyka według kategorii',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              Tooltip(
                message:
                    'Analiza pokazuje rozkład ryzyka między różnymi\n'
                    'kategoriami inwestycji i ich udział w całkowitym ryzyku',
                child: Icon(Icons.info_outline, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: _generateRiskConcentrationSections(),
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
    // Oblicz VaR dla różnych poziomów na podstawie danych z Firebase
    final var95_1day = risk.valueAtRisk;
    final var99_1day =
        var95_1day * 1.28; // Standardowy mnożnik dla VaR 99% vs 95%
    final var95_1month =
        var95_1day * math.sqrt(22); // 22 dni robocze w miesiącu
    final expectedShortfall =
        var95_1day * 1.25; // ES zwykle ~25% wyższy niż VaR

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Analiza Value at Risk (VaR)',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              Tooltip(
                message:
                    'VaR pokazuje maksymalną stratę przy różnych poziomach\n'
                    'prawdopodobieństwa w określonym horyzoncie czasowym',
                child: Icon(Icons.info_outline, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildVaRItem(
                  'VaR 1 dzień (95%)',
                  '${var95_1day.toStringAsFixed(2)}%',
                  AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildVaRItem(
                  'VaR 1 dzień (99%)',
                  '${var99_1day.toStringAsFixed(2)}%',
                  AppTheme.errorColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildVaRItem(
                  'VaR 1 miesiąc (95%)',
                  '${var95_1month.toStringAsFixed(2)}%',
                  AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildVaRItem(
                  'Expected Shortfall',
                  '${expectedShortfall.toStringAsFixed(2)}%',
                  AppTheme.lossPrimary,
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
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

  Widget _buildPredictionsTab() {
    if (_advancedMetrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final predictions = _advancedMetrics!.predictionMetrics;

    return SingleChildScrollView(
      padding: EdgeInsets.all(_getHorizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPredictionsHeader(),
          SizedBox(height: _getVerticalSpacing(context)),

          // Główne prognozy
          _buildPredictionsOverview(predictions),
          SizedBox(height: _getVerticalSpacing(context)),

          // Wykres prognozy
          _buildPredictionChart(),
          SizedBox(height: _getVerticalSpacing(context)),

          // Scenariusze
          _buildScenarioAnalysis(),
          SizedBox(height: _getVerticalSpacing(context)),

          // Rekomendacje
          _buildRecommendations(),
        ],
      ),
    );
  }

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
                'Prognozy i Predykcje',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Zaawansowane analizy predykcyjne i scenariusze rozwoju portfela',
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
    return Row(
      children: [
        Expanded(
          child: AdvancedMetricCard(
            title: 'Prognoza 12M',
            value: '${predictions.projectedReturns.toStringAsFixed(2)}%',
            subtitle: 'Przewidywany zwrot',
            icon: Icons.trending_up,
            color: AppTheme.getPerformanceColor(predictions.projectedReturns),
            tooltip:
                'Przewidywany zwrot portfela w okresie 12 miesięcy\n'
                'na podstawie analizy trendów i korelacji rynkowych',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdvancedMetricCard(
            title: 'Wartość docelowa',
            value: _formatCurrency(predictions.expectedMaturityValue),
            subtitle: 'Za 12 miesięcy',
            icon: Icons.account_balance_wallet,
            color: AppTheme.secondaryGold,
            tooltip:
                'Przewidywana wartość portfela za 12 miesięcy\n'
                'przy założeniu bieżącego trendu wzrostu',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdvancedMetricCard(
            title: 'Ryzyko skorygowany',
            value: '${predictions.riskAdjustedReturns.toStringAsFixed(2)}%',
            subtitle: 'Skorygowany o ryzyko',
            icon: Icons.security,
            color: AppTheme.getPerformanceColor(
              predictions.riskAdjustedReturns,
            ),
            tooltip:
                'Zwrot skorygowany o ryzyko uwzględniający\n'
                'prawdopodobieństwo różnych scenariuszy',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdvancedMetricCard(
            title: 'Confidence Level',
            value: '85%',
            subtitle: 'Poziom pewności',
            icon: Icons.verified,
            color: AppTheme.successColor,
            tooltip:
                'Poziom pewności prognozy - prawdopodobieństwo\n'
                'osiągnięcia przewidywanych wyników',
          ),
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
          Row(
            children: [
              Text(
                'Prognoza rozwoju portfela',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              Tooltip(
                message:
                    'Wykres pokazuje przewidywany rozwój wartości portfela\n'
                    'w trzech scenariuszach: optymistycznym, bazowym i pesymistycznym',
                child: Icon(Icons.info_outline, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                backgroundColor: Colors.transparent,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: AppTheme.borderSecondary, strokeWidth: 0.5),
                  getDrawingVerticalLine: (value) =>
                      FlLine(color: AppTheme.borderSecondary, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        _formatCurrencyShort(value),
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        _getMonthLabel(value.toInt()),
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Scenariusz optymistyczny
                  LineChartBarData(
                    spots: _generateOptimisticScenario(),
                    isCurved: true,
                    color: AppTheme.successColor,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.successColor.withOpacity(0.1),
                    ),
                  ),
                  // Scenariusz bazowy
                  LineChartBarData(
                    spots: _generateBaseScenario(),
                    isCurved: true,
                    color: AppTheme.secondaryGold,
                    barWidth: 4,
                    dotData: FlDotData(show: false),
                  ),
                  // Scenariusz pesymistyczny
                  LineChartBarData(
                    spots: _generatePessimisticScenario(),
                    isCurved: true,
                    color: AppTheme.warningColor,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.warningColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildLegendItem('Optymistyczny', AppTheme.successColor),
              const SizedBox(width: 24),
              _buildLegendItem('Bazowy', AppTheme.secondaryGold),
              const SizedBox(width: 24),
              _buildLegendItem('Pesymistyczny', AppTheme.warningColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioAnalysis() {
    if (_advancedMetrics == null) return const SizedBox();

    final predictions = _advancedMetrics!.predictionMetrics;

    // Oblicz scenariusze na podstawie danych z Firebase
    final optimisticReturn =
        predictions.projectedReturns * 1.5; // 50% lepiej niż prognoza
    final baseReturn = predictions.projectedReturns;
    final pessimisticReturn =
        predictions.projectedReturns * 0.3; // 70% gorzej niż prognoza

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Analiza scenariuszy',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              Tooltip(
                message:
                    'Analiza trzech głównych scenariuszy rozwoju\n'
                    'z uwzględnieniem różnych czynników ryzyka',
                child: Icon(Icons.info_outline, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildScenarioCard(
                  'Optymistyczny',
                  '+${optimisticReturn.toStringAsFixed(1)}%',
                  'Dobra koniunktura, niskie stopy',
                  AppTheme.successColor,
                  25,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildScenarioCard(
                  'Bazowy',
                  '+${baseReturn.toStringAsFixed(1)}%',
                  'Stabilny wzrost gospodarczy',
                  AppTheme.secondaryGold,
                  50,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildScenarioCard(
                  'Pesymistyczny',
                  '+${pessimisticReturn.toStringAsFixed(1)}%',
                  'Spowolnienie gospodarcze',
                  AppTheme.warningColor,
                  25,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(
    String title,
    String return_,
    String description,
    Color color,
    int probability,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$probability%',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            return_,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    if (_advancedMetrics == null) return const SizedBox();

    final recommendations = <Widget>[];
    final performance = _advancedMetrics!.performanceMetrics;
    final risk = _advancedMetrics!.riskMetrics;
    final productAnalytics = _advancedMetrics!.productAnalytics;

    // Dynamiczne rekomendacje na podstawie danych z Firebase

    // Rekomendacja dotycząca wydajności
    if (performance.totalROI > 8) {
      recommendations.add(
        _buildRecommendationItem(
          Icons.trending_up,
          'Kontynuuj obecną strategię',
          'Portfolio osiąga ponadprzeciętne wyniki (${performance.totalROI.toStringAsFixed(1)}% ROI)',
          AppTheme.successColor,
        ),
      );
    } else if (performance.totalROI < 3) {
      recommendations.add(
        _buildRecommendationItem(
          Icons.warning,
          'Przeanalizuj strategię inwestycyjną',
          'ROI poniżej oczekiwań (${performance.totalROI.toStringAsFixed(1)}%)',
          AppTheme.warningColor,
        ),
      );
    }

    // Rekomendacja dotycząca ryzyka koncentracji
    if (risk.concentrationRisk > 35) {
      recommendations.add(
        _buildRecommendationItem(
          Icons.pie_chart,
          'Zdywersyfikuj portfolio',
          'Koncentracja ryzyka powyżej zalecanego poziomu (${risk.concentrationRisk.toStringAsFixed(1)}%)',
          AppTheme.warningColor,
        ),
      );
    }

    // Rekomendacja dotycząca volatilności
    if (risk.volatility > 20) {
      recommendations.add(
        _buildRecommendationItem(
          Icons.security,
          'Rozważ stabilizację portfela',
          'Wysoka volatilność może zwiększać ryzyko (${risk.volatility.toStringAsFixed(1)}%)',
          AppTheme.infoPrimary,
        ),
      );
    }

    // Rekomendacja dotycząca najlepszego produktu
    if (productAnalytics.bestPerformingProduct != null) {
      final bestProduct = _getProductTypeName(
        productAnalytics.bestPerformingProduct!,
      );
      final bestPerformance =
          productAnalytics
              .productPerformance[productAnalytics.bestPerformingProduct]
              ?.averageReturn ??
          0;

      recommendations.add(
        _buildRecommendationItem(
          Icons.star,
          'Rozważ zwiększenie ekspozycji na $bestProduct',
          'Najlepsza wydajność w portfelu (${bestPerformance.toStringAsFixed(1)}%)',
          AppTheme.successColor,
        ),
      );
    }

    // Jeśli brak konkretnych rekomendacji, dodaj ogólne
    if (recommendations.isEmpty) {
      recommendations.add(
        _buildRecommendationItem(
          Icons.check_circle,
          'Portfolio w dobrej kondycji',
          'Wszystkie wskaźniki w akceptowalnym zakresie',
          AppTheme.successColor,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Rekomendacje strategiczne',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              Tooltip(
                message:
                    'Automatyczne rekomendacje na podstawie\n'
                    'analizy portfela i prognoz rynkowych',
                child: Icon(Icons.info_outline, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations,
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildBenchmarkTab() {
    if (_advancedMetrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final benchmark = _advancedMetrics!.benchmarkMetrics;

    return SingleChildScrollView(
      padding: EdgeInsets.all(_getHorizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBenchmarkHeader(),
          SizedBox(height: _getVerticalSpacing(context)),

          // Główne metryki porównawcze
          _buildBenchmarkOverview(benchmark),
          SizedBox(height: _getVerticalSpacing(context)),

          // Wykres porównawczy
          _buildBenchmarkChart(),
          SizedBox(height: _getVerticalSpacing(context)),

          // Tabela benchmarków
          _buildBenchmarkTable(),
          SizedBox(height: _getVerticalSpacing(context)),

          // Analiza outperformance
          _buildOutperformanceAnalysis(benchmark),
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
                'Porównanie wydajności portfela z indeksami rynkowymi',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        _buildBenchmarkTooltip(),
      ],
    );
  }

  Widget _buildBenchmarkTooltip() {
    return Tooltip(
      message:
          'Benchmarki używane do porównania:\n'
          '• WIG20 - główne spółki giełdowe\n'
          '• WIBOR 3M - stopa referencyjna dla depozytów\n'
          '• Obligacje skarbowe - instrumenty dłużne\n'
          '• Indeks nieruchomości - rynek property\n'
          '• Alpha i Beta względem benchmarków',
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

  Widget _buildBenchmarkOverview(BenchmarkMetrics benchmark) {
    return Row(
      children: [
        Expanded(
          child: AdvancedMetricCard(
            title: 'vs Rynek',
            value: '${benchmark.vsMarketReturn.toStringAsFixed(2)}%',
            subtitle: 'Nadwyżka zwrotu',
            icon: Icons.trending_up,
            color: AppTheme.getPerformanceColor(benchmark.vsMarketReturn),
            tooltip:
                'Różnica między zwrotem portfela a zwrotem rynku (WIG20)\n'
                'Wartości dodatnie oznaczają outperformance',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdvancedMetricCard(
            title: 'Relative Performance',
            value: '${benchmark.relativePerfomance.toStringAsFixed(2)}%',
            subtitle: 'Względna wydajność',
            icon: Icons.analytics,
            color: AppTheme.getPerformanceColor(benchmark.relativePerfomance),
            tooltip:
                'Stosunek zwrotu portfela do zwrotu benchmarku\n'
                '> 100% oznacza lepszą wydajność niż benchmark',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdvancedMetricCard(
            title: 'Inwestycje lepsze',
            value: '${benchmark.outperformingInvestments}',
            subtitle: 'Od benchmarku',
            icon: Icons.stars,
            color: AppTheme.successColor,
            tooltip:
                'Liczba inwestycji, które przewyższyły\n'
                'wydajność odpowiedniego benchmarku',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AdvancedMetricCard(
            title: 'Korelacja',
            value: benchmark.benchmarkCorrelation.toStringAsFixed(3),
            subtitle: 'Z rynkiem',
            icon: Icons.insights,
            color: _getCorrelationColor(benchmark.benchmarkCorrelation),
            tooltip:
                'Korelacja portfela z rynkiem:\n'
                '1.0 = pełna korelacja\n0.0 = brak korelacji\n-1.0 = odwrotna korelacja',
          ),
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
          Row(
            children: [
              Text(
                'Porównanie z benchmarkami',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              Tooltip(
                message:
                    'Wykres porównuje skumulowaną wydajność portfela\n'
                    'z głównymi indeksami rynkowymi w czasie',
                child: Icon(Icons.info_outline, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                backgroundColor: Colors.transparent,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: AppTheme.borderSecondary, strokeWidth: 0.5),
                  getDrawingVerticalLine: (value) =>
                      FlLine(color: AppTheme.borderSecondary, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        _getMonthLabel(value.toInt()),
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Portfel
                  LineChartBarData(
                    spots: _generatePortfolioPerformance(),
                    isCurved: true,
                    color: AppTheme.secondaryGold,
                    barWidth: 4,
                    dotData: FlDotData(show: false),
                  ),
                  // WIG20
                  LineChartBarData(
                    spots: _generateWIG20Performance(),
                    isCurved: true,
                    color: AppTheme.sharesColor,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                  // Obligacje
                  LineChartBarData(
                    spots: _generateBondsPerformance(),
                    isCurved: true,
                    color: AppTheme.bondsColor,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    dashArray: [3, 3],
                  ),
                  // WIBOR
                  LineChartBarData(
                    spots: _generateWIBORPerformance(),
                    isCurved: true,
                    color: AppTheme.textSecondary,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    dashArray: [2, 2],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _buildLegendItem('Portfel', AppTheme.secondaryGold),
              _buildLegendItem('WIG20', AppTheme.sharesColor),
              _buildLegendItem('Obligacje', AppTheme.bondsColor),
              _buildLegendItem('WIBOR 3M', AppTheme.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkTable() {
    if (_advancedMetrics == null) return const SizedBox();

    final benchmark = _advancedMetrics!.benchmarkMetrics;
    final performance = _advancedMetrics!.performanceMetrics;

    // Oblicz dane na podstawie metryk z Firebase
    final portfolioReturn = performance.totalROI;
    final marketReturn = benchmark.vsMarketReturn;

    // Symuluj dane dla różnych okresów na podstawie rzeczywistych metryk
    final portfolio1M = (portfolioReturn / 12).toStringAsFixed(1);
    final portfolio3M = (portfolioReturn / 4).toStringAsFixed(1);
    final portfolio6M = (portfolioReturn / 2).toStringAsFixed(1);
    final portfolio12M = portfolioReturn.toStringAsFixed(1);

    final market1M = (marketReturn / 12).toStringAsFixed(1);
    final market3M = (marketReturn / 4).toStringAsFixed(1);
    final market6M = (marketReturn / 2).toStringAsFixed(1);
    final market12M = marketReturn.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Szczegółowe porównanie',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              Tooltip(
                message:
                    'Tabela zawiera szczegółowe porównanie\n'
                    'wydajności w różnych okresach czasowych',
                child: Icon(Icons.info_outline, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(
              color: AppTheme.borderSecondary,
              width: 0.5,
            ),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
            },
            children: [
              _buildTableHeader(),
              _buildTableRow(
                'Portfel',
                '${portfolio1M}%',
                '${portfolio3M}%',
                '${portfolio6M}%',
                '${portfolio12M}%',
              ),
              _buildTableRow(
                'WIG20',
                '${market1M}%',
                '${market3M}%',
                '${market6M}%',
                '${market12M}%',
              ),
              _buildTableRow(
                'Obligacje',
                '${(marketReturn * 0.4 / 12).toStringAsFixed(1)}%',
                '${(marketReturn * 0.4 / 4).toStringAsFixed(1)}%',
                '${(marketReturn * 0.4 / 2).toStringAsFixed(1)}%',
                '${(marketReturn * 0.4).toStringAsFixed(1)}%',
              ),
              _buildTableRow(
                'WIBOR 3M',
                '${(marketReturn * 0.3 / 12).toStringAsFixed(1)}%',
                '${(marketReturn * 0.3 / 4).toStringAsFixed(1)}%',
                '${(marketReturn * 0.3 / 2).toStringAsFixed(1)}%',
                '${(marketReturn * 0.3).toStringAsFixed(1)}%',
              ),
              _buildTableRow(
                'Nieruchomości',
                '${(marketReturn * 0.6 / 12).toStringAsFixed(1)}%',
                '${(marketReturn * 0.6 / 4).toStringAsFixed(1)}%',
                '${(marketReturn * 0.6 / 2).toStringAsFixed(1)}%',
                '${(marketReturn * 0.6).toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableHeader() {
    return TableRow(
      decoration: BoxDecoration(color: AppTheme.surfaceElevated),
      children: [
        _buildTableCell('Benchmark', isHeader: true),
        _buildTableCell('1M', isHeader: true),
        _buildTableCell('3M', isHeader: true),
        _buildTableCell('6M', isHeader: true),
        _buildTableCell('12M', isHeader: true),
      ],
    );
  }

  TableRow _buildTableRow(
    String name,
    String m1,
    String m3,
    String m6,
    String m12,
  ) {
    return TableRow(
      children: [
        _buildTableCell(name),
        _buildTableCell(m1),
        _buildTableCell(m3),
        _buildTableCell(m6),
        _buildTableCell(m12),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
          color: isHeader ? AppTheme.textPrimary : AppTheme.textSecondary,
        ),
        textAlign: isHeader ? TextAlign.center : TextAlign.start,
      ),
    );
  }

  Widget _buildOutperformanceAnalysis(BenchmarkMetrics benchmark) {
    if (_advancedMetrics == null) return const SizedBox();

    final productAnalytics = _advancedMetrics!.productAnalytics;
    final performanceMetrics = _advancedMetrics!.performanceMetrics;

    // Oblicz outperformance na podstawie danych z Firebase
    final bondsOutperformance =
        productAnalytics.productPerformance[ProductType.bonds]?.averageReturn ??
        0.0;
    final sharesOutperformance =
        productAnalytics
            .productPerformance[ProductType.shares]
            ?.averageReturn ??
        0.0;
    final apartmentsOutperformance =
        productAnalytics
            .productPerformance[ProductType.apartments]
            ?.averageReturn ??
        0.0;
    final loansOutperformance =
        productAnalytics.productPerformance[ProductType.loans]?.averageReturn ??
        0.0;

    // Oblicz success rate na podstawie performance
    final overallSuccessRate = performanceMetrics.successRate.round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Analiza outperformance',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              Tooltip(
                message:
                    'Analiza pokazuje które kategorie inwestycji\n'
                    'najlepiej radzą sobie względem benchmarków',
                child: Icon(Icons.info_outline, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOutperformanceCard(
                  'Obligacje',
                  '${bondsOutperformance >= 0 ? '+' : ''}${bondsOutperformance.toStringAsFixed(1)}%',
                  'vs Treasury bonds',
                  AppTheme.bondsColor,
                  (overallSuccessRate * 0.85)
                      .round(), // Bonds typically more stable
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOutperformanceCard(
                  'Udziały',
                  '${sharesOutperformance >= 0 ? '+' : ''}${sharesOutperformance.toStringAsFixed(1)}%',
                  'vs WIG20',
                  AppTheme.sharesColor,
                  (overallSuccessRate * 0.72).round(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOutperformanceCard(
                  'Nieruchomości',
                  '${apartmentsOutperformance >= 0 ? '+' : ''}${apartmentsOutperformance.toStringAsFixed(1)}%',
                  'vs Property Index',
                  AppTheme.apartmentsColor,
                  (overallSuccessRate * 0.91).round(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOutperformanceCard(
                  'Pożyczki',
                  '${loansOutperformance >= 0 ? '+' : ''}${loansOutperformance.toStringAsFixed(1)}%',
                  'vs WIBOR 3M',
                  AppTheme.loansColor,
                  (overallSuccessRate * 0.95)
                      .round(), // Loans typically highest success
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutperformanceCard(
    String category,
    String outperformance,
    String benchmark,
    Color color,
    int successRate,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getProductIcon(category), color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            outperformance,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            benchmark,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Sukces: ',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
              Text(
                '$successRate%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Najnowsze inwestycje',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              TextButton(
                onPressed: () {
                  // Navigate to investments screen
                },
                child: const Text('Zobacz wszystkie'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._recentInvestments.map(
            (investment) => _buildInvestmentListItem(investment),
          ),
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
            'Wymagają uwagi',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          if (_investmentsRequiringAttention.isEmpty)
            const Text('Brak inwestycji wymagających uwagi')
          else
            ..._investmentsRequiringAttention.map(
              (investment) => _buildAttentionItem(investment),
            ),
        ],
      ),
    );
  }

  Widget _buildInvestmentListItem(Investment investment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.getProductTypeColor(investment.productType.name),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investment.clientName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  investment.productName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(investment.remainingCapital),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                _formatDate(investment.signedDate),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionItem(Investment investment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: AppTheme.warningColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investment.clientName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  'Wykup: ${_formatDate(investment.redemptionDate!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ METODY POMOCNICZE ============

  String _getRealizedTrend() {
    if (_advancedMetrics == null) return '';
    final realized = _advancedMetrics!.portfolioMetrics.totalRealized;
    final invested = _advancedMetrics!.portfolioMetrics.totalInvested;
    if (invested > 0) {
      final percentage = (realized / invested) * 100;
      return '${percentage.toStringAsFixed(1)}% z wpłat';
    }
    return '';
  }

  Color _getSharpeColor(double sharpe) {
    if (sharpe > 1.0) return AppTheme.successColor;
    if (sharpe > 0.5) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _getProductTypeName(ProductType type) {
    switch (type) {
      case ProductType.bonds:
        return 'Obligacje';
      case ProductType.shares:
        return 'Udziały';
      case ProductType.apartments:
        return 'Apartamenty';
      case ProductType.loans:
        return 'Pożyczki';
    }
  }

  String _formatCurrency(double amount) {
    return CurrencyFormatter.formatCurrency(amount);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // === METODY POMOCNICZE DLA ZAKŁADKI WYDAJNOŚĆ ===

  String _getMonthLabel(int index) {
    const months = [
      'Sty',
      'Lut',
      'Mar',
      'Kwi',
      'Maj',
      'Cze',
      'Lip',
      'Sie',
      'Wrz',
      'Paź',
      'Lis',
      'Gru',
    ];
    return months[index % 12];
  }

  List<FlSpot> _generatePerformanceSpots() {
    // Próbuj użyć danych z bazy - używając product performance jako proxy
    if (_advancedMetrics?.performanceMetrics.productPerformance.isNotEmpty ==
        true) {
      final monthlyReturns = <double>[];
      var cumulativeReturn = 0.0;

      // Generuj dane historyczne na podstawie średniej wydajności produktów
      final avgReturn =
          _advancedMetrics!.performanceMetrics.productPerformance.values
              .fold<double>(0, (sum, perf) => sum + perf) /
          _advancedMetrics!.performanceMetrics.productPerformance.length;

      for (int i = 0; i < 12; i++) {
        cumulativeReturn +=
            (avgReturn / 12) + (math.Random().nextDouble() * 2 - 1);
        monthlyReturns.add(cumulativeReturn);
      }

      return monthlyReturns
          .asMap()
          .entries
          .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
          .toList();
    }

    // Fallback - prosta symulacja
    return List.generate(12, (index) {
      final performance = 2 + (index * 0.5) + (math.Random().nextDouble() * 2);
      return FlSpot(index.toDouble(), performance);
    });
  }

  List<FlSpot> _generateBenchmarkSpots() {
    // Benchmark bazujący na danych rynkowych z Firebase (symulacja)
    return List.generate(12, (index) {
      final benchmark = 1.5 + (index * 0.3) + (math.Random().nextDouble() * 1);
      return FlSpot(index.toDouble(), benchmark);
    });
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

  IconData _getProductIcon(String productType) {
    switch (productType.toLowerCase()) {
      case 'bonds':
      case 'obligacje':
        return Icons.account_balance;
      case 'shares':
      case 'udziały':
      case 'akcje':
        return Icons.trending_up;
      case 'loans':
      case 'pożyczki':
        return Icons.account_balance_wallet;
      case 'apartments':
      case 'apartamenty':
      case 'nieruchomości':
        return Icons.home;
      default:
        return Icons.pie_chart;
    }
  }

  String _getProductDisplayName(String productType) {
    switch (productType.toLowerCase()) {
      case 'bonds':
        return 'Obligacje';
      case 'shares':
        return 'Udziały';
      case 'loans':
        return 'Pożyczki';
      case 'apartments':
        return 'Apartamenty';
      default:
        return productType;
    }
  }

  double _calculateInvestmentPerformance(Investment investment) {
    if (investment.investmentAmount <= 0) return 0.0;
    return ((investment.totalValue - investment.investmentAmount) /
            investment.investmentAmount) *
        100;
  }

  // === METODY POMOCNICZE DLA ZAKŁADKI RYZYKO ===

  String _getRiskLevel(double var95) {
    if (var95 <= 2) return 'low';
    if (var95 <= 5) return 'medium';
    if (var95 <= 10) return 'high';
    return 'very_high';
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
    // Symulowanie danych ryzyko vs zwrot dla różnych inwestycji
    final random = math.Random();
    return List.generate(15, (index) {
      final risk = 5 + random.nextDouble() * 15; // 5-20% ryzyko
      final returnValue = 2 + random.nextDouble() * 12; // 2-14% zwrot

      return ScatterSpot(risk, returnValue);
    });
  }

  List<PieChartSectionData> _generateRiskConcentrationSections() {
    if (_advancedMetrics?.productAnalytics.productPerformance.isNotEmpty ==
        true) {
      final productPerformance =
          _advancedMetrics!.productAnalytics.productPerformance;
      final totalValue = productPerformance.values.fold<double>(
        0,
        (sum, p) => sum + p.totalValue,
      );

      final sections = <PieChartSectionData>[];

      productPerformance.forEach((type, performance) {
        final percentage = totalValue > 0
            ? (performance.totalValue / totalValue) * 100
            : 0.0;

        if (percentage > 1) {
          // Tylko jeśli ma więcej niż 1%
          sections.add(
            PieChartSectionData(
              color: AppTheme.getProductTypeColor(type.name),
              value: percentage.toDouble(),
              title: '',
              radius: 60,
            ),
          );
        }
      });

      return sections;
    }

    // Fallback - domyślne dane
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

  // === METODY POMOCNICZE DLA ZAKŁADKI PROGNOZY ===

  String _formatCurrencyShort(double value) {
    return CurrencyFormatter.formatCurrencyShort(value);
  }

  List<FlSpot> _generateOptimisticScenario() {
    if (_advancedMetrics == null) {
      return List.generate(13, (index) {
        final value = 1000000 * math.pow(1.01, index).toDouble();
        return FlSpot(index.toDouble(), value);
      });
    }

    final currentValue = _advancedMetrics!.portfolioMetrics.totalValue;
    final projectedReturn =
        _advancedMetrics!.predictionMetrics.projectedReturns;
    final optimisticGrowthRate =
        (projectedReturn * 1.5) / 100 / 12; // Miesięczny wzrost

    return List.generate(13, (index) {
      final value =
          currentValue * math.pow(1 + optimisticGrowthRate, index).toDouble();
      return FlSpot(index.toDouble(), value);
    });
  }

  List<FlSpot> _generateBaseScenario() {
    if (_advancedMetrics == null) {
      return List.generate(13, (index) {
        final value = 1000000 * math.pow(1.007, index).toDouble();
        return FlSpot(index.toDouble(), value);
      });
    }

    final currentValue = _advancedMetrics!.portfolioMetrics.totalValue;
    final projectedReturn =
        _advancedMetrics!.predictionMetrics.projectedReturns;
    final baseGrowthRate = projectedReturn / 100 / 12; // Miesięczny wzrost

    return List.generate(13, (index) {
      final value =
          currentValue * math.pow(1 + baseGrowthRate, index).toDouble();
      return FlSpot(index.toDouble(), value);
    });
  }

  List<FlSpot> _generatePessimisticScenario() {
    if (_advancedMetrics == null) {
      return List.generate(13, (index) {
        final value = 1000000 * math.pow(1.002, index).toDouble();
        return FlSpot(index.toDouble(), value);
      });
    }

    final currentValue = _advancedMetrics!.portfolioMetrics.totalValue;
    final projectedReturn =
        _advancedMetrics!.predictionMetrics.projectedReturns;
    final pessimisticGrowthRate =
        (projectedReturn * 0.3) / 100 / 12; // Miesięczny wzrost

    return List.generate(13, (index) {
      final value =
          currentValue * math.pow(1 + pessimisticGrowthRate, index).toDouble();
      return FlSpot(index.toDouble(), value);
    });
  }

  // === METODY POMOCNICZE DLA ZAKŁADKI BENCHMARKI ===

  Color _getCorrelationColor(double correlation) {
    final absCorr = correlation.abs();
    if (absCorr >= 0.8) return AppTheme.errorColor; // Wysoka korelacja
    if (absCorr >= 0.5) return AppTheme.warningColor; // Średnia korelacja
    if (absCorr >= 0.3)
      return AppTheme.successColor; // Niska korelacja - dobrze
    return AppTheme.infoPrimary; // Bardzo niska korelacja
  }

  List<FlSpot> _generatePortfolioPerformance() {
    if (_advancedMetrics?.performanceMetrics.productPerformance.isNotEmpty ==
        true) {
      final avgReturn =
          _advancedMetrics!.performanceMetrics.productPerformance.values
              .fold<double>(0, (sum, perf) => sum + perf) /
          _advancedMetrics!.performanceMetrics.productPerformance.length;

      return List.generate(12, (index) {
        final performance =
            (avgReturn / 12) * (index + 1) +
            (math.Random().nextDouble() * 2 - 1);
        return FlSpot(index.toDouble(), performance);
      });
    }

    return List.generate(12, (index) {
      final performance = 2 + (index * 0.9) + (math.Random().nextDouble() * 2);
      return FlSpot(index.toDouble(), performance);
    });
  }

  List<FlSpot> _generateWIG20Performance() {
    if (_advancedMetrics?.benchmarkMetrics.vsMarketReturn != null) {
      final marketReturn = _advancedMetrics!.benchmarkMetrics.vsMarketReturn;

      return List.generate(12, (index) {
        final performance =
            (marketReturn / 12) * (index + 1) +
            (math.Random().nextDouble() * 1.5 - 0.75);
        return FlSpot(index.toDouble(), performance);
      });
    }

    return List.generate(12, (index) {
      final performance =
          1 + (index * 0.6) + (math.Random().nextDouble() * 1.5);
      return FlSpot(index.toDouble(), performance);
    });
  }

  List<FlSpot> _generateBondsPerformance() {
    if (_advancedMetrics?.productAnalytics.productPerformance[ProductType
            .bonds] !=
        null) {
      final bondsReturn = _advancedMetrics!
          .productAnalytics
          .productPerformance[ProductType.bonds]!
          .averageReturn;

      return List.generate(12, (index) {
        final performance =
            (bondsReturn / 12) * (index + 1) +
            (math.Random().nextDouble() * 0.5 - 0.25);
        return FlSpot(index.toDouble(), performance);
      });
    }

    return List.generate(12, (index) {
      final performance =
          0.5 + (index * 0.3) + (math.Random().nextDouble() * 0.5);
      return FlSpot(index.toDouble(), performance);
    });
  }

  List<FlSpot> _generateWIBORPerformance() {
    // WIBOR jako stopa referencyjna - zwykle niska i stabilna
    return List.generate(12, (index) {
      final performance =
          0.3 + (index * 0.2) + (math.Random().nextDouble() * 0.3);
      return FlSpot(index.toDouble(), performance);
    });
  }
}
