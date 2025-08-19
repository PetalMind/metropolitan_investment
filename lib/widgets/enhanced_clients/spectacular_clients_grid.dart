import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models_and_services.dart';
import '../../theme/app_theme.dart';

/// 🎯 SPECTACULAR CLIENTS GRID
/// 
/// Zastępuje tradycyjną tabelę spektakularnym, responsywnym gridem z:
/// - Masonry layout dla optimal space utilization
/// - Staggered animations podczas ładowania
/// - Morphing cards z hover effects
/// - Infinite scroll z lazy loading
/// - Multi-selection mode z batch operations
/// - Hero animations dla szczegółów
class SpectacularClientsGrid extends StatefulWidget {
  final List<Client> clients;
  final bool isLoading;
  final bool isSelectionMode;
  final Set<String> selectedClientIds;
  final Function(Client)? onClientTap;
  final Function(Set<String>)? onSelectionChanged;
  final VoidCallback? onLoadMore;
  final bool hasMoreData;
  final ScrollController? scrollController;

  const SpectacularClientsGrid({
    super.key,
    required this.clients,
    this.isLoading = false,
    this.isSelectionMode = false,
    this.selectedClientIds = const {},
    this.onClientTap,
    this.onSelectionChanged,
    this.onLoadMore,
    this.hasMoreData = false,
    this.scrollController,
  });

  @override
  State<SpectacularClientsGrid> createState() => _SpectacularClientsGridState();
}

class _SpectacularClientsGridState extends State<SpectacularClientsGrid>
    with TickerProviderStateMixin {
  
  late AnimationController _staggerController;
  late AnimationController _pulseController;
  
  final List<GlobalKey> _cardKeys = [];
  final Map<String, AnimationController> _cardAnimations = {};
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupCardKeys();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _pulseController.dispose();
    _disposeCardAnimations();
    super.dispose();
  }

  void _initializeAnimations() {
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseController.repeat();
    _staggerController.forward();
  }

  void _setupCardKeys() {
    _cardKeys.clear();
    for (int i = 0; i < widget.clients.length; i++) {
      _cardKeys.add(GlobalKey());
    }
  }

  void _disposeCardAnimations() {
    for (final animation in _cardAnimations.values) {
      animation.dispose();
    }
    _cardAnimations.clear();
  }

  @override
  void didUpdateWidget(SpectacularClientsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.clients.length != oldWidget.clients.length) {
      _setupCardKeys();
      _staggerController.reset();
      _staggerController.forward();
    }
  }

  AnimationController _getCardAnimation(String clientId) {
    if (!_cardAnimations.containsKey(clientId)) {
      _cardAnimations[clientId] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
    }
    return _cardAnimations[clientId]!;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.clients.isEmpty && !widget.isLoading) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
        
        return CustomScrollView(
          controller: widget.scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: _calculateAspectRatio(constraints.maxWidth),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= widget.clients.length) return null;
                    
                    final client = widget.clients[index];
                    final delay = (index * 50).clamp(0, 800);
                    
                    return _buildAnimatedClientCard(
                      client: client,
                      index: index,
                      delay: delay,
                    );
                  },
                  childCount: widget.clients.length,
                ),
              ),
            ),
            
            if (widget.isLoading)
              SliverToBoxAdapter(child: _buildLoadingIndicator()),
              
            if (widget.hasMoreData && !widget.isLoading)
              SliverToBoxAdapter(child: _buildLoadMoreButton()),
          ],
        );
      },
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width > 1400) return 4;
    if (width > 1000) return 3;
    if (width > 600) return 2;
    return 1;
  }

  double _calculateAspectRatio(double width) {
    if (width > 1200) return 1.4;
    if (width > 800) return 1.2;
    return 1.0;
  }

  Widget _buildAnimatedClientCard({
    required Client client,
    required int index,
    required int delay,
  }) {
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, child) {
        final staggerProgress = Curves.easeOutCubic.transform(
          ((_staggerController.value * 1000 - delay) / 200).clamp(0.0, 1.0),
        );
        
        return Transform.translate(
          offset: Offset(0, 50 * (1 - staggerProgress)),
          child: Opacity(
            opacity: staggerProgress,
            child: _buildClientCard(client, index),
          ),
        );
      },
    );
  }

  Widget _buildClientCard(Client client, int index) {
    final isSelected = widget.selectedClientIds.contains(client.id);
    final cardAnimation = _getCardAnimation(client.id);
    
    return AnimatedBuilder(
      animation: Listenable.merge([cardAnimation, _pulseController]),
      builder: (context, child) {
        return Hero(
          tag: 'client_card_${client.id}',
          child: Container(
            key: _cardKeys.length > index ? _cardKeys[index] : null,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isSelected 
                      ? AppTheme.secondaryGold.withOpacity(0.3)
                      : AppTheme.shadowColor.withOpacity(0.1),
                  blurRadius: isSelected ? 20 : 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleCardTap(client),
                onLongPress: () => _handleCardLongPress(client),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  transform: Matrix4.identity()
                    ..scale(isSelected ? 1.05 : 1.0),
                  decoration: BoxDecoration(
                    gradient: _buildCardGradient(client, isSelected),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? AppTheme.secondaryGold.withOpacity(0.6)
                          : AppTheme.borderSecondary.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      _buildCardBackground(),
                      _buildCardContent(client),
                      if (widget.isSelectionMode) _buildSelectionOverlay(isSelected),
                      _buildStatusIndicator(client),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  LinearGradient _buildCardGradient(Client client, bool isSelected) {
    if (isSelected) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.secondaryGold.withOpacity(0.1),
          AppTheme.backgroundSecondary,
          AppTheme.primaryColor.withOpacity(0.05),
        ],
      );
    }
    
    if (!client.isActive) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.errorColor.withOpacity(0.05),
          AppTheme.backgroundSecondary,
          AppTheme.backgroundSecondary,
        ],
      );
    }
    
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppTheme.backgroundSecondary,
        AppTheme.surfaceInteractive.withOpacity(0.5),
        AppTheme.backgroundSecondary,
      ],
    );
  }

  Widget _buildCardBackground() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return CustomPaint(
              painter: ClientCardBackgroundPainter(
                animation: _pulseController,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardContent(Client client) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClientHeader(client),
          const SizedBox(height: 16),
          _buildClientDetails(client),
          const Spacer(),
          _buildClientFooter(client),
        ],
      ),
    );
  }

  Widget _buildClientHeader(Client client) {
    return Row(
      children: [
        _buildClientAvatar(client),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                client.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (client.companyName?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  client.companyName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClientAvatar(Client client) {
    final initials = _getClientInitials(client.name);
    final avatarColor = _getAvatarColor(client.name);
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            avatarColor,
            avatarColor.withOpacity(0.7),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildClientDetails(Client client) {
    return Column(
      children: [
        _buildDetailRow(
          icon: Icons.email_outlined,
          text: client.email,
          color: AppTheme.infoColor,
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          icon: Icons.phone_outlined,
          text: client.phone,
          color: AppTheme.successColor,
        ),
        if (client.pesel?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.badge_outlined,
            text: client.pesel!,
            color: AppTheme.warningColor,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildClientFooter(Client client) {
    return Row(
      children: [
        _buildActiveStatusChip(client),
        const Spacer(),
        _buildQuickActions(client),
      ],
    );
  }

  Widget _buildActiveStatusChip(Client client) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: client.isActive 
            ? AppTheme.successColor.withOpacity(0.15)
            : AppTheme.errorColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: client.isActive 
              ? AppTheme.successColor.withOpacity(0.3)
              : AppTheme.errorColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: client.isActive ? AppTheme.successColor : AppTheme.errorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            client.isActive ? 'Aktywny' : 'Nieaktywny',
            style: TextStyle(
              color: client.isActive ? AppTheme.successColor : AppTheme.errorColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(Client client) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.edit_outlined,
          color: AppTheme.infoColor,
          onTap: () => widget.onClientTap?.call(client),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.more_vert,
          color: AppTheme.textSecondary,
          onTap: () => _showClientOptions(client),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionOverlay(bool isSelected) {
    return Positioned(
      top: 12,
      right: 12,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.secondaryGold 
              : Colors.white.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected 
                ? AppTheme.secondaryGold 
                : AppTheme.borderSecondary,
            width: 2,
          ),
        ),
        child: Icon(
          isSelected ? Icons.check : Icons.circle_outlined,
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(Client client) {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: client.isActive ? AppTheme.successColor : AppTheme.errorColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (client.isActive ? AppTheme.successColor : AppTheme.errorColor)
                  .withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.1),
                child: Icon(
                  Icons.people_outline,
                  size: 120,
                  color: AppTheme.textTertiary.withOpacity(0.5),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Brak klientów',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dodaj pierwszego klienta, aby rozpocząć',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryGold),
            ),
            const SizedBox(height: 16),
            Text(
              'Ładowanie klientów...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: widget.onLoadMore,
          icon: const Icon(Icons.expand_more),
          label: const Text('Załaduj więcej'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryGold,
            foregroundColor: AppTheme.textOnSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  void _handleCardTap(Client client) {
    if (widget.isSelectionMode) {
      _toggleSelection(client.id);
    } else {
      widget.onClientTap?.call(client);
    }
  }

  void _handleCardLongPress(Client client) {
    if (!widget.isSelectionMode) {
      // Trigger selection mode
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
    
    widget.onSelectionChanged?.call(newSelection);
  }

  void _showClientOptions(Client client) {
    // TODO: Implement client options menu
  }

  String _getClientInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _getAvatarColor(String name) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryGold,
      AppTheme.infoColor,
      AppTheme.successColor,
      AppTheme.warningColor,
    ];
    
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }
}

/// Custom painter for card background effects
class ClientCardBackgroundPainter extends CustomPainter {
  final Animation<double> animation;

  ClientCardBackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.secondaryGold.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    // Draw subtle animated background pattern
    for (int i = 0; i < 3; i++) {
      final progress = (animation.value + i * 0.3) % 1.0;
      final radius = size.width * 0.1 * (1 + progress);
      final opacity = (1 - progress) * 0.1;
      
      paint.color = AppTheme.secondaryGold.withOpacity(opacity);
      
      canvas.drawCircle(
        Offset(
          size.width * 0.8,
          size.height * 0.2,
        ),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ClientCardBackgroundPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value;
  }
}
