import 'package:flutter/material.dart';
import '../../../models_and_services.dart';

/// Karta inwestora - główny komponent wyświetlający dane inwestora
class InvestorCard extends StatelessWidget {
  final InvestorSummary investor;
  final int position;
  final double totalPortfolioValue;
  final VoidCallback onTap;

  const InvestorCard({
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

    Color cardColor = AppTheme.primaryAccent;
    try {
      cardColor = Color(
        int.parse('0xFF${investor.client.colorCode.replaceAll('#', '')}'),
      );
    } catch (e) {
      cardColor = AppTheme.primaryAccent;
    }

    final companies = investor.investments
        .map((inv) => inv.productName)
        .toSet()
        .take(3)
        .toList();

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (position * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.surfaceCard, AppTheme.backgroundSecondary],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardColor.withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: cardColor.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildPositionBadge(position, cardColor),
                              const SizedBox(width: 16),
                              Expanded(child: _buildInvestorInfo(companies)),
                              _buildValueSection(percentage),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildStatsRow(),
                          const SizedBox(height: 16),
                          _buildTagsSection(),
                          if (investor.client.notes.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildNotesCard(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPositionBadge(int position, Color cardColor) {
    // Użyj bezpiecznego koloru tła i tekstu dla lepszego kontrastu
    Color safeBackgroundColor = AppTheme.secondaryGold;
    Color textColor = Colors.white;

    // Jeśli cardColor jest zbyt jasny, użyj ciemniejszego tła
    if (cardColor.computeLuminance() > 0.5) {
      safeBackgroundColor = AppTheme.primaryColor;
    } else {
      safeBackgroundColor = cardColor;
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [safeBackgroundColor, safeBackgroundColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: safeBackgroundColor.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Center(
        child: Text(
          '#$position',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvestorInfo(List<String> companies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          investor.client.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 18,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (investor.client.companyName?.isNotEmpty ?? false) ...[
          const SizedBox(height: 4),
          Text(
            investor.client.companyName!,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (companies.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.secondaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.secondaryGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.business_rounded,
                  size: 16,
                  color: AppTheme.secondaryGold,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    companies.join(', ') +
                        (investor.investments.length > 3
                            ? ' (+${investor.investments.length - 3})'
                            : ''),
                    style: const TextStyle(
                      color: AppTheme.secondaryGold,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildValueSection(double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.successColor,
                AppTheme.successColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppTheme.successColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            CurrencyFormatter.formatCurrency(
              investor.totalValue,
              showDecimals: false,
            ),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.infoColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppTheme.infoColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '${percentage.toStringAsFixed(1)}% portfela',
            style: const TextStyle(
              color: AppTheme.infoColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        if (investor.totalRemainingCapital > 0) ...[
          Expanded(
            child: _buildStatCard(
              'Kapitał',
              CurrencyFormatter.formatCurrencyShort(
                investor.totalRemainingCapital,
              ),
              Icons.monetization_on_rounded,
              AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (investor.totalSharesValue > 0) ...[
          Expanded(
            child: _buildStatCard(
              'Udziały',
              CurrencyFormatter.formatCurrencyShort(investor.totalSharesValue),
              Icons.pie_chart_rounded,
              AppTheme.warningColor,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: _buildStatCard(
            'Inwestycje',
            '${investor.investmentCount}',
            Icons.account_balance_wallet_rounded,
            AppTheme.secondaryGold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _buildModernStatusChip(
          _getVotingStatusText(investor.client.votingStatus),
          _getVotingStatusIcon(investor.client.votingStatus),
          _getVotingStatusColor(investor.client.votingStatus),
        ),
        _buildModernStatusChip(
          investor.client.type.displayName,
          Icons.person_rounded,
          AppTheme.textSecondary,
        ),
        if (investor.hasUnviableInvestments)
          _buildModernStatusChip(
            'Niewykonalne',
            Icons.warning_rounded,
            AppTheme.errorColor,
          ),
        if (investor.client.email.isNotEmpty)
          _buildModernStatusChip(
            'Email',
            Icons.email_rounded,
            AppTheme.infoColor,
          ),
      ],
    );
  }

  Widget _buildModernStatusChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.backgroundSecondary, AppTheme.surfaceCard],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.secondaryGold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.note_rounded,
              size: 18,
              color: AppTheme.secondaryGold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              investor.client.notes,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
