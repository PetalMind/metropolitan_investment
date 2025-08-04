import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models_and_services.dart';
import '../services/investor_analytics/investor_analytics.dart';
import '../widgets/investor_analytics/investor_analytics.dart';
import '../providers/investor_analytics_provider.dart';

/// ✨ ENHANCED INVESTOR ANALYTICS SCREEN (MODULAR)
/// Ulepszony ekran analityki inwestorów podzielony na komponenty zgodnie z architekturą projektu.
/// Maksymalnie 300 linii kodu - logika przeniesiona do serwisów, UI do komponentów.
///
/// Features:
/// • 🗳️ Analiza głosowania w czasie rzeczywistym
/// • 📊 Zaawansowane statystyki i trendy
/// • 🎯 Analiza większościowej kontroli kapitału
/// • ⚡ Optymalizowane ładowanie z cache
/// • 📈 Inteligentne filtry i sortowanie
/// • 💎 Professional UI/UX z mikro-animacjami
/// • 🚀 Performance-first architecture
/// • 📱 Responsive design dla wszystkich urządzeń
class EnhancedInvestorAnalyticsScreen extends StatefulWidget {
  const EnhancedInvestorAnalyticsScreen({super.key});

  @override
  State<EnhancedInvestorAnalyticsScreen> createState() =>
      _EnhancedInvestorAnalyticsScreenState();
}

class _EnhancedInvestorAnalyticsScreenState
    extends State<EnhancedInvestorAnalyticsScreen>
    with TickerProviderStateMixin {
  // 🚀 CORE SERVICE
  late EnhancedInvestorAnalyticsService _service;

  // 🎨 ANIMATION CONTROLLERS
  late AnimationController _filterAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _statsAnimationController;
  late Animation<Offset> _filterSlideAnimation;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _statsOpacityAnimation;

  // 🎛️ UI CONTROLLERS
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  final TextEditingController _companyFilterController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 📱 RESPONSIVE
  bool get _isTablet => MediaQuery.of(context).size.width > 768;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeService();
    _setupControllers();
  }

  void _initializeAnimations() {
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _filterSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _filterAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _statsOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _statsAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _fabAnimationController.forward();
    _statsAnimationController.forward();
  }

  void _initializeService() {
    _service = EnhancedInvestorAnalyticsService();
    _service.addListener(_onServiceStateChanged);
    _service.initialize();
  }

  void _setupControllers() {
    _searchController.addListener(_onSearchChanged);
    _minAmountController.addListener(_onFilterChanged);
    _maxAmountController.addListener(_onFilterChanged);
    _companyFilterController.addListener(_onFilterChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onServiceStateChanged() {
    if (!mounted) return;
    setState(() {}); // Trigger rebuild when service state changes
  }

  void _onSearchChanged() {
    _service.updateSearchQuery(_searchController.text);
  }

  void _onFilterChanged() {
    final min = double.tryParse(_minAmountController.text);
    final max = double.tryParse(_maxAmountController.text);
    _service.updateAmountFilters(min, max);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _service.loadMoreData();
    }
  }

  void _toggleFilters() {
    _service.toggleFilterVisibility();

    if (_service.isFilterVisible) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceStateChanged);
    _service.dispose();
    _filterAnimationController.dispose();
    _fabAnimationController.dispose();
    _statsAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _companyFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InvestorAnalyticsProvider(
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        body: Consumer<InvestorAnalyticsStateService>(
          builder: (context, stateService, child) {
            if (_service.isLoading && _service.allInvestors.isEmpty) {
              return EnhancedLoadingView(
                opacityAnimation: _statsOpacityAnimation,
              );
            }

            if (_service.error != null) {
              return EnhancedErrorView(
                error: _service.error,
                usePremiumMode: _service.usePremiumMode,
                onRefresh: _service.refreshData,
                onToggleMode: _service.togglePremiumMode,
              );
            }

            return _buildMainContent(stateService);
          },
        ),
        floatingActionButton: EnhancedFloatingActionButton(
          scaleAnimation: _fabScaleAnimation,
          isFilterVisible: _service.isFilterVisible,
          onToggleFilters: _toggleFilters,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildMainContent(InvestorAnalyticsStateService stateService) {
    return RefreshIndicator(
      onRefresh: _service.refreshData,
      color: AppTheme.secondaryGold,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildEnhancedAppBar(),
          _buildVotingAnalysisCard(),
          _buildMajorityControlCard(),
          if (_service.isFilterVisible) _buildFilterPanel(stateService),
          _buildInvestorsList(stateService),
          if (_service.hasNextPage) _buildLoadMoreButton(),
        ],
      ),
    );
  }

  Widget _buildEnhancedAppBar() {
    return EnhancedInvestorAppBar(
      expandedHeight: _isTablet ? 220 : 160,
      isTablet: _isTablet,
      usePremiumMode: _service.usePremiumMode,
      totalCount: _service.totalCount,
      totalCapital: _service.totalCapital,
      majorityHoldersCount: _service.majorityHolders.length,
      onTogglePremiumMode: _service.togglePremiumMode,
      onToggleFilters: _toggleFilters,
      onRefresh: _service.refreshData,
      statsOpacityAnimation: _statsOpacityAnimation,
    );
  }

  Widget _buildVotingAnalysisCard() {
    return SliverToBoxAdapter(
      child: VotingAnalysisCard(
        votingDistribution: _service.votingDistribution,
        votingCounts: _service.votingCounts,
      ),
    );
  }

  Widget _buildMajorityControlCard() {
    return SliverToBoxAdapter(
      child: MajorityControlCard(
        majorityHolders: _service.majorityHolders,
        totalCapital: _service.totalCapital,
      ),
    );
  }

  Widget _buildFilterPanel(InvestorAnalyticsStateService stateService) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _filterSlideAnimation,
        child: InvestorFilterPanel(
          searchController: _searchController,
          minAmountController: _minAmountController,
          maxAmountController: _maxAmountController,
          companyFilterController: _companyFilterController,
          selectedVotingStatus: _service.selectedVotingStatus,
          selectedClientType: _service.selectedClientType,
          includeInactive: _service.includeInactive,
          showOnlyWithUnviableInvestments:
              _service.showOnlyWithUnviableInvestments,
          sortBy: _service.sortBy,
          sortAscending: _service.sortAscending,
          isTablet: _isTablet,
          onVotingStatusChanged: _service.updateVotingStatus,
          onClientTypeChanged: _service.updateClientType,
          onIncludeInactiveChanged: (_) => _service.toggleIncludeInactive(),
          onShowUnviableChanged: (_) => _service.toggleShowOnlyUnviable(),
          onSortChanged: _service.changeSortOrder,
          onResetFilters: _service.resetFilters,
        ),
      ),
    );
  }

  Widget _buildInvestorsList(InvestorAnalyticsStateService stateService) {
    final displayedInvestors = _service.displayedInvestors;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index < displayedInvestors.length) {
          final investor = displayedInvestors[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InvestorCard(
              investor: investor,
              position: index + 1,
              totalPortfolioValue: _service.totalCapital,
              onTap: () => _showInvestorDetails(investor),
            ),
          );
        }
        return null;
      }, childCount: displayedInvestors.length),
    );
  }

  Widget _buildLoadMoreButton() {
    return SliverToBoxAdapter(
      child: LoadMoreButton(
        isLoading: _service.isLoading,
        onLoadMore: _service.loadMoreData,
      ),
    );
  }

  void _showInvestorDetails(InvestorSummary investor) {
    showDialog(
      context: context,
      builder: (context) => InvestorDetailsDialog(
        investor: investor,
        analyticsService: InvestorAnalyticsService(),
        onUpdate: () {
          _service.refreshData();
        },
      ),
    );
  }
}
