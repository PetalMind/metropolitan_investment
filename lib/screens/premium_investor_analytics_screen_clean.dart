// 🏆 PREMIUM INVESTOR ANALYTICS - REFACTORED WITH WIDGETS
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../config/app_theme.dart';
import '../models_and_services.dart';
import '../widgets/investor_analytics/investor_views_container.dart';

/// Premium analytics screen focused on individual investor performance
/// Displays comprehensive financial metrics for active investors
class PremiumInvestorAnalyticsScreen extends ConsumerStatefulWidget {
  const PremiumInvestorAnalyticsScreen({super.key});

  @override
  ConsumerState<PremiumInvestorAnalyticsScreen> createState() =>
      _PremiumInvestorAnalyticsScreenState();
}

class _PremiumInvestorAnalyticsScreenState
    extends ConsumerState<PremiumInvestorAnalyticsScreen> {
  // 📊 STATE VARIABLES
  List<InvestorSummary> _investors = [];
  List<InvestorSummary> _displayedInvestors = [];
  List<InvestorSummary> _majorityHolders = [];

  String _searchQuery = '';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  VotingStatusFilter _statusFilter = VotingStatusFilter.all;
  ClientTypeFilter _typeFilter = ClientTypeFilter.all;
  bool _showMajorityOnly = false;

  late VotingManager _votingManager;
  late bool _isTablet;

  @override
  void initState() {
    super.initState();
    _votingManager = VotingManager();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInvestorData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
  }

  // 🔄 DATA LOADING
  Future<void> _loadInvestorData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final analyticsService = FirebaseFunctionsAnalyticsService();
      final response = await analyticsService.getOptimizedInvestorAnalytics();

      if (!mounted) return;

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> investorsData = response['data']['investors'] ?? [];

        final investors = investorsData
            .map((data) => InvestorSummary.fromMap(data))
            .where((investor) => investor.viableRemainingCapital > 0)
            .toList();

        // Sort by remaining capital descending
        investors.sort(
          (a, b) =>
              b.viableRemainingCapital.compareTo(a.viableRemainingCapital),
        );

        await _votingManager.initialize(investors);

        setState(() {
          _investors = investors;
          _majorityHolders = _votingManager.getMajorityHolders();
          _isLoading = false;
          _applyFilters();
        });
      } else {
        throw Exception(response['message'] ?? 'Błąd pobierania danych');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Błąd ładowania danych: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    var filtered = List<InvestorSummary>.from(_investors);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((investor) {
        return investor.client.name.toLowerCase().contains(query) ||
            investor.client.companyName?.toLowerCase().contains(query) == true;
      }).toList();
    }

    // Status filter
    if (_statusFilter != VotingStatusFilter.all) {
      filtered = filtered
          .where(
            (investor) =>
                investor.client.votingStatus == _statusFilter.toVotingStatus(),
          )
          .toList();
    }

    // Type filter
    if (_typeFilter != ClientTypeFilter.all) {
      filtered = filtered
          .where(
            (investor) => investor.client.type == _typeFilter.toClientType(),
          )
          .toList();
    }

    // Majority holders filter
    if (_showMajorityOnly) {
      filtered = filtered
          .where((investor) => _majorityHolders.contains(investor))
          .toList();
    }

    setState(() {
      _displayedInvestors = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading) _buildLoadingSliver(),
          if (_hasError) _buildErrorSliver(),
          if (!_isLoading && !_hasError) ...[
            _buildSystemStatsSliver(),
            _buildFiltersSliver(),
            _buildContentSliver(),
          ],
        ],
      ),
    );
  }

  // 🎨 UI COMPONENTS
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.backgroundPrimary,
      foregroundColor: AppTheme.textPrimary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Analiza Inwestorów Premium',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        titlePadding: EdgeInsets.only(left: _isTablet ? 72 : 56, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundPrimary,
                AppTheme.backgroundSecondary,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: _isTablet ? 72 : 56,
                right: 16,
                top: 60,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    color: AppTheme.secondaryGold,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Kompleksowa analiza portfeli inwestorów premium',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSliver() {
    return const SliverFillRemaining(
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorSliver() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorPrimary),
            const SizedBox(height: 16),
            Text(
              'Błąd ładowania danych',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                style: TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInvestorData,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatsSliver() {
    if (_investors.isEmpty) return const SliverToBoxAdapter();

    final totalCapital = _investors.fold<double>(
      0,
      (sum, inv) => sum + inv.viableRemainingCapital,
    );

    final totalInvestmentAmount = _investors.fold<double>(
      0,
      (sum, inv) => sum + inv.totalInvestmentAmount,
    );

    final totalForRestructuring = _investors.fold<double>(
      0,
      (sum, inv) => sum + inv.capitalForRestructuring,
    );

    final totalSecuredByRealEstate = _investors.fold<double>(
      0,
      (sum, inv) => sum + inv.capitalSecuredByRealEstate,
    );

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(_isTablet ? 16 : 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderPrimary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard_rounded,
                  color: AppTheme.secondaryGold,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Podsumowanie systemu',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: _isTablet ? 4 : 2,
              childAspectRatio: _isTablet ? 2.0 : 1.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  'Kapitał pozostały',
                  CurrencyFormatter.formatCurrency(totalCapital),
                  Icons.account_balance_wallet_rounded,
                  AppTheme.secondaryGold,
                ),
                _buildStatCard(
                  'Kwota inwestycji',
                  CurrencyFormatter.formatCurrency(totalInvestmentAmount),
                  Icons.trending_up_rounded,
                  AppTheme.infoPrimary,
                ),
                _buildStatCard(
                  'Do restrukturyzacji',
                  CurrencyFormatter.formatCurrency(totalForRestructuring),
                  Icons.build_rounded,
                  AppTheme.warningPrimary,
                ),
                _buildStatCard(
                  'Zabezpieczony',
                  CurrencyFormatter.formatCurrency(totalSecuredByRealEstate),
                  Icons.home_rounded,
                  AppTheme.successPrimary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSliver() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: _isTablet ? 16 : 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSecondary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
              decoration: InputDecoration(
                hintText: 'Wyszukaj inwestora...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.borderSecondary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.secondaryGold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Filter chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: Text('Tylko większościowi'),
                  selected: _showMajorityOnly,
                  onSelected: (selected) {
                    setState(() {
                      _showMajorityOnly = selected;
                      _applyFilters();
                    });
                  },
                  selectedColor: AppTheme.secondaryGold.withOpacity(0.2),
                ),
                // Status filter dropdown
                DropdownButton<VotingStatusFilter>(
                  value: _statusFilter,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _statusFilter = value;
                        _applyFilters();
                      });
                    }
                  },
                  items: VotingStatusFilter.values.map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: Text(filter.displayName),
                    );
                  }).toList(),
                ),
                // Type filter dropdown
                DropdownButton<ClientTypeFilter>(
                  value: _typeFilter,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _typeFilter = value;
                        _applyFilters();
                      });
                    }
                  },
                  items: ClientTypeFilter.values.map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: Text(filter.displayName),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Znaleziono: ${_displayedInvestors.length} z ${_investors.length} inwestorów',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSliver() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(_isTablet ? 16 : 12),
        child: InvestorViewsContainer(
          investors: _displayedInvestors,
          majorityHolders: _majorityHolders,
          votingManager: _votingManager,
          onInvestorSelected: _showInvestorDetails,
        ),
      ),
    );
  }

  // 🎯 ACTION HANDLERS
  void _showInvestorDetails(InvestorSummary investor) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      investor.client.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Szczegóły inwestora',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              // Financial details grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildDetailCard(
                    'Kapitał pozostały',
                    CurrencyFormatter.formatCurrency(
                      investor.viableRemainingCapital,
                    ),
                    AppTheme.secondaryGold,
                  ),
                  _buildDetailCard(
                    'Kwota inwestycji',
                    CurrencyFormatter.formatCurrency(
                      investor.totalInvestmentAmount,
                    ),
                    AppTheme.infoPrimary,
                  ),
                  _buildDetailCard(
                    'Do restrukturyzacji',
                    CurrencyFormatter.formatCurrency(
                      investor.capitalForRestructuring,
                    ),
                    AppTheme.warningPrimary,
                  ),
                  _buildDetailCard(
                    'Zabezpieczony',
                    CurrencyFormatter.formatCurrency(
                      investor.capitalSecuredByRealEstate,
                    ),
                    AppTheme.successPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Zamknij'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// 🎯 FILTER ENUMS
enum VotingStatusFilter {
  all('Wszystkie'),
  active('Aktywni'),
  inactive('Nieaktywni'),
  blocked('Zablokowani');

  const VotingStatusFilter(this.displayName);
  final String displayName;

  VotingStatus toVotingStatus() {
    switch (this) {
      case VotingStatusFilter.active:
        return VotingStatus.active;
      case VotingStatusFilter.inactive:
        return VotingStatus.inactive;
      case VotingStatusFilter.blocked:
        return VotingStatus.blocked;
      case VotingStatusFilter.all:
        throw StateError('Cannot convert "all" to VotingStatus');
    }
  }
}

enum ClientTypeFilter {
  all('Wszystkie'),
  individual('Osoby fizyczne'),
  company('Firmy');

  const ClientTypeFilter(this.displayName);
  final String displayName;

  ClientType toClientType() {
    switch (this) {
      case ClientTypeFilter.individual:
        return ClientType.individual;
      case ClientTypeFilter.company:
        return ClientType.company;
      case ClientTypeFilter.all:
        throw StateError('Cannot convert "all" to ClientType');
    }
  }
}
