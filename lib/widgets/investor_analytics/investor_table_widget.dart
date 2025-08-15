import 'package:flutter/material.dart';
import '../../models_and_services.dart';

/// 📊 Professional Investor Table Widget
///
/// Displays investors in a comprehensive table format with all financial details
/// visible simultaneously. Features responsive design for tablet/desktop.
class InvestorTableWidget extends StatelessWidget {
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

  const InvestorTableWidget({
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

    return Container(
      margin: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: AppTheme.premiumCardDecoration,
      child: Column(
        children: [
          _buildTableHeader(),
          ...investors.asMap().entries.map(
            (entry) => _buildTableRow(entry.value, entry.key),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: EdgeInsets.all(isTablet ? 16 : 12),
      padding: const EdgeInsets.all(40),
      decoration: AppTheme.premiumCardDecoration,
      child: Center(
        child: Column(
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

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('#', style: _getTableHeaderStyle())),
          Expanded(
            flex: 3,
            child: Text('Inwestor', style: _getTableHeaderStyle()),
          ),
          Expanded(
            flex: 2,
            child: Text('Status', style: _getTableHeaderStyle()),
          ),
          Expanded(
            flex: 2,
            child: Text('Kapitał pozostały', style: _getTableHeaderStyle()),
          ),
          // ✅ ZAWSZE POKAZUJ WSZYSTKIE 3 KOLUMNY NA TABLET
          if (isTablet) ...[
            Expanded(
              flex: 2,
              child: Text('Kwota inwestycji', style: _getTableHeaderStyle()),
            ),
            Expanded(
              flex: 2,
              child: Text('Do restrukturyzacji', style: _getTableHeaderStyle()),
            ),
            Expanded(
              flex: 2,
              child: Text('Zabezp. nieruch.', style: _getTableHeaderStyle()),
            ),
          ] else ...[
            // Mobile - pokazuj skrócone wersje
            Expanded(
              flex: 1,
              child: Text('Kwota\ninwest.', style: _getTableHeaderStyle()),
            ),
            Expanded(
              flex: 1,
              child: Text('Restruk.', style: _getTableHeaderStyle()),
            ),
            Expanded(
              flex: 1,
              child: Text('Zabezp.', style: _getTableHeaderStyle()),
            ),
          ],
          Expanded(
            flex: 1,
            child: Text('Udział', style: _getTableHeaderStyle()),
          ),
          Expanded(
            flex: 1,
            child: Text('Liczba\ninwest.', style: _getTableHeaderStyle()),
          ),
          if (isTablet) ...[
            SizedBox(
              width: 48,
              child: Text('Akcje', style: _getTableHeaderStyle()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableRow(InvestorSummary investor, int index) {
    final votingStatusColor = _getVotingStatusColor(
      investor.client.votingStatus,
    );
    final capitalPercentage = totalViableCapital > 0
        ? (investor.viableRemainingCapital / totalViableCapital) * 100
        : 0.0;
    final isMajorityHolder = majorityHolders.contains(investor);
    final isSelected = selectedInvestorIds.contains(investor.client.id);

    return InkWell(
      onTap: () {
        if (isSelectionMode) {
          onInvestorSelectionToggle(investor.client.id);
        } else {
          onInvestorTap(investor);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMajorityHolder
              ? AppTheme.secondaryGold.withOpacity(0.05)
              : isSelectionMode && isSelected
                  ? AppTheme.primaryAccent.withOpacity(0.1)
                  : AppTheme.backgroundSecondary,
          border: Border(
            bottom: BorderSide(color: AppTheme.borderSecondary, width: 0.5),
            left: isSelectionMode && isSelected 
                ? BorderSide(color: AppTheme.primaryAccent, width: 3)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            // Selection checkbox or position number
            SizedBox(
              width: 30,
              child: isSelectionMode
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (value) => onInvestorSelectionToggle(investor.client.id),
                      activeColor: AppTheme.primaryAccent,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: votingStatusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: votingStatusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: votingStatusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),

            // Investor Name & Type
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investor.client.name,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: isTablet ? 13 : 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          investor.client.type.displayName,
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: isTablet ? 11 : 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isMajorityHolder) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.star_rounded,
                      color: AppTheme.secondaryGold,
                      size: 14,
                    ),
                  ],
                ],
              ),
            ),

            // Voting Status
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: votingStatusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: votingStatusColor.withOpacity(0.3)),
                ),
                child: Text(
                  investor.client.votingStatus.displayName,
                  style: TextStyle(
                    color: votingStatusColor,
                    fontSize: isTablet ? 10 : 9,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Remaining Capital
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyFormatter.formatCurrencyShort(
                      investor.viableRemainingCapital,
                    ),
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 12 : 11,
                    ),
                  ),
                  Text(
                    '${capitalPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: isTablet ? 10 : 9,
                    ),
                  ),
                ],
              ),
            ),

            // ✅ ZAWSZE POKAŻ WSZYSTKIE 3 NOWE KOLUMNY
            // Investment Amount
            Expanded(
              flex: isTablet ? 2 : 1,
              child: Text(
                CurrencyFormatter.formatCurrencyShort(
                  investor.totalInvestmentAmount,
                ),
                style: TextStyle(
                  color: AppTheme.infoPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: isTablet ? 11 : 9,
                ),
              ),
            ),

            // Capital for Restructuring
            Expanded(
              flex: isTablet ? 2 : 1,
              child: Text(
                CurrencyFormatter.formatCurrencyShort(
                  investor.capitalForRestructuring,
                ),
                style: TextStyle(
                  color: AppTheme.warningPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: isTablet ? 11 : 9,
                ),
              ),
            ),

            // Capital Secured by Real Estate
            Expanded(
              flex: isTablet ? 2 : 1,
              child: Text(
                CurrencyFormatter.formatCurrencyShort(
                  investor.capitalSecuredByRealEstate,
                ),
                style: TextStyle(
                  color: AppTheme.successPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: isTablet ? 11 : 9,
                ),
              ),
            ),

            // Share Percentage
            Expanded(
              flex: 1,
              child: Text(
                '${capitalPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isMajorityHolder
                      ? AppTheme.secondaryGold
                      : AppTheme.textSecondary,
                  fontWeight: isMajorityHolder
                      ? FontWeight.w600
                      : FontWeight.w500,
                  fontSize: isTablet ? 11 : 9,
                ),
              ),
            ),

            // Investment Count
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${investor.investmentCount}',
                  style: TextStyle(
                    color: AppTheme.primaryAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 11 : 9,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Actions Menu (Tablet only)
            if (isTablet) ...[
              SizedBox(
                width: 48,
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 16),
                  color: AppTheme.backgroundModal,
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppTheme.infoPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text('Szczegóły'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(
                            Icons.share,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text('Udostępnij'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'details':
                        onInvestorTap(investor);
                        break;
                      case 'export':
                        onExportInvestor(investor);
                        break;
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  TextStyle _getTableHeaderStyle() {
    return TextStyle(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w700,
      fontSize: isTablet ? 13 : 11,
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
