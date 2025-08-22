import 'package:flutter/material.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';

/// Widget wyświetlający podsumowanie inwestycji
class InvestmentsSummaryWidget extends StatelessWidget {
  final List<Investment> investments;
  final List<TextEditingController> remainingCapitalControllers;
  final List<TextEditingController> investmentAmountControllers;
  final List<TextEditingController> capitalForRestructuringControllers;
  final List<TextEditingController> capitalSecuredControllers;

  const InvestmentsSummaryWidget({
    super.key,
    required this.investments,
    required this.remainingCapitalControllers,
    required this.investmentAmountControllers,
    required this.capitalForRestructuringControllers,
    required this.capitalSecuredControllers,
  });

  double _parseValue(String text) {
    final cleanText = text.replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(cleanText) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    // Oblicz sumy z kontrolerów (aktualne wartości)
    double totalRemainingCapital = 0.0;
    double totalInvestmentAmount = 0.0;
    double totalCapitalForRestructuring = 0.0;
    double totalCapitalSecured = 0.0;

    for (int i = 0; i < investments.length; i++) {
      totalRemainingCapital += _parseValue(remainingCapitalControllers[i].text);
      totalInvestmentAmount += _parseValue(investmentAmountControllers[i].text);
      totalCapitalForRestructuring += _parseValue(
        capitalForRestructuringControllers[i].text,
      );
      totalCapitalSecured += _parseValue(capitalSecuredControllers[i].text);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: AppThemePro.accentGold, size: 20),
              const SizedBox(width: 8),
              Text(
                'Podsumowanie inwestycji (${investments.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildSummaryTile(
                context,
                'Kapitał pozostały',
                CurrencyFormatter.formatCurrency(totalRemainingCapital),
                Icons.account_balance,
                AppThemePro.primaryLight,
              ),
              _buildSummaryTile(
                context,
                'Kwota inwestycji',
                CurrencyFormatter.formatCurrency(totalInvestmentAmount),
                Icons.attach_money,
                AppThemePro.profitGreen,
              ),
              _buildSummaryTile(
                context,
                'Kapitał do restrukturyzacji',
                CurrencyFormatter.formatCurrency(totalCapitalForRestructuring),
                Icons.construction,
                AppThemePro.statusWarning,
              ),
              _buildSummaryTile(
                context,
                'Kapitał zabezpieczony',
                CurrencyFormatter.formatCurrency(totalCapitalSecured),
                Icons.security,
                AppThemePro.statusSuccess,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Informacja o automatycznych obliczeniach
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
                      Icons.calculate,
                      color: AppThemePro.accentGold,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Automatyczne obliczenia',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppThemePro.accentGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Kapitał pozostały = Kapitał zabezpieczony + Kapitał do restrukturyzacji\n'
                  'Wartości są automatycznie przeliczane podczas edycji',
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

  Widget _buildSummaryTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
