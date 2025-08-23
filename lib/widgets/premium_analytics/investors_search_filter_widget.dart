import 'package:flutter/material.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';

class InvestorsSearchFilterWidget extends StatefulWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final String? initialSearchQuery;
  final bool isFilterVisible;
  final Function() onToggleFilter;
  final VoidCallback onResetFilters;
  final bool isTablet;
  
  // Filter parameters
  final VotingStatus? selectedVotingStatus;
  final Function(VotingStatus?) onVotingStatusChanged;
  final String sortBy;
  final bool sortAscending;
  final Function(String) onSortChanged;
  final Function() onSortDirectionChanged;

  const InvestorsSearchFilterWidget({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    this.initialSearchQuery,
    required this.isFilterVisible,
    required this.onToggleFilter,
    required this.onResetFilters,
    required this.isTablet,
    this.selectedVotingStatus,
    required this.onVotingStatusChanged,
    required this.sortBy,
    required this.sortAscending,
    required this.onSortChanged,
    required this.onSortDirectionChanged,
  });

  @override
  State<InvestorsSearchFilterWidget> createState() => _InvestorsSearchFilterWidgetState();
}

class _InvestorsSearchFilterWidgetState extends State<InvestorsSearchFilterWidget>
    with TickerProviderStateMixin {
  late AnimationController _filterAnimationController;
  late Animation<Offset> _filterSlideAnimation;

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isFilterVisible) {
      _filterAnimationController.forward();
    }
  }

  @override
  void didUpdateWidget(InvestorsSearchFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFilterVisible != oldWidget.isFilterVisible) {
      if (widget.isFilterVisible) {
        _filterAnimationController.forward();
      } else {
        _filterAnimationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildSearchSection(),
          if (widget.isFilterVisible) _buildAnimatedFilterPanel(),
          _buildSortingBar(),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    final hasInitialSearch = widget.initialSearchQuery != null && 
                            widget.initialSearchQuery!.isNotEmpty;

    return Column(
      children: [
        // Info banner for initial search
        if (hasInitialSearch && widget.searchQuery == widget.initialSearchQuery) ...[
          Container(
            margin: EdgeInsets.all(widget.isTablet ? 16 : 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppThemePro.accentGold.withValues(alpha: 0.1),
                  AppThemePro.accentGoldMuted.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppThemePro.accentGold.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppThemePro.accentGold.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppThemePro.accentGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: AppThemePro.accentGold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aktywne wyszukiwanie',
                        style: TextStyle(
                          color: AppThemePro.accentGold,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Wyszukano: "${widget.initialSearchQuery}"',
                        style: TextStyle(
                          color: AppThemePro.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      widget.searchController.clear();
                      widget.onSearchChanged('');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppThemePro.accentGold,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Enhanced search bar
        Container(
          margin: EdgeInsets.all(widget.isTablet ? 16 : 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppThemePro.surfaceInteractive,
                AppThemePro.backgroundTertiary,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppThemePro.borderSecondary,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: widget.searchController,
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Wyszukaj inwestorów po nazwie...',
              hintStyle: TextStyle(
                color: AppThemePro.textMuted,
                fontSize: 16,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppThemePro.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: AppThemePro.accentGold,
                  size: 20,
                ),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.searchQuery.isNotEmpty)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          widget.searchController.clear();
                          widget.onSearchChanged('');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.clear_rounded,
                            color: AppThemePro.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: widget.onToggleFilter,
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.isFilterVisible
                              ? AppThemePro.accentGold.withValues(alpha: 0.2)
                              : AppThemePro.backgroundTertiary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.isFilterVisible
                                ? AppThemePro.accentGold.withValues(alpha: 0.3)
                                : AppThemePro.borderSecondary,
                          ),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: widget.isFilterVisible
                              ? AppThemePro.accentGold
                              : AppThemePro.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppThemePro.accentGold,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              filled: false,
            ),
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedFilterPanel() {
    return SlideTransition(
      position: _filterSlideAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: widget.isTablet ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppThemePro.surfaceCard,
              AppThemePro.backgroundSecondary,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppThemePro.accentGold.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppThemePro.accentGold,
                      AppThemePro.accentGoldMuted,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.filter_list_rounded,
                  color: AppThemePro.primaryDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Zaawansowane filtry',
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildVotingStatusFilter(),
                  const SizedBox(height: 20),
                  _buildFilterActions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status głosowania',
          style: TextStyle(
            color: AppThemePro.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildVotingStatusChip(null, 'Wszystkie', Icons.all_inclusive_rounded),
            _buildVotingStatusChip(VotingStatus.yes, 'TAK', Icons.check_circle_rounded),
            _buildVotingStatusChip(VotingStatus.no, 'NIE', Icons.cancel_rounded),
            _buildVotingStatusChip(VotingStatus.abstain, 'WSTRZYMUJE', Icons.remove_circle_rounded),
            _buildVotingStatusChip(VotingStatus.undecided, 'NIEZDECYDOWANI', Icons.help_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildVotingStatusChip(VotingStatus? status, String label, IconData icon) {
    final isSelected = widget.selectedVotingStatus == status;
    final color = status != null 
        ? _getVotingStatusColor(status) 
        : AppThemePro.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => widget.onVotingStatusChanged(status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            color: isSelected ? null : AppThemePro.backgroundTertiary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.5)
                  : AppThemePro.borderSecondary,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? color : AppThemePro.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : AppThemePro.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: widget.onResetFilters,
          icon: Icon(Icons.refresh_rounded),
          label: Text('Wyczyść filtry'),
          style: TextButton.styleFrom(
            foregroundColor: AppThemePro.statusError,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        ElevatedButton.icon(
          onPressed: widget.onToggleFilter,
          icon: Icon(Icons.check_rounded),
          label: Text('Zastosuj'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppThemePro.accentGold,
            foregroundColor: AppThemePro.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildSortingBar() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 16 : 12,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.surfaceCard,
            AppThemePro.backgroundTertiary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.borderSecondary,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppThemePro.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sort_rounded,
                  color: AppThemePro.accentGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Sortowanie',
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: widget.onSortDirectionChanged,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppThemePro.backgroundTertiary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppThemePro.accentGold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.sortAscending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: AppThemePro.accentGold,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.sortAscending ? 'Rosnąco' : 'Malejąco',
                          style: TextStyle(
                            color: AppThemePro.accentGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSortChip('name', 'Nazwa', Icons.abc_rounded),
              _buildSortChip('viableRemainingCapital', 'Kapitał pozostały', Icons.trending_up_rounded),
              _buildSortChip('investmentCount', 'Liczba inwestycji', Icons.account_balance_wallet_rounded),
              _buildSortChip('votingStatus', 'Status głosowania', Icons.how_to_vote_rounded),
              _buildSortChip('capitalSecuredByRealEstate', 'Zabezp. nieruchomościami', Icons.home_work_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String sortKey, String label, IconData icon) {
    final isSelected = widget.sortBy == sortKey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => widget.onSortChanged(sortKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppThemePro.accentGold,
                      AppThemePro.accentGoldMuted,
                    ],
                  )
                : null,
            color: isSelected ? null : AppThemePro.backgroundTertiary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppThemePro.accentGold
                  : AppThemePro.borderSecondary,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppThemePro.accentGold.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppThemePro.primaryDark
                    : AppThemePro.textSecondary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppThemePro.primaryDark
                      : AppThemePro.textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return AppThemePro.statusSuccess;
      case VotingStatus.no:
        return AppThemePro.statusError;
      case VotingStatus.abstain:
        return AppThemePro.statusWarning;
      case VotingStatus.undecided:
        return AppThemePro.textMuted;
    }
  }
}