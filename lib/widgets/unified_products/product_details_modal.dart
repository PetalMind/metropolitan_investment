import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../models_and_services.dart';
import '../dialogs/product_investors_tab.dart';
import '../dialogs/product_details_header.dart';

/// Modal ze szczegółami produktu z zakładkami
///
/// 🚀 FUNKCJE ODŚWIEŻANIA PO EDYCJI INWESTYCJI:
/// - Automatyczne odświeżanie przez didUpdateWidget() gdy modal się zaktualizuje
/// - Odświeżanie przez didChangeAppLifecycleState() gdy aplikacja wraca do foreground
/// - Callback onRefresh() w ProductInvestorsTab wywołuje pełne odświeżanie danych
/// - refreshAfterInvestmentEdit() umożliwia zewnętrzne triggowanie odświeżenia
/// - Podwójne odświeżenie z opóźnieniem dla pewności aktualności danych
///
/// Przepływ po edycji inwestycji:
/// 1. Użytkownik edytuje inwestycję w InvestorEditDialog
/// 2. Po zapisie InvestorEditDialog wywołuje onSaved()
/// 3. ProductInvestorsTab otrzymuje onSaved() i wywołuje widget.onRefresh()
/// 4. ProductDetailsModal odświeża _loadInvestors(forceRefresh: true) i _loadProduct()
/// 5. Dodatkowo po 500ms następuje dodatkowe odświeżenie dla pewności
class ProductDetailsModal extends StatefulWidget {
  final UnifiedProduct product;

  const ProductDetailsModal({super.key, required this.product});

  @override
  State<ProductDetailsModal> createState() => _ProductDetailsModalState();
}

class _ProductDetailsModalState extends State<ProductDetailsModal>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  // 🎯 NOWY: Jeden centralny serwis zamiast trzech
  final UnifiedProductModalService _modalService = UnifiedProductModalService();

  // 🎯 NOWY: Centralne dane modalu
  ProductModalData? _modalData;
  bool _isLoadingModalData = false;
  String? _modalError;

  // 🚀 NOWA OCHRONA: Flaga przeciw rekurencyjnemu odświeżaniu
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadModalData(); // 🎯 NOWY: Jedyne wywołanie ładowania danych
  }

  @override
  void didUpdateWidget(ProductDetailsModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 🎯 NOWY: Odśwież dane modalu jeśli produkt się zmienił
    if ((widget.product.id != oldWidget.product.id ||
            widget.product.name != oldWidget.product.name) &&
        !_isRefreshing) {
      debugPrint(
        '🔄 [ProductDetailsModal] didUpdateWidget - odświeżanie danych',
      );
      _loadModalData(forceRefresh: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 🎯 NOWY: Odśwież dane modalu gdy aplikacja wraca do foreground
    if (state == AppLifecycleState.resumed && mounted) {
      _loadModalData(forceRefresh: true);
    }
  }

  void _onTabChanged() {
    // 🎯 NOWY: Sprawdź czy mamy dane modalu, jeśli nie - załaduj
    if (_modalData == null && !_isLoadingModalData) {
      _loadModalData();
    }
  }

  // 🎯 NOWY: Pomocnicze gettery z centralnych danych
  List<InvestorSummary> get _investors => _modalData?.investors ?? [];
  UnifiedProduct get _freshProduct => _modalData?.product ?? widget.product;
  ProductModalStatistics get _statistics =>
      _modalData?.statistics ??
      ProductModalStatistics(
        totalInvestmentAmount: 0.0,
        totalRemainingCapital: 0.0,
        totalCapitalSecuredByRealEstate: 0.0,
        profitLoss: 0.0,
        profitLossPercentage: 0.0,
        totalInvestors: 0,
        activeInvestors: 0,
        inactiveInvestors: 0,
        averageCapitalPerInvestor: 0.0,
      );

  // 🎯 NOWY: Gettery kompatybilne z poprzednim kodem
  double get _totalInvestmentAmount => _statistics.totalInvestmentAmount;
  double get _totalRemainingCapital => _statistics.totalRemainingCapital;
  double get _totalCapitalSecuredByRealEstate =>
      _statistics.totalCapitalSecuredByRealEstate;
  bool get _isLoadingInvestors => _isLoadingModalData;
  String? get _investorsError => _modalError;

  /// ⭐ NOWA METODA: Publiczna metoda do odświeżania danych po edycji inwestycji
  /// Może być wywołana przez dialog edycji inwestora po zakończeniu edycji
  /// 🎯 NOWA METODA: Ładowanie centralnych danych modalu
  Future<void> _loadModalData({bool forceRefresh = false}) async {
    if (_isLoadingModalData) {
      debugPrint(
        '⚠️ [ProductDetailsModal] _loadModalData już w toku - pomijam',
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingModalData = true;
        _modalError = null;
      });
    }

    try {
      debugPrint('🎯 [ProductDetailsModal] Ładowanie danych modalu...');

      final modalData = await _modalService.getProductModalData(
        product: widget.product,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _modalData = modalData;
          _isLoadingModalData = false;
        });

        debugPrint('✅ [ProductDetailsModal] Dane modalu załadowane:');
        debugPrint('  - Inwestorzy: ${modalData.investors.length}');
        debugPrint(
          '  - Suma inwestycji: ${modalData.statistics.totalInvestmentAmount}',
        );
        debugPrint('  - Execution time: ${modalData.executionTime}ms');
      }
    } catch (e) {
      debugPrint('❌ [ProductDetailsModal] Błąd ładowania danych modalu: $e');
      if (mounted) {
        setState(() {
          _modalError = e.toString();
          _isLoadingModalData = false;
        });
      }
    }
  }

  void refreshAfterInvestmentEdit() {
    if (mounted && !_isRefreshing) {
      _isRefreshing = true;
      debugPrint(
        '🔄 [ProductDetailsModal] Odświeżanie danych po edycji inwestycji',
      );

      // 🎯 NOWY: Użyj nowego serwisu do odświeżenia
      _modalService
          .refreshAfterEdit(product: widget.product)
          .then((modalData) {
            if (mounted) {
              setState(() {
                _modalData = modalData;
                _isRefreshing = false;
              });
            }
            debugPrint('✅ [ProductDetailsModal] Dane odświeżone po edycji');
          })
          .catchError((e) {
            debugPrint('❌ [ProductDetailsModal] Błąd odświeżania: $e');
            if (mounted) {
              setState(() {
                _isRefreshing = false;
              });
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;

    // 📱 RESPONSIVE: Dostosuj wymiary do rozmiaru ekranu
    final horizontalPadding = isMobile ? 8.0 : (isTablet ? 24.0 : 32.0);
    final verticalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final maxWidth = isMobile
        ? screenSize.width * 0.95
        : (isTablet ? 600.0 : 900.0);
    final maxHeight = isMobile
        ? screenSize.height * 0.95
        : screenSize.height * 0.9;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          minWidth: isMobile ? 300 : 500,
          minHeight: isMobile ? 400 : 600,
        ),
        decoration: BoxDecoration(
          color: AppTheme.backgroundPrimary,
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          border: Border.all(
            color: AppTheme.borderPrimary.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: isMobile ? 20 : 40,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppTheme.primaryAccent.withOpacity(0.05),
              blurRadius: isMobile ? 10 : 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          child: Column(
            children: [
              ProductDetailsHeader(
                product: widget.product,
                investors: _investors,
                isLoadingInvestors: _isLoadingInvestors,
                onClose: () => Navigator.of(context).pop(),
                onDataChanged: () async {
                  // 🎯 NOWY: Callback do pełnego odświeżenia danych modalu po edycji kapitału
                  debugPrint('🔄 [ProductDetailsModal] Header data changed - refreshing all data');
                  try {
                    await _modalService.clearAllCache();
                    await _loadModalData(forceRefresh: true);
                  } catch (e) {
                    debugPrint('⚠️ [ProductDetailsModal] Error refreshing after header change: $e');
                  }
                },
              ),
              _buildResponsiveTabBar(context, isMobile, isTablet),
              Expanded(child: _buildTabBarView(context, isMobile, isTablet)),
            ],
          ),
        ),
      ),
    );
  }

  /// 📱 RESPONSIVE: Responsywny TabBar z lepszym designem
  Widget _buildResponsiveTabBar(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderSecondary.withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: TabBar(
          controller: _tabController,
          // 🎨 IMPROVED STYLING
          indicatorColor: AppTheme.primaryAccent,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppTheme.primaryAccent,
          unselectedLabelColor: AppTheme.textSecondary,
          dividerColor: Colors.transparent,
          overlayColor: MaterialStateProperty.all(
            AppTheme.primaryAccent.withOpacity(0.1),
          ),
          // 📱 RESPONSIVE TEXT STYLES
          labelStyle: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isMobile ? 12 : (isTablet ? 14 : 15),
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: isMobile ? 12 : (isTablet ? 14 : 15),
            letterSpacing: 0.3,
          ),
          // 📱 RESPONSIVE PADDING
          labelPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : (isTablet ? 12 : 16),
            vertical: isMobile ? 8 : 12,
          ),
          tabs: [
            _buildResponsiveTab(
              context,
              'Przegląd',
              Icons.dashboard_outlined,
              isMobile,
              isTablet,
            ),
            _buildResponsiveTab(
              context,
              'Inwestorzy',
              Icons.people_outline,
              isMobile,
              isTablet,
            ),
            _buildResponsiveTab(
              context,
              isMobile ? 'Analiza' : 'Analityka',
              Icons.analytics_outlined,
              isMobile,
              isTablet,
            ),
            _buildResponsiveTab(
              context,
              'Szczegóły',
              Icons.info_outline,
              isMobile,
              isTablet,
            ),
          ],
        ),
      ),
    );
  }

  /// 📱 RESPONSIVE: Responsywna zakładka z ikonami
  Widget _buildResponsiveTab(
    BuildContext context,
    String text,
    IconData icon,
    bool isMobile,
    bool isTablet,
  ) {
    if (isMobile) {
      // 📱 MOBILE: Tylko ikony lub bardzo krótki tekst
      return Tab(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            if (text.length <= 7) // Tylko krótkie teksty na mobile
              Text(
                text,
                style: const TextStyle(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      );
    } else {
      // 💻 DESKTOP/TABLET: Ikona + pełny tekst
      return Tab(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isTablet ? 18 : 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTabBarView(BuildContext context, bool isMobile, bool isTablet) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Zakładka przeglądu
        _buildOverviewTab(context, isMobile, isTablet),

        // Zakładka inwestorów
        _buildInvestorsTab(context, isMobile, isTablet),

        // Zakładka analityki
        _buildAnalyticsTab(context, isMobile, isTablet),

        // Zakładka szczegółów
        _buildDetailsTab(context, isMobile, isTablet),
      ],
    );
  }

  Widget _buildDetailsTab(BuildContext context, bool isMobile, bool isTablet) {
    final product = _freshProduct;
    final horizontalPadding = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);

    return SingleChildScrollView(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingModalData)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    SizedBox(
                      width: isMobile ? 32 : 40,
                      height: isMobile ? 32 : 40,
                      child: const CircularProgressIndicator(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ładowanie aktualnych danych produktu…',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_modalError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: isMobile ? 32 : 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Błąd pobierania danych produktu',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.errorColor,
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _modalError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                        fontSize: isMobile ? 12 : 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _loadModalData(forceRefresh: true),
                      icon: Icon(Icons.refresh, size: isMobile ? 16 : 18),
                      label: Text(
                        'Ponów próbę',
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Sekcja kwot
          _buildAmountsSection(context, isMobile, isTablet),

          const SizedBox(height: 24),

          // Sekcja szczegółów
          _buildDetailsSection(context, isMobile, isTablet),

          if (product.productType == UnifiedProductType.bonds) ...[
            const SizedBox(height: 24),
            _buildBondsSpecificSection(context, isMobile, isTablet),
          ],

          if (product.productType == UnifiedProductType.shares) ...[
            const SizedBox(height: 24),
            _buildSharesSpecificSection(context, isMobile, isTablet),
          ],
          const SizedBox(height: 24),
          _buildSourceInfoBar(product, isMobile, isTablet),
        ],
      ),
    );
  }

  Widget _buildInvestorsTab(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    return ProductInvestorsTab(
      product: widget.product,
      investors: _investors,
      isLoading: _isLoadingInvestors,
      error: _investorsError,
      onRefresh: () async {
        // 🎯 NOWY: Odśwież dane modalu
        debugPrint(
          '🔄 [ProductDetailsModal] onRefresh wywołany - odświeżanie danych',
        );

        try {
          await _modalService.clearAllCache();
          debugPrint('✅ [ProductDetailsModal] Cache wyczyszczony');
        } catch (e) {
          debugPrint('⚠️ [ProductDetailsModal] Błąd czyszczenia cache: $e');
        }

        await _loadModalData(forceRefresh: true);
        debugPrint('✅ [ProductDetailsModal] onRefresh ukończony');
      },
    );
  }

  Widget _buildAmountsSection(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    final horizontalPadding = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);
    final verticalPadding = isMobile ? 16.0 : 20.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        border: Border.all(
          color: AppTheme.borderPrimary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wartości finansowe',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: isMobile ? 16 : (isTablet ? 18 : 20),
            ),
          ),

          SizedBox(height: isMobile ? 12 : 16),

          if (isMobile)
            _buildAmountsMobileLayout(context)
          else
            _buildAmountsDesktopLayout(context, isTablet),
        ],
      ),
    );
  }

  Widget _buildAmountsMobileLayout(BuildContext context) {
    return Column(
      children: [
        AmountCard(
          title: 'Suma inwestycji',
          value: CurrencyFormatter.formatCurrency(_totalInvestmentAmount),
          icon: Icons.trending_down,
          color: AppTheme.infoPrimary,
        ),

        const SizedBox(height: 12),

        AmountCard(
          title: 'Kapitał pozostały',
          value: CurrencyFormatter.formatCurrency(_totalRemainingCapital),
          icon: Icons.account_balance_wallet,
          color: AppTheme.successPrimary,
          isHighlight: true,
        ),

        const SizedBox(height: 12),

        AmountCard(
          title: 'Zabezpieczony nieruchomością',
          value: CurrencyFormatter.formatCurrency(
            _totalCapitalSecuredByRealEstate,
          ),
          icon: Icons.home,
          color: AppTheme.warningPrimary,
        ),
      ],
    );
  }

  Widget _buildAmountsDesktopLayout(BuildContext context, bool isTablet) {
    final cardSpacing = isTablet ? 12.0 : 16.0;
    final cardPadding = isTablet
        ? const EdgeInsets.all(12)
        : const EdgeInsets.all(16);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AmountCard(
                title: 'Suma inwestycji',
                value: CurrencyFormatter.formatCurrency(_totalInvestmentAmount),
                icon: Icons.trending_down,
                color: AppTheme.infoPrimary,
                padding: cardPadding,
              ),
            ),
            SizedBox(width: cardSpacing),
            Expanded(
              child: AmountCard(
                title: 'Kapitał pozostały',
                value: CurrencyFormatter.formatCurrency(_totalRemainingCapital),
                icon: Icons.account_balance_wallet,
                color: AppTheme.successPrimary,
                isHighlight: true,
                padding: cardPadding,
              ),
            ),
          ],
        ),

        SizedBox(height: cardSpacing),

        AmountCard(
          title: 'Kapitał zabezpieczony nieruchomością',
          value: CurrencyFormatter.formatCurrency(
            _totalCapitalSecuredByRealEstate,
          ),
          icon: Icons.home,
          color: AppTheme.warningPrimary,
          padding: cardPadding,
        ),
      ],
    );
  }

  Widget _buildDetailsSection(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    final padding = EdgeInsets.all(isMobile ? 16 : 20);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: AppTheme.elevatedSurfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Szczegóły produktu',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: isMobile ? 16 : 18,
            ),
          ),

          SizedBox(height: isMobile ? 12 : 16),

          ...widget.product.detailsList.map((detail) {
            return Padding(
              padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: isMobile ? 2 : 1,
                    child: Text(
                      detail.key,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: isMobile ? 13 : 14,
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    flex: isMobile ? 2 : 1,
                    child: Text(
                      detail.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 13 : 14,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBondsSpecificSection(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    if (widget.product.realizedCapital == null &&
        widget.product.remainingCapital == null &&
        widget.product.realizedInterest == null &&
        widget.product.remainingInterest == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.elevatedSurfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Szczegóły obligacji',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          if (isMobile)
            _buildBondsDetailsMobile(context)
          else
            _buildBondsDetailsDesktop(context),
        ],
      ),
    );
  }

  Widget _buildBondsDetailsMobile(BuildContext context) {
    return Column(
      children: [
        if (widget.product.realizedCapital != null &&
            widget.product.realizedCapital! > 0)
          DetailRow(
            label: 'Zrealizowany kapitał',
            value: CurrencyFormatter.formatCurrency(
              widget.product.realizedCapital!,
            ),
            icon: Icons.check_circle,
            color: AppTheme.successColor,
          ),

        if (widget.product.remainingCapital != null &&
            widget.product.remainingCapital! > 0)
          DetailRow(
            label: 'Pozostały kapitał',
            value: CurrencyFormatter.formatCurrency(
              widget.product.remainingCapital!,
            ),
            icon: Icons.account_balance_wallet,
            color: AppTheme.primaryAccent,
          ),

        if (widget.product.realizedInterest != null &&
            widget.product.realizedInterest! > 0)
          DetailRow(
            label: 'Zrealizowane odsetki',
            value: CurrencyFormatter.formatCurrency(
              widget.product.realizedInterest!,
            ),
            icon: Icons.trending_up,
            color: AppTheme.successColor,
          ),

        if (widget.product.remainingInterest != null &&
            widget.product.remainingInterest! > 0)
          DetailRow(
            label: 'Pozostałe odsetki',
            value: CurrencyFormatter.formatCurrency(
              widget.product.remainingInterest!,
            ),
            icon: Icons.schedule,
            color: AppTheme.warningColor,
          ),
      ],
    );
  }

  Widget _buildBondsDetailsDesktop(BuildContext context) {
    final leftDetails = <Widget>[];
    final rightDetails = <Widget>[];

    if (widget.product.realizedCapital != null &&
        widget.product.realizedCapital! > 0) {
      leftDetails.add(
        DetailRow(
          label: 'Zrealizowany kapitał',
          value: CurrencyFormatter.formatCurrency(
            widget.product.realizedCapital!,
          ),
          icon: Icons.check_circle,
          color: AppTheme.successColor,
        ),
      );
    }

    if (widget.product.remainingCapital != null &&
        widget.product.remainingCapital! > 0) {
      rightDetails.add(
        DetailRow(
          label: 'Pozostały kapitał',
          value: CurrencyFormatter.formatCurrency(
            widget.product.remainingCapital!,
          ),
          icon: Icons.account_balance_wallet,
          color: AppTheme.primaryAccent,
        ),
      );
    }

    if (widget.product.realizedInterest != null &&
        widget.product.realizedInterest! > 0) {
      leftDetails.add(
        DetailRow(
          label: 'Zrealizowane odsetki',
          value: CurrencyFormatter.formatCurrency(
            widget.product.realizedInterest!,
          ),
          icon: Icons.trending_up,
          color: AppTheme.successColor,
        ),
      );
    }

    if (widget.product.remainingInterest != null &&
        widget.product.remainingInterest! > 0) {
      rightDetails.add(
        DetailRow(
          label: 'Pozostałe odsetki',
          value: CurrencyFormatter.formatCurrency(
            widget.product.remainingInterest!,
          ),
          icon: Icons.schedule,
          color: AppTheme.warningColor,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: leftDetails)),
        const SizedBox(width: 24),
        Expanded(child: Column(children: rightDetails)),
      ],
    );
  }

  Widget _buildSharesSpecificSection(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    if (widget.product.sharesCount == null &&
        widget.product.pricePerShare == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.elevatedSurfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Szczegóły udziałów',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          if (widget.product.sharesCount != null &&
              widget.product.sharesCount! > 0)
            DetailRow(
              label: 'Liczba udziałów',
              value: '${widget.product.sharesCount}',
              icon: Icons.pie_chart,
              color: AppTheme.primaryAccent,
            ),

          if (widget.product.pricePerShare != null &&
              widget.product.pricePerShare! > 0)
            DetailRow(
              label: 'Cena za udział',
              value: CurrencyFormatter.formatCurrency(
                widget.product.pricePerShare!,
              ),
              icon: Icons.monetization_on,
              color: AppTheme.secondaryGold,
            ),
        ],
      ),
    );
  }

  Widget _buildSourceInfoBar(
    UnifiedProduct product,
    bool isMobile,
    bool isTablet,
  ) {
    final padding = EdgeInsets.all(isMobile ? 10 : 14);
    final spacing = isMobile ? 8.0 : 16.0;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSecondary),
      ),
      child: Wrap(
        spacing: spacing,
        runSpacing: isMobile ? 4 : 8,
        children: [
          MetaChip(icon: Icons.tag, text: 'ID: ${product.id}'),
          MetaChip(
            icon: Icons.upload,
            text:
                'Aktualizacja: ${product.uploadedAt.day.toString().padLeft(2, '0')}.${product.uploadedAt.month.toString().padLeft(2, '0')}.${product.uploadedAt.year}',
          ),
          MetaChip(
            icon: Icons.calendar_today,
            text:
                'Utworzono: ${product.createdAt.day.toString().padLeft(2, '0')}.${product.createdAt.month.toString().padLeft(2, '0')}.${product.createdAt.year}',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, bool isMobile, bool isTablet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statystyki główne
          _buildMainStatsCards(context, isMobile),

          const SizedBox(height: 24),

          // Sekcja kwot - uproszczona w przegladzie
          _buildQuickAmountsSection(context, isMobile),

          const SizedBox(height: 24),

          // Top inwestorzy - podgląd
          _buildTopInvestorsPreview(context),

          const SizedBox(height: 24),

          // Status i kluczowe informacje
          _buildKeyInfoSection(context),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wykresy i analiza
          _buildAnalyticsCharts(context, isMobile),

          const SizedBox(height: 24),

          // Metryki performensu
          _buildPerformanceMetrics(context, isMobile),

          const SizedBox(height: 24),

          // Analiza inwestorów
          _buildInvestorAnalytics(context, isMobile),

          const SizedBox(height: 24),

          // Trendy i prognozy
          _buildTrendsSection(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildMainStatsCards(BuildContext context, bool isMobile) {
    final stats = _statistics;
    final totalInvestors = stats.totalInvestors;
    final totalRemainingCapital = stats.totalRemainingCapital;

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isMobile ? 1.2 : 1.3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        StatCard(
          title: 'Inwestorzy',
          value: totalInvestors.toString(),
          icon: Icons.people,
          color: AppTheme.primaryAccent,
        ),
        StatCard(
          title: 'Suma inwestycji',
          value: CurrencyFormatter.formatCurrencyShort(
            stats.totalInvestmentAmount,
          ),
          icon: Icons.trending_down,
          color: AppTheme.infoPrimary,
        ),
        StatCard(
          title: 'Kapitał pozostały',
          value: CurrencyFormatter.formatCurrencyShort(totalRemainingCapital),
          icon: Icons.account_balance_wallet,
          color: AppTheme.successPrimary,
        ),
        StatCard(
          title: 'Zabezpiecz. nieru.',
          value: CurrencyFormatter.formatCurrencyShort(
            stats.totalCapitalSecuredByRealEstate,
          ),
          icon: Icons.home,
          color: AppTheme.warningPrimary,
        ),
      ],
    );
  }

  Widget _buildQuickAmountsSection(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: AppTheme.primaryAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Przegląd finansowy',
              style: TextStyle(
                color: AppTheme.primaryAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderPrimary),
          ),
          child: Row(
            children: [
              Expanded(
                child: AmountInfo(
                  label: 'Suma inwestycji',
                  amount: _totalInvestmentAmount,
                  icon: Icons.trending_down,
                  color: AppTheme.errorPrimary,
                  formatter: CurrencyFormatter.formatCurrency,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppTheme.borderPrimary,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: AmountInfo(
                  label: 'Kapitał pozostały',
                  amount: _totalRemainingCapital,
                  icon: Icons.account_balance_wallet,
                  color: AppTheme.successPrimary,
                  formatter: CurrencyFormatter.formatCurrency,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppTheme.borderPrimary,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: AmountInfo(
                  label: 'Zabezpiecz. nieru.',
                  amount: _totalCapitalSecuredByRealEstate,
                  icon: Icons.home,
                  color: AppTheme.warningPrimary,
                  formatter: CurrencyFormatter.formatCurrency,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopInvestorsPreview(BuildContext context) {
    if (_isLoadingInvestors) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final topInvestors = _investors.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: AppTheme.secondaryGold, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Top inwestorzy',
                  style: TextStyle(
                    color: AppTheme.primaryAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: Text('Zobacz wszystkich →'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (topInvestors.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Brak inwestorów',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...topInvestors.map(
            (investor) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderPrimary),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryAccent.withValues(
                      alpha: 0.1,
                    ),
                    child: Text(
                      investor.client.name.isNotEmpty
                          ? investor.client.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppTheme.primaryAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investor.client.name,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${investor.investmentCount} inwestycji',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatCurrencyShort(investor.totalValue),
                    style: TextStyle(
                      color: AppTheme.primaryAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildKeyInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              'Kluczowe informacje',
              style: TextStyle(
                color: AppTheme.primaryAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderPrimary),
          ),
          child: Column(
            children: [
              _buildKeyInfoRow(
                'Typ produktu',
                widget.product.productType.displayName,
              ),
              const Divider(),
              _buildKeyInfoRow('Nazwa', widget.product.name),
              const Divider(),
              _buildKeyInfoRow('Opis', widget.product.description),
              if (widget.product.maturityDate != null) ...[
                const Divider(),
                _buildKeyInfoRow(
                  'Data zapadalności',
                  '${widget.product.maturityDate!.day.toString().padLeft(2, '0')}.${widget.product.maturityDate!.month.toString().padLeft(2, '0')}.${widget.product.maturityDate!.year}',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCharts(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: AppTheme.primaryAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              'Analiza wyników',
              style: TextStyle(
                color: AppTheme.primaryAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderPrimary),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 48, color: AppTheme.textSecondary),
                const SizedBox(height: 12),
                Text(
                  'Wykres wydajności w czasie',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Funkcjonalność będzie dostępna wkrótce',
                  style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceMetrics(BuildContext context, bool isMobile) {
    // 🎯 NOWY: Użyj statystyk z centralnego serwisu
    final stats = _statistics;
    final profitLoss = stats.profitLoss;
    final profitLossPercentage = stats.profitLossPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, color: AppTheme.primaryAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              'Metryki wydajności',
              style: TextStyle(
                color: AppTheme.primaryAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        GridView.count(
          crossAxisCount: isMobile ? 1 : 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isMobile ? 4 : 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            PerformanceCard(
              title: 'Zysk/Strata',
              value: CurrencyFormatter.formatCurrency(profitLoss),
              color: profitLoss >= 0
                  ? AppTheme.successPrimary
                  : AppTheme.errorPrimary,
              icon: profitLoss >= 0 ? Icons.trending_up : Icons.trending_down,
            ),
            PerformanceCard(
              title: 'ROI',
              value: '${profitLossPercentage.toStringAsFixed(1)}%',
              color: profitLossPercentage >= 0
                  ? AppTheme.successPrimary
                  : AppTheme.errorPrimary,
              icon: profitLossPercentage >= 0
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
            ),
            PerformanceCard(
              title: 'Średnia na inwestora',
              value: CurrencyFormatter.formatCurrencyShort(
                stats.averageCapitalPerInvestor,
              ),
              color: AppTheme.primaryAccent,
              icon: Icons.person,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvestorAnalytics(BuildContext context, bool isMobile) {
    final stats = _statistics;
    final activeInvestors = stats.activeInvestors;
    final inactiveInvestors = stats.inactiveInvestors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people_outline, color: AppTheme.primaryAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              'Analiza inwestorów',
              style: TextStyle(
                color: AppTheme.primaryAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.successPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      activeInvestors.toString(),
                      style: TextStyle(
                        color: AppTheme.successPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aktywni inwestorzy',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warningPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      inactiveInvestors.toString(),
                      style: TextStyle(
                        color: AppTheme.warningPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nieaktywni',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendsSection(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timeline, color: AppTheme.primaryAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              'Trendy i prognozy',
              style: TextStyle(
                color: AppTheme.primaryAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderPrimary),
          ),
          child: Column(
            children: [
              Icon(Icons.insights, size: 48, color: AppTheme.textSecondary),
              const SizedBox(height: 12),
              Text(
                'Analiza trendów',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Zaawansowane prognozy i analiza trendów będą dostępne wkrótce',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
