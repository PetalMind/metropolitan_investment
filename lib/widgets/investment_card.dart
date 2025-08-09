import 'package:flutter/material.dart';
import '../models/investment.dart';
import '../theme/app_theme_professional.dart';
import '../utils/currency_formatter.dart';

class InvestmentCard extends StatelessWidget {
  final Investment investment;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const InvestmentCard({
    super.key,
    required this.investment,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppThemePro.premiumCardDecoration.copyWith(
        border: Border.all(
          color: AppThemePro.getInvestmentTypeColor(
            investment.productType.name,
          ).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppThemePro.getInvestmentTypeColor(
                        investment.productType.name,
                      ).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      investment.productType.displayName,
                      style: TextStyle(
                        color: AppThemePro.getInvestmentTypeColor(
                          investment.productType.name,
                        ),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    iconColor: AppThemePro.textSecondary,
                    color: AppThemePro.surfaceCard,
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 16,
                              color: AppThemePro.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Edytuj',
                              style: TextStyle(color: AppThemePro.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 16,
                              color: AppThemePro.statusError,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Usuń',
                              style: TextStyle(color: AppThemePro.statusError),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      size: 16,
                      color: AppThemePro.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Client name
              Text(
                investment.clientName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppThemePro.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Product name
              Text(
                investment.productName,
                style: TextStyle(
                  fontSize: 14,
                  color: AppThemePro.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // ⭐ Kapitał pozostały (nie kwota pierwotnej inwestycji)
              Text(
                _formatCurrency(investment.remainingCapital),
                style: TextStyle(
                  fontSize: 20,
                  color: AppThemePro.accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Status
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppThemePro.getStatusColor(investment.status.name),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    investment.status.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppThemePro.getStatusColor(investment.status.name),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Date and employee
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: AppThemePro.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(investment.signedDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppThemePro.textMuted,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(Icons.person, size: 12, color: AppThemePro.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      investment.employeeFullName,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppThemePro.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress indicator for profit/loss
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppThemePro.surfaceInteractive,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  widthFactor:
                      (investment.totalRealized / investment.investmentAmount)
                          .clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: investment.profitLoss >= 0
                          ? AppThemePro.profitGreen
                          : AppThemePro.lossRed,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Profit/Loss percentage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Zwrot',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppThemePro.textMuted,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatPercentage(
                      investment.profitLossPercentage,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: investment.profitLoss >= 0
                          ? AppThemePro.profitGreen
                          : AppThemePro.lossRed,
                      fontWeight: FontWeight.w600,
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

  String _formatCurrency(double amount) {
    return CurrencyFormatter.formatCurrency(amount, showDecimals: false);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
