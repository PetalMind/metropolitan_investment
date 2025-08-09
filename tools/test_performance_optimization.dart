import 'package:firebase_core/firebase_core.dart';
import '../lib/services/product_investors_service.dart';
import '../lib/services/optimized_product_investors_service.dart';
import '../lib/models/unified_product.dart';
import '../lib/models/product_type.dart';

/// Skrypt do testowania wydajności staregos vs nowego serwisu inwestorów
void main() async {
  print('🧪 Rozpoczynam test wydajności...');

  // Inicjalizuj Firebase
  await Firebase.initializeApp();

  // Stwórz testowy produkt
  final testProduct = UnifiedProduct(
    id: 'test-product-id',
    name: 'TEST - Produkt Mieszkaniowy',
    productType: ProductType.shares,
    shortDescription: 'Testowy produkt dla pomiaru wydajności',
    longDescription: 'Szczegółowy opis testowego produktu',
    targetAmount: 1000000,
    unitPrice: 1000,
    unitsAvailable: 1000,
    maturityDate: DateTime.now().add(Duration(days: 365)),
    interestRate: 8.5,
    status: 'active',
    riskLevel: 'średnie',
    minInvestment: 1000,
    investmentPeriod: '12 miesięcy',
    expectedReturn: 8.5,
    totalUnits: 1000,
    soldUnits: 250,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  print('📊 Testowy produkt: "${testProduct.name}"');
  print('   Typ: ${testProduct.productType.displayName}');
  print('');

  // Test starego serwisu
  await testOldService(testProduct);

  print('');

  // Test nowego serwisu
  await testNewService(testProduct);

  print('');
  print('✅ Test wydajności zakończony!');
}

/// Test starego serwisu ProductInvestorsService
Future<void> testOldService(UnifiedProduct product) async {
  print('🔄 TEST STAREGO SERWISU (ProductInvestorsService)');
  print('=' * 50);

  final oldService = ProductInvestorsService();
  final stopwatch = Stopwatch()..start();

  try {
    final investors = await oldService.getInvestorsForProduct(product);
    stopwatch.stop();

    print('⏱️  Czas wykonania: ${stopwatch.elapsedMilliseconds}ms');
    print('👥 Znaleziono inwestorów: ${investors.length}');

    if (investors.isNotEmpty) {
      final totalCapital = investors.fold<double>(
        0,
        (sum, inv) => sum + inv.viableRemainingCapital,
      );
      print('💰 Suma kapitału: ${totalCapital.toStringAsFixed(2)} PLN');

      print('🔍 Przykładowi inwestorzy:');
      for (int i = 0; i < investors.take(3).length; i++) {
        final inv = investors[i];
        print(
          '   ${i + 1}. ${inv.client.name} - ${inv.viableRemainingCapital.toStringAsFixed(2)} PLN',
        );
      }
    }
  } catch (e) {
    stopwatch.stop();
    print('❌ Błąd starego serwisu: $e');
    print('⏱️  Czas do błędu: ${stopwatch.elapsedMilliseconds}ms');
  }
}

/// Test nowego serwisu OptimizedProductInvestorsService
Future<void> testNewService(UnifiedProduct product) async {
  print('🚀 TEST NOWEGO SERWISU (OptimizedProductInvestorsService)');
  print('=' * 50);

  final newService = OptimizedProductInvestorsService();
  final stopwatch = Stopwatch()..start();

  try {
    final investors = await newService.getInvestorsForProduct(product);
    stopwatch.stop();

    print('⏱️  Czas wykonania: ${stopwatch.elapsedMilliseconds}ms');
    print('👥 Znaleziono inwestorów: ${investors.length}');

    if (investors.isNotEmpty) {
      final totalCapital = investors.fold<double>(
        0,
        (sum, inv) => sum + inv.viableRemainingCapital,
      );
      print('💰 Suma kapitału: ${totalCapital.toStringAsFixed(2)} PLN');

      print('🔍 Przykładowi inwestorzy:');
      for (int i = 0; i < investors.take(3).length; i++) {
        final inv = investors[i];
        print(
          '   ${i + 1}. ${inv.client.name} - ${inv.viableRemainingCapital.toStringAsFixed(2)} PLN',
        );
      }
    }
  } catch (e) {
    stopwatch.stop();
    print('❌ Błąd nowego serwisu: $e');
    print('⏱️  Czas do błędu: ${stopwatch.elapsedMilliseconds}ms');
  }
}
