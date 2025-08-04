import 'package:flutter/material.dart';
import '../../../models_and_services.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/currency_formatter.dart';

/// Kompaktowa karta inwestora dla widoku kart
class InvestorCompactCard extends StatelessWidget {
  final InvestorSummary investor;
  final int position;
  final double totalPortfolioValue;
  final VoidCallback onTap;

  const InvestorCompactCard({
    super.key,
    required this.investor,
    required this.position,
    required this.totalPortfolioValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalPortfolioValue > 0
        ? (investor.totalValue / totalPortfolioValue) * 100
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceCard,
            AppTheme.backgroundSecondary.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryGold.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppTheme.borderSecondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Pozycja
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGold,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    '#$position',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Informacje
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      investor.client.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatCurrency(
                        investor.totalValue,
                        showDecimals: false,
                      ),
                      style: const TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${investor.investmentCount} inwestycji • ${percentage.toStringAsFixed(1)}% portfela',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Status ikona
              Icon(
                _getVotingStatusIcon(investor.client.votingStatus),
                color: _getVotingStatusColor(investor.client.votingStatus),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getVotingStatusIcon(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return Icons.check_circle;
      case VotingStatus.no:
        return Icons.cancel;
      case VotingStatus.abstain:
        return Icons.remove_circle;
      case VotingStatus.undecided:
        return Icons.help;
    }
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return AppTheme.successColor;
      case VotingStatus.no:
        return AppTheme.errorColor;
      case VotingStatus.abstain:
        return AppTheme.warningColor;
      case VotingStatus.undecided:
        return AppTheme.textSecondary;
    }
  }
}
