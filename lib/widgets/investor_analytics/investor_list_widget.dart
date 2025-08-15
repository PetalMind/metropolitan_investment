import 'package:flutter/material.dart';
import '../../models_and_services.dart';

/// 📱 Professional Investor List Widget
///
/// Displays investors in expandable cards with detailed financial information
/// in a grid layout. Optimized for mobile and tablet views.
class InvestorListWidget extends StatelessWidget {
  final List<InvestorSummary> investors;
  final List<InvestorSummary> majorityHolders;
  final double totalViableCapital;
  final bool isTablet;
  final Function(InvestorSummary) onInvestorTap;
  final Function(InvestorSummary) onExportInvestor;
  
  // Multi-selection parameters
  final bool isSelectionMode;
  final Set<String> selectedInvestorIds;
  final Function(String) onInvestorSelectionToggle;

  const InvestorListWidget({
    super.key,
    required this.investors,
    required this.majorityHolders,
    required this.totalViableCapital,
    required this.isTablet,
    required this.onInvestorTap,
    required this.onExportInvestor,
    this.isSelectionMode = false,
    this.selectedInvestorIds = const <String>{},
    required this.onInvestorSelectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (investors.isEmpty) {
      return _buildEmptyState();
    }

    return SliverPadding(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildInvestorListItem(investors[index], index),
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

  Widget _buildInvestorListItem(InvestorSummary investor, int index) {
    final votingStatusColor = _getVotingStatusColor(
      investor.client.votingStatus,
    );
    final capitalPercentage = totalViableCapital > 0
        ? (investor.viableRemainingCapital / totalViableCapital) * 100
        : 0.0;
    final isMajorityHolder = majorityHolders.contains(investor);
    final isSelected = selectedInvestorIds.contains(investor.client.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelectionMode && isSelected 
          ? AppTheme.primaryAccent.withOpacity(0.1) 
          : null,
      child: InkWell(
        onTap: () {
          if (isSelectionMode) {
            onInvestorSelectionToggle(investor.client.id);
          } else {
            onInvestorTap(investor);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with checkbox/number, name, and majority star
              Row(
                children: [
                  // Selection checkbox or position number
                  if (isSelectionMode)
                    Container(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (value) => onInvestorSelectionToggle(investor.client.id),
                          activeColor: AppTheme.primaryAccent,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: votingStatusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
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
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investor.client.name,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          investor.client.votingStatus.displayName,
                          style: TextStyle(
                            color: votingStatusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${investor.investmentCount} inwestycji • ${investor.client.type.displayName}',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isMajorityHolder) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.star_rounded,
                      color: AppTheme.secondaryGold,
                      size: 20,
                    ),
                  ],
                  if (isSelectionMode && isSelected) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryAccent,
                      size: 20,
                    ),
                  ],
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Text(
                        '${capitalPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: AppTheme.secondaryGold,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'portfela',
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ✅ WSZYSTKIE 4 KWOTY WIDOCZNE OD RAZU
              InvestorFinancialDetailsGrid(
                investor: investor,
                isTablet: isTablet,
              ),
            ],
          ),
        ),
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

/// 💰 Financial Details Grid Component
///
/// Displays all 4 key financial metrics in a responsive grid layout
class InvestorFinancialDetailsGrid extends StatelessWidget {
  final InvestorSummary investor;
  final bool isTablet;

  const InvestorFinancialDetailsGrid({
    super.key,
    required this.investor,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final financialDetails = _getFinancialDetails();

    // 🎯 MINIMALISTYCZNY GRID - 4 kolumny w rzędzie
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: financialDetails
            .map(
              (detail) => Expanded(child: _buildMinimalFinancialCard(detail)),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMinimalFinancialCard(_FinancialDetail detail) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderSecondary.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 💰 KWOTA - główny akcent
          Text(
            _formatCurrencyCompact(detail.rawValue),
            style: TextStyle(
              color: detail.color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),

          const SizedBox(height: 2),

          // 🏷️ OPIS - subtelny, krótki
          Text(
            _getShortLabel(detail.label),
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 9,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 🎯 Skrócone, bardziej zwięzłe kwoty
  String _formatCurrencyCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M zł';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K zł';
    } else if (value > 0) {
      return '${value.toStringAsFixed(0)} zł';
    } else {
      return '0 zł';
    }
  } // 🏷️ Krótkie, czytelne opisy

  String _getShortLabel(String fullLabel) {
    switch (fullLabel) {
      case 'Kapitał pozostały':
        return 'Pozostały';
      case 'Kwota inwestycji':
        return 'Inwestycja';
      case 'Kapitał do restrukturyzacji':
        return 'Restruktur.';
      case 'Kapitał zabezpieczony nieruchomościami':
        return 'Zabezpiecz.';
      default:
        return fullLabel;
    }
  }

  List<_FinancialDetail> _getFinancialDetails() {
    return [
      _FinancialDetail(
        'Kapitał pozostały',
        CurrencyFormatter.formatCurrency(investor.viableRemainingCapital),
        investor.viableRemainingCapital,
        Icons.account_balance_wallet_rounded,
        AppTheme.secondaryGold,
      ),
      _FinancialDetail(
        'Kwota inwestycji',
        CurrencyFormatter.formatCurrency(investor.totalInvestmentAmount),
        investor.totalInvestmentAmount,
        Icons.trending_up_rounded,
        AppTheme.infoPrimary,
      ),
      _FinancialDetail(
        'Kapitał do restrukturyzacji',
        CurrencyFormatter.formatCurrency(investor.capitalForRestructuring),
        investor.capitalForRestructuring,
        Icons.build_rounded,
        AppTheme.warningPrimary,
      ),
      _FinancialDetail(
        'Zabezpieczony nieruchomościami',
        CurrencyFormatter.formatCurrency(investor.capitalSecuredByRealEstate),
        investor.capitalSecuredByRealEstate,
        Icons.home_rounded,
        AppTheme.successPrimary,
      ),
    ];
  }
}

/// 💰 Financial Detail Data Class
class _FinancialDetail {
  final String label;
  final String value;
  final double rawValue; // Surowa wartość liczbowa
  final IconData icon;
  final Color color;

  _FinancialDetail(
    this.label,
    this.value,
    this.rawValue,
    this.icon,
    this.color,
  );
}
