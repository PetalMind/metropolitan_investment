import 'package:flutter/material.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';

class InvestorsListWidget extends StatelessWidget {
  final List<InvestorSummary> investors;
  final List<InvestorSummary> majorityHolders;
  final double totalViableCapital;
  final bool isTablet;
  final Function(InvestorSummary) onInvestorTap;
  final bool isSelectionMode;
  final Set<String> selectedInvestorIds;
  final Function(String) onInvestorSelectionToggle;

  const InvestorsListWidget({
    super.key,
    required this.investors,
    required this.majorityHolders,
    required this.totalViableCapital,
    required this.isTablet,
    required this.onInvestorTap,
    this.isSelectionMode = false,
    this.selectedInvestorIds = const <String>{},
    required this.onInvestorSelectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (investors.isEmpty) {
      return _buildEmptyState(context);
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(isTablet ? 16 : 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppThemePro.surfaceCard,
              AppThemePro.backgroundSecondary,
              AppThemePro.surfaceCard.withValues(alpha: 0.9),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppThemePro.accentGold.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppThemePro.accentGold.withValues(alpha: 0.1),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const Divider(color: AppThemePro.borderSecondary, height: 1),
            _buildInvestorsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppThemePro.accentGold,
                  AppThemePro.accentGoldMuted,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppThemePro.accentGold.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.people_rounded,
              color: AppThemePro.primaryDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lista inwestorów',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                Text(
                  '${investors.length} inwestorów',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemePro.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildInvestorsList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: investors.length,
      separatorBuilder: (context, index) => const Divider(
        color: AppThemePro.borderSecondary,
        height: 1,
        indent: 20,
        endIndent: 20,
      ),
      itemBuilder: (context, index) => _buildInvestorTile(
        context,
        investors[index],
        index,
      ),
    );
  }

  Widget _buildInvestorTile(
    BuildContext context, 
    InvestorSummary investor, 
    int index,
  ) {
    final isSelected = selectedInvestorIds.contains(investor.client.id);
    final votingStatusColor = _getVotingStatusColor(investor.client.votingStatus);
    final isMajorityHolder = majorityHolders.any(
      (holder) => holder.client.id == investor.client.id,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSelectionMode
            ? () => onInvestorSelectionToggle(investor.client.id)
            : () => onInvestorTap(investor),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: isSelected
              ? BoxDecoration(
                  color: AppThemePro.accentGold.withValues(alpha: 0.1),
                  border: Border(
                    left: BorderSide(
                      color: AppThemePro.accentGold,
                      width: 4,
                    ),
                  ),
                )
              : null,
          child: Row(
            children: [
              // Selection checkbox
              if (isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onInvestorSelectionToggle(investor.client.id),
                  activeColor: AppThemePro.accentGold,
                ),
                const SizedBox(width: 12),
              ],

              // Investor avatar and basic info
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            votingStatusColor.withValues(alpha: 0.2),
                            votingStatusColor.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: votingStatusColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              _getVotingStatusIcon(investor.client.votingStatus),
                              color: votingStatusColor,
                              size: 20,
                            ),
                          ),
                          if (isMajorityHolder)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppThemePro.accentGold,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppThemePro.backgroundSecondary,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.star_rounded,
                                  color: AppThemePro.primaryDark,
                                  size: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            investor.client.name,
                            style: TextStyle(
                              color: AppThemePro.textPrimary,
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildEnhancedVotingStatusBadge(
                                investor.client.votingStatus,
                                votingStatusColor,
                              ),
                              _buildClientTypeBadge(investor.client.type),
                              _buildPortfolioBadge(investor),
                              _buildInvestmentCountBadge(investor),
                              if (isMajorityHolder)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppThemePro.accentGold.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppThemePro.accentGold.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'WIĘKSZOŚĆ',
                                    style: TextStyle(
                                      color: AppThemePro.accentGold,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Financial metrics
              if (isTablet) ...[
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: _buildFinancialMetricsRow(investor),
                ),
              ],

              // Action button
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppThemePro.backgroundTertiary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppThemePro.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedVotingStatusBadge(VotingStatus status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 2,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _getVotingStatusText(status),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientTypeBadge(ClientType? type) {
    final text = _getClientTypeText(type);
    final color = AppThemePro.textSecondary;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_rounded,
            color: color,
            size: 10,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioBadge(InvestorSummary investor) {
    final portfolioPercentage = totalViableCapital > 0 
        ? (investor.totalRemainingCapital / totalViableCapital * 100)
        : 0.0;
    final color = AppThemePro.accentGold;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pie_chart_rounded,
            color: color,
            size: 10,
          ),
          const SizedBox(width: 4),
          Text(
            '${portfolioPercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentCountBadge(InvestorSummary investor) {
    final color = AppThemePro.bondsBlue;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.format_list_numbered_rounded,
            color: color,
            size: 10,
          ),
          const SizedBox(width: 4),
          Text(
            '${investor.investmentCount}',
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetricsRow(InvestorSummary investor) {

    return Row(
      children: [
        Expanded(
          child: _buildMetricColumn(
            'Kapitał pozostały',
            _formatCurrency(investor.totalRemainingCapital),
            AppThemePro.statusSuccess,
            Icons.trending_up_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricColumn(
            'Suma inwestycji',
            _formatCurrency(investor.totalInvestmentAmount),
            AppThemePro.statusInfo,
            Icons.account_balance_wallet_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricColumn(
            'Restrukturyzacja',
            _formatCurrency(investor.capitalForRestructuring),
            AppThemePro.statusWarning,
            Icons.build_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricColumn(
            'Zabezpiecz. nieruch.',
            _formatCurrency(investor.capitalSecuredByRealEstate),
            AppThemePro.realEstateViolet,
            Icons.home_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricColumn(String label, String value, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppThemePro.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppThemePro.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(isTablet ? 16 : 12),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppThemePro.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppThemePro.borderSecondary,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: AppThemePro.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Brak inwestorów',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppThemePro.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nie znaleziono inwestorów spełniających wybrane kryteria.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getVotingStatusText(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return 'TAK';
      case VotingStatus.no:
        return 'NIE';
      case VotingStatus.abstain:
        return 'WSTRZ.';
      case VotingStatus.undecided:
        return 'NIEZDEC.';
    }
  }

  IconData _getVotingStatusIcon(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return Icons.check_circle_rounded;
      case VotingStatus.no:
        return Icons.cancel_rounded;
      case VotingStatus.abstain:
        return Icons.remove_circle_rounded;
      case VotingStatus.undecided:
        return Icons.help_rounded;
    }
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return AppThemePro.statusSuccess;
      case VotingStatus.no:
        return AppThemePro.statusError;
      case VotingStatus.abstain:
        return AppThemePro.statusWarning;
      case VotingStatus.undecided:
        return AppThemePro.textMuted;
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M zł';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k zł';
    } else {
      return '${amount.toStringAsFixed(0)} zł';
    }
  }

  String _getClientTypeText(ClientType? type) {
    if (type == null) return 'Brak';
    
    switch (type) {
      case ClientType.individual:
        return 'Osoba fiz.';
      case ClientType.marriage:
        return 'Małżeństwo';
      case ClientType.company:
        return 'Spółka';
      case ClientType.other:
        return 'Inne';
    }
  }
}