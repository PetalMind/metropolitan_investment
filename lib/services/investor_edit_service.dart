import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';
import 'universal_investment_service.dart' as universal;

/// Serwis obsługujący logikę biznesową edycji inwestora
///
/// Odpowiada za:
/// - Wyszukiwanie inwestycji dla produktu
/// - Walidację danych
/// - Automatyczne obliczenia
/// - Skalowanie produktów
/// - Zapisywanie zmian
/// - Historię zmian
/// - NOWE: Integracja z ProductManagementService dla lepszej wydajności
class InvestorEditService {
  final InvestmentService _investmentService;
  final InvestmentChangeHistoryService _historyService;
  final ProductManagementService _productManagementService; // 🚀 INTEGRACJA

  InvestorEditService({
    InvestmentService? investmentService,
    InvestmentChangeHistoryService? historyService,
    ProductManagementService? productManagementService,
  }) : _investmentService = investmentService ?? InvestmentService(),
       _historyService = historyService ?? InvestmentChangeHistoryService(),
       _productManagementService =
           productManagementService ?? ProductManagementService();

  /// Wyszukuje inwestycje dla danego produktu i inwestora
  ///
  /// Używa ulepszonej logiki wyszukiwania z product_investors_tab.dart:
  /// 1. Deduplikacja inwestycji
  /// 2. Wyszukiwanie po ID produktu
  /// 3. Fallback po nazwie produktu
  /// 4. Fallback po nazwie + firmie
  /// 5. Sprawdzenie ID inwestycji (dla UnifiedProduct z investments)
  /// 6. Tolerancyjne wyszukiwanie po fragmentach nazwy
  List<Investment> findInvestmentsForProduct(
    InvestorSummary investor,
    UnifiedProduct product,
  ) {
    debugPrint('🔍 [InvestorEditService] Szukam inwestycji dla produktu:');
    debugPrint('  Product ID: ${product.id}');
    debugPrint('  Product Name: ${product.name}');
    debugPrint('  Company Name: ${product.companyName}');
    debugPrint('  Company ID: ${product.companyId}');
    debugPrint('  Source File: ${product.sourceFile}');
    debugPrint('  Product Type: ${product.productType}');

    debugPrint(
      '🔍 [InvestorEditService] Inwestycje inwestora (${investor.investments.length}):',
    );
    for (int i = 0; i < investor.investments.length; i++) {
      final inv = investor.investments[i];
      debugPrint('  [$i] Investment ID: ${inv.id}');
      debugPrint('      Product ID: ${inv.productId}');
      debugPrint('      Product Name: ${inv.productName}');
      debugPrint('      Creditor Company: ${inv.creditorCompany}');
      debugPrint('      Company ID: ${inv.companyId}');
      debugPrint('      Product Type: ${inv.productType}');
    }

    // 1. Najpierw deduplikacja inwestycji
    final uniqueInvestments = <String, Investment>{};
    for (final investment in investor.investments) {
      final key = investment.id.isNotEmpty
          ? investment.id
          : '${investment.productName}_${investment.investmentAmount}_${investment.clientId}';
      uniqueInvestments[key] = investment;
    }

    final uniqueInvestmentsList = uniqueInvestments.values.toList();
    debugPrint(
      '🔍 [InvestorEditService] Po deduplikacji: ${uniqueInvestmentsList.length} unikalnych inwestycji',
    );

    // ⭐ ZAKTUALIZOWANA LOGIKA WYSZUKIWANIA (Sierpień 2025):
    // Problem: DeduplicatedProductService tworzy product.id jako hash lub ID pierwszej inwestycji
    // Rozwiązanie: Szukaj po prawdziwym productId z Firebase jako pierwszeństwo

    // KROK 1: Szukaj po productId z Firebase (PREFEROWANE)
    debugPrint(
      '� [InvestorEditService] KROK 1: Szukam po productId z Firebase',
    );
    final productIdMatches = uniqueInvestmentsList
        .where(
          (investment) =>
              investment.productId?.isNotEmpty == true &&
              investment.productId == product.id,
        )
        .toList();

    if (productIdMatches.isNotEmpty) {
      debugPrint(
        '✅ [InvestorEditService] Znaleziono dopasowania po productId: ${productIdMatches.length}',
      );
      return productIdMatches;
    }

    // KROK 2: Szukaj po dokładnej nazwie + company + type (dla kompletności)
    debugPrint(
      '🔍 [InvestorEditService] KROK 2: Szukam po nazwie + company + type',
    );
    final exactMatches = uniqueInvestmentsList
        .where(
          (investment) =>
              investment.productName.trim().toLowerCase() ==
                  product.name.trim().toLowerCase() &&
              investment.companyId.trim().toLowerCase() ==
                  (product.companyId?.trim().toLowerCase() ?? ''),
        )
        .toList();

    if (exactMatches.isNotEmpty) {
      debugPrint(
        '✅ [InvestorEditService] Znaleziono dopasowania po exact match: ${exactMatches.length}',
      );
      return exactMatches;
    }

    // KROK 3: Fallback - szukaj po ID inwestycji (kompatybilność z DeduplicatedProductService)
    debugPrint(
      '🔍 [InvestorEditService] KROK 3: Szukam po ID inwestycji (fallback)',
    );
    if (product.id.isNotEmpty) {
      final idMatches = uniqueInvestmentsList
          .where((investment) => investment.id == product.id)
          .toList();

      if (idMatches.isNotEmpty) {
        debugPrint(
          '✅ [InvestorEditService] Znaleziono dopasowania po ID inwestycji: ${idMatches.length}',
        );
        return idMatches;
      } else {
        debugPrint('⚠️ [InvestorEditService] Brak dopasowań po ID inwestycji');
      }
    }

    // Fallback: sprawdź po nazwie produktu (case-insensitive trim)
    final fallbackMatches = uniqueInvestmentsList
        .where(
          (investment) =>
              investment.productName.trim().toLowerCase() ==
              product.name.trim().toLowerCase(),
        )
        .toList();

    if (fallbackMatches.isNotEmpty) {
      debugPrint(
        '✅ [InvestorEditService] Znaleziono dopasowania po nazwie produktu: ${fallbackMatches.length}',
      );
      return fallbackMatches;
    }

    // 4. Fallback 2: sprawdź po nazwie produktu + firmie
    final companyMatches = uniqueInvestmentsList
        .where(
          (investment) =>
              investment.productName.trim().toLowerCase() ==
                  product.name.trim().toLowerCase() &&
              investment.creditorCompany.trim().toLowerCase() ==
                  (product.companyName?.trim().toLowerCase() ?? ''),
        )
        .toList();

    if (companyMatches.isNotEmpty) {
      debugPrint(
        '✅ [InvestorEditService] Znaleziono dopasowania po nazwie + firmie: ${companyMatches.length}',
      );
      return companyMatches;
    }

    // 5. Ostatni fallback: jeśli to UnifiedProduct pochodzący z inwestycji, sprawdź po ID inwestycji
    if (product.sourceFile == 'investments') {
      final investmentIdMatches = uniqueInvestmentsList
          .where((investment) => investment.id == product.id)
          .toList();

      if (investmentIdMatches.isNotEmpty) {
        debugPrint(
          '✅ [InvestorEditService] Znaleziono dopasowania po ID inwestycji: ${investmentIdMatches.length}',
        );
        return investmentIdMatches;
      }
    }

    // 6. Ostateczny fallback: bardziej tolerancyjne wyszukiwanie po fragmentach nazwy
    final partialMatches = uniqueInvestmentsList.where((investment) {
      // Usuń nadmiarowe spacje i zamień na małe litery
      final investmentName = investment.productName.trim().toLowerCase();
      final productName = product.name.trim().toLowerCase();

      // Sprawdź czy nazwy zawierają się nawzajem
      return investmentName.contains(productName) ||
          productName.contains(investmentName) ||
          _hasCommonWords(investmentName, productName);
    }).toList();

    if (partialMatches.isNotEmpty) {
      debugPrint(
        '✅ [InvestorEditService] Znaleziono dopasowania częściowe: ${partialMatches.length}',
      );
      return partialMatches;
    }

    // 7. Fallback dla produktów utworzonych z Firebase Functions (sprawdź ID inwestycji jako backup)
    if (product.originalProduct != null) {
      if (product.originalProduct is Map<String, dynamic>) {
        final originalData = product.originalProduct as Map<String, dynamic>;
        final originalIds = [
          originalData['id'],
          originalData['investmentId'],
          originalData['originalInvestmentId'],
        ].where((id) => id != null).map((id) => id.toString()).toList();

        if (originalIds.isNotEmpty) {
          final originalIdMatches = uniqueInvestmentsList
              .where((investment) => originalIds.contains(investment.id))
              .toList();

          if (originalIdMatches.isNotEmpty) {
            debugPrint(
              '✅ [InvestorEditService] Znaleziono dopasowania po original IDs: ${originalIdMatches.length}',
            );
            return originalIdMatches;
          }
        }
      }
    }

    debugPrint('❌ [InvestorEditService] Nie znaleziono żadnych dopasowań!');
    return [];
  }

  /// Sprawdza czy dwie nazwy mają wspólne słowa (minimum 2 znaki)
  bool _hasCommonWords(String name1, String name2) {
    final words1 = name1.split(' ').where((w) => w.length >= 2).toSet();
    final words2 = name2.split(' ').where((w) => w.length >= 2).toSet();
    return words1.intersection(words2).isNotEmpty;
  }

  /// Znajduje przykładowe inwestycje dla produktu (do określenia prawdziwego productId)
  ///
  /// ⭐ NOWA METODA (Sierpień 2025):
  /// Służy do znajdowania prawdziwego productId z Firebase zamiast używania
  /// hashu z DeduplicatedProductService
  Future<List<Investment>> _findSampleInvestmentsForProduct(
    UnifiedProduct product,
  ) async {
    try {
      debugPrint(
        '🔍 [InvestorEditService] Szukam przykładowych inwestycji dla produktu: ${product.name}',
      );

      // Użyj Firebase bezpośrednio do pobrania inwestycji
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('investments')
          .where('productName', isEqualTo: product.name)
          .where('companyId', isEqualTo: product.companyId)
          .limit(5) // Wystarczy kilka przykładów
          .get();

      final investments = snapshot.docs
          .map((doc) => Investment.fromFirestore(doc))
          .toList();

      debugPrint(
        '🔍 [InvestorEditService] Znaleziono ${investments.length} dopasowań dla produktu',
      );

      if (investments.isNotEmpty) {
        final firstInvestment = investments.first;
        debugPrint(
          '🔍 [InvestorEditService] Pierwsza inwestycja: ${firstInvestment.id}, productId: ${firstInvestment.productId}',
        );
      }

      return investments;
    } catch (e) {
      debugPrint(
        '❌ [InvestorEditService] Błąd podczas szukania inwestycji: $e',
      );
      return [];
    }
  }

  /// Formatuje wartość do wyświetlenia w kontrolerze z separatorami tysięcznymi
  String formatValueForController(double value) {
    // Jeśli wartość jest całkowita, nie pokazuj miejsc po przecinku
    if (value == value.truncateToDouble()) {
      return CurrencyFormatter.formatNumber(value, decimals: 0);
    }
    // W przeciwnym razie pokaż 2 miejsca po przecinku, ale zamień przecinki na kropki dla edycji
    String formatted = CurrencyFormatter.formatNumber(value, decimals: 2);
    // Zamień przecinek na kropkę dla pól edycji (double.tryParse oczekuje kropek)
    return formatted.replaceAll(',', '.');
  }

  /// Parsuje wartość z kontrolera (usuwa spacje)
  double parseValueFromController(String text) {
    if (text.trim().isEmpty) {
      debugPrint('⚠️ [InvestorEditService] parseValueFromController: empty text, returning 0.0');
      return 0.0;
    }
    final cleanText = text.replaceAll(' ', '').replaceAll(',', '.');
    final result = double.tryParse(cleanText) ?? 0.0;
    debugPrint('🔍 [InvestorEditService] parseValueFromController: "$text" → $result');
    return result;
  }

  /// Parsuje wartość z kontrolera z fallback do oryginalnej wartości
  double parseValueFromControllerWithFallback(String text, double originalValue) {
    if (text.trim().isEmpty) {
      debugPrint('⚠️ [InvestorEditService] parseValueFromControllerWithFallback: empty text, using original value: $originalValue');
      return originalValue;
    }
    final cleanText = text.replaceAll(' ', '').replaceAll(',', '.');
    final result = double.tryParse(cleanText) ?? originalValue;
    debugPrint('🔍 [InvestorEditService] parseValueFromControllerWithFallback: "$text" → $result (original: $originalValue)');
    return result;
  }

  /// Oblicza automatyczne wartości na podstawie wprowadzonych kwot
  ///
  /// NOWA LOGIKA: kapitał pozostały = kapitał zabezpieczony + kapitał do restrukturyzacji
  double calculateRemainingCapital(
    double capitalSecured,
    double capitalForRestructuring,
  ) {
    return capitalSecured + capitalForRestructuring;
  }

  /// Waliduje dane inwestycji
  ValidationResult validateInvestmentData(
    List<Investment> investments,
    List<TextEditingController> remainingCapitalControllers,
    List<TextEditingController> investmentAmountControllers,
    List<TextEditingController> capitalForRestructuringControllers,
    List<TextEditingController> capitalSecuredControllers,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    for (int i = 0; i < investments.length; i++) {
      final remainingCapital = parseValueFromController(
        remainingCapitalControllers[i].text,
      );
      final investmentAmount = parseValueFromController(
        investmentAmountControllers[i].text,
      );
      final capitalForRestructuring = parseValueFromController(
        capitalForRestructuringControllers[i].text,
      );
      final capitalSecured = parseValueFromController(
        capitalSecuredControllers[i].text,
      );

      // Sprawdź czy kwoty są dodatnie
      if (remainingCapital < 0) {
        errors.add(
          'Kapitał pozostały w inwestycji ${i + 1} nie może być ujemny',
        );
      }
      if (investmentAmount < 0) {
        errors.add('Kwota inwestycji ${i + 1} nie może być ujemna');
      }
      if (capitalForRestructuring < 0) {
        errors.add(
          'Kapitał do restrukturyzacji w inwestycji ${i + 1} nie może być ujemny',
        );
      }
      if (capitalSecured < 0) {
        errors.add(
          'Kapitał zabezpieczony w inwestycji ${i + 1} nie może być ujemny',
        );
      }

      // Sprawdź zgodność sum - teraz sprawdzamy czy kapitał pozostały = suma składników
      final calculatedRemainingCapital = calculateRemainingCapital(
        capitalSecured,
        capitalForRestructuring,
      );

      if ((calculatedRemainingCapital - remainingCapital).abs() > 0.01) {
        warnings.add(
          'Niezgodność obliczeń w inwestycji ${i + 1}: '
          'kapitał pozostały (${remainingCapital.toStringAsFixed(2)}) '
          'powinien równać się sumie kapitału zabezpieczonego (${capitalSecured.toStringAsFixed(2)}) '
          'i kapitału do restrukturyzacji (${capitalForRestructuring.toStringAsFixed(2)}) = ${calculatedRemainingCapital.toStringAsFixed(2)}',
        );
      }

      // 📊 DODATKOWA INFORMACJA: Sprawdź zgodność z kwotą inwestycji
      if ((calculatedRemainingCapital - investmentAmount).abs() > 0.01) {
        warnings.add(
          'Uwaga dla inwestycji ${i + 1}: '
          'suma kapitałów (${calculatedRemainingCapital.toStringAsFixed(2)}) '
          'różni się od kwoty inwestycji (${investmentAmount.toStringAsFixed(2)}) '
          'o ${(calculatedRemainingCapital - investmentAmount).abs().toStringAsFixed(2)}',
        );
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.invalid(errors, warnings);
    }

    return ValidationResult(isValid: true, warnings: warnings);
  }

  /// Oblicza podsumowanie zmian w inwestycjach
  InvestmentChangesSummary calculateChangesSummary(
    List<Investment> investments,
    List<TextEditingController> remainingCapitalControllers,
    List<TextEditingController> investmentAmountControllers,
    List<TextEditingController> capitalForRestructuringControllers,
    List<TextEditingController> capitalSecuredControllers,
    List<InvestmentStatus> statusValues,
  ) {
    int changedInvestments = 0;
    double totalRemainingCapital = 0.0;
    double totalInvestmentAmount = 0.0;
    double totalCapitalForRestructuring = 0.0;
    double totalCapitalSecured = 0.0;

    for (int i = 0; i < investments.length; i++) {
      final remainingCapital = parseValueFromController(
        remainingCapitalControllers[i].text,
      );
      final investmentAmount = parseValueFromController(
        investmentAmountControllers[i].text,
      );
      final capitalForRestructuring = parseValueFromController(
        capitalForRestructuringControllers[i].text,
      );
      final capitalSecured = parseValueFromController(
        capitalSecuredControllers[i].text,
      );
      final status = statusValues[i];

      // Sprawdź czy dane się zmieniły
      final original = investments[i];
      if ((remainingCapital - original.remainingCapital).abs() > 0.01 ||
          (investmentAmount - original.investmentAmount).abs() > 0.01 ||
          (capitalForRestructuring - original.capitalForRestructuring).abs() >
              0.01 ||
          (capitalSecured - original.capitalSecuredByRealEstate).abs() > 0.01 ||
          status != original.status) {
        changedInvestments++;
      }

      totalRemainingCapital += remainingCapital;
      totalInvestmentAmount += investmentAmount;
      totalCapitalForRestructuring += capitalForRestructuring;
      totalCapitalSecured += capitalSecured;
    }

    return InvestmentChangesSummary(
      totalInvestments: investments.length,
      changedInvestments: changedInvestments,
      totalRemainingCapital: totalRemainingCapital,
      totalInvestmentAmount: totalInvestmentAmount,
      totalCapitalForRestructuring: totalCapitalForRestructuring,
      totalCapitalSecured: totalCapitalSecured,
    );
  }

  /// Skaluje produkt do nowej całkowitej kwoty
  Future<ProductScalingResult> scaleProduct({
    required UnifiedProduct product,
    required double newTotalAmount,
    required double originalTotalAmount,
    required String reason,
  }) async {
    try {
      debugPrint(
        '🎯 [InvestorEditService] Obsługuję skalowanie całego produktu...',
      );
      debugPrint('   - Produkt: ${product.name}');
      debugPrint('   - Nowa kwota: ${newTotalAmount.toStringAsFixed(2)}');
      debugPrint(
        '   - Poprzednia kwota: ${originalTotalAmount.toStringAsFixed(2)}',
      );

      // ⭐ ZAWSZE UŻYWAJ PRAWDZIWEGO ID Z FIREBASE

      debugPrint('🔄 [InvestorEditService] Strategia skalowania:');

      // ⭐ ZNAJDŹ PRAWDZIWY PRODUCTID Z FIREBASE (Sierpień 2025)
      // Problem: product.id może być hashem z DeduplicatedProductService
      // Rozwiązanie: Znajdź inwestycje tego produktu i użyj ich productId

      final sampleInvestments = await _findSampleInvestmentsForProduct(product);
      if (sampleInvestments.isEmpty) {
        debugPrint(
          '❌ [InvestorEditService] Nie znaleziono inwestycji dla produktu',
        );
        return ProductScalingResult(
          success: false,
          message: 'Nie znaleziono inwestycji dla tego produktu',
          newAmount: originalTotalAmount,
          affectedInvestments: 0,
          scalingFactor: 1.0,
          executionTime: '0ms',
        );
      }

      // Użyj productId z pierwszej znalezionej inwestycji
      final realProductId =
          sampleInvestments.first.productId ?? sampleInvestments.first.id;

      debugPrint('   - Product.id (z DeduplicatedService): ${product.id}');
      debugPrint('   - Real ProductId (z Firebase): $realProductId');
      debugPrint('   - Sample investments found: ${sampleInvestments.length}');

      final scalingResult = await _investmentService.scaleProductInvestments(
        productId: realProductId, // ⭐ UŻYWAMY PRAWDZIWEGO ID Z FIREBASE
        productName: product.name,
        newTotalAmount: newTotalAmount,
        reason: reason,
        companyId: product.companyId,
        creditorCompany: product.companyName,
      );

      debugPrint('✅ [InvestorEditService] Skalowanie zakończone pomyślnie');
      debugPrint('📊 Podsumowanie: ${scalingResult.summary.formattedSummary}');

      return ProductScalingResult(
        success: true,
        message: 'Skalowanie produktu zakończone pomyślnie',
        newAmount: newTotalAmount,
        affectedInvestments: scalingResult.summary.affectedInvestments,
        scalingFactor: scalingResult.summary.scalingFactor,
        executionTime: '${scalingResult.summary.executionTimeMs}ms',
      );
    } catch (e) {
      debugPrint('❌ [InvestorEditService] Błąd skalowania: $e');
      return ProductScalingResult(
        success: false,
        message: 'Błąd skalowania produktu: ${e.toString()}',
      );
    }
  }

  /// 🌟 UNIVERSAL SYSTEM: Zapisuje zmiany w inwestycjach używając UniversalInvestmentService
  ///
  /// Używa jednolitego systemu danych w całej aplikacji - ROZWIĄZUJE PROBLEM NIESPÓJNOŚCI
  Future<bool> saveInvestmentChanges({
    required List<Investment> originalInvestments,
    required List<TextEditingController> remainingCapitalControllers,
    required List<TextEditingController> investmentAmountControllers,
    required List<TextEditingController> capitalForRestructuringControllers,
    required List<TextEditingController> capitalSecuredControllers,
    required List<InvestmentStatus> statusValues,
    required String changeReason,
  }) async {
    try {
      debugPrint(
        '🌟 [InvestorEditService] UNIVERSAL SYSTEM: Zapisuję zmiany w inwestycjach...',
      );

      // Użyj uniwersalnego serwisu - JEDEN SYSTEM DANYCH DLA CAŁEJ APLIKACJI
      final universalService = universal.UniversalInvestmentService.instance;

      int successCount = 0;
      int totalChanges = 0;

      // Przetwórz każdą inwestycję osobno używając partial update
      for (int i = 0; i < originalInvestments.length; i++) {
        final original = originalInvestments[i];

        // DEBUG: Sprawdź wartości kontrolerów przed parsowaniem
        debugPrint('🔍 [InvestorEditService] Raw controller values for investment ${i + 1}:');
        debugPrint('   - investmentAmount controller: "${investmentAmountControllers[i].text}"');
        debugPrint('   - capitalForRestructuring controller: "${capitalForRestructuringControllers[i].text}"');
        debugPrint('   - capitalSecured controller: "${capitalSecuredControllers[i].text}"');
        debugPrint('   - Original values from Firebase:');
        debugPrint('     * investmentAmount: ${original.investmentAmount}');
        debugPrint('     * capitalForRestructuring: ${original.capitalForRestructuring}');
        debugPrint('     * capitalSecuredByRealEstate: ${original.capitalSecuredByRealEstate}');

        // 🎯 IMPROVED: Użyj fallback parsing żeby zachować oryginalne wartości
        final investmentAmount = parseValueFromControllerWithFallback(
          investmentAmountControllers[i].text,
          original.investmentAmount,
        );
        final capitalForRestructuring = parseValueFromControllerWithFallback(
          capitalForRestructuringControllers[i].text,
          original.capitalForRestructuring,
        );
        final capitalSecured = parseValueFromControllerWithFallback(
          capitalSecuredControllers[i].text,
          original.capitalSecuredByRealEstate,
        );
        final status = statusValues[i];

        debugPrint('🔍 [InvestorEditService] Parsed values with fallback:');
        debugPrint('   - investmentAmount: $investmentAmount (original: ${original.investmentAmount})');
        debugPrint('   - capitalForRestructuring: $capitalForRestructuring (original: ${original.capitalForRestructuring})');
        debugPrint('   - capitalSecured: $capitalSecured (original: ${original.capitalSecuredByRealEstate})');

        // 🎯 SMART UPDATE - przekazuj TYLKO zmienione pola, zachowaj oryginalne wartości
        double? updateInvestmentAmount;
        double? updateCapitalForRestructuring;
        double? updateCapitalSecured;
        InvestmentStatus? updateStatus;

        // Przekaż wartość tylko jeśli rzeczywiście się zmieniła
        if ((investmentAmount - original.investmentAmount).abs() > 0.01) {
          updateInvestmentAmount = investmentAmount;
          debugPrint('📝 [InvestorEditService] Change detected: investmentAmount ${original.investmentAmount} → $investmentAmount');
        }
        if ((capitalForRestructuring - original.capitalForRestructuring).abs() > 0.01) {
          updateCapitalForRestructuring = capitalForRestructuring;
          debugPrint('📝 [InvestorEditService] Change detected: capitalForRestructuring ${original.capitalForRestructuring} → $capitalForRestructuring');
        }
        if ((capitalSecured - original.capitalSecuredByRealEstate).abs() > 0.01) {
          updateCapitalSecured = capitalSecured;
          debugPrint('📝 [InvestorEditService] Change detected: capitalSecuredByRealEstate ${original.capitalSecuredByRealEstate} → $capitalSecured');
        }
        if (status != original.status) {
          updateStatus = status;
          debugPrint('📝 [InvestorEditService] Change detected: status ${original.status} → $status');
        }

        // Sprawdź czy są jakiekolwiek zmiany
        if (updateInvestmentAmount == null && 
            updateCapitalForRestructuring == null && 
            updateCapitalSecured == null && 
            updateStatus == null) {
          debugPrint(
            'ℹ️ [InvestorEditService] Brak zmian w inwestycji: ${original.id} - wszystkie pola pozostają bez zmian',
          );
          continue;
        }

        totalChanges++;

        debugPrint(
          '📝 [InvestorEditService] UNIVERSAL: Edytuję inwestycję ${i + 1}/${originalInvestments.length}: ${original.id}',
        );

        debugPrint('🔍 [InvestorEditService] Prepared update values:');
        debugPrint('   - investmentAmount: ${updateInvestmentAmount ?? "NOT CHANGED (${original.investmentAmount})"}');
        debugPrint('   - capitalForRestructuring: ${updateCapitalForRestructuring ?? "NOT CHANGED (${original.capitalForRestructuring})"}');
        debugPrint('   - capitalSecuredByRealEstate: ${updateCapitalSecured ?? "NOT CHANGED (${original.capitalSecuredByRealEstate})"}');
        debugPrint('   - status: ${updateStatus ?? "NOT CHANGED (${original.status})"}');

        final success = await universalService.updateInvestmentFieldsSmart(
          original.id,
          investmentAmount: updateInvestmentAmount,
          capitalForRestructuring: updateCapitalForRestructuring,
          capitalSecuredByRealEstate: updateCapitalSecured,
          // remainingCapital: nie podajemy - zostanie automatycznie obliczony
          autoCalculateRemainingCapital: true,
          status: updateStatus,
          editorName: 'System Edycji Inwestorów',
          editorEmail: 'system@metropolitan.pl',
          changeReason: '$changeReason (auto calculation: capitalSecured + capitalRestructuring)',
        );

        if (success) {
          successCount++;
          debugPrint(
            '✅ [InvestorEditService] UNIVERSAL: Pomyślnie edytowano: ${original.id}',
          );
        } else {
          debugPrint(
            '❌ [InvestorEditService] UNIVERSAL: Błąd edycji ${original.id}',
          );
          // Kontynuuj z pozostałymi inwestycjami
        }
      }

      debugPrint(
        '📊 [InvestorEditService] UNIVERSAL PODSUMOWANIE: $successCount/$totalChanges zmian zapisanych pomyślnie',
      );

      // Wyczyść cache uniwersalnego serwisu
      try {
        await universalService.clearAllCache();
        await _productManagementService.clearAllCache();
        debugPrint('✅ [InvestorEditService] UNIVERSAL: Cache wyczyszczony');
      } catch (e) {
        debugPrint('⚠️ [InvestorEditService] Błąd czyszczenia cache: $e');
      }

      // Zwróć sukces jeśli udało się zapisać wszystkie zmiany
      return successCount == totalChanges;
    } catch (e) {
      debugPrint('💥 [InvestorEditService] UNIVERSAL: Krytyczny błąd: $e');
      return false;
    }
  }

  /// UNIVERSAL: Ponownie ładuje dane inwestycji używając UniversalInvestmentService po skalowaniu
  Future<List<Investment>> reloadInvestmentsAfterScaling(
    List<Investment> originalInvestments,
  ) async {
    try {
      debugPrint(
        '🔄 [InvestorEditService] UNIVERSAL: Ponowne ładowanie danych po skalowaniu...',
      );

      // Użyj uniwersalnego serwisu dla spójnych danych
      final universalService = universal.UniversalInvestmentService.instance;
      final investmentIds = originalInvestments.map((inv) => inv.id).toList();

      final updatedInvestments = await universalService.getInvestments(
        investmentIds,
      );

      debugPrint(
        '✅ [InvestorEditService] UNIVERSAL: Ponowne ładowanie zakończone - ${updatedInvestments.length} inwestycji',
      );
      return updatedInvestments.isNotEmpty
          ? updatedInvestments
          : originalInvestments;
    } catch (e) {
      debugPrint(
        '❌ [InvestorEditService] UNIVERSAL: Błąd podczas ponownego ładowania: $e',
      );
      // Zwróć oryginalne inwestycje w przypadku błędu
      return originalInvestments;
    }
  }

  /// 🚀 NOWA METODA: Pobiera szczegóły produktu z ProductManagementService
  /// Zapewnia lepszą wydajność i spójność z innymi ekranami
  Future<UnifiedProduct?> getProductDetailsOptimized(String productId) async {
    try {
      final productData = await _productManagementService.loadOptimizedData();

      // Sprawdź w optimized products
      final optimizedProduct = productData.optimizedProducts
          .where((p) => p.id == productId)
          .firstOrNull;

      if (optimizedProduct != null) {
        // Konwertuj OptimizedProduct na UnifiedProduct (jeśli potrzebne)
        debugPrint(
          '🚀 [InvestorEditService] Znaleziono produkt w OptimizedProducts: ${optimizedProduct.name}',
        );
        // TODO: Konwersja jeśli potrzebna
        return null; // Tymczasowo
      }

      return null;
    } catch (e) {
      debugPrint(
        '⚠️ [InvestorEditService] Błąd pobierania produktu z ProductManagementService: $e',
      );
      return null;
    }
  }

  /// 🚀 NOWA METODA: Wyszukuje produkty z ProductManagementService
  /// Zapewnia unified search experience
  Future<List<UnifiedProduct>> searchProductsOptimized(String query) async {
    try {
      final searchResult = await _productManagementService.searchProducts(
        query: query,
        useOptimizedMode: true,
        maxResults: 20,
      );

      debugPrint(
        '🔍 [InvestorEditService] ProductManagementService: ${searchResult.totalResults} wyników dla "$query" w ${searchResult.searchTime}ms',
      );

      // TODO: Konwersja OptimizedProduct na UnifiedProduct jeśli potrzebna
      return []; // Tymczasowo
    } catch (e) {
      debugPrint(
        '⚠️ [InvestorEditService] Błąd wyszukiwania w ProductManagementService: $e',
      );
      return [];
    }
  }

  /// 🚀 NOWA METODA: Czyszczenie cache z integracją ProductManagementService
  Future<void> clearAllCache() async {
    try {
      await _productManagementService.clearAllCache();
      debugPrint(
        '✅ [InvestorEditService] Cache ProductManagementService wyczyszczony',
      );
    } catch (e) {
      debugPrint('⚠️ [InvestorEditService] Błąd czyszczenia cache: $e');
    }
  }

  /// 🧹 UNIFIED: Clears all relevant caches to ensure data consistency
  Future<void> clearInvestmentCache() async {
    try {
      // Clear product management cache
      await _productManagementService.clearAllCache();

      // 🎯 RÓWNIEŻ wyczyść cache głównych serwisów używanych przez widok produktów
      try {
        // UltraPreciseProductInvestorsService używa Firebase Functions które mają własny cache
        // więc musimy wymusić forceRefresh w następnych wywołaniach

        final modalService = UnifiedProductModalService();
        await modalService.clearAllCache();

        debugPrint('✅ [InvestorEditService] UNIFIED: All caches cleared');
      } catch (e) {
        debugPrint(
          '⚠️ [InvestorEditService] Warning: Could not clear some caches: $e',
        );
      }

      debugPrint('✅ [InvestorEditService] Investment cache cleared');
    } catch (e) {
      debugPrint(
        '⚠️ [InvestorEditService] Error clearing investment cache: $e',
      );
    }
  }

  /// 🔄 UNIFIED: Refreshes investor data using the same data sources as product views
  Future<InvestorSummary> refreshInvestorData(
    InvestorSummary originalInvestor,
  ) async {
    try {
      debugPrint(
        '🔄 [InvestorEditService] UNIFIED: Refreshing investor data for: ${originalInvestor.client.name}',
      );
      debugPrint(
        '🔄 [InvestorEditService] Original client ID: "${originalInvestor.client.id}"',
      );
      debugPrint(
        '🔄 [InvestorEditService] Original investments: ${originalInvestor.investments.length}',
      );

      // 🎯 STRATEGIA: Pobierz świeże dane dla konkretnych inwestycji zamiast szukania po clientId
      final allFreshInvestments = await _getFreshInvestmentsByIds(
        originalInvestor.investments.map((inv) => inv.id).toList(),
      );

      if (allFreshInvestments.isEmpty) {
        debugPrint(
          '⚠️ [InvestorEditService] No fresh investments found for client: ${originalInvestor.client.id}',
        );
        return originalInvestor;
      }

      debugPrint(
        '✅ [InvestorEditService] Found ${allFreshInvestments.length} fresh investments',
      );

      // 🔧 POPRAW DANE KLIENTA w świeżych inwestycjach jeśli są puste/niepoprawne
      final correctedInvestments = allFreshInvestments.map((inv) {
        // Jeśli inwestycja ma puste clientId/clientName, użyj danych z oryginalnego klienta
        String correctedClientId = inv.clientId;
        String correctedClientName = inv.clientName;

        if (inv.clientId.isEmpty || inv.clientId.startsWith('unknown_')) {
          // Spróbuj użyć prawdziwego ID klienta z oryginalnego inwestora
          if (originalInvestor.client.id.isNotEmpty &&
              !originalInvestor.client.id.startsWith('unknown_')) {
            correctedClientId = originalInvestor.client.id;
          }
        }

        if (inv.clientName.isEmpty || inv.clientName == 'Nieznany klient') {
          if (originalInvestor.client.name.isNotEmpty &&
              originalInvestor.client.name != 'Nieznany klient') {
            correctedClientName = originalInvestor.client.name;
          }
        }

        if (correctedClientId != inv.clientId ||
            correctedClientName != inv.clientName) {
          debugPrint(
            '🔧 [InvestorEditService] Correcting client data for investment ${inv.id}:',
          );
          debugPrint('   - clientId: "${inv.clientId}" → "$correctedClientId"');
          debugPrint(
            '   - clientName: "${inv.clientName}" → "$correctedClientName"',
          );

          return inv.copyWith(
            clientId: correctedClientId,
            clientName: correctedClientName,
          );
        }

        return inv;
      }).toList();

      // Utwórz nowy InvestorSummary ze świeżymi danymi
      final refreshedInvestor = InvestorSummary.withoutCalculations(
        originalInvestor.client,
        correctedInvestments,
      );

      // Przelicz podsumowania
      final calculatedInvestor = InvestorSummary.calculateSecuredCapitalForAll([
        refreshedInvestor,
      ]).first;

      debugPrint(
        '🔄 [InvestorEditService] UNIFIED: Investor data refreshed successfully',
      );
      debugPrint('   - Fresh investments: ${allFreshInvestments.length}');
      debugPrint(
        '   - Total remaining capital: ${calculatedInvestor.totalRemainingCapital}',
      );

      return calculatedInvestor;
    } catch (e) {
      debugPrint('⚠️ [InvestorEditService] Error refreshing investor data: $e');
      return originalInvestor;
    }
  }

  /// 🎯 UNIVERSAL: Pobiera świeże inwestycje po ID używając UniversalInvestmentService
  Future<List<Investment>> _getFreshInvestmentsByIds(
    List<String> investmentIds,
  ) async {
    try {
      debugPrint(
        '🔍 [InvestorEditService] UNIVERSAL: Fetching fresh investments by IDs: $investmentIds',
      );

      // 🚀 FORCE FRESH FETCH: Clear cache first to ensure absolutely fresh data
      final universalService = universal.UniversalInvestmentService.instance;
      await universalService.clearAllCache();

      final investments = await universalService.getInvestments(investmentIds);

      debugPrint(
        '✅ [InvestorEditService] UNIVERSAL: Fetched ${investments.length} fresh investments',
      );

      // 📊 Debug: pokaż szczegóły świeżych inwestycji
      for (final inv in investments) {
        debugPrint('📊 [InvestorEditService] Fresh investment: ${inv.id}');
        debugPrint('   - clientId: "${inv.clientId}"');
        debugPrint('   - clientName: "${inv.clientName}"');
        debugPrint('   - productId: ${inv.productId}');
        debugPrint('   - productName: ${inv.productName}');
        debugPrint('   - remainingCapital: ${inv.remainingCapital}');
        debugPrint('   - investmentAmount: ${inv.investmentAmount}');
        debugPrint(
          '   - capitalForRestructuring: ${inv.capitalForRestructuring}',
        );
        debugPrint(
          '   - capitalSecuredByRealEstate: ${inv.capitalSecuredByRealEstate}',
        );
        debugPrint('   - updatedAt: ${inv.updatedAt.toIso8601String()}');
      }

      return investments;
    } catch (e) {
      debugPrint(
        '❌ [InvestorEditService] UNIVERSAL: Error fetching fresh investments: $e',
      );
      return [];
    }
  }
}
