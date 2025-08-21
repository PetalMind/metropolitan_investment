import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models_and_services.dart'; // Centralized import
import 'product_details_header.dart';
import 'product_details_tabs.dart';
import 'product_details_service.dart';

/// Enhanced widget do wyświetlania szczegółów produktu w modal dialog
class EnhancedProductDetailsDialog extends StatefulWidget {
  final UnifiedProduct product;
  final VoidCallback? onShowInvestors;
  final String?
  highlightInvestmentId; // 🚀 NOWE: ID inwestycji do podświetlenia

  const EnhancedProductDetailsDialog({
    super.key,
    required this.product,
    this.onShowInvestors,
    this.highlightInvestmentId, // 🚀 NOWE: Opcjonalne ID inwestycji do podświetlenia
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

  // ⭐ NOWE: Stan edycji dla przekazania do ProductInvestorsTab
  bool _isEditModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _service = ProductDetailsService();
    
    _loadInvestors();

    // 🚀 NOWE: Jeśli mamy highlightInvestmentId, automatycznie przełącz na zakładkę "Inwestorzy" (index 1)
    if (widget.highlightInvestmentId != null &&
        widget.highlightInvestmentId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabController.animateTo(1); // Przełącz na zakładkę "Inwestorzy"
          debugPrint(
            '🎯 [ProductDetailsDialog] Automatycznie przełączono na zakładkę "Inwestorzy" dla inwestycji: ${widget.highlightInvestmentId}',
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInvestors() async {
    try {
      debugPrint('🔄 [ProductDetailsDialog] Loading investors for product: ${widget.product.name}');
      
      setState(() {
        _isLoadingInvestors = true;
        _investorsError = null;
      });

      final investors = await _service.getInvestorsForProduct(widget.product);

      debugPrint('✅ [ProductDetailsDialog] Loaded ${investors.length} investors');
      
      if (mounted) {
        setState(() {
          _investors = investors;
          _isLoadingInvestors = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [ProductDetailsDialog] Error loading investors: $e');
      debugPrint('Stack trace: $stackTrace');
      
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              // Header z gradientem i przyciskiem zamknięcia - UPROSZCZONA WERSJA
              ProductDetailsHeader(
                product: widget.product,
                investors: _investors,
                isLoadingInvestors: _isLoadingInvestors,
                onClose: () => Navigator.of(context).pop(),
                onShowInvestors: widget.onShowInvestors,
                isCollapsed: false, // ⭐ TYMCZASOWO: Wyłącz zwijanie dla debugowania
                collapseFactor: 1.0, // ⭐ TYMCZASOWO: Pełny rozmiar
                onEditModeChanged: (editMode) {
                  setState(() {
                    _isEditModeEnabled = editMode;
                  });
                },
                onTabChanged: (tabIndex) {
                  _tabController.animateTo(tabIndex);
                },
                onDataChanged: () async {
                  debugPrint('🔄 [ProductDetailsDialog] onDataChanged wywołane...');
                  await _loadInvestors();
                  debugPrint('✅ [ProductDetailsDialog] Dane odświeżone');
                },
              ),

              // Tab Content - UPROSZCZONA WERSJA BEZ NOTIFICATION LISTENER
              Expanded(
                child: ProductDetailsTabs(
                  product: widget.product,
                  tabController: _tabController,
                  investors: _investors,
                  isLoadingInvestors: _isLoadingInvestors,
                  investorsError: _investorsError,
                  onRefreshInvestors: _loadInvestors,
                  isEditModeEnabled: _isEditModeEnabled,
                  highlightInvestmentId: widget.highlightInvestmentId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
