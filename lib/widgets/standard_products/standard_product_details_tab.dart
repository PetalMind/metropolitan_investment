import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';

/// Zakładka z szczegółami standardowego produktu
class StandardProductDetailsTab extends StatelessWidget {
  final Product product;
  final Function(bool) onLoading;
  final Function(String?) onError;

  const StandardProductDetailsTab({
    Key? key,
    required this.product,
    required this.onLoading,
    required this.onError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Podstawowe informacje
          _buildBasicInfoSection(context),

          const SizedBox(height: 32),

          // Szczegóły finansowe
          _buildFinancialDetailsSection(context),

          const SizedBox(height: 32),

          // Daty
          _buildDatesSection(context),

          const SizedBox(height: 32),

          // Dodatkowe informacje
          _buildAdditionalInfoSection(context),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Podstawowe informacje',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _buildInfoRow(
              context,
              'Nazwa produktu',
              product.name,
              Icons.label_outline,
              copyable: true,
            ),

            const SizedBox(height: 16),

            _buildInfoRow(
              context,
              'Typ produktu',
              product.type.displayName,
              _getProductTypeIcon(),
              color: _getProductTypeColor(),
            ),

            const SizedBox(height: 16),

            _buildInfoRow(
              context,
              'ID produktu',
              product.id,
              Icons.fingerprint,
              copyable: true,
            ),

            if (product.companyId.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                'ID spółki',
                product.companyId,
                Icons.business,
                copyable: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialDetailsSection(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Szczegóły finansowe',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (product.interestRate != null) ...[
              _buildInfoRow(
                context,
                'Oprocentowanie',
                '${product.interestRate!.toStringAsFixed(2)}%',
                Icons.percent,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
            ],

            if (product.sharePrice != null) ...[
              _buildInfoRow(
                context,
                'Cena jednostki',
                formatter.format(product.sharePrice!),
                Icons.monetization_on,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
            ],

            if (product.sharesCount != null) ...[
              _buildInfoRow(
                context,
                'Liczba jednostek',
                NumberFormat('#,##0', 'pl_PL').format(product.sharesCount!),
                Icons.format_list_numbered,
              ),
              const SizedBox(height: 16),
            ],

            if (product.sharePrice != null && product.sharesCount != null) ...[
              _buildInfoRow(
                context,
                'Wartość całkowita',
                formatter.format(product.sharePrice! * product.sharesCount!),
                Icons.account_balance,
                color: Colors.purple,
                highlighted: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDatesSection(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('dd.MM.yyyy');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Daty',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (product.issueDate != null) ...[
              _buildInfoRow(
                context,
                'Data emisji',
                dateFormatter.format(product.issueDate!),
                Icons.calendar_today,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
            ],

            if (product.maturityDate != null) ...[
              _buildInfoRow(
                context,
                'Data zapadalności',
                dateFormatter.format(product.maturityDate!),
                Icons.event_available,
                color: _getMaturityDateColor(),
              ),
              const SizedBox(height: 16),

              _buildInfoRow(
                context,
                'Pozostały czas',
                _getRemainingTimeText(),
                Icons.hourglass_empty,
                color: _getMaturityDateColor(),
                highlighted: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.more_horiz,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Dodatkowe informacje',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _buildStatusIndicator(context),

            const SizedBox(height: 16),

            _buildRiskLevelIndicator(context),

            const SizedBox(height: 16),

            _buildLiquidityIndicator(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
    bool copyable = false,
    bool highlighted = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(highlighted ? 16 : 0),
      decoration: highlighted
          ? BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            )
          : null,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color ?? theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: highlighted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontWeight: highlighted ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          if (copyable) ...[
            IconButton(
              onPressed: () => _copyToClipboard(context, value),
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Skopiuj',
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(
                  0.5,
                ),
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final isActive =
        product.maturityDate == null ||
        product.maturityDate!.isAfter(DateTime.now());

    return Row(
      children: [
        Icon(
          isActive ? Icons.check_circle : Icons.cancel,
          size: 20,
          color: isActive ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status produktu',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isActive ? 'Aktywny' : 'Nieaktywny',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRiskLevelIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final riskLevel = _getRiskLevel();
    final riskColor = _getRiskColor(riskLevel);

    return Row(
      children: [
        Icon(Icons.warning_outlined, size: 20, color: riskColor),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Poziom ryzyka',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                riskLevel,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: riskColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiquidityIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final liquidity = _getLiquidityLevel();
    final liquidityColor = _getLiquidityColor(liquidity);

    return Row(
      children: [
        Icon(Icons.water_drop_outlined, size: 20, color: liquidityColor),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Płynność',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                liquidity,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: liquidityColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getProductTypeIcon() {
    switch (product.type) {
      case ProductType.bonds:
        return Icons.account_balance;
      case ProductType.shares:
        return Icons.show_chart;
      case ProductType.loans:
        return Icons.monetization_on;
      case ProductType.apartments:
        return Icons.apartment;
    }
  }

  Color _getProductTypeColor() {
    switch (product.type) {
      case ProductType.bonds:
        return Colors.blue;
      case ProductType.shares:
        return Colors.green;
      case ProductType.loans:
        return Colors.orange;
      case ProductType.apartments:
        return Colors.purple;
    }
  }

  Color _getMaturityDateColor() {
    if (product.maturityDate == null) return Colors.grey;

    final now = DateTime.now();
    final daysUntilMaturity = product.maturityDate!.difference(now).inDays;

    if (daysUntilMaturity < 30) return Colors.red;
    if (daysUntilMaturity < 90) return Colors.orange;
    return Colors.green;
  }

  String _getRemainingTimeText() {
    if (product.maturityDate == null) return 'Brak daty zapadalności';

    final now = DateTime.now();
    final difference = product.maturityDate!.difference(now);

    if (difference.isNegative) {
      return 'Produkt przedawniony';
    }

    final days = difference.inDays;
    if (days < 30) {
      return '$days dni';
    } else if (days < 365) {
      final months = (days / 30).round();
      return '$months miesięcy';
    } else {
      final years = (days / 365).round();
      return '$years lat';
    }
  }

  String _getRiskLevel() {
    switch (product.type) {
      case ProductType.bonds:
        return 'Niskie';
      case ProductType.shares:
        return 'Wysokie';
      case ProductType.loans:
        return 'Średnie';
      case ProductType.apartments:
        return 'Średnie';
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'Niskie':
        return Colors.green;
      case 'Średnie':
        return Colors.orange;
      case 'Wysokie':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getLiquidityLevel() {
    switch (product.type) {
      case ProductType.bonds:
        return 'Wysoka';
      case ProductType.shares:
        return 'Wysoka';
      case ProductType.loans:
        return 'Niska';
      case ProductType.apartments:
        return 'Bardzo niska';
    }
  }

  Color _getLiquidityColor(String liquidity) {
    switch (liquidity) {
      case 'Bardzo niska':
        return Colors.red;
      case 'Niska':
        return Colors.orange;
      case 'Średnia':
        return Colors.amber;
      case 'Wysoka':
        return Colors.lightGreen;
      case 'Bardzo wysoka':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Skopiowano: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
