import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/investment.dart';
import '../services/investment_service.dart';
import '../services/advanced_analytics_service.dart';
import '../widgets/dashboard/dashboard_cache_debug_tab.dart';
import '../widgets/dashboard/dashboard_overview_content.dart';
import '../widgets/dashboard/dashboard_performance_content.dart';
import '../widgets/dashboard/dashboard_risk_content.dart';
import '../widgets/dashboard/dashboard_predictions_content.dart';
import '../widgets/dashboard/dashboard_benchmark_content.dart';

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

  double _getHorizontalPadding(BuildContext context) {
    if (_isMobile(context)) return 16.0;
    if (_isTablet(context)) return 24.0;
    return 32.0;
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
        _investmentService.getInvestmentsPaginated(limit: 10),
        _analyticsService.getAdvancedDashboardMetrics(),
      ]);

      setState(() {
        _recentInvestments = results[0] as List<Investment>;
        _advancedMetrics = results[1] as AdvancedDashboardMetrics;
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
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
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
                'Dashboard Inwestycji',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppTheme.textOnPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Zaawansowana analiza portfela z metrykami ryzyka i wydajności',
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
          const SizedBox(width: 8),
          _buildCompactTabButton(5, 'Cache Debug', Icons.storage),
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
        _buildTabButton(5, 'Cache Debug', Icons.storage),
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
      case 5:
        return _buildCacheDebugTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return DashboardOverviewContent(
      recentInvestments: _recentInvestments,
      metrics: _advancedMetrics,
      isMobile: _isMobile(context),
      selectedTimeFrame: _selectedTimeFrame,
      horizontalPadding: _getHorizontalPadding(context),
      context: context,
    );
  }

  Widget _buildPerformanceTab() {
    return DashboardPerformanceContent(
      metrics: _advancedMetrics,
      isMobile: _isMobile(context),
      horizontalPadding: _getHorizontalPadding(context),
      context: context,
    );
  }

  Widget _buildRiskTab() {
    return DashboardRiskContent(
      metrics: _advancedMetrics,
      isMobile: _isMobile(context),
      horizontalPadding: _getHorizontalPadding(context),
      context: context,
    );
  }

  Widget _buildPredictionsTab() {
    return DashboardPredictionsContent(
      metrics: _advancedMetrics,
      isMobile: _isMobile(context),
      horizontalPadding: _getHorizontalPadding(context),
      context: context,
    );
  }

  Widget _buildBenchmarkTab() {
    return DashboardBenchmarkContent(
      metrics: _advancedMetrics,
      isMobile: _isMobile(context),
      horizontalPadding: _getHorizontalPadding(context),
      context: context,
    );
  }

  Widget _buildCacheDebugTab() {
    return DashboardCacheDebugTab(isMobile: _isMobile(context));
  }
}
