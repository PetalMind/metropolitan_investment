import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import '../../providers/auth_provider.dart';

/// Widget karty edycji pojedynczej inwestycji
class InvestmentEditCard extends StatelessWidget {
  final Investment investment;
  final int index;
  final TextEditingController remainingCapitalController;
  final TextEditingController investmentAmountController;
  final TextEditingController capitalForRestructuringController;
  final TextEditingController capitalSecuredController;
  final InvestmentStatus statusValue;
  final Function(InvestmentStatus) onStatusChanged;
  final VoidCallback? onChanged;

  const InvestmentEditCard({
    super.key,
    required this.investment,
    required this.index,
    required this.remainingCapitalController,
    required this.investmentAmountController,
    required this.capitalForRestructuringController,
    required this.capitalSecuredController,
    required this.statusValue,
    required this.onStatusChanged,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // RBAC: sprawdzenie uprawnień
    final bool canEdit = context.read<AuthProvider>().isAdmin;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek karty
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppThemePro.accentGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${investment.productName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.accentGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(statusValue).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(statusValue),
                      size: 14,
                      color: _getStatusColor(statusValue),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusValue.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(statusValue),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Pola edycji w kompaktowym układzie
          Column(
            children: [
              // Pierwszy rząd - Kwota inwestycji i Kapitał pozostały
              Row(
                children: [
                  Expanded(
                    child: CurrencyInputField(
                      label: 'Kwota inwestycji',
                      controller: investmentAmountController,
                      icon: Icons.attach_money,
                      color: AppThemePro.profitGreen,
                      isEditable:
                          false, // 🔒 ZABLOKOWANE: Kwota inwestycji nie może być edytowana
                      helpText: 'Wartość podstawowa inwestycji',
                      investmentId: investment.id, // 🚀 NOWE: ID inwestycji
                      fieldName: 'investmentAmount', // 🚀 NOWE: Nazwa pola
                      showChangeIndicator:
                          true, // 🚀 NOWE: Pokaż wskaźnik zmian
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CurrencyInputField(
                      label: 'Kapitał pozostały',
                      controller: remainingCapitalController,
                      icon: Icons.account_balance,
                      color: AppThemePro.primaryLight,
                      isEditable: false,
                      helpText: 'Obliczane automatycznie',
                      calculationFormula:
                          'Zabezpieczony + Restrukturyzacja', // 🚀 NOWE: Wzór
                      investmentId: investment.id, // 🚀 NOWE: ID inwestycji
                      fieldName: 'remainingCapital', // 🚀 NOWE: Nazwa pola
                      showChangeIndicator:
                          false, // 🚀 TYMCZASOWO WYŁĄCZONE: debugujemy problem z wskaźnikami
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Drugi rząd - Kapitał zabezpieczony i Kapitał do restrukturyzacji
              Row(
                children: [
                  Expanded(
                    child: CurrencyInputField(
                      label: 'Kapitał zabezpieczony',
                      controller: capitalSecuredController,
                      icon: Icons.security,
                      color: AppThemePro.statusSuccess,
                      isEditable: canEdit, // RBAC: tylko admin może edytować
                      onChanged: canEdit ? onChanged : null,
                      investmentId: investment.id, // 🚀 NOWE: ID inwestycji
                      fieldName:
                          'capitalSecuredByRealEstate', // 🚀 NOWE: Nazwa pola
                      showChangeIndicator:
                          true, // 🚀 NOWE: Pokaż wskaźnik zmian
                      helpText: canEdit
                          ? 'Kapitał zabezpieczony nieruchomością'
                          : 'Brak uprawnień – rola user', // 🚀 RBAC: Lepszy opis
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CurrencyInputField(
                      label: 'Kapitał do restrukturyzacji',
                      controller: capitalForRestructuringController,
                      icon: Icons.construction,
                      color: AppThemePro.statusWarning,
                      isEditable: canEdit, // RBAC: tylko admin może edytować
                      onChanged: canEdit ? onChanged : null,
                      investmentId: investment.id, // 🚀 NOWE: ID inwestycji
                      fieldName:
                          'capitalForRestructuring', // 🚀 NOWE: Nazwa pola
                      showChangeIndicator:
                          false, // 🚀 TYMCZASOWO WYŁĄCZONE: debugujemy problem z wskaźnikami
                      helpText: canEdit
                          ? 'Kapitał przeznaczony na restrukturyzację'
                          : 'Brak uprawnień – rola user', // 🚀 RBAC: Lepszy opis
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flag, size: 16, color: AppThemePro.accentGold),
                  const SizedBox(width: 8),
                  Text(
                    'Status inwestycji',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppThemePro.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Tooltip(
                message: canEdit
                    ? 'Zmień status inwestycji'
                    : kRbacNoPermissionTooltip,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: canEdit
                        ? AppThemePro.backgroundTertiary
                        : AppThemePro.backgroundTertiary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppThemePro.borderPrimary),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<InvestmentStatus>(
                      value: statusValue,
                      isExpanded: true,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: canEdit
                            ? AppThemePro.textPrimary
                            : AppThemePro.textSecondary,
                      ),
                      dropdownColor: AppThemePro.backgroundSecondary,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: canEdit
                            ? AppThemePro.textSecondary
                            : AppThemePro.textSecondary.withOpacity(0.5),
                      ),
                      onChanged: canEdit
                          ? (InvestmentStatus? newValue) {
                              if (newValue != null) {
                                onStatusChanged(newValue);
                                if (onChanged != null) {
                                  onChanged!();
                                }
                              }
                            }
                          : null,
                      items: InvestmentStatus.values.map((status) {
                        return DropdownMenuItem<InvestmentStatus>(
                          value: status,
                          child: Row(
                            children: [
                              Icon(
                                _getStatusIcon(status),
                                size: 16,
                                color: _getStatusColor(status),
                              ),
                              const SizedBox(width: 8),
                              Text(status.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 🚀 NOWE: Panel szybkich obliczeń w czasie rzeczywistym
          const SizedBox(height: 16),
          _buildCalculationPreviewPanel(),

          // Historia zmian
        ],
      ),
    );
  }

  /// 🚀 NOWE: Panel podglądu obliczeń w czasie rzeczywistym
  Widget _buildCalculationPreviewPanel() {
    // Parsuj aktualne wartości z kontrolerów
    final double currentCapitalSecured = _parseControllerValue(
      capitalSecuredController.text,
    );
    final double currentCapitalForRestructuring = _parseControllerValue(
      capitalForRestructuringController.text,
    );
    final double currentInvestmentAmount = _parseControllerValue(
      investmentAmountController.text,
    );

    // Oblicz kapitał pozostały według wzoru
    final double calculatedRemainingCapital =
        currentCapitalSecured + currentCapitalForRestructuring;

    // Sprawdź czy wartości się zgadzają
    final double currentRemainingCapital = _parseControllerValue(
      remainingCapitalController.text,
    );
    final bool isBalanced =
        (calculatedRemainingCapital - currentRemainingCapital).abs() < 0.01;
    final bool matchesInvestmentAmount =
        (calculatedRemainingCapital - currentInvestmentAmount).abs() < 0.01;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.accentGold.withValues(alpha: 0.05),
            AppThemePro.accentGold.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppThemePro.accentGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                size: 16,
                color: AppThemePro.accentGold,
              ),
              const SizedBox(width: 6),
              Text(
                'Podgląd obliczeń na żywo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppThemePro.accentGold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Wzór obliczenia
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppThemePro.backgroundSecondary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppThemePro.borderPrimary, width: 1),
            ),
            child: Text(
              '${currentCapitalSecured.toStringAsFixed(0)} PLN + ${currentCapitalForRestructuring.toStringAsFixed(0)} PLN = ${calculatedRemainingCapital.toStringAsFixed(0)} PLN',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Status zgodności
          Row(
            children: [
              Icon(
                isBalanced ? Icons.check_circle : Icons.warning,
                size: 14,
                color: isBalanced
                    ? AppThemePro.statusSuccess
                    : AppThemePro.statusWarning,
              ),
              const SizedBox(width: 4),
              Text(
                isBalanced ? 'Wartości się zgadzają' : 'Niezgodność wartości',
                style: TextStyle(
                  fontSize: 11,
                  color: isBalanced
                      ? AppThemePro.statusSuccess
                      : AppThemePro.statusWarning,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!matchesInvestmentAmount && isBalanced) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.info_outline,
                  size: 12,
                  color: AppThemePro.statusInfo,
                ),
                const SizedBox(width: 2),
                Text(
                  'Różni się od kwoty inwestycji',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppThemePro.statusInfo,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Helper do parsowania wartości z kontrolera
  double _parseControllerValue(String text) {
    final cleanText = text.replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(cleanText) ?? 0.0;
  }

  Color _getStatusColor(InvestmentStatus status) {
    switch (status) {
      case InvestmentStatus.active:
        return AppThemePro.statusSuccess;
      case InvestmentStatus.inactive:
        return AppThemePro.statusWarning;
      case InvestmentStatus.earlyRedemption:
        return AppThemePro.statusInfo;
      case InvestmentStatus.completed:
        return AppThemePro.profitGreen;
    }
  }

  IconData _getStatusIcon(InvestmentStatus status) {
    switch (status) {
      case InvestmentStatus.active:
        return Icons.check_circle;
      case InvestmentStatus.inactive:
        return Icons.pause_circle;
      case InvestmentStatus.earlyRedemption:
        return Icons.fast_forward;
      case InvestmentStatus.completed:
        return Icons.task_alt;
    }
  }
}
