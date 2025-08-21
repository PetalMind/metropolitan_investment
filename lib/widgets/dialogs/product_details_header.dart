import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/unified_product.dart';
import '../../models/investor_summary.dart';
import '../../models_and_services.dart';
import '../../utils/currency_formatter.dart';
import 'total_capital_edit_dialog.dart';

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
  // ⭐ UJEDNOLICONY SERWIS: Wykorzystujemy zunifikowany serwis modal produktu
  final UnifiedProductModalService _modalService = UnifiedProductModalService();

  ProductModalData? _modalData;
  bool _isLoadingStatistics = false;

  // ⭐ NOWE: Stan edycji - przekazywany do product_investors_tab
  bool _isEditModeEnabled = false;

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
    _loadServerStatistics();
  }

  Future<void> _loadServerStatistics() async {
    await _loadServerStatisticsInternal(forceRefresh: false);
  }

  Future<void> _loadServerStatisticsWithForceRefresh() async {
    await _loadServerStatisticsInternal(forceRefresh: true);
  }

  Future<void> _loadServerStatisticsInternal({
    required bool forceRefresh,
  }) async {
    if (widget.isLoadingInvestors || widget.investors.isEmpty) return;
    if (widget.product.name.trim().isEmpty) return;

    setState(() => _isLoadingStatistics = true);

    try {
      debugPrint(
        '🔄 [ProductDetailsHeader] Loading statistics (forceRefresh: $forceRefresh)',
      );

      // ⭐ UJEDNOLICONE OBLICZENIA: Używamy zunifikowanego serwisu modal produktu
      final modalData = await _modalService.getProductModalData(
        product: widget.product,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      setState(() {
        _modalData = modalData;
        _isLoadingStatistics = false;
      });

      debugPrint('✅ [ProductDetailsHeader] Statistics refreshed successfully');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingStatistics = false);

      // Fallback do lokalnych obliczeń
      debugPrint(
        '⚠️ [ProductDetailsHeader] Fallback do lokalnych statystyk: $error',
      );
    }
  }

  @override
  void didUpdateWidget(covariant ProductDetailsHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.investors != widget.investors ||
        oldWidget.isLoadingInvestors != widget.isLoadingInvestors) {
      // ⭐ NOWE: Wyczyść cache modalu przy aktualizacji danych
      _modalService.clearProductCache(widget.product.id);
      _loadServerStatistics();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
    debugPrint(
      '🔍 [ProductDetailsHeader] Building header for: ${widget.product.name}',
    );
    debugPrint('   - isCollapsed: ${widget.isCollapsed}');
    debugPrint('   - collapseFactor: ${widget.collapseFactor}');
    debugPrint('   - investors count: ${widget.investors.length}');

    return Container(
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
            // ⭐ NOWE: Statystyki znikają gdy header jest zwinięty
            if (!widget.isCollapsed) ...[
              SizedBox(height: (isMobile ? 16 : 20) * widget.collapseFactor),
              AnimatedOpacity(
                opacity: widget.collapseFactor,
                duration: const Duration(milliseconds: 300),
                child: _buildFinancialMetrics(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Metryki (UJEDNOLICONE ŹRÓDŁO DANYCH) ---
  Widget _buildFinancialMetrics() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (_isLoadingStatistics) {
      return isMobile ? _buildMobileLoadingGrid() : _buildDesktopLoadingRow();
    }

    // ⭐ UJEDNOLICONE OBLICZENIA: Używamy danych z UnifiedProductModalService lub fallback lokalny
    final double totalInvestmentAmount;
    final double totalRemainingCapital;
    final double totalCapitalSecured;
    final double totalCapitalForRestructuring;

    if (_modalData != null) {
      // Zunifikowane statystyki z serwisu modal
      totalInvestmentAmount = _modalData!.statistics.totalInvestmentAmount;
      totalRemainingCapital = _modalData!.statistics.totalRemainingCapital;
      totalCapitalSecured =
          _modalData!.statistics.totalCapitalSecuredByRealEstate;
      // Oblicz kapitał do restrukturyzacji lokalnie jeśli nie ma w modalData
      totalCapitalForRestructuring = _computeTotalCapitalForRestructuring();
    } else {
      // Fallback: Obliczenia lokalne według wzoru z product_details_modal.dart
      totalInvestmentAmount = _computeTotalInvestmentAmount();
      totalRemainingCapital = _computeTotalRemainingCapital();
      totalCapitalSecured = _computeTotalCapitalSecured();
      totalCapitalForRestructuring = _computeTotalCapitalForRestructuring();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Etykieta źródła danych (dla przejrzystości)
        Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: isMobile ? 12 : 14,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),

        // Responsywny layout dla metryk
        isMobile
            ? _buildMobileMetricsGrid(
                totalInvestmentAmount,
                totalRemainingCapital,
                totalCapitalSecured,
                totalCapitalForRestructuring,
              )
            : _buildDesktopMetricsWrap(
                totalInvestmentAmount,
                totalRemainingCapital,
                totalCapitalSecured,
                totalCapitalForRestructuring,
              ),
      ],
    );
  }

  Widget _buildMobileLoadingGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 400; // ⭐ NOWE: Wykryj bardzo małe ekrany
    final spacing = isVerySmall ? 8.0 : 12.0;

    if (isVerySmall) {
      // ⭐ NOWE: Na bardzo małych ekranach pokaż w jednej kolumnie
      return Column(
        children: [
          _buildMetricLoadingCard(),
          SizedBox(height: spacing),
          _buildMetricLoadingCard(),
          SizedBox(height: spacing),
          _buildMetricLoadingCard(),
          SizedBox(height: spacing),
          _buildMetricLoadingCard(),
        ],
      );
    }

    return Column(
      children: [
        // Pierwszy wiersz - dwa loading cards
        Row(
          children: [
            Expanded(child: _buildMetricLoadingCard()),
            SizedBox(width: spacing),
            Expanded(child: _buildMetricLoadingCard()),
          ],
        ),

        SizedBox(height: spacing),

        // Drugi wiersz - dwa loading cards
        Row(
          children: [
            Expanded(child: _buildMetricLoadingCard()),
            SizedBox(width: spacing),
            Expanded(child: _buildMetricLoadingCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLoadingRow() {
    final screenWidth = MediaQuery.of(context).size.width;
    // ⭐ NOWE: Spacing dostosowany do układu w jednej linii
    final spacing = screenWidth < 800 ? 12.0 : 16.0;

    return Row(
      children: [
        Expanded(child: _buildMetricLoadingCard()),
        SizedBox(width: spacing),
        Expanded(child: _buildMetricLoadingCard()),
        SizedBox(width: spacing),
        Expanded(child: _buildMetricLoadingCard()),
        SizedBox(width: spacing),
        Expanded(child: _buildMetricLoadingCard()),
      ],
    );
  }

  Widget _buildMobileMetricsGrid(
    double totalInvestmentAmount,
    double totalRemainingCapital,
    double totalCapitalSecured,
    double totalCapitalForRestructuring,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 400; // ⭐ NOWE: Wykryj bardzo małe ekrany

    if (isVerySmall) {
      // ⭐ NOWE: Na bardzo małych ekranach pokaż w jednej kolumnie
      return Column(
        children: [
          _buildCompactMetricCard(
            title: 'Suma inwestycji',
            value: CurrencyFormatter.formatCurrency(totalInvestmentAmount),
            subtitle: 'PLN',
            icon: Icons.trending_up,
            color: AppTheme.infoPrimary,
          ),
          const SizedBox(height: 8),
          _buildCompactMetricCard(
            title: 'Kapitał pozostały',
            value: CurrencyFormatter.formatCurrency(totalRemainingCapital),
            subtitle: 'PLN',
            icon: Icons.account_balance_wallet,
            color: AppTheme.successPrimary,
            onTap: _isEditModeEnabled ? _openTotalCapitalEditDialog : null,
          ),
          const SizedBox(height: 8),
          _buildCompactMetricCard(
            title: 'Kapitał zabezpieczony',
            value: CurrencyFormatter.formatCurrency(totalCapitalSecured),
            subtitle: 'PLN',
            icon: Icons.security,
            color: AppTheme.warningPrimary,
          ),
          const SizedBox(height: 8),
          _buildCompactMetricCard(
            title: 'Kapitał do restrukturyzacji',
            value: CurrencyFormatter.formatCurrency(
              totalCapitalForRestructuring,
            ),
            subtitle: 'PLN',
            icon: Icons.build,
            color: AppTheme.errorPrimary,
          ),
        ],
      );
    }

    // ⭐ ULEPSZONY: Grid 2x2 dla normalnych rozmiarów mobile
    return Column(
      children: [
        // Pierwszy wiersz - dwie karty
        Row(
          children: [
            Expanded(
              child: _buildCompactMetricCard(
                title: 'Suma inwestycji',
                value: CurrencyFormatter.formatCurrency(totalInvestmentAmount),
                subtitle: 'PLN',
                icon: Icons.trending_up,
                color: AppTheme.infoPrimary,
              ),
            ),
            const SizedBox(width: 8), // ⭐ ZMNIEJSZONE: z 12 na 8
            Expanded(
              child: _buildCompactMetricCard(
                title: 'Kapitał pozostały',
                value: CurrencyFormatter.formatCurrency(totalRemainingCapital),
                subtitle: 'PLN',
                icon: Icons.account_balance_wallet,
                color: AppTheme.successPrimary,
                onTap: _isEditModeEnabled ? _openTotalCapitalEditDialog : null,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8), // ⭐ ZMNIEJSZONE: z 12 na 8
        // Drugi wiersz - dwie karty
        Row(
          children: [
            Expanded(
              child: _buildCompactMetricCard(
                title: 'Kapitał zabezpieczony',
                value: CurrencyFormatter.formatCurrency(totalCapitalSecured),
                subtitle: 'PLN',
                icon: Icons.security,
                color: AppTheme.warningPrimary,
              ),
            ),
            const SizedBox(width: 8), // ⭐ ZMNIEJSZONE: z 12 na 8
            Expanded(
              child: _buildCompactMetricCard(
                title: 'Kapitał do restrukturyzacji',
                value: CurrencyFormatter.formatCurrency(
                  totalCapitalForRestructuring,
                ),
                subtitle: 'PLN',
                icon: Icons.build,
                color: AppTheme.errorPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopMetricsWrap(
    double totalInvestmentAmount,
    double totalRemainingCapital,
    double totalCapitalSecured,
    double totalCapitalForRestructuring,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    // ⭐ NOWE: Spacing dostosowany do układu w jednej linii
    final spacing = screenWidth < 800 ? 12.0 : 16.0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Suma inwestycji',
            value: CurrencyFormatter.formatCurrency(totalInvestmentAmount),
            subtitle: 'PLN',
            icon: Icons.trending_up,
            color: AppTheme.infoPrimary,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: _buildMetricCard(
            title: 'Kapitał pozostały',
            value: CurrencyFormatter.formatCurrency(totalRemainingCapital),
            subtitle: 'PLN',
            icon: Icons.account_balance_wallet,
            color: AppTheme.successPrimary,
            onTap: _isEditModeEnabled ? _openTotalCapitalEditDialog : null,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: _buildMetricCard(
            title: 'Kapitał zabezpieczony',
            value: CurrencyFormatter.formatCurrency(totalCapitalSecured),
            subtitle: 'PLN',
            icon: Icons.security,
            color: AppTheme.warningPrimary,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: _buildMetricCard(
            title: 'Kapitał do restrukturyzacji',
            value: CurrencyFormatter.formatCurrency(
              totalCapitalForRestructuring,
            ),
            subtitle: 'PLN',
            icon: Icons.build,
            color: AppTheme.errorPrimary,
          ),
        ),
      ],
    );
  }

  // ⭐ POMOCNICZE METODY OBLICZENIOWE (wzór z product_details_modal.dart)
  double _computeTotalInvestmentAmount() {
    double sum = 0.0;
    final processedIds = <String>{};

    for (final investor in widget.investors) {
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

    for (final investor in widget.investors) {
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
    // Wzór: capitalSecured = max(remainingCapital - capitalForRestructuring, 0)
    return (totalRemaining - totalForRestructuring).clamp(0.0, double.infinity);
  }

  double _computeTotalCapitalForRestructuring() {
    double sum = 0.0;
    final processedIds = <String>{};

    for (final investor in widget.investors) {
      for (final investment in investor.investments) {
        if (investment.productName != widget.product.name) continue;
        if (processedIds.contains(investment.id)) continue;
        processedIds.add(investment.id);
        sum += investment.capitalForRestructuring;
      }
    }
    return sum;
  }

  Widget _buildCloseButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Przycisk edycji
        Container(
          decoration: BoxDecoration(
            color: AppTheme.secondaryGold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.secondaryGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () => _editProduct(),
            icon: const Icon(
              Icons.edit,
              color: AppTheme.secondaryGold,
              size: 20,
            ),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
            tooltip: 'Edytuj produkt',
          ),
        ),
        const SizedBox(width: 12),
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

  void _editProduct() async {
    setState(() {
      _isEditModeEnabled = !_isEditModeEnabled;
    });

    // ⭐ NOWE: Powiadom parent o zmianie trybu edycji
    widget.onEditModeChanged?.call(_isEditModeEnabled);

    if (_isEditModeEnabled) {
      // ⭐ NOWE: Automatycznie przełącz na tab "Inwestorzy" (index 1)
      widget.onTabChanged?.call(1);

      _showSnackBar(
        'Tryb edycji włączony - kliknij na inwestora aby edytować',
        isError: false,
        icon: Icons.edit,
      );
    } else {
      _showSnackBar(
        'Tryb edycji wyłączony',
        isError: false,
        icon: Icons.visibility,
      );
    }
  }

  void _showSnackBar(String message, {required bool isError, IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon ?? (isError ? Icons.error : Icons.check_circle),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError
            ? AppTheme.errorPrimary
            : AppTheme.successPrimary,
        duration: Duration(seconds: isError ? 5 : 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildMainInfo() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    debugPrint('🔍 [ProductDetailsHeader] Building main info:');
    debugPrint('   - Product name: ${widget.product.name}');
    debugPrint('   - Product type: ${widget.product.productType}');
    debugPrint('   - Is mobile: $isMobile');
    debugPrint('   - Is collapsed: ${widget.isCollapsed}');

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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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

  /// Widget loading state dla metryk podczas ładowania z serwera
  Widget _buildMetricLoadingCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 400; // ⭐ NOWE: Wykryj bardzo małe ekrany

    // ⭐ ULEPSZONY: Responsywne rozmiary
    final cardHeight = isVerySmall ? 70.0 : 80.0;
    final padding = isVerySmall ? 8.0 : 16.0;
    final iconSize = isVerySmall ? 14.0 : 16.0;
    final titleWidth = isVerySmall ? 50.0 : 60.0;
    final valueWidth = isVerySmall ? 60.0 : 80.0;
    final valueHeight = isVerySmall ? 16.0 : 20.0;
    final subtitleWidth = isVerySmall ? 25.0 : 30.0;
    final subtitleHeight = isVerySmall ? 10.0 : 12.0;

    return Container(
      height: cardHeight,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(iconSize / 2),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: titleWidth,
                height: subtitleHeight,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          SizedBox(height: isVerySmall ? 6 : 8),
          Container(
            width: valueWidth,
            height: valueHeight,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(height: isVerySmall ? 2 : 4),
          Container(
            width: subtitleWidth,
            height: subtitleHeight,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    // Sprawdź czy to karta "Kapitał pozostały" w trybie edycji
    final isCapitalRemaining = title == 'Kapitał pozostały';
    final showGoldBorder =
        isCapitalRemaining && _isEditModeEnabled && onTap != null;
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 1000),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: showGoldBorder
                        ? AppTheme.secondaryGold
                        : Colors.white.withOpacity(0.2),
                    width: showGoldBorder ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: showGoldBorder
                          ? AppTheme.secondaryGold.withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: showGoldBorder ? 15 : 10,
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
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
          ),
        );
      },
    );
  }

  // Kompaktowa wersja karty metryki dla mobilnych
  Widget _buildCompactMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 400; // ⭐ NOWE: Wykryj bardzo małe ekrany

    // Sprawdź czy to karta "Kapitał pozostały" w trybie edycji
    final isCapitalRemaining = title == 'Kapitał pozostały';
    final showGoldBorder =
        isCapitalRemaining && _isEditModeEnabled && onTap != null;

    // ⭐ ULEPSZONY: Responsywne rozmiary
    final cardHeight = isVerySmall ? 70.0 : 80.0;
    final padding = isVerySmall ? 8.0 : 12.0;
    final iconSize = isVerySmall ? 14.0 : 16.0;
    final titleFontSize = isVerySmall ? 10.0 : 11.0;
    final valueFontSize = isVerySmall ? 12.0 : 14.0;
    final subtitleFontSize = isVerySmall ? 9.0 : 10.0;

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 1000),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 15 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: cardHeight,
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: showGoldBorder
                        ? AppTheme.secondaryGold
                        : Colors.white.withOpacity(0.2),
                    width: showGoldBorder ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: showGoldBorder
                          ? AppTheme.secondaryGold.withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: showGoldBorder ? 12 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ⭐ ULEPSZONY: Lepszy layout dla bardzo małych ekranów
                    if (isVerySmall) ...[
                      // Kompaktowy layout - ikona i tytuł w jednej linii
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: color, size: iconSize),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                    fontSize: titleFontSize,
                                  ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Wartość i waluta w jednej linii
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                value,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.2,
                                      fontSize: valueFontSize,
                                    ),
                              ),
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(width: 2),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                    fontSize: subtitleFontSize,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      // Normalny layout
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: color, size: iconSize),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                    fontSize: titleFontSize,
                                  ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          value,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                                fontSize: valueFontSize,
                              ),
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                fontSize: subtitleFontSize,
                              ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Otwiera dialog edycji całkowitego kapitału pozostałego
  void _openTotalCapitalEditDialog() async {
    if (!_isEditModeEnabled) return;

    try {
      debugPrint(
        '🔍 [ProductDetailsHeader] Pobieranie inwestycji dla dialogu edycji kapitału...',
      );

      // ⭐ POPRAWIONA LOGIKA: Pobierz inwestycje używając bardziej elastycznego filtrowania
      final allInvestorSummaries = _modalData?.investors ?? <InvestorSummary>[];
      final allInvestments = <Investment>[];

      // Zbierz wszystkie inwestycje z investor summaries dla tego konkretnego produktu
      for (final investor in allInvestorSummaries) {
        for (final investment in investor.investments) {
          // Sprawdź czy inwestycja należy do tego produktu używając różnych kryteriów
          bool belongsToProduct = false;

          // Sprawdź po productId
          if (investment.productId != null &&
              investment.productId!.isNotEmpty &&
              investment.productId != "null") {
            if (investment.productId == widget.product.id) {
              belongsToProduct = true;
            }
          }

          // Fallback: sprawdź po nazwie produktu
          if (!belongsToProduct) {
            if (investment.productName.trim().toLowerCase() ==
                widget.product.name.trim().toLowerCase()) {
              belongsToProduct = true;
            }
          }

          if (belongsToProduct) {
            allInvestments.add(investment);
          }
        }
      }

      // Deduplikuj inwestycje po ID
      final uniqueInvestments = <String, Investment>{};
      for (final investment in allInvestments) {
        final key = investment.id.isNotEmpty
            ? investment.id
            : '${investment.productName}_${investment.investmentAmount}_${investment.clientId}';
        uniqueInvestments[key] = investment;
      }

      final investments = uniqueInvestments.values.toList();

      debugPrint(
        '📊 [ProductDetailsHeader] Znaleziono ${investments.length} unikalnych inwestycji dla dialogu',
      );
      if (investments.isNotEmpty) {
        final totalInvestmentAmount = investments.fold(
          0.0,
          (sum, inv) => sum + inv.investmentAmount,
        );
        debugPrint(
          '   - Suma inwestycji: ${totalInvestmentAmount.toStringAsFixed(2)}',
        );
      } else {
        debugPrint('   ⚠️ Brak inwestycji - sprawdź kryteria filtrowania');
        debugPrint('   - Product ID: ${widget.product.id}');
        debugPrint('   - Product Name: ${widget.product.name}');
        debugPrint('   - Dostępni inwestorzy: ${allInvestorSummaries.length}');

        // 🔄 FALLBACK: Użyj oryginalnej logiki jako backup
        debugPrint(
          '🔄 [ProductDetailsHeader] Próbuję backup: pobieranie przez InvestmentService...',
        );
        try {
          final service = InvestmentService();
          final allBackupInvestments = await service.getInvestmentsPaginated(
            limit: 1000,
          );
          final backupInvestments = allBackupInvestments
              .where(
                (inv) =>
                    inv.productId == widget.product.id ||
                    inv.productName.trim().toLowerCase() ==
                        widget.product.name.trim().toLowerCase(),
              )
              .toList();

          if (backupInvestments.isNotEmpty) {
            debugPrint(
              '✅ [ProductDetailsHeader] Backup znalazł ${backupInvestments.length} inwestycji',
            );
            final backupTotalInvestmentAmount = backupInvestments.fold(
              0.0,
              (sum, inv) => sum + inv.investmentAmount,
            );
            debugPrint(
              '   - Backup suma inwestycji: ${backupTotalInvestmentAmount.toStringAsFixed(2)}',
            );
            investments.addAll(backupInvestments);
          }
        } catch (e) {
          debugPrint('❌ [ProductDetailsHeader] Backup failed: $e');
        }
      }

      if (!mounted) return;

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => TotalCapitalEditDialog(
          product: widget.product,
          currentTotalCapital:
              _modalData?.statistics.totalRemainingCapital ??
              _computeTotalRemainingCapital(),
          investments: investments,
          onChanged: () async {
            // Wyczyść cache i wymuś pełne odświeżenie danych w headerze
            await _modalService.clearProductCache(widget.product.id);
            _loadServerStatisticsWithForceRefresh();

            // ⭐ NOWE: Wywołaj callback dla pełnego odświeżenia danych w parent modal
            if (widget.onDataChanged != null) {
              await widget.onDataChanged!();
            }
          },
        ),
      );

      if (result == true) {
        // Dialog został zamknięty z zapisaniem zmian
        debugPrint(
          '✅ [ProductDetailsHeader] Total capital updated successfully',
        );
      }
    } catch (e) {
      debugPrint(
        '❌ [ProductDetailsHeader] Error opening total capital edit dialog: $e',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas otwierania dialogu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
