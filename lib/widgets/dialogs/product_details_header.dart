import 'package:flutter/material.dart';
import '../../models_and_services.dart';

// ⭐ UJEDNOLICONY WZORZEC: Używamy UnifiedDashboardStatisticsService
// zamiast ProductDetailsService + ServerSideStatisticsService

class ProductDetailsHeader extends StatefulWidget {
  final UnifiedProduct product;
  final List<InvestorSummary> investors;
  final bool isLoadingInvestors;
  final VoidCallback onClose;
  final VoidCallback? onShowInvestors;
  final Function(bool)?
  onEditModeChanged; // ⭐ NOWE: Callback dla zmiany trybu edycji
  final Function(int)? onTabChanged; // ⭐ NOWE: Callback dla zmiany tabu
  final Future<void> Function()?
  onDataChanged; // ⭐ NOWE: Callback dla odświeżenia danych po edycji kapitału
  final bool isCollapsed; // ⭐ NOWE: Czy header jest zwinięty
  final double collapseFactor; // ⭐ NOWE: Współczynnik zwinięcia (0.0 - 1.0)

  const ProductDetailsHeader({
    super.key,
    required this.product,
    required this.investors,
    required this.isLoadingInvestors,
    required this.onClose,
    this.onShowInvestors,
    this.onEditModeChanged, // ⭐ NOWE: Callback dla zmiany trybu edycji
    this.onTabChanged, // ⭐ NOWE: Callback dla zmiany tabu
    this.onDataChanged, // ⭐ NOWE: Callback dla odświeżenia danych po edycji kapitału
    this.isCollapsed = false, // ⭐ NOWE: Domyślnie nie zwinięty
    this.collapseFactor = 1.0, // ⭐ NOWE: Domyślnie pełny rozmiar
  });
  @override
  State<ProductDetailsHeader> createState() => _ProductDetailsHeaderState();
}

class _ProductDetailsHeaderState extends State<ProductDetailsHeader>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  
  // ⭐ NOWE: Stan trybu edycji
  bool _isEditMode = false;


  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ⭐ NOWE: Metoda przełączania trybu edycji
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });

    // Powiadom parent dialog o zmianie stanu edycji
    widget.onEditModeChanged?.call(_isEditMode);

    // Jeśli włączamy tryb edycji, przełącz na zakładkę "Inwestorzy" (index 1)
    if (_isEditMode) {
      widget.onTabChanged?.call(1);

      // Pokaż komunikat z instrukcjami
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.edit, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tryb edycji włączony. Kliknij na inwestora, aby go edytować.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryAccent,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // ⭐ NOWE: Oblicz padding i wysokość na podstawie stanu zwijania
    final basePadding = isMobile ? 16.0 : 20.0;
    final padding = basePadding * widget.collapseFactor;
    final opacity = (0.3 + 0.7 * widget.collapseFactor).clamp(0.0, 1.0);

    // ⭐ DEBUG: Dodaj debug info
    print(
      '🔍 [ProductDetailsHeader] Building header for: ${widget.product.name}',
    );

    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(opacity),
            AppTheme.primaryLight.withOpacity(opacity),
            AppTheme.primaryAccent.withOpacity(opacity),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(
              0.3 * widget.collapseFactor,
            ),
            blurRadius: 15 * widget.collapseFactor,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCloseButton(),
            SizedBox(height: (isMobile ? 6 : 8) * widget.collapseFactor),
            _buildMainInfo(),
          ],
        ),
      ),
      ),
    );
  }


  Widget _buildCloseButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // ⭐ NOWE: Przycisk edycji/wyjścia z trybu edycji
        if (!_isEditMode) ...[
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3), width: 1),
            ),
            child: IconButton(
              onPressed: _toggleEditMode,
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(36, 36),
              ),
              tooltip: 'Edytuj inwestycje',
            ),
          ),
        ] else ...[
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
            ),
            child: IconButton(
              onPressed: _toggleEditMode,
              icon: const Icon(Icons.check, color: Colors.white, size: 20),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(36, 36),
              ),
              tooltip: 'Zakończ edycję',
            ),
          ),
        ],
        
        // Przycisk zamknięcia
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
            tooltip: 'Zamknij',
          ),
        ),
      ],
    );
  }


  Widget _buildMainInfo() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;


    if (isMobile || widget.isCollapsed) {
      return _buildMobileMainInfo();
    } else {
      return _buildDesktopMainInfo();
    }
  }

  Widget _buildMobileMainInfo() {
    // ⭐ NOWE: Skaluj rozmiary na podstawie współczynnika zwijania
    final iconSize = (widget.isCollapsed ? 32.0 : 48.0) * widget.collapseFactor;
    final titleFontSize =
        (widget.isCollapsed ? 16.0 : 20.0) * widget.collapseFactor;
    final spacing = 12.0 * widget.collapseFactor;

    if (widget.isCollapsed) {
      // Układ poziomy dla zwiniętego stanu
      return Row(
        children: [
          // Ikona produktu (mniejsza)
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.getProductTypeColor(
                          widget.product.productType.collectionName,
                        ).withOpacity(0.8),
                        AppTheme.getProductTypeColor(
                          widget.product.productType.collectionName,
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(iconSize * 0.33),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.getProductTypeColor(
                          widget.product.productType.collectionName,
                        ).withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getProductIcon(widget.product.productType),
                    color: Colors.white,
                    size: iconSize * 0.5,
                  ),
                ),
              );
            },
          ),

          SizedBox(width: 12),

          // Nazwa produktu w trybie zwiniętym
          Expanded(
            child: Text(
              widget.product.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
                fontSize: titleFontSize,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Status badge
          _buildStatusBadge(),
        ],
      );
    }

    // Układ pionowy dla normalnego stanu
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Górny wiersz: ikona + status badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Ikona produktu (normalna)
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.getProductTypeColor(
                            widget.product.productType.collectionName,
                          ).withOpacity(0.8),
                          AppTheme.getProductTypeColor(
                            widget.product.productType.collectionName,
                          ),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(iconSize * 0.33),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.getProductTypeColor(
                            widget.product.productType.collectionName,
                          ).withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getProductIcon(widget.product.productType),
                      color: Colors.white,
                      size: iconSize * 0.5,
                    ),
                  ),
                );
              },
            ),

            // Status badge (kompaktowy)
            _buildStatusBadge(),
          ],
        ),

        SizedBox(height: spacing),

        // Nazwa produktu
        Text(
          widget.product.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            fontSize: titleFontSize,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        SizedBox(height: spacing * 0.67),

        // Typ produktu
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 10 * widget.collapseFactor,
            vertical: 4 * widget.collapseFactor,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Text(
            widget.product.productType.displayName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              fontSize: 12 * widget.collapseFactor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopMainInfo() {
    // ⭐ NOWE: Skaluj rozmiary na podstawie współczynnika zwijania
    final iconSize = (widget.isCollapsed ? 48.0 : 64.0) * widget.collapseFactor;
    final spacing = 20.0 * widget.collapseFactor;

    return Row(
      children: [
        // Ikona produktu z animacją
        TweenAnimationBuilder(
          duration: const Duration(milliseconds: 800),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.getProductTypeColor(
                        widget.product.productType.collectionName,
                      ).withOpacity(0.8),
                      AppTheme.getProductTypeColor(
                        widget.product.productType.collectionName,
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(iconSize * 0.31),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.getProductTypeColor(
                        widget.product.productType.collectionName,
                      ).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _getProductIcon(widget.product.productType),
                  color: Colors.white,
                  size: iconSize * 0.5,
                ),
              ),
            );
          },
        ),

        SizedBox(width: spacing),

        // Informacje o produkcie
        // Informacje o produkcie
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.product.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  fontSize: widget.isCollapsed ? 18 : 24,
                ),
                maxLines: widget.isCollapsed ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!widget.isCollapsed) ...[
                SizedBox(height: 8 * widget.collapseFactor),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * widget.collapseFactor,
                    vertical: 6 * widget.collapseFactor,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.product.productType.displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      fontSize: 12 * widget.collapseFactor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Status badge
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final color = AppTheme.getStatusColor(widget.product.status.displayName);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // ⭐ NOWE: Skaluj padding na podstawie stanu zwijania
    final horizontalPadding = ((isMobile ? 12 : 16) * widget.collapseFactor)
        .clamp(8.0, 16.0);
    final verticalPadding = ((isMobile ? 6 : 8) * widget.collapseFactor).clamp(
      4.0,
      8.0,
    );
    final fontSize = ((isMobile ? 11 : 12) * widget.collapseFactor).clamp(
      9.0,
      12.0,
    );
    final dotSize = ((isMobile ? 6 : 8) * widget.collapseFactor).clamp(
      4.0,
      8.0,
    );

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.8), color],
              ),
              borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: (isMobile ? 10 : 15) * widget.collapseFactor,
                  spreadRadius: 1,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(dotSize / 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: (isMobile ? 6 : 8) * widget.collapseFactor),
                Text(
                  widget.product.status.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    fontSize: fontSize,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  // ⭐ POMOCNICZA METODA: Ikona produktu (wzór z product_details_modal.dart)
  IconData _getProductIcon(UnifiedProductType productType) {
    switch (productType) {
      case UnifiedProductType.bonds:
        return Icons.account_balance;
      case UnifiedProductType.shares:
        return Icons.trending_up;
      case UnifiedProductType.loans:
        return Icons.monetization_on;
      case UnifiedProductType.apartments:
        return Icons.home;
      case UnifiedProductType.other:
        return Icons.inventory;
    }
  }
}
