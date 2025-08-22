import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'animated_product_stats.dart';

/// 🎯 SCROLL-AWARE PRODUCT HEADER
/// 
/// Inteligentny header który:
/// - Reaguje na pozycję przewijania listy produktów
/// - Płynnie zawija statystyki podczas przewijania w dół
/// - Rozwija się podczas przewijania w górę
/// - Zawiera nowoczesne animowane statystyki
/// - Obsługuje search i filtry w trybie zwiniętym
class ScrollAwareProductHeader extends StatefulWidget {
  final ScrollController scrollController;
  final TextEditingController searchController;
  final dynamic productStatistics;
  final bool isLoading;
  final Function(String)? onSearchChanged;
  final Widget? additionalActions;
  final bool showCharts;
  final VoidCallback? onToggleCharts;
  final VoidCallback? onRefresh;
  final String subtitle;
  final int totalCount;
  final int filteredCount;

  const ScrollAwareProductHeader({
    super.key,
    required this.scrollController,
    required this.searchController,
    this.productStatistics,
    this.isLoading = false,
    this.onSearchChanged,
    this.additionalActions,
    this.showCharts = true,
    this.onToggleCharts,
    this.onRefresh,
    this.subtitle = 'Zarządzanie produktami inwestycyjnymi',
    this.totalCount = 0,
    this.filteredCount = 0,
  });

  @override
  State<ScrollAwareProductHeader> createState() => _ScrollAwareProductHeaderState();
}

class _ScrollAwareProductHeaderState extends State<ScrollAwareProductHeader>
    with TickerProviderStateMixin {
  
  late AnimationController _headerController;
  late AnimationController _searchController;
  late AnimationController _pulseController;
  
  late Animation<double> _headerAnimation;
  late Animation<double> _searchAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isCollapsed = false;
  bool _isSearchExpanded = false;
  double _lastScrollOffset = 0;
  bool _wasScrollingDown = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScroll);
    _headerController.dispose();
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _searchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeInOutCubic,
    );
    
    _searchAnimation = CurvedAnimation(
      parent: _searchController,
      curve: Curves.easeOutBack,
    );
    
    _pulseAnimation = _pulseController;
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start subtle pulse animation
    _pulseController.repeat(reverse: true);
  }

  void _setupScrollListener() {
    widget.scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final currentOffset = widget.scrollController.offset;
    final isScrollingDown = currentOffset > _lastScrollOffset;
    const collapseThreshold = 80.0;
    const expandThreshold = 40.0;
    
    // Determine if should collapse based on scroll direction and position
    bool shouldCollapse = false;
    
    if (isScrollingDown && currentOffset > collapseThreshold) {
      shouldCollapse = true;
    } else if (!isScrollingDown && currentOffset < expandThreshold) {
      shouldCollapse = false;
    } else {
      shouldCollapse = _isCollapsed; // Maintain current state
    }
    
    if (shouldCollapse != _isCollapsed) {
      setState(() {
        _isCollapsed = shouldCollapse;
      });
      
      if (_isCollapsed) {
        _headerController.forward();
        // Collapse search if expanded
        if (_isSearchExpanded) {
          _collapseSearch();
        }
      } else {
        _headerController.reverse();
      }
      
      // Haptic feedback for state change
      HapticFeedback.lightImpact();
    }
    
    _lastScrollOffset = currentOffset;
    _wasScrollingDown = isScrollingDown;
  }

  void _toggleSearch() {
    if (!_isCollapsed) return;
    
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
    });
    
    if (_isSearchExpanded) {
      _searchController.forward();
    } else {
      _searchController.reverse();
    }
    
    HapticFeedback.selectionClick();
  }

  void _collapseSearch() {
    if (_isSearchExpanded) {
      setState(() {
        _isSearchExpanded = false;
      });
      _searchController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _headerAnimation,
        _searchAnimation,
        _pulseAnimation,
      ]),
      builder: (context, child) {
        return SliverToBoxAdapter(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            height: _calculateHeaderHeight(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.9),
                    AppTheme.secondaryGold.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(_isCollapsed ? 0 : 24),
                  bottomRight: Radius.circular(_isCollapsed ? 0 : 24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 15 * (1 - _headerAnimation.value),
                    offset: Offset(0, 8 * (1 - _headerAnimation.value)),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  _buildAnimatedBackground(),
                  _buildHeaderContent(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateHeaderHeight() {
    if (_isCollapsed) {
      return 70.0 + (_isSearchExpanded ? 60.0 : 0.0);
    } else {
      double baseHeight = 140.0;
      double statsHeight = widget.showCharts ? 380.0 : 180.0;
      return baseHeight + statsHeight;
    }
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: HeaderBackgroundPainter(
          animationValue: _pulseAnimation.value,
          isCollapsed: _isCollapsed,
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Padding(
      padding: EdgeInsets.all(_isCollapsed ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleSection(),
          
          if (!_isCollapsed) ...[
            const SizedBox(height: 20),
            _buildSearchSection(),
            const SizedBox(height: 20),
            AnimatedProductStats(
              productStatistics: widget.productStatistics,
              isLoading: widget.isLoading,
              isCollapsed: _isCollapsed,
              showCharts: widget.showCharts,
              onToggleCharts: widget.onToggleCharts,
              scrollController: widget.scrollController,
            ),
          ] else if (_isSearchExpanded) ...[
            const SizedBox(height: 12),
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _searchAnimation,
                child: _buildCollapsedSearchField(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Produkty Inwestycyjne',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _isCollapsed ? 18 : 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              
              if (!_isCollapsed) ...[
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCountBadges(),
              ] else ...[
                const SizedBox(height: 2),
                Text(
                  '${widget.filteredCount} z ${widget.totalCount}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        _buildHeaderActions(),
      ],
    );
  }

  Widget _buildCountBadges() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.successColor.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            'Wyświetlane: ${widget.filteredCount}',
            style: const TextStyle(
              color: AppTheme.successColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.infoColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.infoColor.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            'Łącznie: ${widget.totalCount}',
            style: const TextStyle(
              color: AppTheme.infoColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search toggle button when collapsed
        if (_isCollapsed && !_isSearchExpanded)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: IconButton(
                  onPressed: _toggleSearch,
                  icon: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: 'Wyszukaj produkty',
                ),
              );
            },
          ),
        
        // Refresh button
        IconButton(
          onPressed: widget.onRefresh,
          icon: const Icon(
            Icons.refresh,
            color: AppTheme.secondaryGold,
          ),
          tooltip: 'Odśwież dane',
        ),
        
        // Additional actions
        if (widget.additionalActions != null)
          widget.additionalActions!,
      ],
    );
  }

  Widget _buildSearchSection() {
    return AnimatedOpacity(
      opacity: 1 - _headerAnimation.value,
      duration: const Duration(milliseconds: 200),
      child: _buildSearchField(),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: widget.searchController,
        onChanged: widget.onSearchChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Szukaj po nazwie produktu, firmie, typie...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          suffixIcon: widget.searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    widget.searchController.clear();
                    widget.onSearchChanged?.call('');
                  },
                  icon: Icon(
                    Icons.clear_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedSearchField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 50,
      child: _buildSearchField(),
    );
  }
}

/// Custom painter for animated header background
class HeaderBackgroundPainter extends CustomPainter {
  final double animationValue;
  final bool isCollapsed;

  HeaderBackgroundPainter({
    required this.animationValue,
    required this.isCollapsed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    final particleCount = isCollapsed ? 6 : 15;
    
    for (int i = 0; i < particleCount; i++) {
      final progress = (animationValue + i * 0.15) % 1.0;
      final x = (size.width * 0.1) + (size.width * 0.8 * (i / particleCount));
      final y = size.height * 0.2 + 
          (size.height * 0.6 * (progress * 2 - 1).abs());
      
      final radius = (3 + (i % 4)) * (isCollapsed ? 0.4 : 1.0);
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(HeaderBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.isCollapsed != isCollapsed;
  }
}