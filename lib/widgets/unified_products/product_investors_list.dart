import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../models/investor_summary.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';

/// Widget do wyświetlania listy inwestorów produktu
class ProductInvestorsList extends StatelessWidget {
  final List<InvestorSummary> investors;
  final bool isLoading;
  final String? errorMessage;

  const ProductInvestorsList({
    super.key,
    required this.investors,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState(context);
    }

    if (errorMessage != null) {
      return _buildErrorState(context);
    }

    if (investors.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildInvestorsList(context);
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Ładowanie inwestorów...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              'Błąd ładowania danych',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppTheme.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Brak inwestorów',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ten produkt nie ma jeszcze żadnych inwestorów.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestorsList(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nagłówek z podsumowaniem
        _buildSummaryHeader(context),

        const SizedBox(height: 16),

        // Lista inwestorów
        Expanded(
          child: ListView.builder(
            itemCount: investors.length,
            itemBuilder: (context, index) {
              final investor = investors[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildInvestorCard(context, investor, isMobile),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(BuildContext context) {
    final totalValue = investors.fold<double>(
      0.0,
      (sum, investor) => sum + investor.totalValue,
    );

    final activeInvestors = investors
        .where((investor) => investor.client.isActive)
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryAccent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              context,
              'Inwestorzy',
              '${investors.length}',
              Icons.people,
              AppTheme.primaryAccent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryItem(
              context,
              'Aktywni',
              '$activeInvestors',
              Icons.check_circle,
              AppTheme.successColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildSummaryItem(
              context,
              'Łączna wartość',
              CurrencyFormatter.formatCurrency(totalValue),
              Icons.account_balance_wallet,
              AppTheme.secondaryGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvestorCard(
    BuildContext context,
    InvestorSummary investor,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.elevatedSurfaceDecoration,
      child: isMobile
          ? _buildMobileLayout(context, investor)
          : _buildDesktopLayout(context, investor),
    );
  }

  Widget _buildMobileLayout(BuildContext context, InvestorSummary investor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nazwa i status
        Row(
          children: [
            Expanded(
              child: Text(
                investor.client.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _buildStatusBadge(investor.client.isActive),
          ],
        ),

        const SizedBox(height: 8),

        // Wartość inwestycji
        Text(
          CurrencyFormatter.formatCurrency(investor.totalValue),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.secondaryGold,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        // Detale
        Row(
          children: [
            Icon(Icons.business_center, size: 14, color: AppTheme.textTertiary),
            const SizedBox(width: 4),
            Text(
              '${investor.investments.length} inwestycji',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
            if (investor.client.email.isNotEmpty) ...[
              const SizedBox(width: 16),
              Icon(Icons.email, size: 14, color: AppTheme.textTertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  investor.client.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, InvestorSummary investor) {
    return Row(
      children: [
        // Nazwa i status
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      investor.client.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildStatusBadge(investor.client.isActive),
                ],
              ),
              if (investor.client.email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  investor.client.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Wartość inwestycji
        Expanded(
          flex: 2,
          child: Text(
            CurrencyFormatter.formatCurrency(investor.totalValue),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.secondaryGold,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.right,
          ),
        ),

        const SizedBox(width: 16),

        // Liczba inwestycji
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.business_center,
                size: 16,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                '${investor.investments.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    final color = isActive ? AppTheme.successColor : AppTheme.errorColor;
    final text = isActive ? 'Aktywny' : 'Nieaktywny';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
