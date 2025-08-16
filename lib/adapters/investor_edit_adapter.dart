import 'package:flutter/material.dart';
import '../models_and_services.dart';

/// 🚀 ZUNIFIKOWANY ADAPTER DLA INVESTOR EDIT DIALOG
///
/// Adapter który pozwala InvestorEditDialog używać zunifikowanej architektury
/// z zachowaniem istniejącej logiki UI
class InvestorEditAdapter {
  static InvestorEditAdapter? _instance;
  static InvestorEditAdapter get instance =>
      _instance ??= InvestorEditAdapter._();
  InvestorEditAdapter._();

  final UnifiedDataService _unifiedService = UnifiedDataService.instance;
  late final InvestorEditService _editService;
  bool _initialized = false;

  /// Inicjalizuje adapter
  Future<void> initialize() async {
    if (_initialized) return;
    await _unifiedService.initialize();
    _editService = InvestorEditService();
    _initialized = true;
  }

  /// 🔍 ZNAJDŹ INWESTYCJE DLA PRODUKTU
  /// Używa zunifikowanej architektury do znalezienia inwestycji
  Future<List<Investment>> findInvestmentsForProduct(
    InvestorSummary investor,
    UnifiedProduct product,
  ) async {
    await initialize();

    // Użyj istniejącej logiki z InvestorEditService
    return _editService.findInvestmentsForProduct(investor, product);
  }

  /// 💾 ZAPISZ ZMIANY INWESTYCJI
  /// Integruje się z zunifikowaną architekturą dla spójności danych
  Future<InvestorEditSaveResult> saveInvestmentChanges({
    required List<Investment> originalInvestments,
    required List<TextEditingController> remainingCapitalControllers,
    required List<TextEditingController> investmentAmountControllers,
    required List<TextEditingController> capitalForRestructuringControllers,
    required List<TextEditingController> capitalSecuredControllers,
    required List<InvestmentStatus> statusValues,
    required String changeReason,
  }) async {
    await initialize();

    try {
      // Użyj istniejącej logiki z InvestorEditService
      final success = await _editService.saveInvestmentChanges(
        originalInvestments: originalInvestments,
        remainingCapitalControllers: remainingCapitalControllers,
        investmentAmountControllers: investmentAmountControllers,
        capitalForRestructuringControllers: capitalForRestructuringControllers,
        capitalSecuredControllers: capitalSecuredControllers,
        statusValues: statusValues,
        changeReason: changeReason,
      );

      if (success) {
        // Po udanym zapisie wyczyść cache w zunifikowanej architekturze
        await _unifiedService.clearCache();

        return InvestorEditSaveResult(
          success: true,
          message: 'Zmiany zostały zapisane pomyślnie',
          updatedInvestments:
              originalInvestments, // TODO: Pobierz zaktualizowane dane
          metadata: InvestorEditMetadata(
            saveTime: DateTime.now(),
            changeReason: changeReason,
            investmentsCount: originalInvestments.length,
            cacheCleared: true,
          ),
        );
      } else {
        return InvestorEditSaveResult(
          success: false,
          message: 'Błąd podczas zapisywania zmian',
          updatedInvestments: originalInvestments,
          metadata: InvestorEditMetadata(
            saveTime: DateTime.now(),
            changeReason: changeReason,
            investmentsCount: originalInvestments.length,
            cacheCleared: false,
          ),
        );
      }
    } catch (e) {
      return InvestorEditSaveResult(
        success: false,
        message: 'Błąd podczas zapisywania zmian: ${e.toString()}',
        updatedInvestments: originalInvestments,
        metadata: InvestorEditMetadata(
          saveTime: DateTime.now(),
          changeReason: changeReason,
          investmentsCount: originalInvestments.length,
          cacheCleared: false,
          error: e.toString(),
        ),
      );
    }
  }

  /// 📏 SKALUJ PRODUKT
  /// Używa zunifikowanej architektury dla spójności
  Future<ProductScalingResult> scaleProduct({
    required UnifiedProduct product,
    required double newTotalAmount,
    required double originalTotalAmount,
    required String reason,
  }) async {
    await initialize();

    try {
      // Użyj istniejącej logiki z InvestorEditService
      final scalingResult = await _editService.scaleProduct(
        product: product,
        newTotalAmount: newTotalAmount,
        originalTotalAmount: originalTotalAmount,
        reason: reason,
      );

      if (scalingResult.success) {
        // Po udanym skalowaniu wyczyść cache
        await _unifiedService.clearCache();

        return ProductScalingResult(
          success: true,
          message: scalingResult.message,
          scalingFactor: newTotalAmount / originalTotalAmount,
          metadata: ProductScalingMetadata(
            scalingTime: DateTime.now(),
            originalAmount: originalTotalAmount,
            newAmount: newTotalAmount,
            reason: reason,
            cacheCleared: true,
          ),
        );
      } else {
        return ProductScalingResult(
          success: false,
          message: scalingResult.message,
          scalingFactor: 1.0,
          metadata: ProductScalingMetadata(
            scalingTime: DateTime.now(),
            originalAmount: originalTotalAmount,
            newAmount: newTotalAmount,
            reason: reason,
            cacheCleared: false,
            error: scalingResult.message,
          ),
        );
      }
    } catch (e) {
      return ProductScalingResult(
        success: false,
        message: 'Błąd podczas skalowania produktu: ${e.toString()}',
        scalingFactor: 1.0,
        metadata: ProductScalingMetadata(
          scalingTime: DateTime.now(),
          originalAmount: originalTotalAmount,
          newAmount: newTotalAmount,
          reason: reason,
          cacheCleared: false,
          error: e.toString(),
        ),
      );
    }
  }

  /// 🔄 PRZEŁADUJ INWESTYCJE PO SKALOWANIU
  Future<List<Investment>> reloadInvestmentsAfterScaling(
    List<Investment> originalInvestments,
  ) async {
    await initialize();

    // Użyj istniejącej logiki z InvestorEditService
    return await _editService.reloadInvestmentsAfterScaling(
      originalInvestments,
    );
  }

  /// 🧮 OBLICZ POZOSTAŁY KAPITAŁ
  double calculateRemainingCapital(
    double capitalSecured,
    double capitalForRestructuring,
  ) {
    return _editService.calculateRemainingCapital(
      capitalSecured,
      capitalForRestructuring,
    );
  }

  /// 📝 FORMATUJ WARTOŚĆ DLA KONTROLERA
  String formatValueForController(double? value) {
    return _editService.formatValueForController(value ?? 0.0);
  }

  /// 🔢 PARSUJ WARTOŚĆ Z KONTROLERA
  double parseValueFromController(String text) {
    return _editService.parseValueFromController(text);
  }

  /// 🎯 RESOLVE PRODUCT ID
  String resolveProductId(UnifiedProduct product) {
    return UnifiedProductIdResolver.resolveProductId(
      product.id,
      productName: product.name,
      companyId: product.companyId,
      productType: product.productType,
    );
  }
}

/// 📋 WYNIK ZAPISU EDYCJI INWESTORA
class InvestorEditSaveResult {
  final bool success;
  final String message;
  final List<Investment> updatedInvestments;
  final InvestorEditMetadata metadata;

  const InvestorEditSaveResult({
    required this.success,
    required this.message,
    required this.updatedInvestments,
    required this.metadata,
  });
}

/// 📊 METADATA EDYCJI INWESTORA
class InvestorEditMetadata {
  final DateTime saveTime;
  final String changeReason;
  final int investmentsCount;
  final bool cacheCleared;
  final String? error;

  const InvestorEditMetadata({
    required this.saveTime,
    required this.changeReason,
    required this.investmentsCount,
    required this.cacheCleared,
    this.error,
  });
}

/// 📏 WYNIK SKALOWANIA PRODUKTU
class ProductScalingResult {
  final bool success;
  final String message;
  final double scalingFactor;
  final ProductScalingMetadata metadata;

  const ProductScalingResult({
    required this.success,
    required this.message,
    required this.scalingFactor,
    required this.metadata,
  });
}

/// 📈 METADATA SKALOWANIA PRODUKTU
class ProductScalingMetadata {
  final DateTime scalingTime;
  final double originalAmount;
  final double newAmount;
  final String reason;
  final bool cacheCleared;
  final String? error;

  const ProductScalingMetadata({
    required this.scalingTime,
    required this.originalAmount,
    required this.newAmount,
    required this.reason,
    required this.cacheCleared,
    this.error,
  });
}
