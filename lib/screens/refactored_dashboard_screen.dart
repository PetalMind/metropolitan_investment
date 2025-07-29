import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/investment.dart';
import '../services/web_analytics_service.dart';
import '../widgets/dashboard/dashboard_header.dart';
import '../widgets/dashboard/dashboard_tab_bar.dart';
import '../widgets/dashboard/dashboard_overview_tab.dart';
import '../widgets/dashboard/dashboard_performance_tab.dart';
import '../widgets/dashboard/dashboard_risk_tab.dart';
import '../widgets/dashboard/dashboard_predictions_tab.dart';
import '../widgets/dashboard/dashboard_benchmark_tab.dart';
import '../widgets/dashboard/dashboard_cache_debug_tab.dart';

class RefactoredDashboardScreen extends StatefulWidget {
  const RefactoredDashboardScreen({super.key});

  @override
  State<RefactoredDashboardScreen> createState() =>
      _RefactoredDashboardScreenState();
}

class _RefactoredDashboardScreenState extends State<RefactoredDashboardScreen>
    with TickerProviderStateMixin {
  final WebAnalyticsService _analyticsService = WebAnalyticsService();

  // Dane podstawowe
  List<Investment> _recentInvestments = [];
  List<Investment> _investmentsRequiringAttention = [];
  List<ClientSummary> _topClients = [];
  DashboardMetrics? _dashboardMetrics;

  bool _isLoading = true;
  String _selectedTimeFrame = '12M';
  int _selectedDashboardTab = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // === RESPONSYWNE FUNKCJE POMOCNICZE ===
  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

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
      final recentInvestmentsFuture = _analyticsService.getRecentInvestments(
        limit: 5,
      );
      final attentionInvestmentsFuture = _analyticsService
          .getInvestmentsRequiringAttention();
      final metricsFuture = _analyticsService.getDashboardMetrics();
      final topClientsFuture = _analyticsService.getTopClients(limit: 5);

      final results = await Future.wait([
        recentInvestmentsFuture,
        attentionInvestmentsFuture,
        metricsFuture,
        topClientsFuture,
      ]);

      setState(() {
        _recentInvestments = results[0] as List<Investment>;
        _investmentsRequiringAttention = results[1] as List<Investment>;
        _dashboardMetrics = results[2] as DashboardMetrics;
        _topClients = results[3] as List<ClientSummary>;
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
          onPressed: _loadDashboardData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Ładowanie danych dashboard...',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
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
            DashboardHeader(
              isMobile: _isMobile(context),
              selectedTimeFrame: _selectedTimeFrame,
              onRefresh: _loadDashboardData,
              onTimeFrameChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTimeFrame = value);
                  _loadDashboardData();
                }
              },
            ),
            DashboardTabBar(
              isMobile: _isMobile(context),
              selectedTab: _selectedDashboardTab,
              onTabChanged: (index) =>
                  setState(() => _selectedDashboardTab = index),
            ),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedDashboardTab) {
      case 0:
        return DashboardOverviewTab(
          isMobile: _isMobile(context),
          dashboardMetrics: _dashboardMetrics,
          recentInvestments: _recentInvestments,
          investmentsRequiringAttention: _investmentsRequiringAttention,
          topClients: _topClients,
        );
      case 1:
        return DashboardPerformanceTab(isMobile: _isMobile(context));
      case 2:
        return DashboardRiskTab(isMobile: _isMobile(context));
      case 3:
        return DashboardPredictionsTab(isMobile: _isMobile(context));
      case 4:
        return DashboardBenchmarkTab(isMobile: _isMobile(context));
      case 5:
        return DashboardCacheDebugTab(isMobile: _isMobile(context));
      default:
        return DashboardOverviewTab(
          isMobile: _isMobile(context),
          dashboardMetrics: _dashboardMetrics,
          recentInvestments: _recentInvestments,
          investmentsRequiringAttention: _investmentsRequiringAttention,
          topClients: _topClients,
        );
    }
  }
}
