import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/client.dart';
import '../models/investor_summary.dart';
import '../utils/currency_formatter.dart';

/// 🎛️ PREMIUM PANEL FILTROWANIA ANALYTICS
///
/// Zaawansowany panel filtrowania z:
/// • Wielokryterialne filtry
/// • Real-time aktualizacja
/// • Zapisywanie ustawień
/// • Export filtrów
/// • Smart suggestions

class PremiumAnalyticsFilterPanel extends StatefulWidget {
  final List<InvestorSummary> allInvestors;
  final Function(PremiumAnalyticsFilter) onFiltersChanged;
  final PremiumAnalyticsFilter initialFilter;
  final bool isVisible;
  final VoidCallback? onClose;

  const PremiumAnalyticsFilterPanel({
    super.key,
    required this.allInvestors,
    required this.onFiltersChanged,
    required this.initialFilter,
    this.isVisible = true,
    this.onClose,
  });

  @override
  State<PremiumAnalyticsFilterPanel> createState() =>
      _PremiumAnalyticsFilterPanelState();
}

class _PremiumAnalyticsFilterPanelState
    extends State<PremiumAnalyticsFilterPanel>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  late PremiumAnalyticsFilter _currentFilter;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minCapitalController = TextEditingController();
  final TextEditingController _maxCapitalController = TextEditingController();

  // Quick filters state
  bool _showQuickFilters = true;
  bool _showAdvancedFilters = false;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter.copy();
    _setupAnimations();
    _setupControllers();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  void _setupControllers() {
    _searchController.text = _currentFilter.searchQuery;
    _minCapitalController.text = _currentFilter.minCapital > 0
        ? _currentFilter.minCapital.toStringAsFixed(0)
        : '';
    _maxCapitalController.text = _currentFilter.maxCapital < double.infinity
        ? _currentFilter.maxCapital.toStringAsFixed(0)
        : '';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _minCapitalController.dispose();
    _maxCapitalController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PremiumAnalyticsFilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _slideAnimation.value * MediaQuery.of(context).size.width,
            0,
          ),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: 380,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.backgroundPrimary,
                    AppTheme.backgroundSecondary.withOpacity(0.95),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 25,
                    offset: const Offset(5, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSearchSection(),
                          const SizedBox(height: 24),
                          _buildQuickFiltersSection(),
                          const SizedBox(height: 24),
                          _buildVotingStatusSection(),
                          const SizedBox(height: 24),
                          _buildClientTypeSection(),
                          const SizedBox(height: 24),
                          _buildCapitalRangeSection(),
                          const SizedBox(height: 24),
                          _buildAdvancedFiltersSection(),
                          const SizedBox(height: 24),
                          _buildActiveFiltersSection(),
                          const SizedBox(height: 32),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
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
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list_rounded,
            color: AppTheme.primaryColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtry Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${_getFilteredCount()} z ${widget.allInvestors.length} inwestorów',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(Icons.close_rounded, color: AppTheme.textSecondary),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.backgroundSecondary.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Wyszukiwanie', style: _getSectionHeaderStyle()),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Szukaj inwestorów...',
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppTheme.primaryColor,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _updateSearchFilter('');
                    },
                    icon: Icon(
                      Icons.clear_rounded,
                      color: AppTheme.textSecondary,
                    ),
                  )
                : null,
            filled: true,
            fillColor: AppTheme.backgroundSecondary.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
          onChanged: _updateSearchFilter,
        ),
      ],
    );
  }

  Widget _buildQuickFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Szybkie filtry', style: _getSectionHeaderStyle()),
            const Spacer(),
            IconButton(
              onPressed: () {
                setState(() {
                  _showQuickFilters = !_showQuickFilters;
                });
              },
              icon: Icon(
                _showQuickFilters ? Icons.expand_less : Icons.expand_more,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        if (_showQuickFilters) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickFilterChip(
                'Większość (>51%)',
                _currentFilter.showOnlyMajorityHolders,
                () => _toggleMajorityFilter(),
              ),
              _buildQuickFilterChip(
                'Duzi inwestorzy',
                _currentFilter.showOnlyLargeInvestors,
                () => _toggleLargeInvestorsFilter(),
              ),
              _buildQuickFilterChip(
                'Aktywni',
                _currentFilter.includeActiveOnly,
                () => _toggleActiveOnlyFilter(),
              ),
              _buildQuickFilterChip(
                'Z problemami',
                _currentFilter.showOnlyWithUnviableInvestments,
                () => _toggleUnviableFilter(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildVotingStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status głosowania', style: _getSectionHeaderStyle()),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildVotingStatusChip(null, 'Wszystkie', _getVotingCount(null)),
            ...VotingStatus.values.map(
              (status) => _buildVotingStatusChip(
                status,
                status.displayName,
                _getVotingCount(status),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClientTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Typ klienta', style: _getSectionHeaderStyle()),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildClientTypeChip(null, 'Wszyscy', _getClientTypeCount(null)),
            ...ClientType.values.map(
              (type) => _buildClientTypeChip(
                type,
                type.displayName,
                _getClientTypeCount(type),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCapitalRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Zakres kapitału', style: _getSectionHeaderStyle()),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minCapitalController,
                decoration: InputDecoration(
                  labelText: 'Min',
                  hintText: '0',
                  prefixText: 'PLN ',
                  filled: true,
                  fillColor: AppTheme.backgroundSecondary.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: _updateMinCapital,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxCapitalController,
                decoration: InputDecoration(
                  labelText: 'Max',
                  hintText: '∞',
                  prefixText: 'PLN ',
                  filled: true,
                  fillColor: AppTheme.backgroundSecondary.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: _updateMaxCapital,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCapitalRangePresets(),
      ],
    );
  }

  Widget _buildCapitalRangePresets() {
    final presets = [
      {'label': '< 100K', 'min': 0.0, 'max': 100000.0},
      {'label': '100K - 1M', 'min': 100000.0, 'max': 1000000.0},
      {'label': '1M - 10M', 'min': 1000000.0, 'max': 10000000.0},
      {'label': '> 10M', 'min': 10000000.0, 'max': double.infinity},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((preset) {
        final isSelected =
            _currentFilter.minCapital == preset['min'] &&
            _currentFilter.maxCapital == preset['max'];

        return FilterChip(
          label: Text(preset['label'] as String),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              _updateCapitalRange(
                preset['min'] as double,
                preset['max'] as double,
              );
            }
          },
          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
          checkmarkColor: AppTheme.primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildAdvancedFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Filtry zaawansowane', style: _getSectionHeaderStyle()),
            const Spacer(),
            IconButton(
              onPressed: () {
                setState(() {
                  _showAdvancedFilters = !_showAdvancedFilters;
                });
              },
              icon: Icon(
                _showAdvancedFilters ? Icons.expand_less : Icons.expand_more,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        if (_showAdvancedFilters) ...[
          const SizedBox(height: 12),
          _buildAdvancedFilterOptions(),
        ],
      ],
    );
  }

  Widget _buildAdvancedFilterOptions() {
    return Column(
      children: [
        // Investment count range
        _buildSliderFilter(
          'Liczba inwestycji',
          _currentFilter.minInvestmentCount.toDouble(),
          _currentFilter.maxInvestmentCount.toDouble(),
          0.0,
          20.0,
          (min, max) {
            setState(() {
              _currentFilter.minInvestmentCount = min.round();
              _currentFilter.maxInvestmentCount = max.round();
            });
            _applyFilters();
          },
        ),

        const SizedBox(height: 16),

        // Investment diversity
        CheckboxListTile(
          title: Text('Wysoka dywersyfikacja (≥3 produkty)'),
          value: _currentFilter.requireHighDiversification,
          onChanged: (value) {
            setState(() {
              _currentFilter.requireHighDiversification = value ?? false;
            });
            _applyFilters();
          },
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),

        // Recent activity
        CheckboxListTile(
          title: Text('Ostatnia aktywność (30 dni)'),
          value: _currentFilter.recentActivityOnly,
          onChanged: (value) {
            setState(() {
              _currentFilter.recentActivityOnly = value ?? false;
            });
            _applyFilters();
          },
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildActiveFiltersSection() {
    final activeFilters = _getActiveFilters();
    if (activeFilters.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aktywne filtry', style: _getSectionHeaderStyle()),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: activeFilters.map((filter) {
            return Chip(
              label: Text(filter['label']!),
              deleteIcon: Icon(Icons.close_rounded, size: 18),
              onDeleted: () => filter['onRemove']!(),
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              deleteIconColor: AppTheme.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Apply filters button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _applyFilters,
            icon: Icon(Icons.check_rounded),
            label: Text('Zastosuj filtry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Reset filters button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _resetFilters,
            icon: Icon(Icons.refresh_rounded),
            label: Text('Resetuj filtry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: BorderSide(color: AppTheme.borderPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Save/Load presets
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saveFilterPreset,
                icon: Icon(Icons.save_rounded, size: 18),
                label: Text('Zapisz'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.secondaryGold,
                  side: BorderSide(
                    color: AppTheme.secondaryGold.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loadFilterPreset,
                icon: Icon(Icons.folder_open_rounded, size: 18),
                label: Text('Wczytaj'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.warningColor,
                  side: BorderSide(
                    color: AppTheme.warningColor.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper Widgets
  Widget _buildQuickFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildVotingStatusChip(VotingStatus? status, String label, int count) {
    final isSelected = _currentFilter.votingStatusFilter == status;
    final color = status != null
        ? _getVotingStatusColor(status)
        : AppTheme.textSecondary;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _currentFilter.votingStatusFilter = selected ? status : null;
        });
        _applyFilters();
      },
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
    );
  }

  Widget _buildClientTypeChip(ClientType? type, String label, int count) {
    final isSelected = _currentFilter.clientTypeFilter == type;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _currentFilter.clientTypeFilter = selected ? type : null;
        });
        _applyFilters();
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildSliderFilter(
    String label,
    double currentMin,
    double currentMax,
    double min,
    double max,
    Function(double, double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${currentMin.round()} - ${currentMax == max ? '∞' : currentMax.round()}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        RangeSlider(
          values: RangeValues(currentMin, currentMax),
          min: min,
          max: max,
          divisions: (max - min).round(),
          labels: RangeLabels(
            currentMin.round().toString(),
            currentMax == max ? '∞' : currentMax.round().toString(),
          ),
          onChanged: (RangeValues values) {
            onChanged(values.start, values.end);
          },
          activeColor: AppTheme.primaryColor,
          inactiveColor: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ],
    );
  }

  // Helper Methods
  TextStyle _getSectionHeaderStyle() {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ) ??
        const TextStyle();
  }

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

  int _getFilteredCount() {
    return widget.allInvestors.where(_currentFilter.matches).length;
  }

  int _getVotingCount(VotingStatus? status) {
    return widget.allInvestors
        .where((inv) => status == null || inv.client.votingStatus == status)
        .length;
  }

  int _getClientTypeCount(ClientType? type) {
    return widget.allInvestors
        .where((inv) => type == null || inv.client.type == type)
        .length;
  }

  List<Map<String, dynamic>> _getActiveFilters() {
    final List<Map<String, dynamic>> filters = [];

    if (_currentFilter.searchQuery.isNotEmpty) {
      filters.add({
        'label': 'Szukaj: "${_currentFilter.searchQuery}"',
        'onRemove': () => _updateSearchFilter(''),
      });
    }

    if (_currentFilter.votingStatusFilter != null) {
      filters.add({
        'label': 'Status: ${_currentFilter.votingStatusFilter!.displayName}',
        'onRemove': () {
          setState(() {
            _currentFilter.votingStatusFilter = null;
          });
          _applyFilters();
        },
      });
    }

    if (_currentFilter.clientTypeFilter != null) {
      filters.add({
        'label': 'Typ: ${_currentFilter.clientTypeFilter!.displayName}',
        'onRemove': () {
          setState(() {
            _currentFilter.clientTypeFilter = null;
          });
          _applyFilters();
        },
      });
    }

    if (_currentFilter.minCapital > 0 ||
        _currentFilter.maxCapital < double.infinity) {
      final minStr = _currentFilter.minCapital > 0
          ? CurrencyFormatter.formatCurrencyShort(_currentFilter.minCapital)
          : '0';
      final maxStr = _currentFilter.maxCapital < double.infinity
          ? CurrencyFormatter.formatCurrencyShort(_currentFilter.maxCapital)
          : '∞';

      filters.add({
        'label': 'Kapitał: $minStr - $maxStr',
        'onRemove': () => _updateCapitalRange(0.0, double.infinity),
      });
    }

    return filters;
  }

  // Filter Update Methods
  void _updateSearchFilter(String query) {
    setState(() {
      _currentFilter.searchQuery = query;
      _searchController.text = query;
    });
    _applyFilters();
  }

  void _updateMinCapital(String value) {
    final double? amount = double.tryParse(
      value.replaceAll(',', '').replaceAll(' ', ''),
    );
    setState(() {
      _currentFilter.minCapital = amount ?? 0.0;
    });
    _applyFilters();
  }

  void _updateMaxCapital(String value) {
    final double? amount = double.tryParse(
      value.replaceAll(',', '').replaceAll(' ', ''),
    );
    setState(() {
      _currentFilter.maxCapital = amount ?? double.infinity;
    });
    _applyFilters();
  }

  void _updateCapitalRange(double min, double max) {
    setState(() {
      _currentFilter.minCapital = min;
      _currentFilter.maxCapital = max;
      _minCapitalController.text = min > 0 ? min.toStringAsFixed(0) : '';
      _maxCapitalController.text = max < double.infinity
          ? max.toStringAsFixed(0)
          : '';
    });
    _applyFilters();
  }

  void _toggleMajorityFilter() {
    setState(() {
      _currentFilter.showOnlyMajorityHolders =
          !_currentFilter.showOnlyMajorityHolders;
    });
    _applyFilters();
  }

  void _toggleLargeInvestorsFilter() {
    setState(() {
      _currentFilter.showOnlyLargeInvestors =
          !_currentFilter.showOnlyLargeInvestors;
    });
    _applyFilters();
  }

  void _toggleActiveOnlyFilter() {
    setState(() {
      _currentFilter.includeActiveOnly = !_currentFilter.includeActiveOnly;
    });
    _applyFilters();
  }

  void _toggleUnviableFilter() {
    setState(() {
      _currentFilter.showOnlyWithUnviableInvestments =
          !_currentFilter.showOnlyWithUnviableInvestments;
    });
    _applyFilters();
  }

  void _applyFilters() {
    widget.onFiltersChanged(_currentFilter);
  }

  void _resetFilters() {
    setState(() {
      _currentFilter = PremiumAnalyticsFilter();
      _setupControllers();
    });
    _applyFilters();
  }

  void _saveFilterPreset() {
    // TODO: Implement filter preset saving
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Zapisywanie presetów filtrów - w przygotowaniu'),
      ),
    );
  }

  void _loadFilterPreset() {
    // TODO: Implement filter preset loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wczytywanie presetów filtrów - w przygotowaniu'),
      ),
    );
  }
}

/// 🎯 KLASA FILTRA PREMIUM ANALYTICS
class PremiumAnalyticsFilter {
  String searchQuery;
  VotingStatus? votingStatusFilter;
  ClientType? clientTypeFilter;
  double minCapital;
  double maxCapital;
  int minInvestmentCount;
  int maxInvestmentCount;
  bool showOnlyMajorityHolders;
  bool showOnlyLargeInvestors;
  bool showOnlyWithUnviableInvestments;
  bool includeActiveOnly;
  bool requireHighDiversification;
  bool recentActivityOnly;

  PremiumAnalyticsFilter({
    this.searchQuery = '',
    this.votingStatusFilter,
    this.clientTypeFilter,
    this.minCapital = 0.0,
    this.maxCapital = double.infinity,
    this.minInvestmentCount = 0,
    this.maxInvestmentCount = 100,
    this.showOnlyMajorityHolders = false,
    this.showOnlyLargeInvestors = false,
    this.showOnlyWithUnviableInvestments = false,
    this.includeActiveOnly = false,
    this.requireHighDiversification = false,
    this.recentActivityOnly = false,
  });

  PremiumAnalyticsFilter copy() {
    return PremiumAnalyticsFilter(
      searchQuery: searchQuery,
      votingStatusFilter: votingStatusFilter,
      clientTypeFilter: clientTypeFilter,
      minCapital: minCapital,
      maxCapital: maxCapital,
      minInvestmentCount: minInvestmentCount,
      maxInvestmentCount: maxInvestmentCount,
      showOnlyMajorityHolders: showOnlyMajorityHolders,
      showOnlyLargeInvestors: showOnlyLargeInvestors,
      showOnlyWithUnviableInvestments: showOnlyWithUnviableInvestments,
      includeActiveOnly: includeActiveOnly,
      requireHighDiversification: requireHighDiversification,
      recentActivityOnly: recentActivityOnly,
    );
  }

  bool matches(InvestorSummary investor) {
    // Search query filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      final name = investor.client.name.toLowerCase();
      final email = investor.client.email.toLowerCase();
      if (!name.contains(query) && !email.contains(query)) {
        return false;
      }
    }

    // Voting status filter
    if (votingStatusFilter != null &&
        investor.client.votingStatus != votingStatusFilter) {
      return false;
    }

    // Client type filter
    if (clientTypeFilter != null && investor.client.type != clientTypeFilter) {
      return false;
    }

    // Capital range filter
    final capital = investor.viableRemainingCapital;
    if (capital < minCapital || capital > maxCapital) {
      return false;
    }

    // Investment count filter
    if (investor.investmentCount < minInvestmentCount ||
        investor.investmentCount > maxInvestmentCount) {
      return false;
    }

    // Majority holders filter
    if (showOnlyMajorityHolders) {
      // TODO: Implement majority calculation
    }

    // Large investors filter (>1M PLN)
    if (showOnlyLargeInvestors && capital < 1000000) {
      return false;
    }

    // Unviable investments filter
    if (showOnlyWithUnviableInvestments &&
        investor.client.unviableInvestments.isEmpty) {
      return false;
    }

    // Active only filter
    if (includeActiveOnly && !investor.client.isActive) {
      return false;
    }

    // High diversification filter (≥3 different product types)
    if (requireHighDiversification) {
      final productTypes = investor.investments
          .map((inv) => inv.productType)
          .toSet()
          .length;
      if (productTypes < 3) {
        return false;
      }
    }

    // Recent activity filter
    if (recentActivityOnly) {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final hasRecentActivity = investor.investments.any((inv) {
        // TODO: Check if investment has recent activity based on lastUpdateDate
        // For now, we'll check if the investment was created recently
        return true; // Placeholder - would check inv.createdDate?.isAfter(thirtyDaysAgo) ?? false
      });

      if (!hasRecentActivity) {
        return false;
      }
    }
    return true;
  }

  bool get hasActiveFilters {
    return searchQuery.isNotEmpty ||
        votingStatusFilter != null ||
        clientTypeFilter != null ||
        minCapital > 0 ||
        maxCapital < double.infinity ||
        minInvestmentCount > 0 ||
        maxInvestmentCount < 100 ||
        showOnlyMajorityHolders ||
        showOnlyLargeInvestors ||
        showOnlyWithUnviableInvestments ||
        includeActiveOnly ||
        requireHighDiversification ||
        recentActivityOnly;
  }
}
