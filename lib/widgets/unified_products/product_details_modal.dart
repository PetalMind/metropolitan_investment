import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../models/unified_product.dart';
import '../../models/investor_summary.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../services/firebase_functions_product_investors_service.dart';
import '../dialogs/product_investors_tab.dart';

/// Modal ze szczegółami produktu z zakładkami
class ProductDetailsModal extends StatefulWidget {
  final UnifiedProduct product;

  const ProductDetailsModal({super.key, required this.product});

  @override
  State<ProductDetailsModal> createState() => _ProductDetailsModalState();
}

class _ProductDetailsModalState extends State<ProductDetailsModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFunctionsProductInvestorsService _investorsService =
      FirebaseFunctionsProductInvestorsService();

  List<InvestorSummary> _investors = [];
  bool _isLoadingInvestors = false;
  String? _investorsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadInvestors(); // Załaduj inwestorów od razu
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1 &&
        _investors.isEmpty &&
        !_isLoadingInvestors) {
      _loadInvestors();
    }
  }

  Future<void> _loadInvestors() async {
    if (_isLoadingInvestors) return;

    setState(() {
      _isLoadingInvestors = true;
      _investorsError = null;
    });

    try {
      final result = await _investorsService.getProductInvestors(
        productId: widget.product.id,
        productName: widget.product.name,
        productType: widget.product.productType.name.toLowerCase(),
        searchStrategy: 'comprehensive',
      );
      final investors = result.investors;

      if (mounted) {
        setState(() {
          _investors = investors;
          _isLoadingInvestors = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _investorsError = e.toString();
          _isLoadingInvestors = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 24 : 32,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 700,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: AppTheme.premiumCardDecoration,
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(context),
            Expanded(child: _buildTabBarView(context, isMobile)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final productColor = AppTheme.getProductTypeColor(
      widget.product.productType.name,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            productColor.withValues(alpha: 0.1),
            productColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Ikona produktu
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: productColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: productColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(_getProductIcon(), color: productColor, size: 28),
          ),

          const SizedBox(width: 16),

          // Informacje główne
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: productColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: productColor.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.product.productType.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: productColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(context),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.product.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.product.companyName != null &&
                    widget.product.companyName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.product.companyName!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Przycisk zamknięcia
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            color: AppTheme.textSecondary,
            tooltip: 'Zamknij',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final statusColor = widget.product.isActive
        ? AppTheme.successColor
        : AppTheme.errorColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            widget.product.status.displayName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSecondary, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primaryAccent,
        labelColor: AppTheme.primaryAccent,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Przegląd', icon: Icon(Icons.dashboard_outlined, size: 20)),
          Tab(text: 'Inwestorzy', icon: Icon(Icons.people_outline, size: 20)),
          Tab(
            text: 'Analityka',
            icon: Icon(Icons.analytics_outlined, size: 20),
          ),
          Tab(text: 'Szczegóły', icon: Icon(Icons.info_outline, size: 20)),
        ],
      ),
    );
  }

  Widget _buildTabBarView(BuildContext context, bool isMobile) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Zakładka przeglądu
        _buildOverviewTab(context, isMobile),

        // Zakładka inwestorów
        _buildInvestorsTab(context),

        // Zakładka analityki
        _buildAnalyticsTab(context, isMobile),

        // Zakładka szczegółów
        _buildDetailsTab(context, isMobile),
      ],
    );
  }

  Widget _buildDetailsTab(BuildContext context, bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sekcja kwot
          _buildAmountsSection(context, isMobile),

          const SizedBox(height: 24),

          // Sekcja szczegółów
          _buildDetailsSection(context, isMobile),

          if (widget.product.productType == UnifiedProductType.bonds) ...[
            const SizedBox(height: 24),
            _buildBondsSpecificSection(context, isMobile),
          ],

          if (widget.product.productType == UnifiedProductType.shares) ...[
            const SizedBox(height: 24),
            _buildSharesSpecificSection(context, isMobile),
          ],

          const SizedBox(height: 24),
          _buildFooterInfo(context),
        ],
      ),
    );
  }

  Widget _buildInvestorsTab(BuildContext context) {
    return ProductInvestorsTab(
      product: widget.product,
      investors: _investors,
      isLoading: _isLoadingInvestors,
      error: _investorsError,
      onRefresh: _loadInvestors,
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color ?? AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color ?? AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: color != null
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountsSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.elevatedSurfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wartości finansowe',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          if (isMobile)
            _buildAmountsMobileLayout(context)
          else
            _buildAmountsDesktopLayout(context),
        ],
      ),
    );
  }

  Widget _buildAmountsMobileLayout(BuildContext context) {
    return Column(
      children: [
        if (widget.product.investmentAmount > 0)
          _buildAmountCard(
            context,
            'Kwota inwestycji',
            CurrencyFormatter.formatCurrency(widget.product.investmentAmount),
            Icons.account_balance_wallet_outlined,
            AppTheme.primaryAccent,
          ),

        const SizedBox(height: 12),

        _buildAmountCard(
          context,
          'Wartość całkowita',
          CurrencyFormatter.formatCurrency(widget.product.totalValue),
          Icons.trending_up,
          AppTheme.secondaryGold,
          isHighlight: true,
        ),
      ],
    );
  }

  Widget _buildAmountsDesktopLayout(BuildContext context) {
    return Row(
      children: [
        if (widget.product.investmentAmount > 0) ...[
          Expanded(
            child: _buildAmountCard(
              context,
              'Kwota inwestycji',
              CurrencyFormatter.formatCurrency(widget.product.investmentAmount),
              Icons.account_balance_wallet_outlined,
              AppTheme.primaryAccent,
            ),
          ),
          const SizedBox(width: 16),
        ],

        Expanded(
          child: _buildAmountCard(
            context,
            'Wartość całkowita',
            CurrencyFormatter.formatCurrency(widget.product.totalValue),
            Icons.trending_up,
            AppTheme.secondaryGold,
            isHighlight: true,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isHighlight = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlight
            ? color.withValues(alpha: 0.05)
            : AppTheme.surfaceCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight
              ? color.withValues(alpha: 0.2)
              : AppTheme.borderSecondary,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isHighlight ? color : AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.elevatedSurfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Szczegóły produktu',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          ...widget.product.detailsList.map((detail) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: isMobile ? 2 : 1,
                    child: Text(
                      detail.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
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

  Widget _buildBondsSpecificSection(BuildContext context, bool isMobile) {
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
          _buildDetailRow(
            'Zrealizowany kapitał',
            CurrencyFormatter.formatCurrency(widget.product.realizedCapital!),
            Icons.check_circle,
            color: AppTheme.successColor,
          ),

        if (widget.product.remainingCapital != null &&
            widget.product.remainingCapital! > 0)
          _buildDetailRow(
            'Pozostały kapitał',
            CurrencyFormatter.formatCurrency(widget.product.remainingCapital!),
            Icons.account_balance_wallet,
            color: AppTheme.primaryAccent,
          ),

        if (widget.product.realizedInterest != null &&
            widget.product.realizedInterest! > 0)
          _buildDetailRow(
            'Zrealizowane odsetki',
            CurrencyFormatter.formatCurrency(widget.product.realizedInterest!),
            Icons.trending_up,
            color: AppTheme.successColor,
          ),

        if (widget.product.remainingInterest != null &&
            widget.product.remainingInterest! > 0)
          _buildDetailRow(
            'Pozostałe odsetki',
            CurrencyFormatter.formatCurrency(widget.product.remainingInterest!),
            Icons.schedule,
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
        _buildDetailRow(
          'Zrealizowany kapitał',
          CurrencyFormatter.formatCurrency(widget.product.realizedCapital!),
          Icons.check_circle,
          color: AppTheme.successColor,
        ),
      );
    }

    if (widget.product.remainingCapital != null &&
        widget.product.remainingCapital! > 0) {
      rightDetails.add(
        _buildDetailRow(
          'Pozostały kapitał',
          CurrencyFormatter.formatCurrency(widget.product.remainingCapital!),
          Icons.account_balance_wallet,
          color: AppTheme.primaryAccent,
        ),
      );
    }

    if (widget.product.realizedInterest != null &&
        widget.product.realizedInterest! > 0) {
      leftDetails.add(
        _buildDetailRow(
          'Zrealizowane odsetki',
          CurrencyFormatter.formatCurrency(widget.product.realizedInterest!),
          Icons.trending_up,
          color: AppTheme.successColor,
        ),
      );
    }

    if (widget.product.remainingInterest != null &&
        widget.product.remainingInterest! > 0) {
      rightDetails.add(
        _buildDetailRow(
          'Pozostałe odsetki',
          CurrencyFormatter.formatCurrency(widget.product.remainingInterest!),
          Icons.schedule,
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

  Widget _buildSharesSpecificSection(BuildContext context, bool isMobile) {
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
            _buildDetailRow(
              'Liczba udziałów',
              '${widget.product.sharesCount}',
              Icons.pie_chart,
              color: AppTheme.primaryAccent,
            ),

          if (widget.product.pricePerShare != null &&
              widget.product.pricePerShare! > 0)
            _buildDetailRow(
              'Cena za udział',
              CurrencyFormatter.formatCurrency(widget.product.pricePerShare!),
              Icons.monetization_on,
              color: AppTheme.secondaryGold,
            ),
        ],
      ),
    );
  }

  Widget _buildFooterInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, bool isMobile) {
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

  Widget _buildAnalyticsTab(BuildContext context, bool isMobile) {
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
    final totalInvestors = _investors.length;
    final totalInvestment = widget.product.totalValue;
    final averageInvestment = totalInvestors > 0
        ? totalInvestment / totalInvestors
        : 0.0;

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isMobile ? 1.2 : 1.3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          'Inwestorzy',
          totalInvestors.toString(),
          Icons.people,
          AppTheme.primaryAccent,
        ),
        _buildStatCard(
          'Wartość całkowita',
          CurrencyFormatter.formatCurrencyShort(totalInvestment),
          Icons.account_balance_wallet,
          AppTheme.successPrimary,
        ),
        _buildStatCard(
          'Średnia inwestycja',
          CurrencyFormatter.formatCurrencyShort(averageInvestment),
          Icons.trending_up,
          AppTheme.warningPrimary,
        ),
        _buildStatCard(
          'Status',
          _getProductStatusText(),
          Icons.info,
          _getProductStatusColor(),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
                child: _buildAmountInfo(
                  'Kwota inwestycji',
                  widget.product.investmentAmount,
                  Icons.trending_down,
                  AppTheme.errorPrimary,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppTheme.borderPrimary,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _buildAmountInfo(
                  'Wartość całkowita',
                  widget.product.totalValue,
                  Icons.trending_up,
                  AppTheme.successPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInfo(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          CurrencyFormatter.formatCurrency(amount),
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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
    final profitLoss =
        widget.product.totalValue - widget.product.investmentAmount;
    final profitLossPercentage = widget.product.investmentAmount > 0
        ? (profitLoss / widget.product.investmentAmount) * 100
        : 0.0;

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
            _buildPerformanceCard(
              'Zysk/Strata',
              CurrencyFormatter.formatCurrency(profitLoss),
              profitLoss >= 0 ? AppTheme.successPrimary : AppTheme.errorPrimary,
              profitLoss >= 0 ? Icons.trending_up : Icons.trending_down,
            ),
            _buildPerformanceCard(
              'ROI',
              '${profitLossPercentage.toStringAsFixed(1)}%',
              profitLossPercentage >= 0
                  ? AppTheme.successPrimary
                  : AppTheme.errorPrimary,
              profitLossPercentage >= 0
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
            ),
            _buildPerformanceCard(
              'Średnia na inwestora',
              CurrencyFormatter.formatCurrencyShort(
                _investors.isNotEmpty
                    ? widget.product.totalValue / _investors.length
                    : 0,
              ),
              AppTheme.primaryAccent,
              Icons.person,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInvestorAnalytics(BuildContext context, bool isMobile) {
    final activeInvestors = _investors.where((i) => i.client.isActive).length;
    final inactiveInvestors = _investors.length - activeInvestors;

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

  String _getProductStatusText() {
    if (widget.product.maturityDate != null) {
      final now = DateTime.now();
      final daysToMaturity = widget.product.maturityDate!
          .difference(now)
          .inDays;

      if (daysToMaturity < 0) {
        return 'Przeterminowany';
      } else if (daysToMaturity < 30) {
        return 'Wkrótce zapadalność';
      } else {
        return 'Aktywny';
      }
    }
    return 'Aktywny';
  }

  Color _getProductStatusColor() {
    if (widget.product.maturityDate != null) {
      final now = DateTime.now();
      final daysToMaturity = widget.product.maturityDate!
          .difference(now)
          .inDays;

      if (daysToMaturity < 0) {
        return AppTheme.errorPrimary;
      } else if (daysToMaturity < 30) {
        return AppTheme.warningPrimary;
      } else {
        return AppTheme.successPrimary;
      }
    }
    return AppTheme.successPrimary;
  }

  IconData _getProductIcon() {
    switch (widget.product.productType) {
      case UnifiedProductType.bonds:
        return Icons.account_balance;
      case UnifiedProductType.shares:
        return Icons.trending_up;
      case UnifiedProductType.loans:
        return Icons.handshake;
      case UnifiedProductType.apartments:
        return Icons.home;
      case UnifiedProductType.other:
        return Icons.category;
    }
  }
}
