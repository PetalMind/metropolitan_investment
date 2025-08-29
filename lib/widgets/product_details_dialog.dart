import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models_and_services.dart'; // Centralny import z ultra-precyzyjnym serwisem
import '../providers/auth_provider.dart';
import '../models_and_services.dart';
import 'premium_error_widget.dart';
import 'dialogs/product_delete_dialog.dart';

/// Enhanced widget do wyświetlania szczegółów produktu w modal dialog
class EnhancedProductDetailsDialog extends StatefulWidget {
  final UnifiedProduct product;

  const EnhancedProductDetailsDialog({super.key, required this.product});

  @override
  State<EnhancedProductDetailsDialog> createState() =>
      _EnhancedProductDetailsDialogState();
}

class _EnhancedProductDetailsDialogState
    extends State<EnhancedProductDetailsDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;
  
  final UltraPreciseProductInvestorsService _investorsService =
      UltraPreciseProductInvestorsService();

  List<InvestorSummary> _investors = [];
  bool _isLoadingInvestors = true;
  String? _investorsError;

  // Stany dla operacji edycji i usuwania
  bool _isPerformingAction = false;
  
  // State for header collapse animation
  bool _isHeaderCollapsed = false;
  // double _scrollOffset = 0.0; // Commented out as not currently used
  static const double _headerCollapseThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerAnimation = Tween<double>(
      begin: 1.0,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _scrollController.addListener(_onScroll);
    _tabController.addListener(_onTabChanged);
    
    // Rozpocznij ładowanie inwestorów natychmiast
    _loadInvestors();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _tabController.removeListener(_onTabChanged);
    _scrollController.dispose();
    _tabController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    final offset = _scrollController.offset;
    // setState(() {
    //   _scrollOffset = offset;
    // });
    
    if (offset > _headerCollapseThreshold && !_isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = true;
      });
      _headerAnimationController.forward();
    } else if (offset <= _headerCollapseThreshold && _isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = false;
      });
      _headerAnimationController.reverse();
    }
  }
  
  void _onTabChanged() {
    // Reset scroll position when changing tabs
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _loadInvestors() async {
    try {
      setState(() {
        _isLoadingInvestors = true;
        _investorsError = null;
      });

      print('🔍 [ProductDetailsDialog] Ładowanie inwestorów dla produktu:');
      print('  - Nazwa: "${widget.product.name}"');
      print('  - Typ: ${widget.product.productType.displayName}');
      print('  - ID: ${widget.product.id}');

      // ⭐ ZAWSZE UŻYWAJ PRAWDZIWEGO ID Z FIREBASE
      final isDeduplicated =
          widget.product.additionalInfo['isDeduplicated'] == true;

      final result = await _investorsService.getProductInvestors(
        productId: widget
            .product
            .id, // Używamy prawdziwego ID inwestycji (np. "bond_0770")
        productName: widget.product.name,
        searchStrategy: 'productId', // Ultra-precyzyjne wyszukiwanie po ID
      );

      if (isDeduplicated) {
        print(
          '🔄 [ProductDetailsDialog] Produkt deduplikowany - szukam po ID pierwszej inwestycji: ${widget.product.id}',
        );
      } else {
        print(
          '🔄 [ProductDetailsDialog] Produkt pojedynczy - szukam po ID: ${widget.product.id}',
        );
      }
      final investors = result.investors;

      if (mounted) {
        setState(() {
          _investors = investors;
          _isLoadingInvestors = false;
        });

        print(
          '✅ [ProductDetailsDialog] Załadowano ${investors.length} inwestorów',
        );
      }
    } catch (e) {
      print('❌ [ProductDetailsDialog] Błąd podczas ładowania inwestorów: $e');
      if (mounted) {
        setState(() {
          _investorsError = 'Błąd podczas ładowania inwestorów: $e';
          _isLoadingInvestors = false;
        });
      }
    }
  }

  /// Obsługuje wyświetlanie historii zmian produktu
  Future<void> _handleShowHistory() async {
    try {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => ProductHistoryDialog(
          product: widget.product,
        ),
      );
    } catch (e) {
      print('❌ Błąd podczas wyświetlania historii: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wystąpił błąd podczas ładowania historii: $e'),
            backgroundColor: AppTheme.errorPrimary,
          ),
        );
      }
    }
  }

  /// Obsługuje edycję produktu
  Future<void> _handleEditProduct() async {
    setState(() {
      _isPerformingAction = true;
    });

    try {
      // TODO: Implement product edit dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funkcja edycji produktu będzie wkrótce dostępna'),
          backgroundColor: AppTheme.infoPrimary,
        ),
      );
    } catch (e) {
      print('❌ Błąd podczas edycji produktu: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wystąpił błąd podczas edycji: $e'),
            backgroundColor: AppTheme.errorPrimary,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPerformingAction = false;
        });
      }
    }
  }

  /// Obsługuje usuwanie produktu
  Future<void> _handleDeleteProduct() async {
    setState(() {
      _isPerformingAction = true;
    });

    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ProductDeleteDialog(
          product: widget.product,
          onProductDeleted: () {
            // Zamknij aktualny dialog po usunięciu produktu
            Navigator.of(context).pop();
          },
        ),
      );

      if (result == true) {
        // Dialog został zamknięty po pomyślnym usunięciu
        print('✅ Produkt został usunięty pomyślnie');
        Navigator.of(context).pop(); // Zamknij dialog szczegółów produktu
      }
    } catch (e) {
      print('❌ Błąd podczas usuwania produktu: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wystąpił błąd podczas usuwania: $e'),
            backgroundColor: AppTheme.errorPrimary,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPerformingAction = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsywne wymiary dialogu
    final dialogWidth = screenWidth > 800
        ? screenWidth * 0.6
        : screenWidth * 0.92;
    final dialogHeight = screenHeight * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
        decoration: BoxDecoration(
          color: AppTheme.backgroundModal,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.borderPrimary.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Header z gradientem i przyciskiem zamknięcia
                _buildDialogHeader(),

                // Tab Bar
                _buildTabBar(),

                // Tab Bar View with enhanced scrolling
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildScrollableTab(_buildOverviewTab()),
                      _buildScrollableTab(_buildInvestorsTab()),
                      _buildScrollableTab(_buildAnalyticsTab()),
                    ],
                  ),
                ),
              ],
            ),

            // Loading overlay
            if (_isPerformingAction)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: PremiumShimmerLoadingWidget.analyticsCard(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryLight,
            AppTheme.primaryAccent,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Górna sekcja z przyciskami akcji
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Przyciski akcji
              Row(
                children: [
                  // Przycisk historii - dostępny dla wszystkich
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.infoPrimary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.infoPrimary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: _isPerformingAction
                          ? null
                          : _handleShowHistory,
                      icon: const Icon(
                        Icons.history,
                        color: Colors.white,
                        size: 18,
                      ),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                      tooltip: 'Historia zmian',
                    ),
                  ),

                  const SizedBox(width: 8),
                  // Przycisk edycji with RBAC
                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      final canEdit = auth.isAdmin;
                      return Container(
                        decoration: BoxDecoration(
                          color: canEdit 
                              ? Colors.white.withOpacity(0.15)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: canEdit 
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          onPressed: (_isPerformingAction || !canEdit)
                              ? null
                              : _handleEditProduct,
                      icon: _isPerformingAction
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.edit,
                              color: canEdit ? Colors.white : Colors.grey,
                              size: 18,
                            ),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                      tooltip: canEdit ? 'Edytuj produkt' : 'Brak uprawnień do edycji',
                    ),
                  );
                    },
                  ),

                  const SizedBox(width: 8),

                  // Przycisk usuwania
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.errorPrimary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.errorPrimary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: _isPerformingAction
                          ? null
                          : _handleDeleteProduct,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                      tooltip: 'Usuń produkt',
                    ),
                  ),
                ],
              ),

              // Przycisk zamknięcia
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                  tooltip: 'Zamknij',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Ikona produktu z animacją
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 800),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 64,
                      height: 64,
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
                        borderRadius: BorderRadius.circular(20),
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
                        size: 32,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 20),

              // Informacje o produkcie
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge
              _buildAnimatedStatusBadge(),
            ],
          ),

          const SizedBox(height: 20),

          // Metryki finansowe with enhanced layout
          _buildEnhancedFinancialMetrics(),
        ],
      ),
    );
      },
    );
  }

  Widget _buildAnimatedStatusBadge() {
    final color = AppTheme.getStatusColor(widget.product.status.displayName);

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.8), color],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.product.status.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedFinancialMetrics() {
    final profitLoss =
        widget.product.totalValue - widget.product.investmentAmount;
    final profitLossPercentage = widget.product.investmentAmount > 0
        ? (profitLoss / widget.product.investmentAmount) * 100
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid: 4 columns on wide screens, 2 on medium, 1 on narrow
        final isWide = constraints.maxWidth > 600;
        final isMedium = constraints.maxWidth > 400;
        
        if (isWide) {
          // 4-column layout for wide screens
          return _build4ColumnMetrics(profitLoss, profitLossPercentage);
        } else if (isMedium) {
          // 2-column layout for medium screens
          return _build2ColumnMetrics(profitLoss, profitLossPercentage);
        } else {
          // Single column for narrow screens
          return _buildSingleColumnMetrics(profitLoss, profitLossPercentage);
        }
      },
    );
  }
  
  Widget _build4ColumnMetrics(double profitLoss, double profitLossPercentage) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Inwestycja',
            value: _formatCurrency(widget.product.investmentAmount),
            subtitle: 'Kapitał początkowy',
            icon: Icons.input,
            color: AppTheme.infoPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Wartość',
            value: _formatCurrency(widget.product.totalValue),
            subtitle: 'Aktualna wartość',
            icon: Icons.account_balance_wallet,
            color: AppTheme.secondaryGold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: profitLoss >= 0 ? 'Zysk' : 'Strata',
            value: _formatCurrency(profitLoss.abs()),
            subtitle: '${profitLossPercentage.toStringAsFixed(1)}%',
            icon: profitLoss >= 0 ? Icons.trending_up : Icons.trending_down,
            color: profitLoss >= 0
                ? AppTheme.gainPrimary
                : AppTheme.lossPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'ROI',
            value: '${profitLossPercentage.toStringAsFixed(2)}%',
            subtitle: 'Return on Investment',
            icon: Icons.assessment,
            color: profitLoss >= 0
                ? AppTheme.successPrimary
                : AppTheme.errorPrimary,
          ),
        ),
      ],
    );
  }
  
  Widget _build2ColumnMetrics(double profitLoss, double profitLossPercentage) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Inwestycja',
                value: _formatCurrency(widget.product.investmentAmount),
                subtitle: 'PLN',
                icon: Icons.input,
                color: AppTheme.infoPrimary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: 'Wartość',
                value: _formatCurrency(widget.product.totalValue),
                subtitle: 'PLN',
                icon: Icons.account_balance_wallet,
                color: AppTheme.secondaryGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: profitLoss >= 0 ? 'Zysk' : 'Strata',
                value: _formatCurrency(profitLoss.abs()),
                subtitle: '${profitLossPercentage.toStringAsFixed(1)}%',
                icon: profitLoss >= 0 ? Icons.trending_up : Icons.trending_down,
                color: profitLoss >= 0
                    ? AppTheme.gainPrimary
                    : AppTheme.lossPrimary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: 'ROI',
                value: '${profitLossPercentage.toStringAsFixed(2)}%',
                subtitle: 'Return',
                icon: Icons.assessment,
                color: profitLoss >= 0
                    ? AppTheme.successPrimary
                    : AppTheme.errorPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSingleColumnMetrics(double profitLoss, double profitLossPercentage) {
    return Column(
      children: [
        _buildMetricCard(
          title: 'Inwestycja',
          value: _formatCurrency(widget.product.investmentAmount),
          subtitle: 'Kapitał początkowy',
          icon: Icons.input,
          color: AppTheme.infoPrimary,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: 'Wartość obecna',
          value: _formatCurrency(widget.product.totalValue),
          subtitle: 'Aktualna wycena',
          icon: Icons.account_balance_wallet,
          color: AppTheme.secondaryGold,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: profitLoss >= 0 ? 'Zysk' : 'Strata',
          value: _formatCurrency(profitLoss.abs()),
          subtitle: '${profitLossPercentage.toStringAsFixed(1)}% ROI',
          icon: profitLoss >= 0 ? Icons.trending_up : Icons.trending_down,
          color: profitLoss >= 0
              ? AppTheme.gainPrimary
              : AppTheme.lossPrimary,
        ),
      ],
    );
  }
  
  Widget _buildScrollableTab(Widget content) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: content,
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 1000),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
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

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundModal,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderPrimary, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                const Text('Szczegóły'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_outline, size: 18),
                const SizedBox(width: 8),
                _isLoadingInvestors
                    ? const Row(
                        children: [
                          Text('Inwestorzy '),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                AppTheme.secondaryGold,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Text('Inwestorzy (${_investors.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.analytics_outlined, size: 18),
                const SizedBox(width: 8),
                const Text('Analiza'),
              ],
            ),
          ),
        ],
        labelColor: AppTheme.secondaryGold,
        unselectedLabelColor: AppTheme.textTertiary,
        indicatorColor: AppTheme.secondaryGold,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.2,
        ),
        indicator: BoxDecoration(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(3),
            bottomRight: Radius.circular(3),
          ),
          gradient: LinearGradient(
            colors: [
              AppTheme.secondaryGold.withOpacity(0.6),
              AppTheme.secondaryGold,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondaryGold.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getProductIcon(UnifiedProductType type) {
    switch (type) {
      case UnifiedProductType.bonds:
        return Icons.account_balance;
      case UnifiedProductType.shares:
        return Icons.trending_up;
      case UnifiedProductType.loans:
        return Icons.attach_money;
      case UnifiedProductType.apartments:
        return Icons.apartment;
      case UnifiedProductType.other:
        return Icons.inventory;
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M zł';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K zł';
    } else {
      return '${amount.toStringAsFixed(2)} zł';
    }
  }

  Widget _buildOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statystyki finansowe produktu z headera
        _buildEnhancedFinancialMetrics(),

        const SizedBox(height: 24),

        // Szczegółowe informacje specyficzne dla typu produktu
        _buildProductSpecificDetails(),

        const SizedBox(height: 24),

        // Podstawowe informacje
        _buildBasicInformation(),

        const SizedBox(height: 24),

        // Opis produktu
        if (widget.product.description.isNotEmpty) ...[
          _buildDescriptionSection(),
          const SizedBox(height: 24),
        ],

        // Dodatkowe informacje
        if (widget.product.additionalInfo.isNotEmpty) ...[
          _buildAdditionalInfoSection(),
        ],
      ],
    );
  }

  Widget _buildInvestorsTab() {
    if (_isLoadingInvestors) {
      return const Center(
        child: PremiumShimmerLoadingWidget.listItem(),
      );
    }

    if (_investorsError != null) {
      return PremiumErrorWidget(
        error: _investorsError!,
        onRetry: _loadInvestors,
      );
    }

    if (_investors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Brak inwestorów',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nie znaleziono inwestorów dla tego produktu.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Pokaż informacje debuggowe
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Informacje o wyszukiwaniu:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nazwa: "${widget.product.name}"',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      'Typ: ${widget.product.productType.displayName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      'Kolekcja: ${widget.product.productType.collectionName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadInvestors,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Spróbuj ponownie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.textOnPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _investors.map((investor) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(Icons.person, color: AppTheme.primaryColor),
            ),
            title: Text(
              investor.client.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (investor.client.email.isNotEmpty)
                  Text(
                    investor.client.email,
                    style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.8),
                    ),
                  ),
                if (investor.client.phone.isNotEmpty)
                  Text(
                    investor.client.phone,
                    style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.8),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Inwestycje: ${investor.investmentCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryGold,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppTheme.secondaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatCurrency(investor.viableRemainingCapital),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryGold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnalyticsTab() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statystyki inwestorów
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statystyki Inwestorów',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Liczba Inwestorów',
                        _investors.length.toString(),
                        Icons.people,
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Łączny Kapitał',
                        _formatCurrency(
                          _investors.fold(
                            0.0,
                            (sum, investor) =>
                                sum + investor.viableRemainingCapital,
                          ),
                        ),
                        Icons.attach_money,
                        AppTheme.secondaryGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Średnia Inwestycja',
                        _investors.isNotEmpty
                            ? _formatCurrency(
                                _investors.fold(
                                      0.0,
                                      (sum, investor) =>
                                          sum + investor.viableRemainingCapital,
                                    ) /
                                    _investors.length,
                              )
                            : '0 zł',
                        Icons.trending_up,
                        AppTheme.successPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Łączne Inwestycje',
                        _investors
                            .fold(
                              0,
                              (sum, investor) => sum + investor.investmentCount,
                            )
                            .toString(),
                        Icons.account_balance,
                        AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Ranking inwestorów
          if (_investors.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Inwestorzy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._investors.take(5).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final investor = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundPrimary.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: index == 0
                              ? AppTheme.secondaryGold.withOpacity(0.3)
                              : AppTheme.primaryColor.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? AppTheme.secondaryGold
                                  : AppTheme.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: index == 0
                                      ? AppTheme.backgroundPrimary
                                      : AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  investor.client.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${investor.investmentCount} inwestycji',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary.withOpacity(
                                      0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatCurrency(investor.viableRemainingCapital),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: index == 0
                                  ? AppTheme.secondaryGold
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textTertiary,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Buduje szczegóły specyficzne dla typu produktu
  Widget _buildProductSpecificDetails() {
    switch (widget.product.productType) {
      case UnifiedProductType.bonds:
        return _buildBondsDetails();
      case UnifiedProductType.shares:
        return _buildSharesDetails();
      case UnifiedProductType.loans:
        return _buildLoansDetails();
      case UnifiedProductType.apartments:
        return _buildApartmentsDetails();
      case UnifiedProductType.other:
        return _buildOtherProductDetails();
    }
  }

  /// Szczegóły dla obligacji
  Widget _buildBondsDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.bondsColor.withOpacity(0.1),
            AppTheme.bondsBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.bondsColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.bondsColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bondsColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance,
                  color: AppTheme.bondsColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Szczegóły Obligacji',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.bondsColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Informacje o instrumencie dłużnym',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.product.realizedCapital != null)
            _buildDetailRow(
              'Zrealizowany kapitał',
              _formatCurrency(widget.product.realizedCapital!),
            ),
          if (widget.product.remainingCapital != null)
            _buildDetailRow(
              'Pozostały kapitał',
              _formatCurrency(widget.product.remainingCapital!),
            ),
          if (widget.product.realizedInterest != null)
            _buildDetailRow(
              'Zrealizowane odsetki',
              _formatCurrency(widget.product.realizedInterest!),
            ),
          if (widget.product.remainingInterest != null)
            _buildDetailRow(
              'Pozostałe odsetki',
              _formatCurrency(widget.product.remainingInterest!),
            ),
          if (widget.product.interestRate != null)
            _buildDetailRow(
              'Oprocentowanie',
              '${widget.product.interestRate!.toStringAsFixed(2)}%',
            ),
          if (widget.product.maturityDate != null)
            _buildDetailRow(
              'Data zapadalności',
              _formatDate(widget.product.maturityDate!),
            ),
          if (widget.product.companyName != null)
            _buildDetailRow('Emitent', widget.product.companyName!),
        ],
      ),
    );
  }

  /// Szczegóły dla udziałów
  Widget _buildSharesDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.sharesColor.withOpacity(0.1),
            AppTheme.sharesBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.sharesColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.sharesColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.sharesColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: AppTheme.sharesColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Szczegóły Udziałów',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.sharesColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Informacje o udziałach w spółce',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.product.sharesCount != null)
            _buildDetailRow(
              'Liczba udziałów',
              widget.product.sharesCount.toString(),
            ),
          if (widget.product.pricePerShare != null)
            _buildDetailRow(
              'Cena za udział',
              _formatCurrency(widget.product.pricePerShare!),
            ),
          if (widget.product.companyName != null)
            _buildDetailRow('Nazwa spółki', widget.product.companyName!),
          _buildDetailRow(
            'Wartość całkowita',
            _formatCurrency(widget.product.totalValue),
          ),
        ],
      ),
    );
  }

  /// Szczegóły dla pożyczek
  Widget _buildLoansDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.loansColor.withOpacity(0.1),
            AppTheme.loansBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.loansColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.loansColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.loansColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.attach_money,
                  color: AppTheme.loansColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Szczegóły Pożyczki',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.loansColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Informacje o produkcie pożyczkowym',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.product.additionalInfo['borrower'] != null)
            _buildDetailRow(
              'Pożyczkobiorca',
              widget.product.additionalInfo['borrower'].toString(),
            ),
          if (widget.product.additionalInfo['creditorCompany'] != null)
            _buildDetailRow(
              'Spółka wierzyciel',
              widget.product.additionalInfo['creditorCompany'].toString(),
            ),
          if (widget.product.interestRate != null)
            _buildDetailRow(
              'Oprocentowanie',
              '${widget.product.interestRate!.toStringAsFixed(2)}%',
            ),
          if (widget.product.maturityDate != null)
            _buildDetailRow(
              'Termin spłaty',
              _formatDate(widget.product.maturityDate!),
            ),
          if (widget.product.additionalInfo['collateral'] != null)
            _buildDetailRow(
              'Zabezpieczenie',
              widget.product.additionalInfo['collateral'].toString(),
            ),
          if (widget.product.additionalInfo['status'] != null)
            _buildDetailRow(
              'Status pożyczki',
              widget.product.additionalInfo['status'].toString(),
            ),
        ],
      ),
    );
  }
    /// Szczegóły dla apartamentów
  Widget _buildApartmentsDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.apartmentsColor.withOpacity(0.1),
            AppTheme.apartmentsBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.apartmentsColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.apartmentsColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.apartmentsColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.apartment,
                  color: AppTheme.apartmentsColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Szczegóły Apartamentu',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.apartmentsColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Informacje o nieruchomości',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.product.additionalInfo['apartmentNumber'] != null)
            _buildDetailRow(
              'Numer apartamentu',
              widget.product.additionalInfo['apartmentNumber'].toString(),
            ),
          if (widget.product.additionalInfo['building'] != null)
            _buildDetailRow(
              'Budynek',
              widget.product.additionalInfo['building'].toString(),
            ),
          if (widget.product.additionalInfo['area'] != null)
            _buildDetailRow(
              'Powierzchnia',
              '${widget.product.additionalInfo['area']} m²',
            ),
          if (widget.product.additionalInfo['roomCount'] != null)
            _buildDetailRow(
              'Liczba pokoi',
              widget.product.additionalInfo['roomCount'].toString(),
            ),
          if (widget.product.additionalInfo['floor'] != null)
            _buildDetailRow(
              'Piętro',
              widget.product.additionalInfo['floor'].toString(),
            ),
          if (widget.product.additionalInfo['apartmentType'] != null)
            _buildDetailRow(
              'Typ apartamentu',
              widget.product.additionalInfo['apartmentType'].toString(),
            ),
          if (widget.product.additionalInfo['pricePerSquareMeter'] != null)
            _buildDetailRow(
              'Cena za m²',
              '${widget.product.additionalInfo['pricePerSquareMeter']} PLN/m²',
            ),
          if (widget.product.additionalInfo['address'] != null)
            _buildDetailRow(
              'Adres',
              widget.product.additionalInfo['address'].toString(),
            ),
          // Dodatkowe amenity
          Row(
            children: [
              if (widget.product.additionalInfo['hasBalcony'] == true)
                _buildAmenityChip('Balkon', Icons.balcony),
              if (widget.product.additionalInfo['hasParkingSpace'] == true) ...[
                const SizedBox(width: 8),
                _buildAmenityChip('Parking', Icons.local_parking),
              ],
              if (widget.product.additionalInfo['hasStorage'] == true) ...[
                const SizedBox(width: 8),
                _buildAmenityChip('Komórka', Icons.storage),
                ],
              ],
            ),
          ],
        ),
      );
  }


  /// Szczegóły dla innych produktów
  Widget _buildOtherProductDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.backgroundTertiary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Szczegóły Produktu',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Informacje o produkcie inwestycyjnym',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            'Wartość całkowita',
            _formatCurrency(widget.product.totalValue),
          ),
          if (widget.product.companyName != null)
            _buildDetailRow('Firma', widget.product.companyName!),
          if (widget.product.currency != null)
            _buildDetailRow('Waluta', widget.product.currency!),
        ],
      ),
    );
  }

  /// Buduje podstawowe informacje o produkcie
  Widget _buildBasicInformation() {
    // Nowoczesna, responsywna karta "Informacje" z mikrointerakcjami
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 12 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.surfaceElevated.withOpacity(0.5),
                    AppTheme.surfaceCard,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.borderPrimary.withOpacity(0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryGold.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: AppTheme.secondaryGold,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Informacje',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      // Small action buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: 'Kopiuj ID',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: widget.product.id));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('ID skopiowane do schowka'),
                                    backgroundColor: AppTheme.infoPrimary,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundSecondary.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.copy, size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Pokaż więcej',
                            child: InkWell(
                              onTap: () {
                                // Subtelna mikrointerakcja: expanduj/scroll do sekcji opisu
                                // Używamy fabrycznego zachowania: scroll to top of overview handled by parent scroll controller
                                // Jeśli potrzebne, można dodać callback do otwierania odpowiedniej sekcji.
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Przejdź do szczegółów produktu'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundSecondary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.more_horiz, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Responsive grid of key/value pairs with microinteractions
                  LayoutBuilder(builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    final isMedium = constraints.maxWidth > 420 && constraints.maxWidth <= 700;

                    final infoItems = <_InfoItem>[
                      _InfoItem(label: 'ID Produktu', value: widget.product.id),
                      _InfoItem(label: 'Typ', value: widget.product.productType.displayName),
                      _InfoItem(label: 'Status', value: widget.product.isActive ? 'Aktywny' : 'Nieaktywny'),
                      _InfoItem(label: 'Kwota inwestycji', value: _formatCurrency(widget.product.investmentAmount)),
                      _InfoItem(label: 'Data utworzenia', value: _formatDate(widget.product.createdAt)),
                      _InfoItem(label: 'Ostatnia aktualizacja', value: _formatDate(widget.product.uploadedAt)),
                      _InfoItem(label: 'Waluta', value: widget.product.currency ?? 'PLN'),
                    ];

                    if (isWide) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: infoItems.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 4.2,
                        ),
                        itemBuilder: (context, index) {
                          final item = infoItems[index];
                          return _AnimatedInfoTile(item: item);
                        },
                      );
                    } else if (isMedium) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: infoItems.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 5,
                        ),
                        itemBuilder: (context, index) {
                          final item = infoItems[index];
                          return _AnimatedInfoTile(item: item);
                        },
                      );
                    } else {
                      return Column(
                        children: infoItems.map((i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AnimatedInfoTile(item: i),
                        )).toList(),
                      );
                    }
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Buduje sekcję opisu
  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.infoPrimary.withOpacity(0.05),
            AppTheme.infoBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.infoPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.infoPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: AppTheme.infoPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Opis Produktu',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.infoPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.borderSecondary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              widget.product.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textPrimary,
                height: 1.6,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Buduje sekcję dodatkowych informacji
  Widget _buildAdditionalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.neutralPrimary.withOpacity(0.05),
            AppTheme.neutralBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.neutralPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.neutralPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.more_horiz,
                  color: AppTheme.neutralPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Dodatkowe Informacje',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.neutralPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...widget.product.additionalInfo.entries
              .where((entry) => !_isSpecialField(entry.key))
              .map(
                (entry) => _buildDetailRow(
                  _formatFieldName(entry.key),
                  entry.value.toString(),
                ),
              ),
        ],
      ),
    );
  }

  /// Buduje chip z amenity dla apartamentów
  Widget _buildAmenityChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.successPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.successPrimary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.successPrimary, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.successPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Sprawdza czy pole jest specjalne (już wyświetlone w sekcji specyficznej)
  bool _isSpecialField(String fieldName) {
    const specialFields = [
      'borrower',
      'creditorCompany',
      'collateral',
      'status',
      'apartmentNumber',
      'building',
      'area',
      'roomCount',
      'floor',
      'apartmentType',
      'pricePerSquareMeter',
      'address',
      'hasBalcony',
      'hasParkingSpace',
      'hasStorage',
    ];
    return specialFields.contains(fieldName);
  }

  /// Formatuje nazwę pola dla wyświetlenia
  String _formatFieldName(String fieldName) {
    // Mapa tłumaczeń dla polskich nazw pól
    const translations = {
      'nazwa_produktu': 'Nazwa produktu',
      'typ_produktu': 'Typ produktu',
      'kwota_inwestycji': 'Kwota inwestycji',
      'data_utworzenia': 'Data utworzenia',
      'ostatnia_aktualizacja': 'Ostatnia aktualizacja',
      'oprocentowanie': 'Oprocentowanie',
      'data_zapadalnosci': 'Data zapadalności',
      'liczba_udzialow': 'Liczba udziałów',
      'cena_za_udzial': 'Cena za udział',
      'companyName': 'Nazwa firmy',
      'waluta': 'Waluta',
      'projekt_nazwa': 'Nazwa projektu',
      'numer_apartamentu': 'Numer apartamentu',
      'powierzchnia': 'Powierzchnia',
      'liczba_pokoi': 'Liczba pokoi',
      'pietro': 'Piętro',
      'typ_apartamentu': 'Typ apartamentu',
      'cena_za_m2': 'Cena za m²',
      'balkon': 'Balkon',
      'miejsce_parkingowe': 'Miejsce parkingowe',
      'komorka': 'Komórka',
      'adres': 'Adres',
      'pozyczkobiorca': 'Pożyczkobiorca',
      'wierzyciel_spolka': 'Wierzyciel spółka',
      'zabezpieczenie': 'Zabezpieczenie',
      'status_pozyczki': 'Status pożyczki',
    };

    return translations[fieldName] ??
        fieldName.replaceAll('_', ' ').toUpperCase()[0] +
            fieldName.replaceAll('_', ' ').substring(1);
  }

  /// Formatuje datę
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Buduje sekcję ze statystykami finansowymi produktu

  Widget _buildFinancialMetricsLoading() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundTertiary.withOpacity(0.3),
            AppTheme.backgroundSecondary.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderPrimary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundTertiary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundTertiary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(
              4,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 3 ? 16 : 0),
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundTertiary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetricsEmpty() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundTertiary.withOpacity(0.3),
            AppTheme.backgroundSecondary.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderPrimary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Brak danych finansowych',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Statystyki będą dostępne po załadowaniu danych inwestorów.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
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

  // Metody obliczeniowe dla statystyk
  double _computeTotalInvestmentAmount() {
    double sum = 0.0;
    final processedIds = <String>{};

    for (final investor in _investors) {
      for (final investment in investor.investments) {
        if (investment.productName != widget.product.name) continue;
        if (processedIds.contains(investment.id)) continue;
        processedIds.add(investment.id);
        sum += investment.investmentAmount;
      }
    }
    return sum;
  }

  double _computeTotalRemainingCapital() {
    double sum = 0.0;
    final processedIds = <String>{};

    for (final investor in _investors) {
      for (final investment in investor.investments) {
        if (investment.productName != widget.product.name) continue;
        if (processedIds.contains(investment.id)) continue;
        processedIds.add(investment.id);
        sum += investment.remainingCapital;
      }
    }
    return sum;
  }

  double _computeTotalCapitalSecured() {
    final totalRemaining = _computeTotalRemainingCapital();
    final totalForRestructuring = _computeTotalCapitalForRestructuring();
    return (totalRemaining - totalForRestructuring).clamp(0.0, double.infinity);
  }

  double _computeTotalCapitalForRestructuring() {
    double sum = 0.0;
    final processedIds = <String>{};

    for (final investor in _investors) {
      for (final investment in investor.investments) {
        if (investment.productName != widget.product.name) continue;
        if (processedIds.contains(investment.id)) continue;
        processedIds.add(investment.id);
        sum += investment.capitalForRestructuring;
      }
    }
    return sum;
  }
}

// --- Helpers for modern information card ---------------------------------
class _InfoItem {
  final String label;
  final String value;
  _InfoItem({required this.label, required this.value});
}

class _AnimatedInfoTile extends StatefulWidget {
  final _InfoItem item;
  const _AnimatedInfoTile({Key? key, required this.item}) : super(key: key);

  @override
  State<_AnimatedInfoTile> createState() => _AnimatedInfoTileState();
}

class _AnimatedInfoTileState extends State<_AnimatedInfoTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 160), vsync: this);
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.985).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSecondary.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.value,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Copy action
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: widget.item.value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.item.label} skopiowane'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundSecondary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.copy, size: 16, color: AppTheme.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
