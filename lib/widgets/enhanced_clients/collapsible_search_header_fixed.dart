import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';

/// 🎭 COLLAPSIBLE SEARCH HEADER Z CAŁKOWITYM UKRYWANIEM STATYSTYK
/// 
/// Inteligentny header który:
/// - Zwija się podczas przewijania w dół (ukrywa statystyki CAŁKOWICIE)
/// - Rozwija się podczas przewijania w górę  
/// - Transformuje pole wyszukiwania w ikonę w trybie zwiniętym
/// - Smooth animations z physics-based motion
/// - Statystyki znikają całkowicie podczas przewijania
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
  final bool isCollapsed; // 🚀 KONTROLUJE CAŁKOWITE UKRYWANIE STATYSTYK

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
    this.isCollapsed = false,
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
  late Animation<double> _statsHideAnimation;
  
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
    
    _statsHideAnimation = CurvedAnimation(
      parent: _collapseController,
      curve: Curves.easeInOutQuart,
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

  @override
  void didUpdateWidget(CollapsibleSearchHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reaguj na zmiany zewnętrznego stanu collapsed
    if (widget.isCollapsed != oldWidget.isCollapsed) {
      if (widget.isCollapsed) {
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
    if (!widget.isCollapsed) return;
    
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
      animation: Listenable.merge([_collapseAnimation, _searchExpandAnimation, _pulseAnimation, _statsHideAnimation]),
      builder: (context, child) {
        // 🚀 DYNAMICZNA WYSOKOŚĆ - 240px gdy rozwinięty (więcej miejsca na statystyki), 80px gdy zwinięty
        final headerHeight = widget.isCollapsed ? 80.0 : 240.0;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: headerHeight,
          decoration: BoxDecoration(
            // 🎨 NIEPRZEZROCZYSTE TŁO - lista będzie pod headerem
            color: AppTheme.backgroundPrimary, // Solidne tło
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.9), // Mniej przezroczystości
                AppTheme.secondaryGold.withOpacity(0.2),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 3),
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
                  vertical: widget.isCollapsed ? 12.0 : 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🎨 STATYSTYKI NA GÓRZE - ELASTYCZNA WYSOKOŚĆ GDY WIDOCZNE
                    if (!widget.isCollapsed && widget.statsWidget != null) ...[
                      Flexible(
                        child: widget.statsWidget!,
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    _buildHeaderContent(),
                    
                    if (!widget.isCollapsed) ...[
                      const SizedBox(height: 16),
                      _buildSearchSection(),
                    ],
                    
                    // Expanded search in collapsed mode
                    if (widget.isCollapsed && _isSearchExpanded) ...[
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
          animationValue: _pulseAnimation.value,
          isCollapsed: widget.isCollapsed,
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
              Text(
                widget.isSelectionMode ? '✉️ Wybór klientów' : '👥 Klienci',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.isCollapsed ? 20 : 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              
              if (!widget.isCollapsed) ...[
                const SizedBox(height: 4),
                Text(
                  widget.isSelectionMode 
                      ? 'Wybierz klientów do wysłania emaila'
                      : 'Zarządzanie bazą klientów',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // 🎯 COLLAPSED SEARCH ICON
        if (widget.isCollapsed && !_isSearchExpanded)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: GestureDetector(
                  onTap: _toggleSearchField,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              );
            },
          ),
          
        if (widget.additionalActions != null)
          widget.additionalActions!,
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
    return AnimatedOpacity(
      opacity: 1 - _collapseAnimation.value,
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        label: Text(
          'Aktywni (${widget.activeClientsCount})',
          style: TextStyle(
            color: widget.showActiveOnly ? Colors.white : Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: widget.showActiveOnly,
        onSelected: (bool selected) => widget.onToggleActiveOnly?.call(),
        selectedColor: AppTheme.secondaryGold.withOpacity(0.3),
        checkmarkColor: Colors.white,
        backgroundColor: Colors.white.withOpacity(0.1),
        side: BorderSide(
          color: widget.showActiveOnly
              ? AppTheme.secondaryGold
              : Colors.white.withOpacity(0.3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        elevation: widget.showActiveOnly ? 4 : 0,
        shadowColor: AppTheme.secondaryGold.withOpacity(0.3),
      ),
    );
  }
}

/// 🎨 PARTICLE BACKGROUND PAINTER
/// 
/// Rysuje animowane cząsteczki w tle header'a
class ParticleBackgroundPainter extends CustomPainter {
  final double animationValue;
  final bool isCollapsed;

  ParticleBackgroundPainter({
    required this.animationValue,
    required this.isCollapsed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw animated particles
    for (int i = 0; i < 20; i++) {
      final x = (size.width / 20) * i + (animationValue * 10);
      final y = math.sin((i * 0.5) + (animationValue * 2)) * 20 + size.height / 2;
      final radius = isCollapsed ? 1.0 : 2.0;
      
      canvas.drawCircle(
        Offset(x % size.width, y),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticleBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.isCollapsed != isCollapsed;
  }
}
