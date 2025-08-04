import 'package:flutter/material.dart';
import '../../../models_and_services.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/currency_formatter.dart';

/// Kafelek inwestora dla widoku siatki
class InvestorGridTile extends StatelessWidget {
  final InvestorSummary investor;
  final int position;
  final double totalPortfolioValue;
  final VoidCallback onTap;

  const InvestorGridTile({
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
            AppTheme.backgroundSecondary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryGold.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppTheme.borderSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pozycja i wartość
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$position',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Nazwa klienta
              Text(
                investor.client.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Wartość
              Text(
                CurrencyFormatter.formatCurrency(
                  investor.totalValue,
                  showDecimals: false,
                ),
                style: const TextStyle(
                  color: AppTheme.successColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Liczba inwestycji
              Text(
                '${investor.investmentCount} inwestycji',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),

              const Spacer(),

              // Status
              Row(
                children: [
                  Icon(
                    _getVotingStatusIcon(investor.client.votingStatus),
                    size: 14,
                    color: _getVotingStatusColor(investor.client.votingStatus),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _getVotingStatusText(investor.client.votingStatus),
                      style: TextStyle(
                        color: _getVotingStatusColor(
                          investor.client.votingStatus,
                        ),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getVotingStatusText(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return 'Za';
      case VotingStatus.no:
        return 'Przeciw';
      case VotingStatus.abstain:
        return 'Wstrzymuje się';
      case VotingStatus.undecided:
        return 'Niezdecydowany';
    }
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
