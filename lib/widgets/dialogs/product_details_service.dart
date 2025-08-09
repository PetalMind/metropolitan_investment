import 'package:flutter/material.dart';
import '../../../models/unified_product.dart';
import '../../../models/investor_summary.dart';
import '../../../services/product_investors_service.dart';

/// Service do obsługi logiki dialogu szczegółów produktu
class ProductDetailsService {
  final ProductInvestorsService _investorsService = ProductInvestorsService();

  /// Pobiera inwestorów dla danego produktu
  Future<List<InvestorSummary>> getInvestorsForProduct(
    UnifiedProduct product,
  ) async {
    try {
      print('🔍 [ProductDetailsService] Ładowanie inwestorów dla produktu:');
      print('  - Nazwa: "${product.name}"');
      print('  - Typ: ${product.productType.displayName}');

      // Używamy ulepszonej metody getInvestorsForProduct z zaawansowanymi strategiami
      final investors = await _investorsService.getInvestorsForProduct(product);

      print(
        '✅ [ProductDetailsService] Załadowano ${investors.length} inwestorów',
      );

      return investors;
    } catch (e) {
      print('❌ [ProductDetailsService] Błąd podczas ładowania inwestorów: $e');
      rethrow;
    }
  }

  /// Formatuje wartość walutową
  String formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M zł';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K zł';
    } else {
      return '${amount.toStringAsFixed(2)} zł';
    }
  }

  /// Formatuje datę w polskim formacie
  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Formatuje nazwę pola dla wyświetlenia
  String formatFieldName(String fieldName) {
    // Mapa tłumaczeń dla polskich nazw pól
    const translations = {
      'nazwa_produktu': 'Nazwa produktu',
      'typ_produktu': 'Typ produktu',
      'kwota_inwestycji': 'Kwota inwestycji',
      'data_utworzenia': 'Data utworzenia',
      'ostatnia_aktualizacja': 'Ostatnia aktualizacja',
      'oprocentowanie': 'Oprocentowanie',
      'data_zapadalnosci': 'Data zapadalności',
      'liczba_udzialow': 'Liczba udziałów',
      'cena_za_udzial': 'Cena za udział',
      'nazwa_firmy': 'Nazwa firmy',
      'waluta': 'Waluta',
      'projekt_nazwa': 'Nazwa projektu',
      'numer_apartamentu': 'Numer apartamentu',
      'powierzchnia': 'Powierzchnia',
      'liczba_pokoi': 'Liczba pokoi',
      'pietro': 'Piętro',
      'typ_apartamentu': 'Typ apartamentu',
      'cena_za_m2': 'Cena za m²',
      'balkon': 'Balkon',
      'miejsce_parkingowe': 'Miejsce parkingowe',
      'komorka': 'Komórka',
      'adres': 'Adres',
      'pozyczkobiorca': 'Pożyczkobiorca',
      'wierzyciel_spolka': 'Wierzyciel spółka',
      'zabezpieczenie': 'Zabezpieczenie',
      'status_pozyczki': 'Status pożyczki',
    };

    return translations[fieldName] ??
        fieldName.replaceAll('_', ' ').toUpperCase()[0] +
            fieldName.replaceAll('_', ' ').substring(1);
  }

  /// Sprawdza czy pole jest specjalne (już wyświetlone w sekcji specyficznej)
  bool isSpecialField(String fieldName) {
    const specialFields = [
      'borrower',
      'creditorCompany',
      'collateral',
      'status',
      'apartmentNumber',
      'building',
      'area',
      'roomCount',
      'floor',
      'apartmentType',
      'pricePerSquareMeter',
      'address',
      'hasBalcony',
      'hasParkingSpace',
      'hasStorage',
    ];
    return specialFields.contains(fieldName);
  }

  /// Zwraca ikonę dla danego typu produktu
  IconData getProductIcon(UnifiedProductType type) {
    switch (type) {
      case UnifiedProductType.bonds:
        return Icons.account_balance;
      case UnifiedProductType.shares:
        return Icons.trending_up;
      case UnifiedProductType.loans:
        return Icons.attach_money;
      case UnifiedProductType.apartments:
        return Icons.apartment;
      case UnifiedProductType.other:
        return Icons.inventory;
    }
  }
}
