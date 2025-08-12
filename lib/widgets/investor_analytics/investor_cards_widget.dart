import 'package:flutter/material.dart';
import '../../models_and_services.dart';

/// 🎴 Professional Investor Cards Widget
///
/// Displays investors in a card grid layout with comprehensive financial details
/// shown directly on each card. Perfect for visual overview.
class InvestorCardsWidget extends StatelessWidget {
  final List<InvestorSummary> investors;
  final List<InvestorSummary> majorityHolders;
  final double totalViableCapital;
  final bool isTablet;
  final Function(InvestorSummary) onInvestorTap;

  const InvestorCardsWidget({
    super.key,
    required this.investors,
    required this.majorityHolders,
    required this.totalViableCapital,
    required this.isTablet,
    required this.onInvestorTap,
  });

  @override
  Widget build(BuildContext context) {
    if (investors.isEmpty) {
      return _buildEmptyState();
    }

    return SliverPadding(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 2 : 1,
          childAspectRatio: isTablet ? 1.4 : 1.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildInvestorCard(investors[index], index),
          childCount: investors.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Brak inwestorów',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Spróbuj zmienić filtry wyszukiwania',
              style: TextStyle(color: AppTheme.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestorCard(InvestorSummary investor, int index) {
    final votingStatusColor = _getVotingStatusColor(
      investor.client.votingStatus,
    );
    final capitalPercentage = totalViableCapital > 0
        ? (investor.viableRemainingCapital / totalViableCapital) * 100
        : 0.0;
    final isMajorityHolder = majorityHolders.contains(investor);

    return Card(
      elevation: isMajorityHolder ? 4 : 2,
      child: InkWell(
        onTap: () => onInvestorTap(investor),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isMajorityHolder
                ? LinearGradient(
                    colors: [
                      AppTheme.secondaryGold.withOpacity(0.05),
                      AppTheme.secondaryGold.withOpacity(0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            border: isMajorityHolder
                ? Border.all(color: AppTheme.secondaryGold.withOpacity(0.3))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with position and name
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: votingStatusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: votingStatusColor.withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: votingStatusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                investor.client.name,
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isTablet ? 15 : 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isMajorityHolder) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.star_rounded,
                                color: AppTheme.secondaryGold,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          investor.client.type.displayName,
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: isTablet ? 12 : 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Voting status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: votingStatusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: votingStatusColor.withOpacity(0.3)),
                ),
                child: Text(
                  investor.client.votingStatus.displayName,
                  style: TextStyle(
                    color: votingStatusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ✅ FINANCIAL METRICS GRID - WSZYSTKIE 4 WIDOCZNE
              Expanded(child: _buildFinancialMetricsGrid(investor)),

              const SizedBox(height: 8),

              // Share and investment count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${investor.investmentCount} inwestycji',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isMajorityHolder
                          ? AppTheme.secondaryGold.withOpacity(0.2)
                          : AppTheme.primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${capitalPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isMajorityHolder
                            ? AppTheme.secondaryGold
                            : AppTheme.primaryAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildFinancialMetricsGrid(InvestorSummary investor) {
    final metrics = [
      _FinancialMetric(
        'Kapitał pozostały',
        CurrencyFormatter.formatCurrencyShort(investor.viableRemainingCapital),
        AppTheme.secondaryGold,
        Icons.account_balance_wallet_rounded,
      ),
      _FinancialMetric(
        'Kwota inwestycji',
        CurrencyFormatter.formatCurrencyShort(investor.totalInvestmentAmount),
        AppTheme.infoPrimary,
        Icons.trending_up_rounded,
      ),
      _FinancialMetric(
        'Do restrukturyzacji',
        CurrencyFormatter.formatCurrencyShort(investor.capitalForRestructuring),
        AppTheme.warningPrimary,
        Icons.build_rounded,
      ),
      _FinancialMetric(
        'Zabezp. nieruch.',
        CurrencyFormatter.formatCurrencyShort(
          investor.capitalSecuredByRealEstate,
        ),
        AppTheme.successPrimary,
        Icons.home_rounded,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: isTablet ? 2.5 : 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) => _buildMetricCard(metrics[index]),
    );
  }

  Widget _buildMetricCard(_FinancialMetric metric) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: metric.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: metric.color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(metric.icon, color: metric.color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  metric.label,
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            metric.value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: isTablet ? 13 : 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return AppTheme.successPrimary;
      case VotingStatus.no:
        return AppTheme.errorPrimary;
      case VotingStatus.abstain:
        return AppTheme.warningPrimary;
      case VotingStatus.undecided:
        return AppTheme.neutralPrimary;
    }
  }
}

/// Helper class for financial metrics
class _FinancialMetric {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  _FinancialMetric(this.label, this.value, this.color, this.icon);
}
