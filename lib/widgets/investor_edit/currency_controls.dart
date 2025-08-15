import 'package:flutter/material.dart';
import '../../utils/currency_input_formatter.dart';
import '../../theme/app_theme_professional.dart';

/// Widget dla pól edycji kwot walutowych z formatowaniem
///
/// Zapewnia:
/// - Automatyczne formatowanie z separatorami tysięcznymi
/// - Walidację wartości
/// - Spójny wygląd zgodny z AppThemePro
/// - Obsługę tekstu pomocy
class CurrencyInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final Color color;
  final bool isEditable;
  final String? helpText;
  final String? Function(String?)? validator;
  final VoidCallback? onChanged;

  const CurrencyInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    required this.color,
    this.isEditable = true,
    this.helpText,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppThemePro.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: isEditable,
          inputFormatters: isEditable ? [CurrencyInputFormatter()] : null,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isEditable
                ? AppThemePro.textPrimary
                : AppThemePro.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isEditable
                ? AppThemePro.backgroundSecondary
                : AppThemePro.backgroundTertiary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppThemePro.borderPrimary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppThemePro.borderPrimary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppThemePro.lossRed),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppThemePro.borderSecondary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
            suffixText: 'PLN',
            suffixStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppThemePro.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          validator: validator,
          onChanged: (value) {
            if (onChanged != null) {
              onChanged!();
            }
          },
        ),
        if (helpText != null) ...[
          const SizedBox(height: 4),
          Text(
            helpText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppThemePro.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget dla kontrolek całkowitej kwoty produktu
class ProductTotalAmountControl extends StatelessWidget {
  final TextEditingController controller;
  final double originalAmount;
  final bool isChangingAmount;
  final double? pendingChange;
  final VoidCallback? onChanged;

  const ProductTotalAmountControl({
    super.key,
    required this.controller,
    required this.originalAmount,
    this.isChangingAmount = false,
    this.pendingChange,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: AppThemePro.accentGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Całkowita kwota produktu',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          CurrencyInputField(
            label: 'Nowa kwota całkowita',
            controller: controller,
            icon: Icons.edit,
            color: AppThemePro.accentGold,
            helpText:
                'Zmiana tej wartości przeskaluje wszystkie inwestycje proporcjonalnie',
            onChanged: onChanged,
          ),

          const SizedBox(height: 16),

          if (pendingChange != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppThemePro.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppThemePro.accentGold.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppThemePro.accentGold,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Oczekujące skalowanie',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemePro.accentGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Oryginalna kwota: ${originalAmount.toStringAsFixed(2)} PLN\n'
                    'Nowa kwota: ${pendingChange!.toStringAsFixed(2)} PLN\n'
                    'Współczynnik: ${((pendingChange! / originalAmount) * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppThemePro.backgroundTertiary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppThemePro.borderSecondary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppThemePro.accentGold,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Jak działa skalowanie',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppThemePro.accentGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Zmiana tej kwoty automatycznie przeskaluje WSZYSTKIE inwestycje w produkcie\n'
                  '• Proporcje między inwestorami zostaną zachowane\n'
                  '• Operacja jest wykonywana przez serwer Firebase Functions\n'
                  '• Historia zmian zostanie automatycznie zapisana',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
