import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/investment.dart';
import '../services/web_analytics_service.dart';
import '../services/dashboard_service.dart';
import '../services/firebase_functions_data_service.dart';
import '../widgets/cache_debug_widget.dart';
import '../utils/currency_formatter.dart';

class SimpleDashboardScreen extends StatefulWidget {
  const SimpleDashboardScreen({super.key});

  @override
  State<SimpleDashboardScreen> createState() => _SimpleDashboardScreenState();
}

class _SimpleDashboardScreenState extends State<SimpleDashboardScreen>
    with TickerProviderStateMixin {
  final WebAnalyticsService _analyticsService = WebAnalyticsService();
  final DashboardService _dashboardService = DashboardService();
  final FirebaseFunctionsDataService _dataService =
      FirebaseFunctionsDataService();

  // Dane
  List<Investment> _recentInvestments = [];
  List<Investment> _investmentsRequiringAttention = [];
  DashboardMetrics? _dashboardMetrics;
  ProductTypeStatistics? _productStats;
  Map<String, dynamic>? _optimizedDashboardData;
  bool _useOptimizedData = false;

  // UI State
  bool _isLoading = false;
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _loadDashboardData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      if (_useOptimizedData) {
        // Load optimized data using Firebase Functions
        final results = await Future.wait([
          _dashboardService.getOptimizedDashboardData(),
          _dataService.getProductTypeStatistics(),
        ]);

        setState(() {
          _optimizedDashboardData = results[0] as Map<String, dynamic>;
          _productStats = results[1] as ProductTypeStatistics;
        });
      } else {
        // Legacy method
        final futures = await Future.wait([
          _analyticsService.getRecentInvestments(limit: 5),
          _analyticsService.getInvestmentsRequiringAttention(),
          _analyticsService.getDashboardMetrics(),
        ]);

        setState(() {
          _recentInvestments = futures[0] as List<Investment>;
          _investmentsRequiringAttention = futures[1] as List<Investment>;
          _dashboardMetrics = futures[2] as DashboardMetrics;
        });
      }

      setState(() => _isLoading = false);
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          _useOptimizedData ? 'Dashboard (Optimized)' : 'Dashboard (Legacy)',
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_useOptimizedData ? Icons.flash_on : Icons.flash_off),
            tooltip: _useOptimizedData
                ? 'Przełącz na Legacy'
                : 'Przełącz na Firebase Functions',
            onPressed: () {
              setState(() {
                _useOptimizedData = !_useOptimizedData;
              });
              _loadDashboardData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Odśwież',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  if (_useOptimizedData) _buildOptimizedSummary(),
                  _buildTabBar(),
                  Expanded(child: _buildTabContent()),
                ],
              ),
            ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabButton('Przegląd', 0, Icons.dashboard),
          _buildTabButton('Ostatnie', 1, Icons.history),
          _buildTabButton('Uwaga', 2, Icons.warning),
          _buildTabButton('Cache Debug', 3, Icons.bug_report),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                  fontSize: 12,
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
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildRecentInvestmentsTab();
      case 2:
        return _buildAttentionTab();
      case 3:
        return _buildCacheDebugTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    if (_dashboardMetrics == null) {
      return const Center(child: Text('Brak danych metryk'));
    }

    final metrics = _dashboardMetrics!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMetricsGrid(metrics),
          const SizedBox(height: 16),
          _buildQuickStats(metrics),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(DashboardMetrics metrics) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: _getGridCrossAxisCount(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMetricCard(
          'Łączne inwestycje',
          metrics.totalInvestments.toString(),
          Icons.account_balance_wallet,
          AppTheme.primaryColor,
        ),
        _buildMetricCard(
          'Łączna wartość',
          CurrencyFormatter.formatCurrency(metrics.totalValue),
          Icons.trending_up,
          Colors.green,
        ),
        _buildMetricCard(
          'Kwota inwestycji',
          CurrencyFormatter.formatCurrency(metrics.totalInvestmentAmount),
          Icons.savings,
          Colors.blue,
        ),
        _buildMetricCard(
          'ROI',
          '${metrics.roi.toStringAsFixed(2)}%',
          Icons.percent,
          metrics.roi >= 0 ? Colors.green : Colors.red,
        ),
        _buildMetricCard(
          'Aktywne',
          metrics.activeInvestments.toString(),
          Icons.play_circle,
          Colors.orange,
        ),
        _buildMetricCard(
          'Zakończone',
          metrics.completedInvestments.toString(),
          Icons.check_circle,
          Colors.grey,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
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
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(DashboardMetrics metrics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Szybkie statystyki',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            'Zrealizowany kapitał',
            CurrencyFormatter.formatCurrency(metrics.totalRealizedCapital),
          ),
          _buildStatRow(
            'Pozostały kapitał',
            CurrencyFormatter.formatCurrency(metrics.totalRemainingCapital),
          ),
          _buildStatRow(
            'Zrealizowane odsetki',
            CurrencyFormatter.formatCurrency(metrics.totalRealizedInterest),
          ),
          _buildStatRow(
            'Pozostałe odsetki',
            CurrencyFormatter.formatCurrency(metrics.totalRemainingInterest),
          ),
          _buildStatRow(
            'Średnia inwestycja',
            CurrencyFormatter.formatCurrency(metrics.averageInvestmentAmount),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecentInvestmentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ostatnie inwestycje',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._recentInvestments.map(
            (investment) => _buildInvestmentCard(investment),
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inwestycje wymagające uwagi',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_investmentsRequiringAttention.isEmpty)
            const Center(
              child: Text(
                'Brak inwestycji wymagających uwagi',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._investmentsRequiringAttention.map(
              (investment) =>
                  _buildInvestmentCard(investment, showWarning: true),
            ),
        ],
      ),
    );
  }

  Widget _buildInvestmentCard(
    Investment investment, {
    bool showWarning = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: showWarning ? Border.all(color: Colors.orange, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showWarning)
                const Icon(Icons.warning, color: Colors.orange, size: 20),
              if (showWarning) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  investment.clientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusChip(investment.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            investment.productName,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kwota: ${CurrencyFormatter.formatCurrency(investment.investmentAmount)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'Wartość: ${CurrencyFormatter.formatCurrency(investment.totalValue)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(InvestmentStatus status) {
    Color color;
    String label;

    switch (status) {
      case InvestmentStatus.active:
        color = Colors.green;
        label = 'Aktywny';
        break;
      case InvestmentStatus.completed:
        color = Colors.grey;
        label = 'Zakończony';
        break;
      case InvestmentStatus.inactive:
        color = Colors.red;
        label = 'Nieaktywny';
        break;
      case InvestmentStatus.earlyRedemption:
        color = Colors.orange;
        label = 'Wykup wcześniejszy';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCacheDebugTab() {
    return const CacheDebugWidget();
  }

  Widget _buildOptimizedSummary() {
    if (_optimizedDashboardData == null || _productStats == null) {
      return const SizedBox.shrink();
    }

    final summary = _productStats!.summary;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Firebase Functions Dashboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  'OPTIMIZED',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Statystyki podsumowujące
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Łączne produkty',
                  '${summary.totalCount}',
                  Icons.inventory,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Łączna wartość',
                  '${(summary.totalValue / 1000000).toStringAsFixed(1)}M PLN',
                  Icons.monetization_on,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Statystyki poszczególnych typów
          Row(
            children: [
              Expanded(
                child: _buildProductTypeCard(
                  'Obligacje',
                  _productStats!.bonds,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildProductTypeCard(
                  'Udziały',
                  _productStats!.shares,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildProductTypeCard(
                  'Pożyczki',
                  _productStats!.loans,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildProductTypeCard(
                  'Apartamenty',
                  _productStats!.apartments,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
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
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTypeCard(String name, ProductStats stats, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${stats.count}',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${(stats.totalValue / 1000).toStringAsFixed(0)}K',
            style: TextStyle(color: color.withOpacity(0.7), fontSize: 10),
          ),
        ],
      ),
    );
  }

  int _getGridCrossAxisCount() {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }
}
