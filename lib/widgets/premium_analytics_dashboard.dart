import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/investor_summary.dart';
import '../models/client.dart';
import 'premium_analytics_filter_panel.dart';
import 'premium_analytics_floating_controls.dart';
import 'tabs/voting_charts_tab.dart';
import 'tabs/trends_charts_tab.dart';
import 'tabs/distribution_charts_tab.dart';
import 'tabs/risk_analysis_tab.dart';

/// 🏢 GŁÓWNY DASHBOARD WYKRESÓW PREMIUM ANALYTICS
///
/// Centralny hub zarządzania wszystkimi wykresami analitycznymi.
/// Dostarcza spójny interfejs i zarządzanie stanem dla wszystkich komponentów.
/// Z zintegrowanym systemem filtrowania w czasie rzeczywistym.

class PremiumAnalyticsDashboard extends StatefulWidget {
  final List<InvestorSummary> investors;
  final Map<VotingStatus, double> votingDistribution;
  final Map<VotingStatus, int> votingCounts;
  final double totalCapital;
  final List<InvestorSummary> majorityHolders;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const PremiumAnalyticsDashboard({
    super.key,
    required this.investors,
    required this.votingDistribution,
    required this.votingCounts,
    required this.totalCapital,
    required this.majorityHolders,
    this.onRefresh,
    this.isLoading = false,
  });

  @override
  State<PremiumAnalyticsDashboard> createState() =>
      _PremiumAnalyticsDashboardState();
}

class _PremiumAnalyticsDashboardState extends State<PremiumAnalyticsDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Filter state
  bool _isFilterVisible = false;
  late PremiumAnalyticsFilter _currentFilter;
  List<InvestorSummary> _filteredInvestors = [];
  Map<VotingStatus, double> _filteredVotingDistribution = {};
  Map<VotingStatus, int> _filteredVotingCounts = {};
  double _filteredTotalCapital = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentFilter = PremiumAnalyticsFilter();
    _initializeFilteredData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PremiumAnalyticsDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.investors != oldWidget.investors ||
        widget.votingDistribution != oldWidget.votingDistribution ||
        widget.votingCounts != oldWidget.votingCounts ||
        widget.totalCapital != oldWidget.totalCapital) {
      _applyFilters();
    }
  }

  void _initializeFilteredData() {
    _filteredInvestors = List.from(widget.investors);
    _filteredVotingDistribution = Map.from(widget.votingDistribution);
    _filteredVotingCounts = Map.from(widget.votingCounts);
    _filteredTotalCapital = widget.totalCapital;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Stack(
        children: [
          Column(
            children: [
              _buildDashboardHeader(),
              _buildTabBar(),
              Expanded(
                child: widget.isLoading
                    ? _buildLoadingState()
                    : _buildChartsContent(),
              ),
            ],
          ),
          // Floating filter overlay
          if (_isFilterVisible) _buildFilterOverlay(),
          // Quick filter controls
          _buildFloatingControls(),
        ],
      ),
    );
  }

  Widget _buildFilterOverlay() {
    return Positioned.fill(
      child: Container(
        color: AppTheme.backgroundPrimary.withOpacity(0.95),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: PremiumAnalyticsFilterPanel(
              allInvestors: widget.investors,
              initialFilter: _currentFilter,
              onFiltersChanged: (newFilter) {
                setState(() {
                  _currentFilter = newFilter;
                  _applyFilters();
                });
              },
              onClose: () {
                setState(() {
                  _isFilterVisible = false;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingControls() {
    return Positioned(
      top: 120,
      right: 20,
      child: PremiumAnalyticsFloatingControls(
        allInvestors: widget.investors,
        currentFilter: _currentFilter,
        onFiltersChanged: (newFilter) {
          setState(() {
            _currentFilter = newFilter;
            _applyFilters();
          });
        },
        onShowFullPanel: () {
          setState(() {
            _isFilterVisible = true;
          });
        },
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.backgroundSecondary.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Analytics',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    Text(
                      'Zaawansowana analiza portfela • ${_filteredInvestors.length} inwestorów',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.refresh_rounded,
          label: 'Odśwież',
          onTap: widget.onRefresh,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: Icons.download_rounded,
          label: 'Eksport',
          onTap: _exportData,
          color: AppTheme.secondaryGold,
        ),
  
        const Spacer(),
        _buildActionButton(
          icon: Icons.fullscreen_rounded,
          label: 'Pełny ekran',
          onTap: _toggleFullscreen,
          color: AppTheme.warningColor,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    required Color color,
  }) {
    return Tooltip(
      message: label,
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.pie_chart_rounded), text: 'Głosowanie'),
          Tab(icon: Icon(Icons.trending_up_rounded), text: 'Trendy'),
          Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Dystrybucja'),
          Tab(icon: Icon(Icons.shield_rounded), text: 'Ryzyko'),
        ],
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
    );
  }

  Widget _buildChartsContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        VotingChartsTab(
          filteredInvestors: _filteredInvestors,
          filteredVotingDistribution: _filteredVotingDistribution,
          filteredVotingCounts: _filteredVotingCounts,
          filteredTotalCapital: _filteredTotalCapital,
        ),
        TrendsChartsTab(
          filteredInvestors: _filteredInvestors,
          filteredTotalCapital: _filteredTotalCapital,
        ),
        DistributionChartsTab(
          filteredInvestors: _filteredInvestors,
          filteredTotalCapital: _filteredTotalCapital,
        ),
        RiskAnalysisTab(
          filteredInvestors: _filteredInvestors,
          filteredTotalCapital: _filteredTotalCapital,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  void _applyFilters() {
    setState(() {
      _filteredInvestors = widget.investors.where((investor) {
        return _currentFilter.matches(investor);
      }).toList();

      // Recalculate totals for filtered data
      _filteredTotalCapital = _filteredInvestors.fold(
        0.0,
        (sum, investor) => sum + investor.viableRemainingCapital,
      );

      // Recalculate voting distribution for filtered data
      _filteredVotingDistribution = {};
      _filteredVotingCounts = {};

      for (final investor in _filteredInvestors) {
        final status = investor.client.votingStatus;
        _filteredVotingDistribution[status] =
            (_filteredVotingDistribution[status] ?? 0.0) +
            investor.viableRemainingCapital;
        _filteredVotingCounts[status] =
            (_filteredVotingCounts[status] ?? 0) + 1;
      }
    });
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Eksport danych - funkcja w przygotowaniu')),
    );
  }

  void _shareReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Udostępnianie raportu - funkcja w przygotowaniu'),
      ),
    );
  }

  void _toggleFullscreen() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pełny ekran - funkcja w przygotowaniu')),
    );
  }
}
