import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models_and_services.dart';

class EmployeeSearchAndFiltersWidget extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String?) onBranchFilterChanged;
  final Function(String?) onStatusFilterChanged;
  final Function(String?) onPositionFilterChanged;
  final List<String> branches;
  final List<String> positions;
  final String currentSearchQuery;
  final String? selectedBranch;
  final String? selectedStatus;
  final String? selectedPosition;

  const EmployeeSearchAndFiltersWidget({
    super.key,
    required this.onSearchChanged,
    required this.onBranchFilterChanged,
    required this.onStatusFilterChanged,
    required this.onPositionFilterChanged,
    required this.branches,
    required this.positions,
    required this.currentSearchQuery,
    this.selectedBranch,
    this.selectedStatus,
    this.selectedPosition,
  });

  @override
  State<EmployeeSearchAndFiltersWidget> createState() =>
      _EmployeeSearchAndFiltersWidgetState();
}

class _EmployeeSearchAndFiltersWidgetState
    extends State<EmployeeSearchAndFiltersWidget>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late AnimationController _filterAnimationController;
  late AnimationController _searchAnimationController;
  late Animation<double> _filterSlideAnimation;
  late Animation<double> _searchScaleAnimation;

  bool _isFiltersExpanded = false;
  bool _isSearchFocused = false;
  int _activeFiltersCount = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.currentSearchQuery);

    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _filterSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _filterAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _searchScaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _updateActiveFiltersCount();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterAnimationController.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EmployeeSearchAndFiltersWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateActiveFiltersCount();
  }

  void _updateActiveFiltersCount() {
    int count = 0;
    if (widget.selectedBranch != null) count++;
    if (widget.selectedStatus != null) count++;
    if (widget.selectedPosition != null) count++;

    setState(() {
      _activeFiltersCount = count;
    });
  }

  void _toggleFilters() {
    setState(() {
      _isFiltersExpanded = !_isFiltersExpanded;
    });

    if (_isFiltersExpanded) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }

    HapticFeedback.lightImpact();
  }

  void _clearAllFilters() {
    widget.onBranchFilterChanged(null);
    widget.onStatusFilterChanged(null);
    widget.onPositionFilterChanged(null);
    HapticFeedback.mediumImpact();
  }

  Widget _buildSearchField() {
    return AnimatedBuilder(
      animation: _searchScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _searchScaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isSearchFocused
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: widget.onSearchChanged,
              onTap: () {
                setState(() {
                  _isSearchFocused = true;
                });
                _searchAnimationController.forward();
              },
              onEditingComplete: () {
                setState(() {
                  _isSearchFocused = false;
                });
                _searchAnimationController.reverse();
              },
              decoration: InputDecoration(
                labelText: 'Szukaj pracowników',
                hintText: 'Wpisz imię, nazwisko, email, stanowisko...',
                prefixIcon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.search,
                    color: _isSearchFocused
                        ? AppTheme.primaryColor
                        : AppTheme.textTertiary,
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 200),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: IconButton(
                              onPressed: () {
                                _searchController.clear();
                                widget.onSearchChanged('');
                                HapticFeedback.lightImpact();
                              },
                              icon: const Icon(Icons.clear),
                              tooltip: 'Wyczyść wyszukiwanie',
                            ),
                          );
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.borderPrimary.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppTheme.backgroundPrimary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    final chips = <Widget>[];

    if (widget.selectedBranch != null) {
      chips.add(
        _buildFilterChip(
          'Filia: ${widget.selectedBranch}',
          () => widget.onBranchFilterChanged(null),
          AppTheme.primaryColor,
        ),
      );
    }

    if (widget.selectedStatus != null) {
      chips.add(
        _buildFilterChip(
          'Status: ${widget.selectedStatus}',
          () => widget.onStatusFilterChanged(null),
          AppTheme.successPrimary,
        ),
      );
    }

    if (widget.selectedPosition != null) {
      chips.add(
        _buildFilterChip(
          'Stanowisko: ${widget.selectedPosition}',
          () => widget.onPositionFilterChanged(null),
          AppTheme.secondaryGold,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...chips,
                  if (chips.length > 1) _buildClearAllButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove, Color color) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Chip(
            label: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            deleteIcon: Icon(Icons.close, size: 16, color: color),
            onDeleted: onRemove,
            backgroundColor: color.withValues(alpha: 0.1),
            side: BorderSide(color: color.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildClearAllButton() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: ActionChip(
            label: const Text(
              'Wyczyść wszystkie',
              style: TextStyle(
                color: AppTheme.errorPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: _clearAllFilters,
            backgroundColor: AppTheme.errorPrimary.withValues(alpha: 0.1),
            side: BorderSide(
              color: AppTheme.errorPrimary.withValues(alpha: 0.3),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFiltersPanel() {
    return AnimatedBuilder(
      animation: _filterSlideAnimation,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _filterSlideAnimation,
          axisAlignment: -1.0,
          child: Container(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      children: [
                        // Branch filter
                        Expanded(
                          child: _buildAnimatedDropdown(
                            'Filia',
                            widget.selectedBranch,
                            [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Wszystkie filie'),
                              ),
                              ...widget.branches.map((branch) {
                                return DropdownMenuItem<String>(
                                  value: branch,
                                  child: Text(branch),
                                );
                              }),
                            ],
                            widget.onBranchFilterChanged,
                            Icons.business,
                            AppTheme.primaryColor,
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Status filter
                        Expanded(
                          child: _buildAnimatedDropdown(
                            'Status',
                            widget.selectedStatus,
                            const [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text('Wszystkie statusy'),
                              ),
                              DropdownMenuItem<String>(
                                value: 'Aktywny',
                                child: Text('Aktywny'),
                              ),
                              DropdownMenuItem<String>(
                                value: 'Nieaktywny',
                                child: Text('Nieaktywny'),
                              ),
                            ],
                            widget.onStatusFilterChanged,
                            Icons.verified_user,
                            AppTheme.successPrimary,
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Position filter
                        Expanded(
                          child: _buildAnimatedDropdown(
                            'Stanowisko',
                            widget.selectedPosition,
                            [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Wszystkie stanowiska'),
                              ),
                              ...widget.positions.map((position) {
                                return DropdownMenuItem<String>(
                                  value: position,
                                  child: Text(position),
                                );
                              }),
                            ],
                            widget.onPositionFilterChanged,
                            Icons.work,
                            AppTheme.secondaryGold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedDropdown(
    String label,
    String? value,
    List<DropdownMenuItem<String>> items,
    Function(String?) onChanged,
    IconData icon,
    Color accentColor,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: value,
                decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon, color: accentColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.borderPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentColor, width: 2),
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundPrimary,
                ),
                items: items,
                onChanged: onChanged,
                dropdownColor: AppTheme.backgroundPrimary,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with search and filter toggle
          Row(
            children: [
              // Search field
              Expanded(flex: 3, child: _buildSearchField()),

              const SizedBox(width: 16),

              // Filter toggle button
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 200),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isFiltersExpanded
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _toggleFilters,
                            icon: AnimatedRotation(
                              duration: const Duration(milliseconds: 200),
                              turns: _isFiltersExpanded ? 0.5 : 0,
                              child: const Icon(Icons.expand_more),
                            ),
                            label: const Text('Filtry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFiltersExpanded
                                  ? AppTheme.primaryColor
                                  : AppTheme.backgroundPrimary,
                              foregroundColor: _isFiltersExpanded
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        // Active filters badge
                        if (_activeFiltersCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 300),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, badgeValue, child) {
                                return Transform.scale(
                                  scale: badgeValue,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorPrimary,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.errorPrimary
                                              .withValues(alpha: 0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                    child: Text(
                                      _activeFiltersCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          // Active filters chips
          _buildFilterChips(),

          // Expandable filters panel
          _buildFiltersPanel(),
        ],
      ),
    );
  }
}
