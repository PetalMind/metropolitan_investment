import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/standard_product_investors_service.dart';
import 'standard_product_details_tab.dart';
import 'standard_product_investors_tab.dart';
import 'standard_product_analytics_tab.dart';
import 'standard_product_performance_tab.dart';

/// Zaawansowany dialog dla standardowych produktów
///
/// Oferuje kompleksowy widok produktu z:
/// - Szczegółami produktu
/// - Listą inwestorów
/// - Analityką i statystykami
/// - Danymi wydajności
class AdvancedProductDialog extends StatefulWidget {
  final Product product;

  const AdvancedProductDialog({super.key, required this.product});

  /// Wyświetla dialog w kontekście
  static Future<void> show(BuildContext context, Product product) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => AdvancedProductDialog(product: product),
    );
  }

  @override
  State<AdvancedProductDialog> createState() => _AdvancedProductDialogState();
}

class _AdvancedProductDialogState extends State<AdvancedProductDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late StandardProductInvestorsService _investorsService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _investorsService = StandardProductInvestorsService();

    // Słuchaj zmian zakładek aby optymalizować ładowanie danych
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // Można tutaj dodać logikę do preloadowania danych dla konkretnych zakładek
    if (mounted) {
      setState(() {
        // Refresh UI when tab changes
      });
    }
  }

  void _setLoading(bool loading) {
    // Placeholder - w przyszłości można dodać globalne wskaźniki ładowania
  }

  void _setError(String? error) {
    // Placeholder - w przyszłości można dodać globalne wskaźniki błędów
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 1200;
    final isTablet = screenSize.width > 600 && screenSize.width <= 1200;
    final isMobile = screenSize.width <= 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isDesktop ? 40 : 20),
      child: Container(
        width: _getDialogWidth(isDesktop, isTablet, isMobile),
        height: _getDialogHeight(isDesktop, isTablet, isMobile),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDesktop),

            // Tabs
            _buildTabBar(context, isDesktop),

            // Content
            Expanded(child: _buildTabBarView(context)),
          ],
        ),
      ),
    );
  }

  double _getDialogWidth(bool isDesktop, bool isTablet, bool isMobile) {
    if (isDesktop) return 1200;
    if (isTablet) return 800;
    return double.infinity;
  }

  double _getDialogHeight(bool isDesktop, bool isTablet, bool isMobile) {
    if (isDesktop) return 800;
    if (isTablet) return 700;
    return double.infinity;
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Ikona produktu
          Container(
            width: isDesktop ? 56 : 48,
            height: isDesktop ? 56 : 48,
            decoration: BoxDecoration(
              color: _getProductTypeColor(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getProductTypeIcon(),
              color: Colors.white,
              size: isDesktop ? 28 : 24,
            ),
          ),

          SizedBox(width: isDesktop ? 16 : 12),

          // Informacje o produkcie
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: isDesktop ? 8 : 4),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getProductTypeColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.product.type.displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getProductTypeColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    if (widget.product.companyId.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.business,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ID: ${widget.product.companyId}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Przycisk zamknięcia
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Zamknij',
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
                0.5,
              ),
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 3,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.bodyMedium,
        tabs: [
          Tab(
            icon: Icon(Icons.info_outline, size: isDesktop ? 20 : 18),
            text: 'Szczegóły',
          ),
          Tab(
            icon: Icon(Icons.people_outline, size: isDesktop ? 20 : 18),
            text: 'Inwestorzy',
          ),
          Tab(
            icon: Icon(Icons.analytics_outlined, size: isDesktop ? 20 : 18),
            text: 'Analityka',
          ),
          Tab(
            icon: Icon(Icons.trending_up_outlined, size: isDesktop ? 20 : 18),
            text: 'Wydajność',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView(BuildContext context) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Zakładka szczegółów
        StandardProductDetailsTab(
          product: widget.product,
          onLoading: _setLoading,
          onError: _setError,
        ),

        // Zakładka inwestorów
        StandardProductInvestorsTab(
          product: widget.product,
          investorsService: _investorsService,
          onLoading: _setLoading,
          onError: _setError,
        ),

        // Zakładka analityki
        StandardProductAnalyticsTab(
          product: widget.product,
          investorsService: _investorsService,
          onLoading: _setLoading,
          onError: _setError,
        ),

        // Zakładka wydajności
        StandardProductPerformanceTab(
          product: widget.product,
          investorsService: _investorsService,
          onLoading: _setLoading,
          onError: _setError,
        ),
      ],
    );
  }

  Color _getProductTypeColor() {
    switch (widget.product.type) {
      case ProductType.bonds:
        return Colors.blue;
      case ProductType.shares:
        return Colors.green;
      case ProductType.loans:
        return Colors.orange;
      case ProductType.apartments:
        return Colors.purple;
    }
  }

  IconData _getProductTypeIcon() {
    switch (widget.product.type) {
      case ProductType.bonds:
        return Icons.account_balance;
      case ProductType.shares:
        return Icons.show_chart;
      case ProductType.loans:
        return Icons.monetization_on;
      case ProductType.apartments:
        return Icons.apartment;
    }
  }
}
