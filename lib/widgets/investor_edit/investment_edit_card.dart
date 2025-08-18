import 'package:flutter/material.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import 'currency_controls.dart';

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
                  'Inwestycja ${index + 1}',
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

          // Informacje o inwestycji
          Text(
            'ID: ${investment.id}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppThemePro.textSecondary,
              fontFamily: 'monospace',
            ),
          ),

          const SizedBox(height: 16),

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
                      isEditable: false, // 🔒 ZABLOKOWANE: Kwota inwestycji nie może być edytowana
                      helpText: 'Wartość podstawowa inwestycji',
                      originalValue: investment.investmentAmount, // 🚀 NOWE: Oryginalna wartość
                      showChangeIndicator: true, // 🚀 NOWE: Pokaż wskaźnik zmian
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
                      calculationFormula: 'Zabezpieczony + Restrukturyzacja', // 🚀 NOWE: Wzór
                      originalValue: investment.remainingCapital, // 🚀 NOWE: Oryginalna wartość
                      showChangeIndicator: true, // 🚀 NOWE: Pokaż wskaźnik zmian
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
                      onChanged: onChanged,
                      originalValue: investment.capitalSecuredByRealEstate, // 🚀 NOWE: Oryginalna wartość
                      showChangeIndicator: true, // 🚀 NOWE: Pokaż wskaźnik zmian
                      helpText: 'Kapitał zabezpieczony nieruchomością', // 🚀 NOWE: Lepszy opis
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CurrencyInputField(
                      label: 'Kapitał do restrukturyzacji',
                      controller: capitalForRestructuringController,
                      icon: Icons.construction,
                      color: AppThemePro.statusWarning,
                      onChanged: onChanged,
                      originalValue: investment.capitalForRestructuring, // 🚀 NOWE: Oryginalna wartość
                      showChangeIndicator: true, // 🚀 NOWE: Pokaż wskaźnik zmian
                      helpText: 'Kapitał przeznaczony na restrukturyzację', // 🚀 NOWE: Lepszy opis
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppThemePro.backgroundTertiary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppThemePro.borderPrimary),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<InvestmentStatus>(
                    value: statusValue,
                    isExpanded: true,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppThemePro.textPrimary,
                    ),
                    dropdownColor: AppThemePro.backgroundSecondary,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: AppThemePro.textSecondary,
                    ),
                    onChanged: (InvestmentStatus? newValue) {
                      if (newValue != null) {
                        onStatusChanged(newValue);
                        if (onChanged != null) {
                          onChanged!();
                        }
                      }
                    },
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
            ],
          ),

          // 🚀 NOWE: Panel szybkich obliczeń w czasie rzeczywistym
          const SizedBox(height: 16),
          _buildCalculationPreviewPanel(),

          // Historia zmian
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                // Implementacja historii już istnieje w parent dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Historia zmian dostępna w zakładce "Historia Zmian"'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              icon: Icon(
                Icons.history,
                size: 16,
                color: AppThemePro.textSecondary,
              ),
              label: Text(
                'Zobacz historię zmian',
                style: TextStyle(
                  fontSize: 13,
                  color: AppThemePro.textSecondary,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🚀 NOWE: Panel podglądu obliczeń w czasie rzeczywistym
  Widget _buildCalculationPreviewPanel() {
    // Parsuj aktualne wartości z kontrolerów
    final double currentCapitalSecured = _parseControllerValue(capitalSecuredController.text);
    final double currentCapitalForRestructuring = _parseControllerValue(capitalForRestructuringController.text);
    final double currentInvestmentAmount = _parseControllerValue(investmentAmountController.text);
    
    // Oblicz kapitał pozostały według wzoru
    final double calculatedRemainingCapital = currentCapitalSecured + currentCapitalForRestructuring;
    
    // Sprawdź czy wartości się zgadzają
    final double currentRemainingCapital = _parseControllerValue(remainingCapitalController.text);
    final bool isBalanced = (calculatedRemainingCapital - currentRemainingCapital).abs() < 0.01;
    final bool matchesInvestmentAmount = (calculatedRemainingCapital - currentInvestmentAmount).abs() < 0.01;
    
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
              border: Border.all(
                color: AppThemePro.borderPrimary,
                width: 1,
              ),
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
                color: isBalanced ? AppThemePro.statusSuccess : AppThemePro.statusWarning,
              ),
              const SizedBox(width: 4),
              Text(
                isBalanced ? 'Wartości się zgadzają' : 'Niezgodność wartości',
                style: TextStyle(
                  fontSize: 11,
                  color: isBalanced ? AppThemePro.statusSuccess : AppThemePro.statusWarning,
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
