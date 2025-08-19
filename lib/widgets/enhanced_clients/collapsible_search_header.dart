import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';

/// 🎭 COLLAPSIBLE SEARCH HEADER
/// 
/// Inteligentny header który:
/// - Zwija się podczas przewijania w dół
/// - Rozwija się podczas przewijania w górę  
/// - Transformuje pole wyszukiwania w ikonę w trybie zwiniętym
/// - Smooth animations z physics-based motion
class CollapsibleSearchHeader extends StatefulWidget {
  final TextEditingController searchController;
  final VoidCallback? onSearchTap;
  final Function(String)? onSearchChanged;
  final Widget? statsWidget;
  final bool showActiveOnly;
  final VoidCallback? onToggleActiveOnly;
  final int activeClientsCount;
  final bool isSelectionMode;
  final VoidCallback? onSelectionModeToggle;
  final Widget? additionalActions;

  const CollapsibleSearchHeader({
    super.key,
    required this.searchController,
    this.onSearchTap,
    this.onSearchChanged,
    this.statsWidget,
    this.showActiveOnly = false,
    this.onToggleActiveOnly,
    this.activeClientsCount = 0,
    this.isSelectionMode = false,
    this.onSelectionModeToggle,
    this.additionalActions,
  });

  @override
  State<CollapsibleSearchHeader> createState() => _CollapsibleSearchHeaderState();
}

class _CollapsibleSearchHeaderState extends State<CollapsibleSearchHeader>
    with TickerProviderStateMixin {
  
  late AnimationController _collapseController;
  late AnimationController _searchController;
  late AnimationController _pulseController;
  
  late Animation<double> _collapseAnimation;
  late Animation<double> _searchExpandAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isCollapsed = false;
  bool _isSearchExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _collapseController.dispose();
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _collapseController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _searchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _collapseAnimation = CurvedAnimation(
      parent: _collapseController,
      curve: Curves.easeInOutCubic,
    );
    
    _searchExpandAnimation = CurvedAnimation(
      parent: _searchController,
      curve: Curves.easeOutBack,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start subtle pulse animation
    _pulseController.repeat(reverse: true);
  }

  /// Method to be called from parent when scroll position changes
  void updateScrollPosition(double scrollOffset, double maxScrollExtent) {
    final shouldCollapse = scrollOffset > 100;
    
    if (shouldCollapse != _isCollapsed) {
      setState(() {
        _isCollapsed = shouldCollapse;
      });
      
      if (_isCollapsed) {
        _collapseController.forward();
        if (_isSearchExpanded) {
          _collapseSearchField();
        }
      } else {
        _collapseController.reverse();
      }
    }
  }

  void _toggleSearchField() {
    if (!_isCollapsed) return;
    
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
    });
    
    if (_isSearchExpanded) {
      _searchController.forward();
      // Auto-focus on the search field
      Future.delayed(const Duration(milliseconds: 200), () {
        FocusScope.of(context).requestFocus(FocusNode());
      });
    } else {
      _searchController.reverse();
    }
  }

  void _collapseSearchField() {
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
      animation: Listenable.merge([_collapseAnimation, _searchExpandAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Container(
          height: _isCollapsed 
            ? (80.0 + (_isSearchExpanded ? 60.0 : 0.0))
            : (200.0 + (widget.statsWidget != null ? 120.0 : 0.0)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
                AppTheme.secondaryGold.withOpacity(0.1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 20 * (1 - _collapseAnimation.value),
                offset: Offset(0, 5 * (1 - _collapseAnimation.value)),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background particles
              _buildParticleBackground(),
              
              // Main content
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: _isCollapsed ? 12.0 : 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderContent(),
                    
                    if (!_isCollapsed) ...[
                      const SizedBox(height: 16),
                      _buildSearchSection(),
                      
                      if (widget.statsWidget != null) ...[
                        const SizedBox(height: 20),
                        _buildStatsSection(),
                      ],
                    ] else if (_isSearchExpanded) ...[
                      const SizedBox(height: 12),
                      _buildCollapsedSearchField(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticleBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: ParticleBackgroundPainter(
          animation: _pulseAnimation,
          isCollapsed: _isCollapsed,
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                  color: AppTheme.textOnPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: _isCollapsed ? 20 : 28,
                ),
                child: Text(
                  widget.isSelectionMode ? '✉️ Wybór klientów' : '👥 Klienci',
                ),
              ),
              
              if (!_isCollapsed) ...[
                const SizedBox(height: 8),
                AnimatedOpacity(
                  opacity: 1 - _collapseAnimation.value,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    'Zarządzaj bazą klientów z zaawansowanymi funkcjami',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textOnPrimary.withOpacity(0.8),
                    ),
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

  Widget _buildHeaderActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search icon (visible when collapsed)
        if (_isCollapsed && !_isSearchExpanded)
          Transform.scale(
            scale: _pulseAnimation.value,
            child: IconButton(
              onPressed: _toggleSearchField,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.secondaryGold.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: AppTheme.secondaryGold,
                  size: 20,
                ),
              ),
            ),
          ),
        
        if (!_isCollapsed || widget.additionalActions != null) ...[
          const SizedBox(width: 12),
          widget.additionalActions ?? const SizedBox.shrink(),
        ],
      ],
    );
  }

  Widget _buildSearchSection() {
    return AnimatedOpacity(
      opacity: 1 - _collapseAnimation.value,
      duration: const Duration(milliseconds: 200),
      child: Row(
        children: [
          Expanded(child: _buildSearchField()),
          const SizedBox(width: 16),
          _buildActiveClientsFilter(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: TextField(
        controller: widget.searchController,
        onChanged: widget.onSearchChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Szukaj po imieniu, emailu, telefonie...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withOpacity(0.8),
          ),
          suffixIcon: widget.searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    widget.searchController.clear();
                    widget.onSearchChanged?.call('');
                  },
                  icon: Icon(
                    Icons.clear_rounded,
                    color: Colors.white.withOpacity(0.8),
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
      height: _searchExpandAnimation.value * 50,
      child: Transform.scale(
        scale: _searchExpandAnimation.value,
        child: Opacity(
          opacity: _searchExpandAnimation.value,
          child: _buildSearchField(),
        ),
      ),
    );
  }

  Widget _buildActiveClientsFilter() {
    return Container(
      decoration: BoxDecoration(
        color: widget.showActiveOnly 
            ? AppTheme.secondaryGold.withOpacity(0.3)
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.showActiveOnly 
              ? AppTheme.secondaryGold.withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onToggleActiveOnly,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.showActiveOnly 
                      ? Icons.people 
                      : Icons.people_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Aktywni (${widget.activeClientsCount})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return AnimatedOpacity(
      opacity: 1 - _collapseAnimation.value,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: widget.statsWidget ?? const SizedBox.shrink(),
      ),
    );
  }
}

/// Custom painter for animated particle background
class ParticleBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isCollapsed;

  ParticleBackgroundPainter({
    required this.animation,
    required this.isCollapsed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final particleCount = isCollapsed ? 8 : 15;
    
    for (int i = 0; i < particleCount; i++) {
      final progress = (animation.value + i * 0.1) % 1.0;
      final x = (size.width * 0.1) + (size.width * 0.8 * (i / particleCount));
      final y = size.height * 0.2 + 
          (size.height * 0.6 * math.sin(progress * 2 * math.pi));
      
      final radius = (3 + (i % 3)) * (isCollapsed ? 0.5 : 1.0);
      
      canvas.drawCircle(
        Offset(x, y),
        radius * animation.value,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticleBackgroundPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
           oldDelegate.isCollapsed != isCollapsed;
  }
}
