import 'package:flutter/material.dart';
import '../models_and_services.dart';

/// Wynik operacji skalowania produktu
class ProductScalingResult {
  final bool success;
  final String message;
  final double? newAmount;
  final int? affectedInvestments;
  final double? scalingFactor;
  final String? executionTime;

  const ProductScalingResult({
    required this.success,
    required this.message,
    this.newAmount,
    this.affectedInvestments,
    this.scalingFactor,
    this.executionTime,
  });
}

/// Stan edycji inwestora
class InvestorEditState {
  final bool isLoading;
  final bool isChanged;
  final String? error;
  final bool isChangingTotalAmount;
  final double? pendingTotalAmountChange;
  final double originalTotalProductAmount;

  const InvestorEditState({
    this.isLoading = false,
    this.isChanged = false,
    this.error,
    this.isChangingTotalAmount = false,
    this.pendingTotalAmountChange,
    this.originalTotalProductAmount = 0.0,
  });

  InvestorEditState copyWith({
    bool? isLoading,
    bool? isChanged,
    String? error,
    bool? isChangingTotalAmount,
    double? pendingTotalAmountChange,
    double? originalTotalProductAmount,
  }) {
    return InvestorEditState(
      isLoading: isLoading ?? this.isLoading,
      isChanged: isChanged ?? this.isChanged,
      error: error ?? this.error,
      isChangingTotalAmount: isChangingTotalAmount ?? this.isChangingTotalAmount,
      pendingTotalAmountChange: pendingTotalAmountChange ?? this.pendingTotalAmountChange,
      originalTotalProductAmount: originalTotalProductAmount ?? this.originalTotalProductAmount,
    );
  }

  /// Czyści błąd ze stanu
  InvestorEditState clearError() {
    return copyWith(error: null);
  }

  /// Ustawia stan ładowania
  InvestorEditState withLoading(bool loading) {
    return copyWith(isLoading: loading);
  }

  /// Oznacza że dane zostały zmienione
  InvestorEditState withChanges() {
    return copyWith(isChanged: true);
  }

  /// Resetuje stan zmian
  InvestorEditState resetChanges() {
    return copyWith(
      isChanged: false,
      pendingTotalAmountChange: null,
    );
  }
}

/// Dane kontrolerów dla edycji inwestycji
class InvestmentEditControllers {
  final List<TextEditingController> remainingCapitalControllers;
  final List<TextEditingController> investmentAmountControllers;
  final List<TextEditingController> capitalForRestructuringControllers;
  final List<TextEditingController> capitalSecuredByRealEstateControllers;
  final List<InvestmentStatus> statusValues;
  final TextEditingController totalProductAmountController;

  InvestmentEditControllers({
    required this.remainingCapitalControllers,
    required this.investmentAmountControllers,
    required this.capitalForRestructuringControllers,
    required this.capitalSecuredByRealEstateControllers,
    required this.statusValues,
    required this.totalProductAmountController,
  });

  /// Zwalnia wszystkie kontrolery
  void dispose() {
    for (final controller in remainingCapitalControllers) {
      controller.dispose();
    }
    for (final controller in investmentAmountControllers) {
      controller.dispose();
    }
    for (final controller in capitalForRestructuringControllers) {
      controller.dispose();
    }
    for (final controller in capitalSecuredByRealEstateControllers) {
      controller.dispose();
    }
    totalProductAmountController.dispose();
  }

  /// Czyści wszystkie kontrolery
  void clear() {
    remainingCapitalControllers.clear();
    investmentAmountControllers.clear();
    capitalForRestructuringControllers.clear();
    capitalSecuredByRealEstateControllers.clear();
    statusValues.clear();
  }
}

/// Podsumowanie zmian w inwestycjach
class InvestmentChangesSummary {
  final int totalInvestments;
  final int changedInvestments;
  final double totalRemainingCapital;
  final double totalInvestmentAmount;
  final double totalCapitalForRestructuring;
  final double totalCapitalSecured;

  const InvestmentChangesSummary({
    required this.totalInvestments,
    required this.changedInvestments,
    required this.totalRemainingCapital,
    required this.totalInvestmentAmount,
    required this.totalCapitalForRestructuring,
    required this.totalCapitalSecured,
  });
}

/// Typ operacji na inwestycji
enum InvestmentEditOperation {
  updateAmount,
  updateStatus,
  scaleProduct,
  calculateAutomatic,
}

/// Wynik walidacji edycji
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  factory ValidationResult.valid() {
    return const ValidationResult(isValid: true);
  }

  factory ValidationResult.invalid(List<String> errors, [List<String>? warnings]) {
    return ValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings ?? [],
    );
  }
}
