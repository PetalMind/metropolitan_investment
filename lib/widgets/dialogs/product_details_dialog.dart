import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/unified_product.dart';
import '../../models/investor_summary.dart';
import 'product_details_header.dart';
import 'product_details_tabs.dart';
import 'product_details_service.dart';

/// Enhanced widget do wyświetlania szczegółów produktu w modal dialog
class EnhancedProductDetailsDialog extends StatefulWidget {
  final UnifiedProduct product;
  final VoidCallback? onShowInvestors;

  const EnhancedProductDetailsDialog({
    super.key,
    required this.product,
    this.onShowInvestors,
  });

  @override
  State<EnhancedProductDetailsDialog> createState() =>
      _EnhancedProductDetailsDialogState();
}

class _EnhancedProductDetailsDialogState
    extends State<EnhancedProductDetailsDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ProductDetailsService _service;

  List<InvestorSummary> _investors = [];
  bool _isLoadingInvestors = true;
  String? _investorsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _service = ProductDetailsService();
    _loadInvestors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

      final investors = await _service.getInvestorsForProduct(widget.product);

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
        child: Column(
          children: [
            // Header z gradientem i przyciskiem zamknięcia
            ProductDetailsHeader(
              product: widget.product,
              investors: _investors,
              isLoadingInvestors: _isLoadingInvestors,
              onClose: () => Navigator.of(context).pop(),
              onShowInvestors: widget.onShowInvestors,
            ),

            // Tab Content
            Expanded(
              child: ProductDetailsTabs(
                product: widget.product,
                tabController: _tabController,
                investors: _investors,
                isLoadingInvestors: _isLoadingInvestors,
                investorsError: _investorsError,
                onRefreshInvestors: _loadInvestors,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
