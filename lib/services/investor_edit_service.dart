import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';
import '../models/investor_edit_models.dart';
import '../utils/currency_formatter.dart';

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
    final cleanText = text.replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(cleanText) ?? 0.0;
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

      // Sprawdź zgodność sum
      final calculatedRemainingCapital = calculateRemainingCapital(
        capitalSecured,
        capitalForRestructuring,
      );
      if ((calculatedRemainingCapital - investmentAmount).abs() > 0.01) {
        warnings.add(
          'Niezgodność sum w inwestycji ${i + 1}: '
          'kwota inwestycji (${investmentAmount.toStringAsFixed(2)}) '
          'różni się od kapitału pozostałego (${calculatedRemainingCapital.toStringAsFixed(2)})',
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

  /// Zapisuje zmiany w inwestycjach
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
      debugPrint('💾 [InvestorEditService] Zapisuję zmiany w inwestycjach...');

      // Przygotuj listę zmian do zapisania
      final List<Investment> updatedInvestments = [];

      for (int i = 0; i < originalInvestments.length; i++) {
        final original = originalInvestments[i];

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
        bool hasChanges = false;
        final Map<String, dynamic> oldValues = {};
        final Map<String, dynamic> newValues = {};

        if ((remainingCapital - original.remainingCapital).abs() > 0.01) {
          hasChanges = true;
          oldValues['remainingCapital'] = original.remainingCapital;
          newValues['remainingCapital'] = remainingCapital;
        }

        if ((investmentAmount - original.investmentAmount).abs() > 0.01) {
          hasChanges = true;
          oldValues['investmentAmount'] = original.investmentAmount;
          newValues['investmentAmount'] = investmentAmount;
        }

        if ((capitalForRestructuring - original.capitalForRestructuring).abs() >
            0.01) {
          hasChanges = true;
          oldValues['capitalForRestructuring'] =
              original.capitalForRestructuring;
          newValues['capitalForRestructuring'] = capitalForRestructuring;
        }

        if ((capitalSecured - original.capitalSecuredByRealEstate).abs() >
            0.01) {
          hasChanges = true;
          oldValues['capitalSecuredByRealEstate'] =
              original.capitalSecuredByRealEstate;
          newValues['capitalSecuredByRealEstate'] = capitalSecured;
        }

        if (status != original.status) {
          hasChanges = true;
          oldValues['status'] = original.status.toString();
          newValues['status'] = status.toString();
        }

        if (hasChanges) {
          // Utwórz zaktualizowaną inwestycję
          final updatedInvestment = Investment(
            id: original.id,
            clientId: original.clientId,
            clientName: original.clientName,
            employeeId: original.employeeId,
            employeeFirstName: original.employeeFirstName,
            employeeLastName: original.employeeLastName,
            branchCode: original.branchCode,
            status: status,
            isAllocated: original.isAllocated,
            marketType: original.marketType,
            signedDate: original.signedDate,
            entryDate: original.entryDate,
            exitDate: original.exitDate,
            proposalId: original.proposalId,
            productType: original.productType,
            productName: original.productName,
            productId: original.productId,
            creditorCompany: original.creditorCompany,
            companyId: original.companyId,
            issueDate: original.issueDate,
            redemptionDate: original.redemptionDate,
            sharesCount: original.sharesCount,
            investmentAmount: investmentAmount,
            paidAmount: original.paidAmount,
            realizedCapital: original.realizedCapital,
            realizedInterest: original.realizedInterest,
            transferToOtherProduct: original.transferToOtherProduct,
            remainingCapital: remainingCapital,
            remainingInterest: original.remainingInterest,
            plannedTax: original.plannedTax,
            realizedTax: original.realizedTax,
            currency: original.currency,
            exchangeRate: original.exchangeRate,
            createdAt: original.createdAt,
            updatedAt: DateTime.now(),
            capitalSecuredByRealEstate: capitalSecured,
            capitalForRestructuring: capitalForRestructuring,
            additionalInfo: original.additionalInfo,
          );

          updatedInvestments.add(updatedInvestment);

          // Zapisz do historii
          try {
            await _historyService.recordChange(
              investmentId: original.id,
              oldValues: oldValues,
              newValues: newValues,
              changeType: InvestmentChangeType.bulkUpdate,
              customDescription: changeReason,
            );
          } catch (historyError) {
            debugPrint(
              '⚠️ [InvestorEditService] Błąd zapisywania historii: $historyError',
            );
          }
        }
      }

      if (updatedInvestments.isEmpty) {
        debugPrint('ℹ️ [InvestorEditService] Brak zmian do zapisania');
        return true;
      }

      debugPrint(
        '💾 [InvestorEditService] Zapisuję ${updatedInvestments.length} zmian...',
      );

      // Zapisz zmiany przez InvestmentService
      for (final updatedInvestment in updatedInvestments) {
        try {
          await _investmentService.updateInvestment(
            updatedInvestment.id,
            updatedInvestment,
          );
          debugPrint(
            '✅ [InvestorEditService] Zapisano inwestycję: ${updatedInvestment.id}',
          );
        } catch (e) {
          debugPrint(
            '❌ [InvestorEditService] Błąd zapisywania inwestycji ${updatedInvestment.id}: $e',
          );
          return false;
        }
      }

      debugPrint(
        '✅ [InvestorEditService] Wszystkie zmiany zostały zapisane pomyślnie',
      );
      return true;
    } catch (e) {
      debugPrint('❌ [InvestorEditService] Błąd podczas zapisywania zmian: $e');
      return false;
    }
  }

  /// Ponownie ładuje dane inwestycji z backend po skalowaniu
  Future<List<Investment>> reloadInvestmentsAfterScaling(
    List<Investment> originalInvestments,
  ) async {
    try {
      debugPrint(
        '🔄 [InvestorEditService] Ponowne ładowanie danych po skalowaniu...',
      );

      final updatedInvestments = <Investment>[];

      for (final originalInvestment in originalInvestments) {
        // Pobierz zaktualizowane dane z Firebase
        final updatedInvestment = await _investmentService.getInvestment(
          originalInvestment.id,
        );

        if (updatedInvestment != null) {
          updatedInvestments.add(updatedInvestment);
          debugPrint(
            '✅ [InvestorEditService] Zaktualizowano inwestycję: ${originalInvestment.id}',
          );
        } else {
          debugPrint(
            '⚠️ [InvestorEditService] Nie znaleziono zaktualizowanych danych dla inwestycji: ${originalInvestment.id}',
          );
          // Zachowaj oryginalną inwestycję jeśli nie udało się załadować nowych danych
          updatedInvestments.add(originalInvestment);
        }
      }

      debugPrint('✅ [InvestorEditService] Ponowne ładowanie zakończone');
      return updatedInvestments;
    } catch (e) {
      debugPrint(
        '❌ [InvestorEditService] Błąd podczas ponownego ładowania: $e',
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
}
