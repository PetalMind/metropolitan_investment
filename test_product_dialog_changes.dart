import 'package:flutter/material.dart';
import 'lib/models_and_services.dart';
import 'lib/widgets/dialogs/product_details_dialog.dart';
import 'lib/theme/app_theme.dart';

/// Test widżet do sprawdzenia zmian w dialogu produktu
class TestProductDialogChanges extends StatelessWidget {
  const TestProductDialogChanges({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        colorScheme: AppTheme.colorScheme,
        textTheme: AppTheme.textTheme,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Test Dialogu Produktu'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _showTestBondDialog(context),
                child: const Text('Test Dialog - Obligacja'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showTestShareDialog(context),
                child: const Text('Test Dialog - Udział'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showTestApartmentDialog(context),
                child: const Text('Test Dialog - Apartament'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTestBondDialog(BuildContext context) {
    final testBond = UnifiedProduct(
      id: 'test_bond_1',
      name: 'Test Obligacja Spółka ABC',
      productType: UnifiedProductType.bonds,
      investmentAmount: 500000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      uploadedAt: DateTime.now().subtract(const Duration(days: 360)),
      sourceFile: 'test_bonds.xlsx',
      status: ProductStatus.active,
      remainingCapital: 450000.0,
      interestRate: 8.5,
      maturityDate: DateTime.now().add(const Duration(days: 730)),
      companyName: 'Spółka ABC',
      currency: 'PLN',
      additionalInfo: {
        'borrower': 'Spółka ABC Sp. z o.o.',
        'collateral': 'Nieruchomość biurowa w Warszawie',
        'creditorCompany': 'Metropolitan Investment',
      },
    );

    showDialog(
      context: context,
      builder: (context) => EnhancedProductDetailsDialog(product: testBond),
    );
  }

  void _showTestShareDialog(BuildContext context) {
    final testShare = UnifiedProduct(
      id: 'test_share_1',
      name: 'Test Udziały XYZ',
      productType: UnifiedProductType.shares,
      investmentAmount: 750000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      uploadedAt: DateTime.now().subtract(const Duration(days: 175)),
      sourceFile: 'test_shares.xlsx',
      status: ProductStatus.active,
      sharesCount: 1500,
      pricePerShare: 500.0,
      companyName: 'Spółka XYZ',
      currency: 'PLN',
      additionalInfo: {'sector': 'Technologie', 'dividendRate': '5.2%'},
    );

    showDialog(
      context: context,
      builder: (context) => EnhancedProductDetailsDialog(product: testShare),
    );
  }

  void _showTestApartmentDialog(BuildContext context) {
    final testApartment = UnifiedProduct(
      id: 'test_apartment_1',
      name: 'Apartament Warszawa Centrum',
      productType: UnifiedProductType.apartments,
      investmentAmount: 1200000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      uploadedAt: DateTime.now().subtract(const Duration(days: 85)),
      sourceFile: 'test_apartments.xlsx',
      status: ProductStatus.active,
      additionalInfo: {
        'apartmentNumber': '45',
        'building': 'A',
        'area': 85.5,
        'roomCount': 3,
        'floor': 12,
        'apartmentType': 'Standard',
        'pricePerSquareMeter': 14035.0,
        'address': 'ul. Marszałkowska 123, Warszawa',
        'hasBalcony': true,
        'hasParkingSpace': true,
        'hasStorage': false,
      },
    );

    showDialog(
      context: context,
      builder: (context) =>
          EnhancedProductDetailsDialog(product: testApartment),
    );
  }
}

void main() {
  runApp(const TestProductDialogChanges());
}
