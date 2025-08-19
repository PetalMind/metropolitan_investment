import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models_and_services.dart';
import '../../theme/app_theme.dart';

/// 🎨 CLIENTS GRID VIEW
/// 
/// Spektakularne karty klientów z:
/// - Staggered animations z physics-based timing
/// - Contextual color coding z visual hierarchy
/// - Micro-interactions z haptic feedback  
/// - Multi-selection z smooth transitions
/// - Responsive grid z adaptive layouts
/// - Parallax effects z depth perception
class ClientsGridView extends StatefulWidget {
  final List<Client> clients;
  final ClientViewMode viewMode;
  final bool isCompactMode;
  final Set<String> selectedClientIds;
  final bool isSelectionMode;
  final double animationProgress;
  final Function(Set<String>) onSelectionChanged;
  final Function(Client) onClientTap;
  final bool canEdit;

  const ClientsGridView({
    super.key,
    required this.clients,
    required this.viewMode,
    required this.isCompactMode,
    required this.selectedClientIds,
    required this.isSelectionMode,
    required this.animationProgress,
    required this.onSelectionChanged,
    required this.onClientTap,
    required this.canEdit,
  });

  @override
  State<ClientsGridView> createState() => _ClientsGridViewState();
}

class _ClientsGridViewState extends State<ClientsGridView>
    with TickerProviderStateMixin {
  
  late AnimationController _staggerController;
  late AnimationController _selectionController;
  late AnimationController _hoverController;
  
  final Map<String, AnimationController> _cardControllers = {};
  final Map<String, Animation<double>> _cardScaleAnimations = {};
  final Map<String, Animation<Offset>> _cardSlideAnimations = {};
  
  final ScrollController _scrollController = ScrollController();
  String? _hoveredClientId;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _createCardAnimations();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _selectionController.dispose();
    _hoverController.dispose();
    _scrollController.dispose();
    
    for (final controller in _cardControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  void _initializeAnimations() {
    _staggerController = AnimationController(
      duration: Duration(milliseconds: 100 * widget.clients.length.clamp(0, 20)),
      vsync: this,
    );
    
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  void _createCardAnimations() {
    // Clear existing controllers
    for (final controller in _cardControllers.values) {
      controller.dispose();
    }
    _cardControllers.clear();
    _cardScaleAnimations.clear();
    _cardSlideAnimations.clear();
    
    // Create new animations for each client
    for (int i = 0; i < widget.clients.length; i++) {
      final client = widget.clients[i];
      final controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      
      _cardControllers[client.id] = controller;
      
      _cardScaleAnimations[client.id] = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(
          i * 0.1,
          1.0,
          curve: Curves.elasticOut,
        ),
      ));
      
      _cardSlideAnimations[client.id] = Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(
          i * 0.05,
          1.0,
          curve: Curves.easeOutCubic,
        ),
      ));
    }
    
    // Start staggered animation
    _startStaggeredAnimation();
  }

  void _startStaggeredAnimation() {
    for (int i = 0; i < widget.clients.length; i++) {
      final client = widget.clients[i];
      final controller = _cardControllers[client.id];
      
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted && controller != null) {
          controller.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(ClientsGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.clients.length != oldWidget.clients.length ||
        widget.clients != oldWidget.clients) {
      _createCardAnimations();
    }
    
    if (widget.isSelectionMode != oldWidget.isSelectionMode) {
      if (widget.isSelectionMode) {
        _selectionController.forward();
      } else {
        _selectionController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.clients.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: _buildViewByMode(),
    );
  }

  Widget _buildViewByMode() {
    switch (widget.viewMode) {
      case ClientViewMode.grid:
        return _buildGridView();
      case ClientViewMode.list:
        return _buildListView();
      case ClientViewMode.cards:
        return _buildCardsView();
      case ClientViewMode.timeline:
        return _buildTimelineView();
    }
  }

  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
        final childAspectRatio = widget.isCompactMode ? 1.3 : 1.1;
        
        return GridView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: widget.clients.length,
          itemBuilder: (context, index) {
            final client = widget.clients[index];
            return _buildClientCard(client, index);
          },
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      itemCount: widget.clients.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final client = widget.clients[index];
        return _buildClientListTile(client, index);
      },
    );
  }

  Widget _buildCardsView() {
    return ListView.separated(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      itemCount: widget.clients.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final client = widget.clients[index];
        return _buildClientExpandedCard(client, index);
      },
    );
  }

  Widget _buildTimelineView() {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      itemCount: widget.clients.length,
      itemBuilder: (context, index) {
        final client = widget.clients[index];
        return _buildTimelineItem(client, index);
      },
    );
  }

  Widget _buildClientCard(Client client, int index) {
    final isSelected = widget.selectedClientIds.contains(client.id);
    final isHovered = _hoveredClientId == client.id;
    final scaleAnimation = _cardScaleAnimations[client.id];
    final slideAnimation = _cardSlideAnimations[client.id];
    
    if (scaleAnimation == null || slideAnimation == null) {
      return const SizedBox();
    }

    // Calculate parallax offset
    final parallaxOffset = _calculateParallaxOffset(index);

    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: slideAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: Transform.translate(
              offset: Offset(0, parallaxOffset),
              child: MouseRegion(
                onEnter: (_) => _onHover(client.id),
                onExit: (_) => _onHover(null),
                child: GestureDetector(
                  onTap: () => _onClientTap(client),
                  onLongPress: () => _onClientLongPress(client),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.identity()
                      ..scale(isHovered ? 1.02 : 1.0)
                      ..rotateX(isHovered ? -0.01 : 0.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _getClientGradient(client),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _getClientColor(client).withOpacity(
                              isHovered ? 0.3 : 0.15,
                            ),
                            blurRadius: isHovered ? 20 : 12,
                            offset: Offset(0, isHovered ? 8 : 4),
                          ),
                        ],
                        border: isSelected ? Border.all(
                          color: AppTheme.secondaryGold,
                          width: 3,
                        ) : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // Background pattern
                            _buildCardBackground(client),
                            
                            // Content
                            _buildCardContent(client),
                            
                            // Selection overlay
                            if (widget.isSelectionMode)
                              _buildSelectionOverlay(isSelected),
                            
                            // Status indicators
                            _buildStatusIndicators(client),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardBackground(Client client) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getClientColor(client).withOpacity(0.1),
              _getClientColor(client).withOpacity(0.05),
            ],
          ),
        ),
        child: CustomPaint(
          painter: ClientCardPatternPainter(
            color: _getClientColor(client),
            opacity: 0.03,
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(Client client) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Avatar
              _buildClientAvatar(client),
              
              const SizedBox(width: 12),
              
              // Name and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name.length > 20
                          ? '${client.name.substring(0, 20)}...'
                          : client.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    _buildClientSubtitle(client),
                  ],
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Metrics row
          _buildClientMetrics(client),
          
          const SizedBox(height: 12),
          
          // Action buttons
          if (!widget.isSelectionMode)
            _buildCardActions(client),
        ],
      ),
    );
  }

  Widget _buildClientAvatar(Client client) {
    final color = _getClientColor(client);
    final initials = _getClientInitials(client.name);
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildClientSubtitle(Client client) {
    return Row(
      children: [
        // Status indicator
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: client.isActive 
                ? AppTheme.successColor 
                : AppTheme.errorColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        
        const SizedBox(width: 6),
        
        Expanded(
          child: Text(
            client.isActive ? 'Aktywny' : 'Nieaktywny',
            style: TextStyle(
              color: client.isActive 
                  ? AppTheme.successColor 
                  : AppTheme.errorColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientMetrics(Client client) {
    // TODO: Get real metrics from service
    final metrics = _getClientMetrics(client);
    
    return Row(
      children: [
        _buildMetricChip(
          Icons.account_balance_wallet_rounded,
          '${metrics['investments']}',
          'inwestycji',
          AppTheme.secondaryGold,
        ),
        
        const SizedBox(width: 8),
        
        _buildMetricChip(
          Icons.trending_up_rounded,
          '${metrics['value']}k',
          'wartość',
          AppTheme.infoColor,
        ),
      ],
    );
  }

  Widget _buildMetricChip(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardActions(Client client) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            Icons.visibility_rounded,
            'Szczegóły',
            () => widget.onClientTap(client),
            AppTheme.infoColor,
          ),
        ),
        
        if (widget.canEdit) ...[
          const SizedBox(width: 8),
          
          _buildActionButton(
            Icons.edit_rounded,
            '',
            () => _onEditClient(client),
            AppTheme.warningColor,
            isIconOnly: true,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color color, {
    bool isIconOnly = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isIconOnly ? 8 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              if (!isIconOnly) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionOverlay(bool isSelected) {
    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.secondaryGold.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: isSelected ? Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.secondaryGold,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryGold.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ) : null,
      ),
    );
  }

  Widget _buildStatusIndicators(Client client) {
    return Positioned(
      top: 12,
      right: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TODO: Add more status indicators based on client metrics
          if (client.isActive)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.successColor,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.successColor.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClientListTile(Client client, int index) {
    final isSelected = widget.selectedClientIds.contains(client.id);
    final scaleAnimation = _cardScaleAnimations[client.id];
    
    if (scaleAnimation == null) return const SizedBox();

    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, child) {
        return ScaleTransition(
          scale: scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(
                color: AppTheme.secondaryGold,
                width: 2,
              ) : Border.all(
                color: AppTheme.borderSecondary,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _buildClientAvatar(client),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        client.email,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                _buildClientMetrics(client),
                
                const SizedBox(width: 16),
                
                if (!widget.isSelectionMode)
                  _buildActionButton(
                    Icons.arrow_forward_rounded,
                    '',
                    () => widget.onClientTap(client),
                    AppTheme.infoColor,
                    isIconOnly: true,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClientExpandedCard(Client client, int index) {
    // TODO: Implement expanded card view
    return _buildClientCard(client, index);
  }

  Widget _buildTimelineItem(Client client, int index) {
    final scaleAnimation = _cardScaleAnimations[client.id];
    
    if (scaleAnimation == null) return const SizedBox();

    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline connector
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getClientColor(client),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  if (index < widget.clients.length - 1)
                    Container(
                      width: 2,
                      height: 60,
                      color: AppTheme.borderSecondary,
                    ),
                ],
              ),
              
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: _buildClientCard(client, index),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 80,
            color: AppTheme.textTertiary,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Brak klientów',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Dostosuj filtry lub dodaj nowych klientów',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  int _calculateCrossAxisCount(double width) {
    if (width > 1400) return 4;
    if (width > 1000) return 3;
    if (width > 600) return 2;
    return 1;
  }

  double _calculateParallaxOffset(int index) {
    final scrollRatio = _scrollOffset / 1000;
    return math.sin(scrollRatio + index * 0.1) * 2;
  }

  Color _getClientColor(Client client) {
    // Generate color based on client name hash
    final hash = client.name.hashCode;
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryGold,
      AppTheme.infoColor,
      AppTheme.successColor,
      AppTheme.warningColor,
    ];
    return colors[hash.abs() % colors.length];
  }

  LinearGradient _getClientGradient(Client client) {
    final color = _getClientColor(client);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppTheme.backgroundSecondary,
        color.withOpacity(0.05),
      ],
    );
  }

  String _getClientInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, math.min(2, name.length)).toUpperCase();
  }

  Map<String, dynamic> _getClientMetrics(Client client) {
    // TODO: Get real metrics from service
    return {
      'investments': math.Random().nextInt(10) + 1,
      'value': math.Random().nextInt(500) + 50,
    };
  }

  void _onHover(String? clientId) {
    setState(() {
      _hoveredClientId = clientId;
    });
  }

  void _onClientTap(Client client) {
    if (widget.isSelectionMode) {
      _toggleSelection(client.id);
    } else {
      widget.onClientTap(client);
    }
  }

  void _onClientLongPress(Client client) {
    if (!widget.isSelectionMode) {
      _toggleSelection(client.id);
    }
  }

  void _toggleSelection(String clientId) {
    final newSelection = Set<String>.from(widget.selectedClientIds);
    
    if (newSelection.contains(clientId)) {
      newSelection.remove(clientId);
    } else {
      newSelection.add(clientId);
    }
    
    widget.onSelectionChanged(newSelection);
  }

  void _onEditClient(Client client) {
    // TODO: Show edit client dialog
    print('Edit client: ${client.name}');
  }
}

// Custom painter for card background patterns
class ClientCardPatternPainter extends CustomPainter {
  final Color color;
  final double opacity;

  ClientCardPatternPainter({
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw subtle geometric pattern
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        final x = (size.width / 4) * i;
        final y = (size.height / 4) * j;
        
        canvas.drawCircle(
          Offset(x, y),
          8,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ClientCardPatternPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.opacity != opacity;
  }
}

// Enums (should be imported from main screen)
enum ClientViewMode { grid, list, cards, timeline }
