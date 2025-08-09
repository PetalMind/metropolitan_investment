import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firebase_functions_dashboard_service.dart';
import '../widgets/dashboard/overview_tab.dart';
import '../widgets/dashboard/performance_tab.dart';
import '../widgets/dashboard/risk_tab.dart';
import '../widgets/dashboard/predictions_tab.dart';
import '../widgets/dashboard/benchmark_tab.dart';

/// 📊 REFACTORED DASHBOARD SCREEN
///
/// Zrefaktorowany dashboard z:
/// - Podziałem na osobne widgety dla każdej zakładki
/// - Integracją z Firebase Functions dla zaawansowanej analityki
/// - Optymalizacją wydajności przez server-side processing
/// - Wsparcie dla split_investment_data structure (bonds, shares, loans, apartments)
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dane z Firebase Functions
  Map<String, dynamic>? _allDashboardMetrics;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  // Status połączenia
  bool _functionsHealthy = true;

  final List<DashboardTab> _tabs = [
    DashboardTab(
      id: 'overview',
      label: 'Przegląd',
      icon: Icons.dashboard,
      color: AppTheme.primaryColor,
    ),
    DashboardTab(
      id: 'performance',
      label: 'Wydajność',
      icon: Icons.trending_up,
      color: AppTheme.gainPrimary,
    ),
    DashboardTab(
      id: 'risk',
      label: 'Ryzyko',
      icon: Icons.warning_outlined,
      color: AppTheme.loansColor,
    ),
    DashboardTab(
      id: 'predictions',
      label: 'Prognozy',
      icon: Icons.psychology,
      color: AppTheme.bondsColor,
    ),
    DashboardTab(
      id: 'benchmark',
      label: 'Benchmarki',
      icon: Icons.compare_arrows,
      color: AppTheme.sharesColor,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _initializeDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 🚀 INICJALIZACJA DASHBOARD
  /// Sprawdza health Firebase Functions i ładuje dane
  Future<void> _initializeDashboard() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // 1. Sprawdź status Firebase Functions
      _functionsHealthy =
          await FirebaseFunctionsDashboardService.checkFunctionsHealth();

      if (!_functionsHealthy) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Firebase Functions niedostępne. Spróbuj ponownie później.';
          _isLoading = false;
        });
        return;
      }

      // 2. Załaduj wszystkie dane dashboard równolegle
      final allMetrics =
          await FirebaseFunctionsDashboardService.getAllDashboardMetrics(
            forceRefresh: false,
            timePeriod: 'all',
            riskProfile: 'moderate',
            predictionHorizon: 12,
            benchmarkType: 'market',
          );

      if (allMetrics['error'] == true) {
        setState(() {
          _hasError = true;
          _errorMessage = allMetrics['message'] ?? 'Nieznany błąd';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _allDashboardMetrics = allMetrics;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 🔄 ODŚWIEŻANIE DANYCH
  Future<void> _refreshDashboard() async {
    // Wymuś odświeżenie cache
    await FirebaseFunctionsDashboardService.refreshAllCache();
    await _initializeDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Column(
        children: [
          _buildDashboardHeader(),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
      floatingActionButton: _buildRefreshButton(),
    );
  }

  /// 📋 HEADER Z STATUSEM
  Widget _buildDashboardHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        boxShadow: [
          BoxShadow(
            color: AppTheme.textSecondary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Analityczny',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Zaawansowana analiza portfela inwestycyjnego',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              _buildStatusIndicator(),
            ],
          ),
          if (_allDashboardMetrics != null) ...[
            const SizedBox(height: 16),
            _buildQuickStats(),
          ],
        ],
      ),
    );
  }

  /// 🟢 STATUS INDICATOR
  Widget _buildStatusIndicator() {
    if (_isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Ładowanie...',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      );
    }

    if (_hasError) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 16, color: AppTheme.lossPrimary),
          const SizedBox(width: 8),
          Text(
            'Błąd',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.lossPrimary),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _functionsHealthy
                ? AppTheme.gainPrimary
                : AppTheme.lossPrimary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _functionsHealthy ? 'Online' : 'Offline',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _functionsHealthy
                ? AppTheme.gainPrimary
                : AppTheme.lossPrimary,
          ),
        ),
      ],
    );
  }

  /// 📊 SZYBKIE STATYSTYKI
  Widget _buildQuickStats() {
    final advancedMetrics =
        _allDashboardMetrics?['advanced'] as Map<String, dynamic>?;
    final portfolioMetrics =
        advancedMetrics?['portfolioMetrics'] as Map<String, dynamic>?;

    if (portfolioMetrics == null) return const SizedBox.shrink();

    final executionTime =
        _allDashboardMetrics?['advanced']?['executionTime'] as int? ?? 0;
    final dataPoints =
        _allDashboardMetrics?['advanced']?['dataPoints'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickStatItem(
            'Wartość Portfela',
            formatCurrency(
              (portfolioMetrics['totalValue'] as num?)?.toDouble() ?? 0.0,
            ),
            Icons.account_balance_wallet,
          ),
          _buildQuickStatItem(
            'ROI',
            '${(portfolioMetrics['roi'] as num?)?.toStringAsFixed(1) ?? '0.0'}%',
            Icons.trending_up,
          ),
          _buildQuickStatItem(
            'Inwestycji',
            '${portfolioMetrics['totalInvestmentsCount'] ?? 0}',
            Icons.pie_chart,
          ),
          _buildQuickStatItem(
            'Czas obliczeń',
            '${executionTime}ms',
            Icons.speed,
          ),
          _buildQuickStatItem('Punkty danych', '$dataPoints', Icons.data_usage),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  /// 📑 TAB BAR
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.textSecondary.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.primaryColor,
        labelColor: AppTheme.textPrimary,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: Theme.of(context).textTheme.labelLarge,
        tabs: _tabs
            .map((tab) => Tab(icon: Icon(tab.icon, size: 20), text: tab.label))
            .toList(),
      ),
    );
  }

  /// 📋 ZAWARTOŚĆ ZAKŁADEK
  Widget _buildTabContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Ładowanie danych analitycznych...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.lossPrimary),
            const SizedBox(height: 16),
            Text(
              'Błąd ładowania dashboard',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: AppTheme.textPrimary),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _initializeDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        // 1. OVERVIEW TAB
        OverviewTab(dashboardMetrics: _allDashboardMetrics?['advanced']),

        // 2. PERFORMANCE TAB
        PerformanceTab(advancedMetrics: _allDashboardMetrics?['advanced']),

        // 3. RISK TAB
        RiskTab(advancedMetrics: _allDashboardMetrics?['advanced']),

        // 4. PREDICTIONS TAB
        const PredictionsTab(),

        // 5. BENCHMARK TAB
        const BenchmarkTab(),
      ],
    );
  }

  /// 🔄 REFRESH BUTTON
  Widget _buildRefreshButton() {
    return FloatingActionButton(
      onPressed: _isLoading ? null : _refreshDashboard,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: AppTheme.textOnPrimary,
      tooltip: 'Odśwież dane',
      child: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.textOnPrimary,
              ),
            )
          : const Icon(Icons.refresh),
    );
  }
}

/// 📑 MODEL ZAKŁADKI DASHBOARD
class DashboardTab {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const DashboardTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// 💰 HELPER: Format currency
String formatCurrency(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M PLN';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K PLN';
  } else {
    return '${value.toStringAsFixed(0)} PLN';
  }
}

/// 🔍 HELPER: Format percentage
String formatPercentage(double value) {
  return '${value.toStringAsFixed(1)}%';
}

/// 📅 HELPER: Format date
String formatDate(DateTime date) {
  final months = [
    'sty',
    'lut',
    'mar',
    'kwi',
    'maj',
    'cze',
    'lip',
    'sie',
    'wrz',
    'paź',
    'lis',
    'gru',
  ];

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
