import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/investor_summary.dart';
import '../models/client.dart';
import '../utils/currency_formatter.dart';
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
    _applyFilters();
  }

  @override
  void didUpdateWidget(PremiumAnalyticsDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.investors != oldWidget.investors) {
      _applyFilters();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.backgroundPrimary,
                AppTheme.backgroundSecondary.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
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
        ),

        // Filter Panel Overlay
        if (_isFilterVisible)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: PremiumAnalyticsFilterPanel(
              allInvestors: widget.investors,
              onFiltersChanged: _onFiltersChanged,
              initialFilter: _currentFilter,
              isVisible: _isFilterVisible,
              onClose: () => setState(() => _isFilterVisible = false),
            ),
          ),

        // Floating Quick Controls
        Positioned(
          bottom: 20,
          left: 20,
          right: _isFilterVisible ? 400 : 20,
          child: PremiumAnalyticsFloatingControls(
            allInvestors: widget.investors,
            currentFilter: _currentFilter,
            onFiltersChanged: _onFiltersChanged,
            onShowFullPanel: () => setState(() => _isFilterVisible = true),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryGold.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 Premium Analytics Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Zaawansowana analiza ${_filteredInvestors.length} z ${widget.investors.length} inwestorów • '
                  '${CurrencyFormatter.formatCurrencyShort(_filteredTotalCapital)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
          onTap: _exportCharts,
          color: AppTheme.secondaryGold,
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: Icons.filter_list_rounded,
          label: 'Filtry',
          onTap: _toggleFilterPanel,
          color: _isFilterVisible
              ? AppTheme.primaryColor
              : AppTheme.textSecondary,
        ),
        const SizedBox(width: 12),
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
          Tab(icon: Icon(Icons.pie_chart_rounded), text: 'Rozkład Głosów'),
          Tab(icon: Icon(Icons.show_chart_rounded), text: 'Trendy Kapitału'),
          Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Dystrybucja'),
          Tab(icon: Icon(Icons.analytics_rounded), text: 'Analiza Ryzyka'),
        ],
        indicator: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondary,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
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

    }

  // UI Action Methods
  void _toggleFilter() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
    });
  }

  void _clearFilters() {
    setState(() {
      _currentFilter = PremiumAnalyticsFilter();
      _applyFilters();
    });
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Eksport danych - funkcja w przygotowaniu')),
    );
  }

  void _shareReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Udostępnianie raportu - funkcja w przygotowaniu')),
    );
  }

  void _exportCharts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eksport wykresów - funkcja w przygotowaniu'),
      ),
    );
  }

  void _toggleFullscreen() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pełny ekran - funkcja w przygotowaniu')),
    );
  }
}
}
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildStatCard(
          'Głosy ZA',
          '${_filteredVotingCounts[VotingStatus.yes] ?? 0}',
          '${_getVotingPercentage(VotingStatus.yes).toStringAsFixed(1)}%',
          Icons.thumb_up_rounded,
          const Color(0xFF00C851),
        ),
        _buildStatCard(
          'Głosy PRZECIW',
          '${_filteredVotingCounts[VotingStatus.no] ?? 0}',
          '${_getVotingPercentage(VotingStatus.no).toStringAsFixed(1)}%',
          Icons.thumb_down_rounded,
          const Color(0xFFFF4444),
        ),
        _buildStatCard(
          'Wstrzymania',
          '${_filteredVotingCounts[VotingStatus.abstain] ?? 0}',
          '${_getVotingPercentage(VotingStatus.abstain).toStringAsFixed(1)}%',
          Icons.remove_circle_rounded,
          const Color(0xFFFF8800),
        ),
        _buildStatCard(
          'Niezdecydowani',
          '${_filteredVotingCounts[VotingStatus.undecided] ?? 0}',
          '${_getVotingPercentage(VotingStatus.undecided).toStringAsFixed(1)}%',
          Icons.help_rounded,
          const Color(0xFF9E9E9E),
        ),
      ],
    );
  }

  Widget _buildTrendsStatsGrid() {
    final avgCapital = _filteredInvestors.isNotEmpty
        ? _filteredTotalCapital / _filteredInvestors.length
        : 0.0;
    final maxCapital = _filteredInvestors.isNotEmpty
        ? _filteredInvestors
              .map((i) => i.viableRemainingCapital)
              .reduce((a, b) => a > b ? a : b)
        : 0.0;

    return GridView.count(
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
          'Koncentracja',
          '${(maxCapital / _filteredTotalCapital * 100).toStringAsFixed(1)}%',
          'top inwestor',
          Icons.center_focus_strong_rounded,
          AppTheme.warningColor,
        ),
      ],
    );
  }

  Widget _buildDistributionStatsGrid() {
    final smallInvestors = _filteredInvestors
        .where((i) => i.viableRemainingCapital < 100000)
        .length;
    final mediumInvestors = _filteredInvestors
        .where(
          (i) =>
              i.viableRemainingCapital >= 100000 &&
              i.viableRemainingCapital < 1000000,
        )
        .length;
    final largeInvestors = _filteredInvestors
        .where((i) => i.viableRemainingCapital >= 1000000)
        .length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2,
      children: [
        _buildStatCard(
          'Mali (<100K)',
          '$smallInvestors',
          '${(smallInvestors / _filteredInvestors.length * 100).toStringAsFixed(0)}%',
          Icons.people_rounded,
          const Color(0xFF4CAF50),
        ),
        _buildStatCard(
          'Średni (100K-1M)',
          '$mediumInvestors',
          '${(mediumInvestors / _filteredInvestors.length * 100).toStringAsFixed(0)}%',
          Icons.business_rounded,
          const Color(0xFF2196F3),
        ),
        _buildStatCard(
          'Duzi (>1M)',
          '$largeInvestors',
          '${(largeInvestors / _filteredInvestors.length * 100).toStringAsFixed(0)}%',
          Icons.account_balance_wallet_rounded,
          const Color(0xFFFF5722),
        ),
      ],
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
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryGold],
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ładowanie danych analitycznych...',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Przygotowujemy zaawansowane wykresy',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  // Filter and data processing methods
  void _applyFilters() {
    _filteredInvestors = widget.investors
        .where(_currentFilter.matches)
        .toList();
    _calculateFilteredMetrics();
  }

  void _calculateFilteredMetrics() {
    _filteredTotalCapital = _filteredInvestors.fold<double>(
      0.0,
      (sum, investor) => sum + investor.viableRemainingCapital,
    );

    // Reset voting counts and distribution
    _filteredVotingDistribution = {};
    _filteredVotingCounts = {};

    for (final status in VotingStatus.values) {
      final investorsWithStatus = _filteredInvestors
          .where((inv) => inv.client.votingStatus == status)
          .toList();

      final capital = investorsWithStatus.fold<double>(
        0.0,
        (sum, inv) => sum + inv.viableRemainingCapital,
      );

      _filteredVotingDistribution[status] = capital;
      _filteredVotingCounts[status] = investorsWithStatus.length;
    }
  }

  void _onFiltersChanged(PremiumAnalyticsFilter newFilter) {
    setState(() {
      _currentFilter = newFilter;
      _applyFilters();
    });
  }

  void _toggleFilterPanel() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
    });
  }

  double _getVotingPercentage(VotingStatus status) {
    final total = _filteredVotingCounts.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    final count = _filteredVotingCounts[status] ?? 0;
    return total > 0 ? (count / total) * 100 : 0.0;
  }

  Map<String, double> _calculateRadarMetrics() {
    // Oblicz metryki dla wykresu radar
    return {
      'Dywersyfikacja': _calculateDiversificationScore(),
      'Płynność': _calculateLiquidityScore(),
      'Rentowność': _calculateProfitabilityScore(),
      'Stabilność': _calculateStabilityScore(),
      'Wzrost': _calculateGrowthScore(),
      'Jakość': _calculateQualityScore(),
    };
  }

  double _calculateDiversificationScore() {
    if (_filteredInvestors.isEmpty) return 0.0;

    final avgProductTypes =
        _filteredInvestors
            .map(
              (i) => i.investments.map((inv) => inv.productType).toSet().length,
            )
            .reduce((a, b) => a + b) /
        _filteredInvestors.length;

    return (avgProductTypes / 4 * 100).clamp(
      0.0,
      100.0,
    ); // Zakładając max 4 typy produktów
  }

  double _calculateLiquidityScore() {
    // Uproszczona kalkulacja płynności
    return 75.0; // Przykładowa wartość
  }

  double _calculateProfitabilityScore() {
    // Uproszczona kalkulacja rentowności
    return 65.0; // Przykładowa wartość
  }

  double _calculateStabilityScore() {
    // Uproszczona kalkulacja stabilności
    return 80.0; // Przykładowa wartość
  }

  double _calculateGrowthScore() {
    // Uproszczona kalkulacja wzrostu
    return 70.0; // Przykładowa wartość
  }

  double _calculateQualityScore() {
    // Uproszczona kalkulacja jakości
    return 85.0; // Przykładowa wartość
  }

  void _showVotingDetails() {
    // Implementacja szczegółów głosowania
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Szczegóły głosowania'),
        content: const Text('Funkcja w przygotowaniu...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _exportCharts() {
    // Implementacja eksportu wykresów
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eksport wykresów - funkcja w przygotowaniu'),
      ),
    );
  }

  void _toggleFullscreen() {
    // Implementacja pełnego ekranu
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pełny ekran - funkcja w przygotowaniu')),
    );
  }
}
