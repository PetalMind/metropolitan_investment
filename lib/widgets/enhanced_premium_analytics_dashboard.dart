import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/investor_summary.dart';
import '../models/client.dart';
import '../services/firebase_functions_analytics_service_updated.dart';
import 'firebase_functions_dialogs_updated.dart';
import '../utils/currency_formatter.dart';

/// 🚀 ENHANCED PREMIUM ANALYTICS DASHBOARD
/// Zintegrowany z nowymi Firebase Functions dla zwiększonej wydajności
///
/// NOWE FUNKCJE:
/// - Integracja z modularnych Firebase Functions
/// - Real-time statistiks produktów
/// - Optymalizowane wyszukiwanie inwestorów
/// - Zaawansowane cache management
/// - Debug diagnostics
class EnhancedPremiumAnalyticsDashboard extends StatefulWidget {
  final List<InvestorSummary> investors;
  final Map<VotingStatus, double> votingDistribution;
  final Map<VotingStatus, int> votingCounts;
  final double totalCapital;
  final List<InvestorSummary> majorityHolders;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const EnhancedPremiumAnalyticsDashboard({
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
  State<EnhancedPremiumAnalyticsDashboard> createState() =>
      _EnhancedPremiumAnalyticsDashboardState();
}

class _EnhancedPremiumAnalyticsDashboardState
    extends State<EnhancedPremiumAnalyticsDashboard>
    with TickerProviderStateMixin {
  final FirebaseFunctionsAnalyticsServiceUpdated _functionsService =
      FirebaseFunctionsAnalyticsServiceUpdated();

  late TabController _tabController;

  // Enhanced state management
  bool _isLoadingStats = false;
  ProductStatisticsResult? _productStats;
  ClientsResult? _clientsInfo;

  // Performance metrics
  int? _lastExecutionTime;
  bool? _lastCacheUsed;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
    ); // +1 tab for new functions
    _loadEnhancedData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Ładuje dodatkowe dane z nowych Firebase Functions
  Future<void> _loadEnhancedData() async {
    if (!mounted) return;

    setState(() => _isLoadingStats = true);

    try {
      // Równoległe ładowanie dla lepszej wydajności
      final results = await Future.wait([
        _functionsService.getUnifiedProductStatistics(),
        _functionsService.getAllClients(page: 1, pageSize: 10),
      ]);

      if (mounted) {
        setState(() {
          _productStats = results[0] as ProductStatisticsResult;
          _clientsInfo = results[1] as ClientsResult;
          _lastExecutionTime = _productStats?.metadata.executionTime;
          _lastCacheUsed = _productStats?.metadata.cacheUsed;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
      print('❌ [Enhanced Dashboard] Błąd ładowania danych: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Column(
        children: [
          _buildEnhancedHeader(),
          _buildEnhancedTabBar(),
          Expanded(
            child: widget.isLoading
                ? _buildLoadingState()
                : _buildEnhancedContent(),
          ),
        ],
      ),
      floatingActionButton: _buildEnhancedFAB(),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🚀 Enhanced Premium Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              _buildPerformanceIndicator(),
            ],
          ),
          const SizedBox(height: 12),
          _buildEnhancedStatsRow(),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator() {
    if (_lastExecutionTime == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _lastCacheUsed == true
            ? AppTheme.successPrimary.withOpacity(0.2)
            : AppTheme.warningPrimary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _lastCacheUsed == true ? Icons.cached : Icons.refresh,
            size: 16,
            color: _lastCacheUsed == true
                ? AppTheme.successPrimary
                : AppTheme.warningPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            '${_lastExecutionTime}ms',
            style: TextStyle(
              fontSize: 12,
              color: _lastCacheUsed == true
                  ? AppTheme.successPrimary
                  : AppTheme.warningPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatsRow() {
    return Row(
      children: [
        _buildQuickStat(
          '👥 Inwestorzy',
          '${widget.investors.length}',
          AppTheme.infoPrimary,
        ),
        const SizedBox(width: 16),
        _buildQuickStat(
          '💰 Kapitał',
          CurrencyFormatter.formatCurrencyShort(widget.totalCapital),
          AppTheme.secondaryGold,
        ),
        const SizedBox(width: 16),
        if (_productStats != null)
          _buildQuickStat(
            '📦 Produkty',
            '${_productStats!.totalProducts}',
            AppTheme.successPrimary,
          ),
        const SizedBox(width: 16),
        if (_clientsInfo != null)
          _buildQuickStat(
            '🏢 Klienci',
            '${_clientsInfo!.totalCount}',
            AppTheme.warningPrimary,
          ),
      ],
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedTabBar() {
    return Container(
      color: AppTheme.backgroundSecondary,
      child: Material(
        color: Colors.transparent,
        child: TabBar(
          controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.secondaryGold,
        labelColor: AppTheme.secondaryGold,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: '📊 Przegląd', icon: Icon(Icons.dashboard, size: 16)),
          Tab(text: '🗳️ Głosowanie', icon: Icon(Icons.how_to_vote, size: 16)),
          Tab(text: '📈 Trendy', icon: Icon(Icons.trending_up, size: 16)),
          Tab(text: '👑 Większość', icon: Icon(Icons.gavel, size: 16)),
          Tab(text: '🚀 Functions', icon: Icon(Icons.functions, size: 16)),
        ],
        ),
      ),
    );
  }

  Widget _buildEnhancedContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildVotingTab(),
        _buildTrendsTab(),
        _buildMajorityTab(),
        _buildFunctionsTab(), // Nowa zakładka
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Przegląd systemu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingStats)
            const Center(child: CircularProgressIndicator())
          else if (_productStats != null)
            _buildProductStatsGrid(),
          const SizedBox(height: 24),
          _buildInvestorsOverview(),
        ],
      ),
    );
  }

  Widget _buildProductStatsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _productStats!.productTypeBreakdown.length,
      itemBuilder: (context, index) {
        final breakdown = _productStats!.productTypeBreakdown[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.secondaryGold.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                breakdown.typeName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Liczba: ${breakdown.count}',
                style: TextStyle(color: Colors.grey[300]),
              ),
              Text(
                'Wartość: ${CurrencyFormatter.formatCurrencyShort(breakdown.totalValue)}',
                style: TextStyle(
                  color: AppTheme.secondaryGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${breakdown.percentage.toStringAsFixed(1)}% portfela',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvestorsOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👥 Inwestorzy',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Razem: ${widget.investors.length}'),
              Text(
                CurrencyFormatter.formatCurrency(widget.totalCapital),
                style: TextStyle(
                  color: AppTheme.secondaryGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVotingTab() {
    return const Center(
      child: Text(
        '🗳️ Analiza głosowania\n(Implementacja w przyszłej wersji)',
        style: TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTrendsTab() {
    return const Center(
      child: Text(
        '📈 Analiza trendów\n(Implementacja w przyszłej wersji)',
        style: TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMajorityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👑 Kontrola większościowa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text('Inwestorów większościowych: ${widget.majorityHolders.length}'),
          const SizedBox(height: 12),
          ...widget.majorityHolders
              .take(5)
              .map(
                (investor) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          investor.client.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatCurrencyShort(
                          investor.totalValue,
                        ),
                        style: TextStyle(
                          color: AppTheme.secondaryGold,
                          fontWeight: FontWeight.bold,
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

  /// 🚀 NOWA ZAKŁADKA: Firebase Functions
  Widget _buildFunctionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🚀 Firebase Functions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nowe modularne funkcje Firebase dla zwiększonej wydajności',
            style: TextStyle(color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),

          // Performance metrics
          if (_lastExecutionTime != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚡ Metryki wydajności',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Czas wykonania:',
                        style: TextStyle(color: Colors.grey[300]),
                      ),
                      Text(
                        '${_lastExecutionTime}ms',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cache użyty:',
                        style: TextStyle(color: Colors.grey[300]),
                      ),
                      Text(
                        _lastCacheUsed == true ? 'Tak' : 'Nie',
                        style: TextStyle(
                          color: _lastCacheUsed == true
                              ? AppTheme.successPrimary
                              : AppTheme.warningPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Dostępne funkcje
          _buildFunctionCard(
            '📦 Statystyki produktów',
            'Szczegółowe statystyki wszystkich produktów inwestycyjnych',
            Icons.bar_chart,
            AppTheme.successPrimary,
            () =>
                FirebaseFunctionsDialogsUpdated.showProductStatistics(context),
          ),

          _buildFunctionCard(
            '👥 Informacje o klientach',
            'Pobierz i wyświetl informacje o klientach systemu',
            Icons.people,
            AppTheme.infoPrimary,
            () => FirebaseFunctionsDialogsUpdated.showClientsInfo(context),
          ),

          _buildFunctionCard(
            '🔍 Wyszukaj inwestorów',
            'Znajdź inwestorów konkretnego produktu lub typu',
            Icons.search,
            AppTheme.warningPrimary,
            () => FirebaseFunctionsDialogsUpdated.showProductInvestorsSearch(
              context,
            ),
          ),

          _buildFunctionCard(
            '🧪 Test diagnostyczny',
            'Uruchom test diagnostyczny funkcji Firebase',
            Icons.bug_report,
            AppTheme.primaryAccent,
            () => FirebaseFunctionsDialogsUpdated.showDebugTest(context),
          ),

          _buildFunctionCard(
            '🗑️ Wyczyść cache',
            'Wymuś odświeżenie wszystkich danych cache',
            Icons.clear_all,
            AppTheme.errorPrimary,
            () => FirebaseFunctionsDialogsUpdated.clearCache(
              context,
              _loadEnhancedData,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[600],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Ładowanie enhanced analytics...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        FirebaseFunctionsDialogsUpdated.showMainActionMenu(context);
      },
      backgroundColor: AppTheme.secondaryGold,
      icon: const Icon(Icons.functions, color: Colors.black),
      label: const Text(
        'Functions',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }
}
