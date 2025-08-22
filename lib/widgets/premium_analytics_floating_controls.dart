import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/client.dart';
import '../models/investor_summary.dart';
import '../utils/currency_formatter.dart';
import 'premium_analytics_filter_panel.dart';

/// 🎛️ FLOATING FILTER CONTROLS
///
/// Szybkie kontrolki filtrów pływające nad wykresami
/// Zapewniają natychmiastowy dostęp do najważniejszych filtrów

class PremiumAnalyticsFloatingControls extends StatefulWidget {
  final List<InvestorSummary> allInvestors;
  final PremiumAnalyticsFilter currentFilter;
  final Function(PremiumAnalyticsFilter) onFiltersChanged;
  final VoidCallback? onShowFullPanel;

  const PremiumAnalyticsFloatingControls({
    super.key,
    required this.allInvestors,
    required this.currentFilter,
    required this.onFiltersChanged,
    this.onShowFullPanel,
  });

  @override
  State<PremiumAnalyticsFloatingControls> createState() =>
      _PremiumAnalyticsFloatingControlsState();
}

class _PremiumAnalyticsFloatingControlsState
    extends State<PremiumAnalyticsFloatingControls>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.backgroundPrimary.withOpacity(0.95),
                    AppTheme.backgroundSecondary.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const Divider(height: 1),
                  _buildQuickFilters(),
                  _buildActiveFiltersIndicator(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final filteredCount = widget.allInvestors
        .where(widget.currentFilter.matches)
        .length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.filter_alt_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Szybkie filtry',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '$filteredCount z ${widget.allInvestors.length} inwestorów',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onShowFullPanel,
            icon: Icon(Icons.tune_rounded, color: AppTheme.textSecondary),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.backgroundSecondary.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            tooltip: 'Pokaż wszystkie filtry',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Row 1: Voting Status Quick Filters
          Row(
            children: [
              Expanded(child: _buildVotingQuickFilter(VotingStatus.yes, 'ZA')),
              const SizedBox(width: 8),
              Expanded(
                child: _buildVotingQuickFilter(VotingStatus.no, 'PRZECIW'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildVotingQuickFilter(
                  VotingStatus.undecided,
                  'NIEZDEC.',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Special Filters
          Row(
            children: [
              Expanded(
                child: _buildSpecialFilter(
                  'Większość',
                  widget.currentFilter.showOnlyMajorityHolders,
                  () => _toggleMajorityFilter(),
                  Icons.stars_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSpecialFilter(
                  'Duzi (>1M)',
                  widget.currentFilter.showOnlyLargeInvestors,
                  () => _toggleLargeInvestorsFilter(),
                  Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSpecialFilter(
                  'Aktywni',
                  widget.currentFilter.includeActiveOnly,
                  () => _toggleActiveFilter(),
                  Icons.verified_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVotingQuickFilter(VotingStatus status, String label) {
    final isSelected = widget.currentFilter.votingStatusFilter == status;
    final color = _getVotingStatusColor(status);
    final count = widget.allInvestors
        .where((inv) => inv.client.votingStatus == status)
        .length;

    return GestureDetector(
      onTap: () => _selectVotingStatus(isSelected ? null : status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialFilter(
    String label,
    bool isSelected,
    VoidCallback onTap,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersIndicator() {
    if (!widget.currentFilter.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    final activeCount = _countActiveFilters();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_alt_rounded,
            size: 16,
            color: AppTheme.warningColor,
          ),
          const SizedBox(width: 8),
          Text(
            'Aktywne filtry: $activeCount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.warningColor,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _resetAllFilters,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Resetuj',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warningColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return const Color(0xFF00C851);
      case VotingStatus.no:
        return const Color(0xFFFF4444);
      case VotingStatus.abstain:
        return const Color(0xFFFF8800);
      case VotingStatus.undecided:
        return const Color(0xFF9E9E9E);
    }
  }

  int _countActiveFilters() {
    int count = 0;
    if (widget.currentFilter.searchQuery.isNotEmpty) count++;
    if (widget.currentFilter.votingStatusFilter != null) count++;
    if (widget.currentFilter.clientTypeFilter != null) count++;
    if (widget.currentFilter.minCapital > 0 ||
        widget.currentFilter.maxCapital < double.infinity) {
      count++;
    }
    if (widget.currentFilter.showOnlyMajorityHolders) count++;
    if (widget.currentFilter.showOnlyLargeInvestors) count++;
    if (widget.currentFilter.includeActiveOnly) count++;
    if (widget.currentFilter.showOnlyWithUnviableInvestments) count++;
    return count;
  }

  // Filter Actions
  void _selectVotingStatus(VotingStatus? status) {
    final newFilter = widget.currentFilter.copy();
    newFilter.votingStatusFilter = status;
    widget.onFiltersChanged(newFilter);
  }

  void _toggleMajorityFilter() {
    final newFilter = widget.currentFilter.copy();
    newFilter.showOnlyMajorityHolders = !newFilter.showOnlyMajorityHolders;
    widget.onFiltersChanged(newFilter);
  }

  void _toggleLargeInvestorsFilter() {
    final newFilter = widget.currentFilter.copy();
    newFilter.showOnlyLargeInvestors = !newFilter.showOnlyLargeInvestors;
    widget.onFiltersChanged(newFilter);
  }

  void _toggleActiveFilter() {
    final newFilter = widget.currentFilter.copy();
    newFilter.includeActiveOnly = !newFilter.includeActiveOnly;
    widget.onFiltersChanged(newFilter);
  }

  void _resetAllFilters() {
    widget.onFiltersChanged(PremiumAnalyticsFilter());
  }
}

/// 📊 FILTER STATISTICS WIDGET
///
/// Pokazuje statystyki dotyczące aktualnie zastosowanych filtrów

class PremiumAnalyticsFilterStats extends StatelessWidget {
  final List<InvestorSummary> originalInvestors;
  final List<InvestorSummary> filteredInvestors;
  final PremiumAnalyticsFilter currentFilter;

  const PremiumAnalyticsFilterStats({
    super.key,
    required this.originalInvestors,
    required this.filteredInvestors,
    required this.currentFilter,
  });

  @override
  Widget build(BuildContext context) {
    final originalCapital = originalInvestors.fold<double>(
      0.0,
      (sum, inv) => sum + inv.viableRemainingCapital,
    );
    final filteredCapital = filteredInvestors.fold<double>(
      0.0,
      (sum, inv) => sum + inv.viableRemainingCapital,
    );

    final countPercentage = originalInvestors.isNotEmpty
        ? (filteredInvestors.length / originalInvestors.length) * 100
        : 0.0;
    final capitalPercentage = originalCapital > 0
        ? (filteredCapital / originalCapital) * 100
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Column(
        children: [
          Text(
            'Statystyki filtrowania',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Inwestorzy',
                  '${filteredInvestors.length}',
                  '${countPercentage.toStringAsFixed(1)}%',
                  Icons.people_rounded,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Kapitał',
                  CurrencyFormatter.formatCurrencyShort(filteredCapital),
                  '${capitalPercentage.toStringAsFixed(1)}%',
                  Icons.account_balance_wallet_rounded,
                  AppTheme.secondaryGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    String percentage,
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
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            percentage,
            style: TextStyle(fontSize: 11, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }
}
