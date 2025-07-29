import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/investment.dart';
import '../theme/app_theme.dart';
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
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.getProductTypeColor(
                investment.productType.name,
              ).withOpacity(0.3),
              width: 2,
            ),
          ),
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
                      color: AppTheme.getProductTypeColor(
                        investment.productType.name,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      investment.productType.displayName,
                      style: TextStyle(
                        color: AppTheme.getProductTypeColor(
                          investment.productType.name,
                        ),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
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
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Edytuj'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Usuń', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert, size: 16),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Client name
              Text(
                investment.clientName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Product name
              Text(
                investment.productName,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Investment amount
              Text(
                _formatCurrency(investment.investmentAmount),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.primaryColor,
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
                      color: AppTheme.getStatusColor(investment.status.name),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    investment.status.displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.getStatusColor(investment.status.name),
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
                    color: AppTheme.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(investment.signedDate),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.textHint),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(Icons.person, size: 12, color: AppTheme.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      investment.employeeFullName,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.textHint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Progress indicator for profit/loss
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  widthFactor:
                      (investment.totalRealized / investment.investmentAmount)
                          .clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: investment.profitLoss >= 0
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.textHint),
                  ),
                  Text(
                    '${investment.profitLossPercentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: investment.profitLoss >= 0
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
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
