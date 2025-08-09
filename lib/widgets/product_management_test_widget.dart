/// Test widget dla funkcjonalności zarządzania produktami
/// Użyj tego w development mode do testowania nowych dialogów

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/unified_product.dart';
import '../dialogs/product_edit_dialog.dart';
import '../dialogs/product_delete_dialog.dart';
import '../product_details_dialog.dart';

class ProductManagementTestWidget extends StatelessWidget {
  const ProductManagementTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Test: Zarządzanie produktami'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTestButton(
              context,
              'Test pełnego dialogu produktu',
              Icons.visibility,
              () => _showFullProductDialog(context),
            ),

            const SizedBox(height: 16),

            _buildTestButton(
              context,
              'Test dialogu edycji',
              Icons.edit,
              () => _showEditDialog(context),
            ),

            const SizedBox(height: 16),

            _buildTestButton(
              context,
              'Test dialogu usuwania',
              Icons.delete,
              () => _showDeleteDialog(context),
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderPrimary, width: 1),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.infoPrimary,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Instrukcje testowania',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Pełny dialog - testuje wszystkie funkcje\n'
                    '2. Dialog edycji - testuje formularz edycji\n'
                    '3. Dialog usuwania - testuje sprawdzanie powiązań',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      width: 280,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondaryGold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  void _showFullProductDialog(BuildContext context) {
    final testProduct = _createTestProduct();

    showDialog(
      context: context,
      builder: (context) => EnhancedProductDetailsDialog(product: testProduct),
    );
  }

  void _showEditDialog(BuildContext context) {
    final testProduct = _createTestProduct();

    showDialog(
      context: context,
      builder: (context) => ProductEditDialog(
        product: testProduct,
        onProductUpdated: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Test: Produkt został zaktualizowany'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final testProduct = _createTestProduct();

    showDialog(
      context: context,
      builder: (context) => ProductDeleteDialog(
        product: testProduct,
        onProductDeleted: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Test: Produkt został usunięty'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  UnifiedProduct _createTestProduct() {
    return UnifiedProduct(
      id: 'test-product-id-123',
      name: 'Test Obligacja ABC',
      productType: UnifiedProductType.bonds,
      investmentAmount: 250000.00,
      totalValue: 275000.00,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
      sourceFile: 'test_data.xlsx',
      status: ProductStatus.active,
      additionalInfo: {
        'company': 'Test Company Sp. z o.o.',
        'interest_rate': 5.5,
        'maturity_date': DateTime.now()
            .add(const Duration(days: 365 * 2))
            .toIso8601String(),
      },
    );
  }
}

/// Extension dla łatwego dodania testowego widgetu do ekranu
extension ProductManagementTesting on BuildContext {
  /// Pokazuje test widget w nowym ekranie
  void showProductManagementTest() {
    Navigator.of(this).push(
      MaterialPageRoute(
        builder: (context) => const ProductManagementTestWidget(),
      ),
    );
  }

  /// Pokazuje test widget jako overlay
  void showProductManagementTestOverlay() {
    showDialog(
      context: this,
      builder: (context) =>
          Dialog.fullscreen(child: const ProductManagementTestWidget()),
    );
  }
}
