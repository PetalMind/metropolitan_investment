import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';

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
  
  // 🚀 NOWE: Dane inwestycji i kapitału
  final Map<String, InvestorSummary>? investorSummaries; // clientId -> InvestorSummary
  final Map<String, List<Investment>>? clientInvestments; // clientId -> List<Investment>

  SpectacularClientsGrid({
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
    this.investorSummaries, // 🚀 NOWE
    this.clientInvestments, // 🚀 NOWE
  });

  @override
  State<SpectacularClientsGrid> createState() => _SpectacularClientsGridState();
}

class _SpectacularClientsGridState extends State<SpectacularClientsGrid>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late AnimationController _pulseController;

  // 🚀 PREMIUM ANIMATIONS - tylko dla TOP 50 inwestorów
  late AnimationController _premiumShimmerController;
  late AnimationController _premiumGlowController;
  late AnimationController _premiumFloatController;

  final List<GlobalKey> _cardKeys = [];
  final Map<String, AnimationController> _cardAnimations = {};
  
  // 🚀 TOP INVESTORS - identyfikacja top 50 inwestorów
  Set<String> _topInvestorIds = {};

  @override
  void initState() {
    super.initState();
    print(
      '🎨 [SpectacularClientsGrid] initState - klienci: ${widget.clients.length}',
    );
    print(
      '💰 [SpectacularClientsGrid] initState - dane inwestycji: ${widget.investorSummaries?.length ?? 0}',
    );
    _initializeAnimations();
    _setupCardKeys();
    _identifyTopInvestors();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _pulseController.dispose();
    _premiumShimmerController.dispose();
    _premiumGlowController.dispose();
    _premiumFloatController.dispose();
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

    // 🚀 PREMIUM ANIMATIONS - tylko dla TOP 50 inwestorów
    _premiumShimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _premiumGlowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _premiumFloatController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _pulseController.repeat();
    _staggerController.forward();
    
    // 🚀 Uruchom premium animacje
    _premiumShimmerController.repeat(reverse: true);
    _premiumGlowController.repeat(reverse: true);
    _premiumFloatController.repeat(reverse: true);
  }

  /// 🚀 IDENTYFIKUJ TOP 50 INWESTORÓW
  void _identifyTopInvestors() {
    if (widget.investorSummaries == null || widget.investorSummaries!.isEmpty) {
      _topInvestorIds.clear();
      print(
        '🚫 [SpectacularClientsGrid] Brak danych inwestycji - premium animacje wyłączone',
      );
      return;
    }

    // Sortuj klientów po całkowitym kapitale pozostałym (malejąco)
    final sortedClients =
        widget.clients.where((client) {
          final summary = widget.investorSummaries![client.id];
          return summary != null && summary.totalRemainingCapital > 0;
        }).toList()..sort((a, b) {
          final summaryA = widget.investorSummaries![a.id]!;
          final summaryB = widget.investorSummaries![b.id]!;
          return summaryB.totalRemainingCapital.compareTo(
            summaryA.totalRemainingCapital,
          );
        });

    // Weź top 50 inwestorów
    _topInvestorIds = sortedClients.take(50).map((client) => client.id).toSet();

    print('🎯 [SpectacularClientsGrid] TOP 50 INWESTORÓW ZIDENTYFIKOWANYCH:');
    print('   - Łącznie klientów z danymi inwestycji: ${sortedClients.length}');
    print('   - Top 50 inwestorów: ${_topInvestorIds.length}');
    if (_topInvestorIds.isNotEmpty) {
      final topInvestor = sortedClients.first;
      final topSummary = widget.investorSummaries![topInvestor.id]!;
      print(
        '   - Największy inwestor: ${topInvestor.name} - ${topSummary.totalRemainingCapital.toStringAsFixed(2)} PLN',
      );
      print('   - Premium animacje AKTYWNE dla top inwestorów!');
    }
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

    if (widget.clients.length != oldWidget.clients.length ||
        widget.investorSummaries != oldWidget.investorSummaries) {
      print('🔄 [SpectacularClientsGrid] didUpdateWidget - zmiana danych!');
      print(
        '   - Klienci: ${oldWidget.clients.length} -> ${widget.clients.length}',
      );
      print(
        '   - Dane inwestycji: ${oldWidget.investorSummaries?.length ?? 0} -> ${widget.investorSummaries?.length ?? 0}',
      );
      _setupCardKeys();
      _identifyTopInvestors(); // 🚀 Re-identify top investors
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
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index >= widget.clients.length) return null;

                  final client = widget.clients[index];
                  final delay = (index * 50).clamp(0, 800);

                  return _buildAnimatedClientCard(
                    client: client,
                    index: index,
                    delay: delay,
                  );
                }, childCount: widget.clients.length),
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
    if (width > 400) return 1;
    return 1; // Mobile: zawsze 1 kolumna dla wąskich ekranów
  }

  double _calculateAspectRatio(double width) {
    if (width > 1200) return 1.4;
    if (width > 800) return 1.2;
    if (width > 600) return 1.0;
    return 0.8; // Mobile: niższe karty dla lepszego wykorzystania przestrzeni
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
    final isTopInvestor = _topInvestorIds.contains(
      client.id,
    ); // 🚀 Czy to top inwestor?

    // 🚀 DEBUG: Log premium status
    if (isTopInvestor) {
      print(
        '✨ [SpectacularClientsGrid] ${client.name} jest TOP INWESTOREM - premium animacje włączone!',
      );
    }

    final cardAnimation = _getCardAnimation(client.id);

    return AnimatedBuilder(
      animation: Listenable.merge([
        cardAnimation,
        _pulseController,
        // 🚀 Dodaj premium animacje tylko dla top inwestorów
        if (isTopInvestor) ...[
          _premiumShimmerController,
          _premiumGlowController,
          _premiumFloatController,
        ],
      ]),
      builder: (context, child) {
        // 🚀 Oblicz premium efekty tylko dla top inwestorów
        final premiumOffset = isTopInvestor
            ? Offset(0, sin(_premiumFloatController.value * 2 * pi) * 3)
            : Offset.zero;

        final premiumScale = isTopInvestor
            ? 1.0 + (_premiumGlowController.value * 0.02)
            : 1.0;

        return Transform.translate(
          offset: premiumOffset,
          child: Transform.scale(
            scale: premiumScale,
            child: Hero(
              tag: 'client_card_${client.id}',
              child: Container(
                key: _cardKeys.length > index ? _cardKeys[index] : null,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _buildCardShadows(
                    client,
                    isSelected,
                    isTopInvestor,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _handleCardTap(client);
                    },
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      _handleCardLongPress(client);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      transform: Matrix4.identity()
                        ..scale(isSelected ? 1.02 : 1.0),
                      decoration: BoxDecoration(
                        gradient: _buildCardGradient(
                          client,
                          isSelected,
                          isTopInvestor,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getBorderColor(
                            client,
                            isSelected,
                            isTopInvestor,
                          ),
                          width: _getBorderWidth(
                            client,
                            isSelected,
                            isTopInvestor,
                          ),
                        ),
                      ),
                      child: Stack(
                        children: [
                          _buildCardBackground(isTopInvestor),
                          _buildCardContent(client),
                          if (widget.isSelectionMode)
                            _buildSelectionOverlay(isSelected),
                          _buildStatusIndicator(client),
                          if (isTopInvestor)
                            _buildPremiumCrownIndicator(), // 🚀 Korona dla top inwestorów
                        ],
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

  /// 🚀 SHADOWS DLA KART - uwzględnia top inwestorów
  List<BoxShadow> _buildCardShadows(
    Client client,
    bool isSelected,
    bool isTopInvestor,
  ) {
    final shadows = <BoxShadow>[];

    // Main card shadow
    shadows.add(
      BoxShadow(
        color: isSelected
            ? AppThemePro.accentGold.withOpacity(0.4)
            : AppThemePro.overlayMedium.withOpacity(0.15),
        blurRadius: isSelected ? 25 : 15,
        spreadRadius: isSelected ? 3 : 1,
        offset: const Offset(0, 8),
      ),
    );

    // 🚀 PREMIUM GLOW dla top inwestorów
    if (isTopInvestor) {
      shadows.add(
        BoxShadow(
          color: AppThemePro.accentGold.withOpacity(
            0.3 + (_premiumGlowController.value * 0.2),
          ),
          blurRadius: 30 + (_premiumGlowController.value * 20),
          spreadRadius: 2 + (_premiumGlowController.value * 3),
          offset: const Offset(0, 0),
        ),
      );
    }

    // Subtle glow effect for selected
    if (isSelected) {
      shadows.add(
        BoxShadow(
          color: AppThemePro.accentGold.withOpacity(0.2),
          blurRadius: 40,
          spreadRadius: 0,
          offset: const Offset(0, 0),
        ),
      );
    }

    // Inner highlight
    shadows.add(
      BoxShadow(
        color: Colors.white.withOpacity(0.05),
        blurRadius: 8,
        spreadRadius: -2,
        offset: const Offset(0, -2),
      ),
    );

    return shadows;
  }

  LinearGradient _buildCardGradient(
    Client client,
    bool isSelected, [
    bool isTopInvestor = false,
  ]) {
    if (isSelected) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppThemePro.accentGold.withOpacity(0.15),
          AppThemePro.backgroundSecondary.withOpacity(0.95),
          AppThemePro.backgroundPrimary,
          AppThemePro.accentGold.withOpacity(0.08),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      );
    }

    if (!client.isActive) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppThemePro.statusError.withOpacity(0.08),
          AppThemePro.backgroundSecondary.withOpacity(0.95),
          AppThemePro.backgroundPrimary,
          AppThemePro.neutralGray.withOpacity(0.1),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      );
    }

    // 🚀 PREMIUM GRADIENT dla top inwestorów
    if (isTopInvestor) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppThemePro.accentGold.withOpacity(
            0.12 + (_premiumShimmerController.value * 0.08),
          ),
          AppThemePro.backgroundSecondary.withOpacity(0.98),
          AppThemePro.backgroundPrimary,
          AppThemePro.accentGold.withOpacity(
            0.06 + (_premiumShimmerController.value * 0.04),
          ),
        ],
        stops: const [0.0, 0.4, 0.8, 1.0],
      );
    }

    // Professional investment card gradient
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppThemePro.backgroundSecondary.withOpacity(0.98),
        AppThemePro.backgroundPrimary,
        AppThemePro.backgroundSecondary.withOpacity(0.95),
        AppThemePro.accentGold.withOpacity(0.03),
      ],
      stops: const [0.0, 0.4, 0.8, 1.0],
    );
  }

  Color _getBorderColor(Client client, bool isSelected, bool isTopInvestor) {
    if (isSelected) {
      return AppThemePro.accentGold.withOpacity(0.8);
    }

    if (isTopInvestor) {
      return AppThemePro.accentGold.withOpacity(
        0.6 + (_premiumGlowController.value * 0.2),
      );
    }

    return AppThemePro.borderSecondary.withOpacity(0.3);
  }

  double _getBorderWidth(Client client, bool isSelected, bool isTopInvestor) {
    if (isSelected) return 2.5;
    if (isTopInvestor) return 2.0 + (_premiumGlowController.value * 0.5);
    return 1.2;
  }

  Widget _buildCardBackground([bool isTopInvestor = false]) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return CustomPaint(
              painter: ProfessionalClientCardPainter(
                animation: _pulseController,
                isSelected: widget.selectedClientIds.contains,
                isTopInvestor: isTopInvestor,
                premiumShimmer: isTopInvestor
                    ? _premiumShimmerController
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardContent(Client client, [bool isTopInvestor = false]) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsywny padding - mniejszy na mobile
        final isMobile = constraints.maxWidth < 400;
        final padding = isMobile ? 12.0 : 20.0;
        final spacing = isMobile ? 12.0 : 16.0;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClientHeader(client, isMobile, isTopInvestor),
              SizedBox(height: spacing),
              _buildClientDetails(client, isMobile),
              const Spacer(),
              _buildClientFooter(client, isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumCrownIndicator() {
    return Positioned(
      top: 8,
      right: 8,
      child: AnimatedBuilder(
        animation: _premiumGlowController,
        builder: (context, child) {
          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppThemePro.accentGold.withOpacity(
                    0.8 + (_premiumGlowController.value * 0.2),
                  ),
                  AppThemePro.accentGold.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppThemePro.accentGold.withOpacity(0.6),
                  blurRadius: 8 + (_premiumGlowController.value * 4),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(Icons.star, color: Colors.white, size: 14),
          );
        },
      ),
    );
  }

  Widget _buildClientHeader(
    Client client, [
    bool isMobile = false,
    bool isTopInvestor = false,
  ]) {
    return Row(
      children: [
        _buildClientAvatar(client, isMobile),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    AppThemePro.textPrimary,
                    AppThemePro.accentGold.withOpacity(0.8),
                  ],
                ).createShader(bounds),
                child: Text(
                  client.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 15 : 17,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (client.companyName?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  client.companyName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.textSecondary.withOpacity(0.9),
                    fontStyle: FontStyle.italic,
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w500,
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

  Widget _buildClientAvatar(Client client, [bool isMobile = false]) {
    final initials = _getClientInitials(client.name);
    final avatarColor = _getAvatarColor(client.name);
    final size = isMobile ? 40.0 : 50.0; // Mniejszy avatar na mobile
    final fontSize = isMobile ? 14.0 : 18.0; // Mniejsza czcionka na mobile

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            avatarColor.withOpacity(0.9),
            avatarColor,
            avatarColor.withOpacity(0.8),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppThemePro.accentGold.withOpacity(0.3), 
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: avatarColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: fontSize,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientDetails(Client client, [bool isMobile = false]) {
    final spacing = isMobile ? 6.0 : 8.0;
    
    // 🚀 NOWE: Pobierz dane inwestycji dla klienta
    final investorSummary = widget.investorSummaries?[client.id];
    // final investments = widget.clientInvestments?[client.id] ?? []; // Na razie nieużywane
    
    return Column(
      children: [
        // 💰 NOWE: Informacje o kapitale i inwestycjach (PRIORYTET)
        if (investorSummary != null) ...[
          _buildDetailRow(
            icon: Icons.account_balance_wallet_outlined,
            text: '${CurrencyFormatter.formatCurrency(investorSummary.totalRemainingCapital)} PLN',
            color: AppTheme.secondaryGold,
            isMobile: isMobile,
          ),
          SizedBox(height: spacing),
          _buildDetailRow(
            icon: Icons.trending_up_outlined,
            text: '${investorSummary.investmentCount} inwestycji',
            color: AppTheme.infoColor,
            isMobile: isMobile,
          ),
          if (investorSummary.capitalSecuredByRealEstate > 0) ...[
            SizedBox(height: spacing),
            _buildDetailRow(
              icon: Icons.security_outlined,
              text: '${CurrencyFormatter.formatCurrency(investorSummary.capitalSecuredByRealEstate)} PLN zabezp.',
              color: AppTheme.successColor,
              isMobile: isMobile,
            ),
          ],
          SizedBox(height: spacing),
        ],
        
        // Podstawowe dane kontaktowe (DRUGORZĘDNE)
        _buildDetailRow(
          icon: Icons.email_outlined,
          text: client.email.isEmpty ? 'Brak email' : client.email,
          color: client.email.isEmpty ? AppTheme.warningColor : AppTheme.infoColor,
          isMobile: isMobile,
        ),
        SizedBox(height: spacing),
        _buildDetailRow(
          icon: Icons.phone_outlined,
          text: client.phone.isEmpty ? 'Brak telefonu' : client.phone,
          color: client.phone.isEmpty ? AppTheme.warningColor : AppTheme.successColor,
          isMobile: isMobile,
        ),
        
        // PESEL (jeśli dostępny)
        if (client.pesel?.isNotEmpty == true) ...[
          SizedBox(height: spacing),
          _buildDetailRow(
            icon: Icons.badge_outlined,
            text: client.pesel!,
            color: AppTheme.warningColor,
            isMobile: isMobile,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String text,
    required Color color,
    bool isMobile = false,
  }) {
    final iconSize = isMobile ? 14.0 : 16.0;
    final padding = isMobile ? 4.0 : 6.0;
    final spacing = isMobile ? 6.0 : 8.0;
    
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: iconSize, color: color),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(
              color: AppThemePro.textSecondary.withOpacity(0.9),
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildClientFooter(Client client, [bool isMobile = false]) {
    return Row(
      children: [
        _buildActiveStatusChip(client, isMobile),
        const Spacer(),
        // Ukryj przyciski akcji - zgodnie z wymaganiem
        // _buildQuickActions(client),
      ],
    );
  }

  Widget _buildActiveStatusChip(Client client, [bool isMobile = false]) {
    final horizontalPadding = isMobile ? 8.0 : 12.0;
    final verticalPadding = isMobile ? 4.0 : 6.0;
    final fontSize = isMobile ? 10.0 : 12.0;
    final dotSize = isMobile ? 6.0 : 8.0;
    final spacing = isMobile ? 4.0 : 6.0;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: client.isActive
              ? [
                  AppThemePro.statusSuccess.withOpacity(0.2),
                  AppThemePro.statusSuccess.withOpacity(0.1),
                ]
              : [
                  AppThemePro.statusError.withOpacity(0.2),
                  AppThemePro.statusError.withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: client.isActive
              ? AppThemePro.statusSuccess.withOpacity(0.4)
              : AppThemePro.statusError.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: client.isActive
                ? AppThemePro.statusSuccess.withOpacity(0.2)
                : AppThemePro.statusError.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: client.isActive
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: spacing),
          Text(
            client.isActive ? 'AKTYWNY' : 'NIEAKTYWNY',
            style: TextStyle(
              color: client.isActive
                  ? AppThemePro.statusSuccess
                  : AppThemePro.statusError,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Usunięte metody _buildQuickActions i _buildActionButton
  // zgodnie z wymaganiem usunięcia przycisków edycji i menu

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
          gradient: RadialGradient(
            colors: [
              client.isActive 
                  ? AppThemePro.statusSuccess 
                  : AppThemePro.statusError,
              client.isActive 
                  ? AppThemePro.statusSuccess.withOpacity(0.8)
                  : AppThemePro.statusError.withOpacity(0.8),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (client.isActive
                      ? AppThemePro.statusSuccess
                      : AppThemePro.statusError)
                  .withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 3,
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
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Dodaj pierwszego klienta, aby rozpocząć',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textTertiary),
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
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

  // Usunięta metoda _showClientOptions - nie jest już potrzebna

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

/// 🎨 Professional custom painter for investment-grade client cards
class ProfessionalClientCardPainter extends CustomPainter {
  final Animation<double> animation;
  final bool Function(String) isSelected;
  final bool isTopInvestor;
  final Animation<double>? premiumShimmer;

  ProfessionalClientCardPainter({
    required this.animation,
    required this.isSelected,
    this.isTopInvestor = false,
    this.premiumShimmer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Professional gradient mesh background
    final backgroundPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.7, -0.3),
        radius: 1.2,
        colors: [
          AppThemePro.accentGold.withOpacity(0.08),
          AppThemePro.accentGold.withOpacity(0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Animated professional particles
    final particlePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final progress = (animation.value + i * 0.2) % 1.0;
      final opacity = (sin(progress * 2 * pi) * 0.5 + 0.5) * 0.15;
      
      final x = size.width * (0.2 + (i * 0.15));
      final y = size.height * (0.1 + progress * 0.8);
      final radius = (2 + i * 0.5) * (1 + progress * 0.3);

      particlePaint.color = AppThemePro.accentGold.withOpacity(opacity);

      canvas.drawCircle(Offset(x, y), radius, particlePaint);
    }

    // Professional corner accents
    final accentPaint = Paint()
      ..color = AppThemePro.accentGold.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Top-left accent
    final topLeftPath = Path();
    topLeftPath.moveTo(0, size.height * 0.2);
    topLeftPath.lineTo(0, 0);
    topLeftPath.lineTo(size.width * 0.2, 0);
    canvas.drawPath(topLeftPath, accentPaint);

    // Bottom-right accent
    final bottomRightPath = Path();
    bottomRightPath.moveTo(size.width * 0.8, size.height);
    bottomRightPath.lineTo(size.width, size.height);
    bottomRightPath.lineTo(size.width, size.height * 0.8);
    canvas.drawPath(bottomRightPath, accentPaint);

    // Subtle investment-grade pattern
    final patternPaint = Paint()
      ..color = AppThemePro.accentGold.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw subtle grid pattern
    for (double x = size.width * 0.1; x < size.width; x += size.width * 0.15) {
      canvas.drawLine(
        Offset(x, size.height * 0.1),
        Offset(x, size.height * 0.9),
        patternPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ProfessionalClientCardPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value;
  }
}
