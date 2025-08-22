import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../theme/app_theme.dart';

/// 🔍 CLIENTS DISCOVERY PANEL
/// 
/// AI-powered search i zaawansowane filtry z:
/// - Smart search z auto-suggestions
/// - Contextual filters z visual feedback
/// - Sort controls z smooth transitions
/// - View mode switcher z animated icons
/// - Advanced filters panel z progressive disclosure
class ClientsDiscoveryPanel extends StatefulWidget {
  final String searchQuery;
  final Set<ClientFilter> activeFilters;
  final ClientSortMode sortMode;
  final ClientViewMode viewMode;
  final bool isCompactMode;
  final Function(String) onSearchChanged;
  final Function(Set<ClientFilter>) onFiltersChanged;
  final Function(ClientSortMode) onSortChanged;
  final Function(ClientViewMode) onViewModeChanged;
  final VoidCallback onToggleCompact;
  final int totalClients;
  final int filteredClients;

  const ClientsDiscoveryPanel({
    super.key,
    required this.searchQuery,
    required this.activeFilters,
    required this.sortMode,
    required this.viewMode,
    required this.isCompactMode,
    required this.onSearchChanged,
    required this.onFiltersChanged,
    required this.onSortChanged,
    required this.onViewModeChanged,
    required this.onToggleCompact,
    required this.totalClients,
    required this.filteredClients,
  });

  @override
  State<ClientsDiscoveryPanel> createState() => _ClientsDiscoveryPanelState();
}

class _ClientsDiscoveryPanelState extends State<ClientsDiscoveryPanel>
    with TickerProviderStateMixin {
  
  late AnimationController _searchController;
  late AnimationController _filterController;
  late AnimationController _viewModeController;
  late AnimationController _pulseController;
  
  late Animation<double> _searchScaleAnimation;
  late Animation<double> _filterSlideAnimation;
  late Animation<double> _viewModeRotateAnimation;
  late Animation<double> _pulseAnimation;
  
  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  bool _showAdvancedFilters = false;
  bool _isSearchFocused = false;
  List<String> _searchSuggestions = [];
  Timer? _searchDebouncer;
  Timer? _suggestionTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupSearchController();
    _startAnimations();
    _generateSampleSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterController.dispose();
    _viewModeController.dispose();
    _pulseController.dispose();
    _searchTextController.dispose();
    _searchFocusNode.dispose();
    _searchDebouncer?.cancel();
    _suggestionTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _searchController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _filterController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _viewModeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _searchScaleAnimation = _searchController;
    
    _filterSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _filterController,
      curve: Curves.easeOutCubic,
    ));
    
    _viewModeRotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _viewModeController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupSearchController() {
    _searchTextController.text = widget.searchQuery;
    
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
      
      if (_isSearchFocused) {
        _searchController.forward();
        _generateSearchSuggestions();
      } else {
        _searchController.reverse();
      }
    });
  }

  void _startAnimations() {
    _filterController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _generateSampleSuggestions() {
    _searchSuggestions = [
      'Aktywni klienci premium',
      'Klienci z wysokim kapitałem',
      'Nowi klienci (ostatnie 30 dni)',
      'Klienci wymagający uwagi',
      'Korporacyjni inwestorzy',
    ];
  }

  void _generateSearchSuggestions() {
    _suggestionTimer?.cancel();
    _suggestionTimer = Timer(const Duration(milliseconds: 300), () {
      if (_isSearchFocused && mounted) {
        setState(() {
          _searchSuggestions = [
            'Aktywni klienci premium',
            'Klienci z wysokim kapitałem',
            'Nowi klienci (ostatnie 30 dni)',
            'Klienci wymagający uwagi',
            'Korporacyjni inwestorzy',
            'Klienci z terminami',
          ].where((suggestion) {
            final query = _searchTextController.text.toLowerCase();
            return query.isEmpty || suggestion.toLowerCase().contains(query);
          }).toList();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppTheme.borderSecondary.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Main search and controls row
          _buildMainRow(),
          
          // Advanced filters (collapsible)
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            height: _showAdvancedFilters ? null : 0,
            child: _showAdvancedFilters 
                ? _buildAdvancedFilters()
                : const SizedBox(),
          ),
          
          // Results summary bar
          _buildResultsSummary(),
        ],
      ),
    );
  }

  Widget _buildMainRow() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // 🔍 Search field
          Expanded(
            flex: 3,
            child: _buildSearchField(),
          ),
          
          const SizedBox(width: 16),
          
          // 🎯 Quick filters
          Expanded(
            flex: 2,
            child: _buildQuickFilters(),
          ),
          
          const SizedBox(width: 16),
          
          // 📊 Sort & View controls
          _buildViewControls(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return ScaleTransition(
      scale: _searchScaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundPrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isSearchFocused 
                ? AppTheme.secondaryGold 
                : AppTheme.borderSecondary,
            width: _isSearchFocused ? 2 : 1,
          ),
          boxShadow: _isSearchFocused ? [
            BoxShadow(
              color: AppTheme.secondaryGold.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            TextField(
              controller: _searchTextController,
              focusNode: _searchFocusNode,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: '🔍 Znajdź klientów...',
                hintStyle: TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 16,
                ),
                prefixIcon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isSearchFocused ? Icons.search_rounded : Icons.search,
                    color: _isSearchFocused 
                        ? AppTheme.secondaryGold 
                        : AppTheme.textSecondary,
                    size: _isSearchFocused ? 24 : 20,
                  ),
                ),
                suffixIcon: _searchTextController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchTextController.clear();
                          widget.onSearchChanged('');
                        },
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: AppTheme.textSecondary,
                        ),
                      )
                    : IconButton(
                        onPressed: _toggleAdvancedFilters,
                        icon: AnimatedRotation(
                          turns: _showAdvancedFilters ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.tune_rounded,
                            color: _showAdvancedFilters 
                                ? AppTheme.secondaryGold 
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                _searchDebouncer?.cancel();
                _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
                  widget.onSearchChanged(value);
                });
                _generateSearchSuggestions();
              },
            ),
            
            // Search suggestions dropdown
            if (_isSearchFocused && _searchSuggestions.isNotEmpty)
              _buildSearchSuggestions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderSecondary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Sugestie wyszukiwania',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...._searchSuggestions.map((suggestion) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _searchTextController.text = suggestion;
                  widget.onSearchChanged(suggestion);
                  _searchFocusNode.unfocus();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: AppTheme.textTertiary,
                        size: 16,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.north_west_rounded,
                        color: AppTheme.textTertiary,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildQuickFilterChip(
            'Aktywni',
            Icons.check_circle_rounded,
            widget.activeFilters.any((f) => f is ActiveClientsFilter),
            () => _toggleFilter(ActiveClientsFilter()),
          ),
          
          const SizedBox(width: 8),
          
          _buildQuickFilterChip(
            'Premium',
            Icons.star_rounded,
            widget.activeFilters.any((f) => f is PremiumClientsFilter),
            () => _toggleFilter(PremiumClientsFilter()),
          ),
          
          const SizedBox(width: 8),
          
          _buildQuickFilterChip(
            'Nowi',
            Icons.new_releases_rounded,
            widget.activeFilters.any((f) => f is NewClientsFilter),
            () => _toggleFilter(NewClientsFilter()),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return ScaleTransition(
      scale: isActive ? _pulseAnimation : 
              const AlwaysStoppedAnimation(1.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isActive 
                  ? AppTheme.secondaryGold.withOpacity(0.15)
                  : AppTheme.backgroundPrimary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive 
                    ? AppTheme.secondaryGold 
                    : AppTheme.borderSecondary,
                width: isActive ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isActive 
                      ? AppTheme.secondaryGold 
                      : AppTheme.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive 
                        ? AppTheme.secondaryGold 
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sort dropdown
        _buildSortDropdown(),
        
        const SizedBox(width: 12),
        
        // View mode switcher
        _buildViewModeSwitcher(),
        
        const SizedBox(width: 12),
        
        // Compact mode toggle
        _buildCompactToggle(),
      ],
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderSecondary,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ClientSortMode>(
          value: widget.sortMode,
          icon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: AppTheme.textSecondary,
          ),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: AppTheme.backgroundPrimary,
          items: ClientSortMode.values.map((mode) {
            return DropdownMenuItem(
              value: mode,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getSortIcon(mode),
                    color: AppTheme.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(mode.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (mode) {
            if (mode != null) {
              widget.onSortChanged(mode);
            }
          },
        ),
      ),
    );
  }

  Widget _buildViewModeSwitcher() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderSecondary,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ClientViewMode.values.map((mode) {
          final isActive = widget.viewMode == mode;
          
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                widget.onViewModeChanged(mode);
                _viewModeController.forward().then((_) {
                  _viewModeController.reverse();
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive 
                      ? AppTheme.secondaryGold.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AnimatedRotation(
                  turns: isActive ? _viewModeRotateAnimation.value * 0.1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _getViewModeIcon(mode),
                    color: isActive 
                        ? AppTheme.secondaryGold 
                        : AppTheme.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompactToggle() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onToggleCompact,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isCompactMode 
                ? AppTheme.infoColor.withOpacity(0.15)
                : AppTheme.backgroundPrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isCompactMode 
                  ? AppTheme.infoColor 
                  : AppTheme.borderSecondary,
              width: 1,
            ),
          ),
          child: Icon(
            widget.isCompactMode 
                ? Icons.unfold_more_rounded 
                : Icons.unfold_less_rounded,
            color: widget.isCompactMode 
                ? AppTheme.infoColor 
                : AppTheme.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.5),
        end: Offset.zero,
      ).animate(_filterSlideAnimation),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.backgroundPrimary.withOpacity(0.5),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zaawansowane filtry',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Filter categories
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildAdvancedFilterSection(
                  'Status klienta',
                  [
                    'Aktywni',
                    'Nieaktywni',
                    'Premium',
                    'Standard',
                  ],
                ),
                
                _buildAdvancedFilterSection(
                  'Okres współpracy',
                  [
                    'Ostatni miesiąc',
                    'Ostatnie 3 miesiące',
                    'Ostatni rok',
                    'Ponad rok',
                  ],
                ),
                
                _buildAdvancedFilterSection(
                  'Wartość portfela',
                  [
                    'Do 50k zł',
                    '50k - 200k zł',
                    '200k - 500k zł',
                    'Powyżej 500k zł',
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedFilterSection(
    String title,
    List<String> options,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderSecondary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              return _buildAdvancedFilterChip(option);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilterChip(String label) {
    final isActive = false; // TODO: Implement filter state
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: Toggle advanced filter
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isActive 
                ? AppTheme.secondaryGold.withOpacity(0.15)
                : AppTheme.backgroundPrimary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive 
                  ? AppTheme.secondaryGold 
                  : AppTheme.borderSecondary,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive 
                  ? AppTheme.secondaryGold 
                  : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppTheme.textSecondary,
            size: 16,
          ),
          
          const SizedBox(width: 8),
          
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                children: [
                  const TextSpan(text: 'Wyświetlono '),
                  TextSpan(
                    text: '${widget.filteredClients}',
                    style: const TextStyle(
                      color: AppTheme.secondaryGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' z '),
                  TextSpan(
                    text: '${widget.totalClients}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' klientów'),
                ],
              ),
            ),
          ),
          
          if (widget.activeFilters.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.activeFilters.length} filtrów',
                style: TextStyle(
                  color: AppTheme.warningColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleAdvancedFilters() {
    setState(() {
      _showAdvancedFilters = !_showAdvancedFilters;
    });
    
    if (_showAdvancedFilters) {
      _filterController.forward();
    } else {
      _filterController.reverse();
    }
  }

  void _toggleFilter(ClientFilter filter) {
    final newFilters = Set<ClientFilter>.from(widget.activeFilters);
    
    // Remove existing filter of same type
    newFilters.removeWhere((f) => f.runtimeType == filter.runtimeType);
    
    // Add new filter if it wasn't already active
    if (!widget.activeFilters.any((f) => f.runtimeType == filter.runtimeType)) {
      newFilters.add(filter);
    }
    
    widget.onFiltersChanged(newFilters);
  }

  IconData _getSortIcon(ClientSortMode mode) {
    switch (mode) {
      case ClientSortMode.nameAsc:
      case ClientSortMode.nameDesc:
        return Icons.sort_by_alpha_rounded;
      case ClientSortMode.dateAsc:
      case ClientSortMode.dateDesc:
        return Icons.date_range_rounded;
      case ClientSortMode.valueAsc:
      case ClientSortMode.valueDesc:
        return Icons.attach_money_rounded;
    }
  }

  IconData _getViewModeIcon(ClientViewMode mode) {
    switch (mode) {
      case ClientViewMode.grid:
        return Icons.grid_view_rounded;
      case ClientViewMode.list:
        return Icons.list_rounded;
      case ClientViewMode.cards:
        return Icons.view_agenda_rounded;
      case ClientViewMode.timeline:
        return Icons.timeline_rounded;
    }
  }
}

// Filter classes (should be imported from main screen)
abstract class ClientFilter {
  String get displayName;
  List<dynamic> apply(List<dynamic> clients);
}

class ActiveClientsFilter extends ClientFilter {
  @override
  String get displayName => 'Aktywni';
  
  @override
  List<dynamic> apply(List<dynamic> clients) => clients;
}

class PremiumClientsFilter extends ClientFilter {
  @override
  String get displayName => 'Premium';
  
  @override
  List<dynamic> apply(List<dynamic> clients) => clients;
}

class NewClientsFilter extends ClientFilter {
  @override
  String get displayName => 'Nowi';
  
  @override
  List<dynamic> apply(List<dynamic> clients) => clients;
}

// Enums (should be imported from main screen)
enum ClientSortMode { nameAsc, nameDesc, dateAsc, dateDesc, valueAsc, valueDesc }
enum ClientViewMode { grid, list, cards, timeline }

extension ClientSortModeExtension on ClientSortMode {
  String get displayName {
    switch (this) {
      case ClientSortMode.nameAsc:
        return 'Nazwa A-Z';
      case ClientSortMode.nameDesc:
        return 'Nazwa Z-A';
      case ClientSortMode.dateAsc:
        return 'Data rosnąco';
      case ClientSortMode.dateDesc:
        return 'Data malejąco';
      case ClientSortMode.valueAsc:
        return 'Wartość rosnąco';
      case ClientSortMode.valueDesc:
        return 'Wartość malejąco';
    }
  }
}
