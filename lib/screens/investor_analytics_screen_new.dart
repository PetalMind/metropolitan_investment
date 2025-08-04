import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models_and_services.dart';
import '../services/investor_analytics/investor_analytics.dart';
import '../widgets/investor_analytics/investor_analytics.dart';

/// Uproszczony ekran analityki inwestorów wykorzystujący refaktoryzowane komponenty
class InvestorAnalyticsScreen extends StatefulWidget {
  const InvestorAnalyticsScreen({super.key});

  @override
  State<InvestorAnalyticsScreen> createState() =>
      _InvestorAnalyticsScreenState();
}

class _InvestorAnalyticsScreenState extends State<InvestorAnalyticsScreen>
    with TickerProviderStateMixin {
  // Kontrolery animacji
  late AnimationController _filterAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<Offset> _filterSlideAnimation;
  late Animation<double> _fabScaleAnimation;

  // Kontrolery filtrów
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  final TextEditingController _companyFilterController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Stan filtrów
  bool _isFilterVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupControllers();
    _loadInitialData();
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

    _filterSlideAnimation =
        Tween<Offset>(
          begin: const Offset(0.0, -1.0),
          end: const Offset(0.0, 0.0),
        ).animate(
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

    // Animacja wejścia FAB
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fabAnimationController.forward();
    });
  }

  void _setupControllers() {
    // Nasłuchuj zmian w kontrolerach i aktualizuj stan
    _searchController.addListener(() {
      context.read<InvestorAnalyticsStateService>().updateSearchQuery(
        _searchController.text,
      );
    });

    _minAmountController.addListener(() {
      final minAmount = double.tryParse(_minAmountController.text);
      final maxAmount = double.tryParse(_maxAmountController.text);
      context.read<InvestorAnalyticsStateService>().updateAmountFilters(
        minAmount,
        maxAmount,
      );
    });

    _maxAmountController.addListener(() {
      final minAmount = double.tryParse(_minAmountController.text);
      final maxAmount = double.tryParse(_maxAmountController.text);
      context.read<InvestorAnalyticsStateService>().updateAmountFilters(
        minAmount,
        maxAmount,
      );
    });

    _companyFilterController.addListener(() {
      context.read<InvestorAnalyticsStateService>().updateCompanyFilter(
        _companyFilterController.text,
      );
    });
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvestorAnalyticsStateService>().loadInvestorData();
    });
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    _fabAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _companyFilterController.dispose();
    super.dispose();
  }

  void _toggleFilter() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
    });

    if (_isFilterVisible) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  void _resetFilters() {
    _searchController.clear();
    _minAmountController.clear();
    _maxAmountController.clear();
    _companyFilterController.clear();

    context.read<InvestorAnalyticsStateService>().resetFilters();
    _toggleFilter();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtry zostały zresetowane'),
        duration: Duration(seconds: 2),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
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
          context.read<InvestorAnalyticsStateService>().loadInvestorData();
        },
      ),
    );
  }

  void _generateEmailList() {
    final stateService = context.read<InvestorAnalyticsStateService>();
    final selectedIds = stateService.filteredInvestors
        .where((inv) => inv.client.email.isNotEmpty)
        .map((inv) => inv.client.id)
        .toList();

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brak inwestorów z adresami email w aktualnej liście'),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EmailGeneratorDialog(
        analyticsService: InvestorAnalyticsService(),
        clientIds: selectedIds,
      ),
    );
  }

  void _showViewOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildViewOptionsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Consumer<InvestorAnalyticsStateService>(
        builder: (context, stateService, child) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildResponsiveAppBar(context, isTablet, stateService),

              if (stateService.isLoading &&
                  stateService.filteredInvestors.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppTheme.secondaryGold,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Ładowanie danych inwestorów...',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else if (stateService.error != null)
                SliverFillRemaining(child: _buildErrorView(stateService))
              else ...[
                // Sekcja podsumowania
                SliverToBoxAdapter(
                  child: InvestorSummarySection(
                    allInvestors: stateService.allInvestors,
                    filteredInvestors: stateService.filteredInvestors,
                    totalPortfolioValue: stateService.totalPortfolioValue,
                    majorityControlAnalysis:
                        stateService.majorityControlAnalysis,
                    isTablet: isTablet,
                  ),
                ),

                // Panel filtrów (opcjonalnie widoczny)
                if (_isFilterVisible)
                  SliverToBoxAdapter(
                    child: SlideTransition(
                      position: _filterSlideAnimation,
                      child: InvestorFilterPanel(
                        searchController: _searchController,
                        minAmountController: _minAmountController,
                        maxAmountController: _maxAmountController,
                        companyFilterController: _companyFilterController,
                        selectedVotingStatus: stateService.selectedVotingStatus,
                        selectedClientType: stateService.selectedClientType,
                        includeInactive: stateService.includeInactive,
                        showOnlyWithUnviableInvestments:
                            stateService.showOnlyWithUnviableInvestments,
                        sortBy: stateService.sortBy,
                        sortAscending: stateService.sortAscending,
                        isTablet: isTablet,
                        onVotingStatusChanged: (status) {
                          stateService.updateVotingStatus(status);
                        },
                        onClientTypeChanged: (type) {
                          stateService.updateClientType(type);
                        },
                        onIncludeInactiveChanged: (include) {
                          stateService.toggleIncludeInactive();
                        },
                        onShowUnviableChanged: (show) {
                          stateService.toggleShowOnlyUnviable();
                        },
                        onSortChanged: (sortBy) {
                          stateService.changeSortOrder(sortBy);
                        },
                        onResetFilters: _resetFilters,
                      ),
                    ),
                  ),

                // Lista inwestorów
                _buildInvestorsList(stateService, isTablet),

                // Kontrolki paginacji
                if (stateService.filteredInvestors.length >
                    stateService.pageSize)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: PaginationControls(
                        currentPage: stateService.currentPage,
                        totalPages: stateService.totalPages,
                        hasPreviousPage: stateService.hasPreviousPage,
                        hasNextPage: stateService.hasNextPage,
                        pageSize: stateService.pageSize,
                        totalItems: stateService.filteredInvestors.length,
                        onPageChanged: (page) {
                          stateService.changePage(page);
                        },
                        onPageSizeChanged: (size) {
                          stateService.changePageSize(size);
                        },
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: _buildResponsiveFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildResponsiveAppBar(
    BuildContext context,
    bool isTablet,
    InvestorAnalyticsStateService stateService,
  ) {
    return SliverAppBar(
      expandedHeight: isTablet ? 200 : 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.backgroundSecondary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Analityka Inwestorów',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.backgroundSecondary, AppTheme.surfaceCard],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isTablet) ...[
                    Text(
                      'Zarządzanie portfelem inwestycyjnym',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _buildQuickStats(stateService),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFilterVisible ? Icons.filter_list_off : Icons.filter_list,
            color: AppTheme.secondaryGold,
          ),
          onPressed: _toggleFilter,
          tooltip: _isFilterVisible ? 'Ukryj filtry' : 'Pokaż filtry',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.secondaryGold),
          color: AppTheme.surfaceCard,
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                stateService.loadInvestorData();
                break;
              case 'export':
                _generateEmailList();
                break;
              case 'reset':
                _resetFilters();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'refresh',
              child: ListTile(
                leading: Icon(Icons.refresh, color: AppTheme.secondaryGold),
                title: Text(
                  'Odśwież dane',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.email, color: AppTheme.secondaryGold),
                title: Text(
                  'Generuj maile',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'reset',
              child: ListTile(
                leading: Icon(Icons.clear_all, color: AppTheme.secondaryGold),
                title: Text(
                  'Resetuj filtry',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(InvestorAnalyticsStateService stateService) {
    if (stateService.isLoading) {
      return const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.secondaryGold,
            ),
          ),
          SizedBox(width: 8),
          Text('Ładowanie...', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildQuickStatItem(
            '${stateService.filteredInvestors.length}',
            'Inwestorów',
            Icons.people,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildQuickStatItem(
            '${stateService.pageSize}',
            'Na stronie',
            Icons.view_list,
          ),
        ),
        if (stateService.majorityControlAnalysis?.hasControlGroup ?? false) ...[
          const SizedBox(width: 16),
          Expanded(
            child: _buildQuickStatItem(
              '${stateService.majorityControlAnalysis!.controlGroupCount}',
              'Do 51%',
              Icons.pie_chart,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickStatItem(String value, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.secondaryGold),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildErrorView(InvestorAnalyticsStateService stateService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Wystąpił błąd',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              stateService.error ?? 'Nieznany błąd',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                stateService.loadInvestorData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryGold,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestorsList(
    InvestorAnalyticsStateService stateService,
    bool isTablet,
  ) {
    if (stateService.filteredInvestors.isEmpty && !stateService.isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppTheme.textSecondary.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Brak inwestorów spełniających kryteria',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Spróbuj zmienić filtry wyszukiwania',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final currentPageData = stateService.currentPageData;
    final startIndex = stateService.currentPage * stateService.pageSize;

    switch (stateService.currentView) {
      case 'grid':
        return _buildInvestorsGrid(currentPageData, startIndex, stateService);
      case 'cards':
        return _buildInvestorsCards(currentPageData, startIndex, stateService);
      default:
        return _buildInvestorsList_Classic(
          currentPageData,
          startIndex,
          stateService,
        );
    }
  }

  Widget _buildInvestorsList_Classic(
    List<InvestorSummary> currentPageData,
    int startIndex,
    InvestorAnalyticsStateService stateService,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index < currentPageData.length) {
          final investor = currentPageData[index];
          final globalPosition = startIndex + index + 1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InvestorCard(
              investor: investor,
              position: globalPosition,
              totalPortfolioValue: stateService.totalPortfolioValue,
              onTap: () => _showInvestorDetails(investor),
            ),
          );
        }
        return null;
      }, childCount: currentPageData.length),
    );
  }

  Widget _buildInvestorsGrid(
    List<InvestorSummary> currentPageData,
    int startIndex,
    InvestorAnalyticsStateService stateService,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index < currentPageData.length) {
            final investor = currentPageData[index];
            final globalPosition = startIndex + index + 1;
            return InvestorGridTile(
              investor: investor,
              position: globalPosition,
              totalPortfolioValue: stateService.totalPortfolioValue,
              onTap: () => _showInvestorDetails(investor),
            );
          }
          return null;
        }, childCount: currentPageData.length),
      ),
    );
  }

  Widget _buildInvestorsCards(
    List<InvestorSummary> currentPageData,
    int startIndex,
    InvestorAnalyticsStateService stateService,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index < currentPageData.length) {
          final investor = currentPageData[index];
          final globalPosition = startIndex + index + 1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InvestorCompactCard(
              investor: investor,
              position: globalPosition,
              totalPortfolioValue: stateService.totalPortfolioValue,
              onTap: () => _showInvestorDetails(investor),
            ),
          );
        }
        return null;
      }, childCount: currentPageData.length),
    );
  }

  Widget _buildResponsiveFAB() {
    return Consumer<InvestorAnalyticsStateService>(
      builder: (context, stateService, child) {
        return ScaleTransition(
          scale: _fabScaleAnimation,
          child: FloatingActionButton.extended(
            onPressed: _showViewOptions,
            backgroundColor: AppTheme.secondaryGold,
            foregroundColor: Colors.white,
            icon: Icon(_getViewIcon(stateService.currentView)),
            label: Text(_getViewLabel(stateService.currentView)),
            tooltip: 'Zmień widok',
          ),
        );
      },
    );
  }

  Widget _buildViewOptionsBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Opcje widoku',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildViewOption('Lista', 'list', Icons.view_list),
                  _buildViewOption('Karty', 'cards', Icons.view_agenda),
                  _buildViewOption('Kafelki', 'grid', Icons.grid_view),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewOption(String title, String viewType, IconData icon) {
    return Consumer<InvestorAnalyticsStateService>(
      builder: (context, stateService, child) {
        final isSelected = stateService.currentView == viewType;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              icon,
              color: isSelected
                  ? AppTheme.secondaryGold
                  : AppTheme.textSecondary,
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppTheme.secondaryGold
                    : AppTheme.textPrimary,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check, color: AppTheme.secondaryGold)
                : null,
            onTap: () {
              stateService.changeView(viewType);
              Navigator.pop(context);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: isSelected
                ? AppTheme.secondaryGold.withOpacity(0.1)
                : Colors.transparent,
          ),
        );
      },
    );
  }

  IconData _getViewIcon(String currentView) {
    switch (currentView) {
      case 'cards':
        return Icons.view_agenda;
      case 'grid':
        return Icons.grid_view;
      default:
        return Icons.view_list;
    }
  }

  String _getViewLabel(String currentView) {
    switch (currentView) {
      case 'cards':
        return 'Karty';
      case 'grid':
        return 'Kafelki';
      default:
        return 'Lista';
    }
  }
}
