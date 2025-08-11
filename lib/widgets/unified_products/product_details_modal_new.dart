import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../models/unified_product.dart';
import '../../models/investor_summary.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../services/firebase_functions_product_investors_service.dart';
import 'product_investors_list.dart';

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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
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
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            _buildTabBar(context),
            Flexible(child: _buildTabBarView(context, isMobile)),
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
          Tab(text: 'Szczegóły', icon: Icon(Icons.info_outline, size: 20)),
          Tab(text: 'Inwestorzy', icon: Icon(Icons.people_outline, size: 20)),
        ],
      ),
    );
  }

  Widget _buildTabBarView(BuildContext context, bool isMobile) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Zakładka szczegółów
        _buildDetailsTab(context, isMobile),

        // Zakładka inwestorów
        _buildInvestorsTab(context),
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ProductInvestorsList(
        investors: _investors,
        isLoading: _isLoadingInvestors,
        errorMessage: _investorsError,
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
            context,
            'Zrealizowany kapitał',
            CurrencyFormatter.formatCurrency(widget.product.realizedCapital!),
            AppTheme.successColor,
          ),

        if (widget.product.remainingCapital != null &&
            widget.product.remainingCapital! > 0)
          _buildDetailRow(
            context,
            'Pozostały kapitał',
            CurrencyFormatter.formatCurrency(widget.product.remainingCapital!),
            AppTheme.primaryAccent,
          ),

        if (widget.product.realizedInterest != null &&
            widget.product.realizedInterest! > 0)
          _buildDetailRow(
            context,
            'Zrealizowane odsetki',
            CurrencyFormatter.formatCurrency(widget.product.realizedInterest!),
            AppTheme.successColor,
          ),

        if (widget.product.remainingInterest != null &&
            widget.product.remainingInterest! > 0)
          _buildDetailRow(
            context,
            'Pozostałe odsetki',
            CurrencyFormatter.formatCurrency(widget.product.remainingInterest!),
            AppTheme.warningColor,
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
          context,
          'Zrealizowany kapitał',
          CurrencyFormatter.formatCurrency(widget.product.realizedCapital!),
          AppTheme.successColor,
        ),
      );
    }

    if (widget.product.remainingCapital != null &&
        widget.product.remainingCapital! > 0) {
      rightDetails.add(
        _buildDetailRow(
          context,
          'Pozostały kapitał',
          CurrencyFormatter.formatCurrency(widget.product.remainingCapital!),
          AppTheme.primaryAccent,
        ),
      );
    }

    if (widget.product.realizedInterest != null &&
        widget.product.realizedInterest! > 0) {
      leftDetails.add(
        _buildDetailRow(
          context,
          'Zrealizowane odsetki',
          CurrencyFormatter.formatCurrency(widget.product.realizedInterest!),
          AppTheme.successColor,
        ),
      );
    }

    if (widget.product.remainingInterest != null &&
        widget.product.remainingInterest! > 0) {
      rightDetails.add(
        _buildDetailRow(
          context,
          'Pozostałe odsetki',
          CurrencyFormatter.formatCurrency(widget.product.remainingInterest!),
          AppTheme.warningColor,
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
              context,
              'Liczba udziałów',
              '${widget.product.sharesCount}',
              AppTheme.primaryAccent,
            ),

          if (widget.product.pricePerShare != null &&
              widget.product.pricePerShare! > 0)
            _buildDetailRow(
              context,
              'Cena za udział',
              CurrencyFormatter.formatCurrency(widget.product.pricePerShare!),
              AppTheme.secondaryGold,
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
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppTheme.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Źródło danych: ${widget.product.sourceFile}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
