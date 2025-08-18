import 'package:flutter/material.dart';
import '../../utils/currency_input_formatter.dart';
import '../../theme/app_theme_professional.dart';
import '../../models_and_services.dart';

/// Widget dla pól edycji kwot walutowych z formatowaniem
///
/// Zapewnia:
/// - Automatyczne formatowanie z separatorami tysięcznymi
/// - Walidację wartości
/// - Spójny wygląd zgodny z AppThemePro
/// - Obsługę tekstu pomocy
/// - 🚀 NOWE: Wizualne wskaźniki zmian na podstawie rzeczywistej historii
class CurrencyInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final Color color;
  final bool isEditable;
  final String? helpText;
  final String? Function(String?)? validator;
  final VoidCallback? onChanged;
  final String? investmentId; // 🚀 NOWE: ID inwestycji do pobierania historii
  final String? fieldName; // 🚀 NOWE: Nazwa pola do śledzenia zmian
  final String? calculationFormula; // 🚀 NOWE: Wzór obliczenia (np. "Zabezpieczony + Restrukturyzacja")
  final bool showChangeIndicator; // 🚀 NOWE: Czy pokazywać wskaźnik zmian

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
    this.investmentId, // 🚀 NOWE: ID inwestycji do pobierania historii
    this.fieldName, // 🚀 NOWE: Nazwa pola do śledzenia zmian
    this.calculationFormula, // 🚀 NOWE: Wzór obliczenia
    this.showChangeIndicator = false, // 🚀 NOWE: Wskaźnik zmian
  });

  @override
  State<CurrencyInputField> createState() => _CurrencyInputFieldState();
}

class _CurrencyInputFieldState extends State<CurrencyInputField> {
  FieldChangeInfo? _fieldChangeInfo;
  bool _isLoadingChange = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.showChangeIndicator && 
        widget.investmentId != null && 
        widget.fieldName != null) {
      _loadFieldChangeInfo();
    }
  }
  
  /// Ładuje informacje o zmianach z historii
  Future<void> _loadFieldChangeInfo() async {
    if (_isLoadingChange) return;
    
    setState(() {
      _isLoadingChange = true;
    });
    
    try {
      final calculator = InvestmentChangeCalculatorService();
      final text = widget.controller.text.replaceAll(' ', '').replaceAll(',', '.');
      final currentValue = double.tryParse(text) ?? 0.0;
      
      final changeInfo = await calculator.calculateFieldChange(
        investmentId: widget.investmentId!,
        fieldName: widget.fieldName!,
        currentValue: currentValue,
      );
      
      if (mounted) {
        setState(() {
          _fieldChangeInfo = changeInfo;
          _isLoadingChange = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [CurrencyInputField] Error loading field change info: $e');
      if (mounted) {
        setState(() {
          _isLoadingChange = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon, size: 16, color: widget.color),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppThemePro.textPrimary,
              ),
            ),
            // 🚀 NOWE: Wskaźnik zmian na podstawie rzeczywistej historii
            if (widget.showChangeIndicator && _fieldChangeInfo != null && _fieldChangeInfo!.changeAmount.abs() > 0.01) ...[
              const SizedBox(width: 8),
              _isLoadingChange
                  ? _buildLoadingIndicator()
                  : _buildChangeIndicator(_fieldChangeInfo!),
            ] else if (widget.showChangeIndicator && _isLoadingChange) ...[
              const SizedBox(width: 8),
              _buildLoadingIndicator(),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          enabled: widget.isEditable,
          inputFormatters: widget.isEditable ? [CurrencyInputFormatter()] : null,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: widget.isEditable
                ? AppThemePro.textPrimary
                : AppThemePro.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: widget.isEditable
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
              borderSide: BorderSide(color: widget.color, width: 2),
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
          validator: widget.validator,
          onChanged: (value) {
            if (widget.onChanged != null) {
              widget.onChanged!();
            }
            // Przeładuj informacje o zmianach gdy wartość się zmieni
            if (widget.showChangeIndicator && 
                widget.investmentId != null && 
                widget.fieldName != null) {
              _loadFieldChangeInfo();
            }
          },
        ),
        if (widget.helpText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.helpText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppThemePro.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        // 🚀 NOWE: Wzór obliczenia
        if (widget.calculationFormula != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppThemePro.accentGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppThemePro.accentGold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calculate,
                  size: 12,
                  color: AppThemePro.accentGold,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.calculationFormula!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.accentGold,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Widget wskaźnika ładowania
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppThemePro.textMuted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppThemePro.textMuted),
        ),
      ),
    );
  }

  /// Widget wskaźnika zmian
  Widget _buildChangeIndicator(FieldChangeInfo changeInfo) {
    final isPositive = changeInfo.isPositive;
    final color = isPositive ? AppThemePro.profitGreen : AppThemePro.lossRed;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${changeInfo.changePercentage.abs().toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
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
