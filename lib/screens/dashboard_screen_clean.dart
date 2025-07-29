import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';

import '../config/theme.dart';
import '../models/models_and_services.dart';
import '../services/advanced_analytics_service.dart';
import '../widgets/common/advanced_metric_card.dart';
import '../widgets/charts/advanced_line_chart.dart';
import '../widgets/charts/advanced_pie_chart.dart';
import '../widgets/charts/advanced_scatter_chart.dart';
import '../widgets/dashboard/dashboard_overview_content.dart';
import '../widgets/dashboard/dashboard_performance_content.dart';
import '../widgets/dashboard/dashboard_risk_content.dart';
import '../widgets/dashboard/dashboard_predictions_content.dart';
import '../widgets/dashboard/dashboard_benchmark_content.dart';

class DashboardScreenComplete extends StatefulWidget {
  const DashboardScreenComplete({super.key});

  @override
  State<DashboardScreenComplete> createState() =>
      _DashboardScreenCompleteState();
}

class _DashboardScreenCompleteState extends State<DashboardScreenComplete>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  final AdvancedAnalyticsService _analyticsService = AdvancedAnalyticsService();
  AdvancedMetrics? _advancedMetrics;
  bool _isLoading = true;

  final List<Tab> _tabs = [
    const Tab(icon: Icon(Icons.dashboard), text: 'Przegląd'),
    const Tab(icon: Icon(Icons.trending_up), text: 'Wydajność'),
    const Tab(icon: Icon(Icons.security), text: 'Ryzyko'),
    const Tab(icon: Icon(Icons.analytics), text: 'Prognozy'),
    const Tab(icon: Icon(Icons.compare_arrows), text: 'Benchmark'),
  ];

  // Metody pomocnicze
  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  double _getHorizontalPadding(BuildContext context) =>
      _isMobile(context) ? 16.0 : 24.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
    _loadAdvancedMetrics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdvancedMetrics() async {
    try {
      final metrics = await _analyticsService.calculateAdvancedMetrics();
      setState(() {
        _advancedMetrics = metrics;
        _isLoading = false;
      });
    } catch (e) {
      print('Błąd ładowania zaawansowanych metryk: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _advancedMetrics == null
          ? const Center(child: Text('Błąd ładowania danych'))
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.backgroundPrimary,
      elevation: 0,
      title: Row(
        children: [
          Icon(Icons.analytics_outlined, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Text(
            'Dashboard Analityczny',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
          onPressed: () {
            setState(() {
              _isLoading = true;
            });
            _loadAdvancedMetrics();
          },
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: _tabs,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        isScrollable: _isMobile(context),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: _isMobile(context) ? 12 : 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildPerformanceTab(),
        _buildRiskTab(),
        _buildPredictionsTab(),
        _buildBenchmarkTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return DashboardOverviewContent(
      metrics: _advancedMetrics!,
      isMobile: _isMobile(context),
      horizontalPadding: _getHorizontalPadding(context),
      context: context,
    );
  }

  Widget _buildPerformanceTab() {
    return DashboardPerformanceContent(
      metrics: _advancedMetrics!,
      isMobile: _isMobile(context),
      horizontalPadding: _getHorizontalPadding(context),
      context: context,
    );
  }

  Widget _buildRiskTab() {
    return DashboardRiskContent(
      metrics: _advancedMetrics!,
      isMobile: _isMobile(context),
      horizontalPadding: _getHorizontalPadding(context),
      context: context,
    );
  }

  Widget _buildPredictionsTab() {
    return DashboardPredictionsContent(
      metrics: _advancedMetrics!,
      isMobile: _isMobile(context),
      horizontalPadding: _getHorizontalPadding(context),
      context: context,
    );
  }

  Widget _buildBenchmarkTab() {
    return DashboardBenchmarkContent(
      metrics: _advancedMetrics!,
      isMobile: _isMobile(context),
      horizontalPadding: _getHorizontalPadding(context),
      context: context,
    );
  }
}
