import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/client.dart';
import '../models/investor_summary.dart';
import '../utils/currency_formatter.dart';

/// 🎨 REUŻYWALNE WIDGETY DLA INVESTOR ANALYTICS
/// Zawiera wszystkie powtarzalne komponenty UI

class InvestorWidgets {
  /// Karta statystyk głosowania
  static Widget buildVotingStatCard(
    String title,
    double amount,
    double percentage,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatCurrencyShort(amount),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Nowoczesny chip statusu
  static Widget buildModernStatusChip(
    String label,
    IconData icon,
    Color color,
  ) {
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
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Karta statystyk
  static Widget buildStatCard(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Element szybkich statystyk
  static Widget buildQuickStatItem(String value, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.secondaryGold, size: 16),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  /// Badge pozycji
  static Widget buildPositionBadge(int position, Color cardColor) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, cardColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '#$position',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  /// Sekcja informacji o inwestorze
  static Widget buildInvestorInfo(
    InvestorSummary investor,
    List<String> companies,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          investor.client.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (investor.client.companyName?.isNotEmpty ?? false) ...[
          const SizedBox(height: 4),
          Text(
            investor.client.companyName!,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (companies.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            companies.join(', '),
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ],
    );
  }

  /// Sekcja wartości
  static Widget buildValueSection(InvestorSummary investor, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryAccent, AppTheme.secondaryGold],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            CurrencyFormatter.formatCurrencyShort(
              investor.viableRemainingCapital,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSecondary, width: 1),
          ),
          child: Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Rząd statystyk
  static Widget buildStatsRow(InvestorSummary investor) {
    return Row(
      children: [
        if (investor.totalRemainingCapital > 0) ...[
          buildStatCard(
            'Pozostały',
            CurrencyFormatter.formatCurrencyShort(
              investor.totalRemainingCapital,
            ),
            Icons.account_balance,
            AppTheme.warningColor,
          ),
          const SizedBox(width: 12),
        ],
        if (investor.totalSharesValue > 0) ...[
          buildStatCard(
            'Udziały',
            CurrencyFormatter.formatCurrencyShort(investor.totalSharesValue),
            Icons.pie_chart,
            AppTheme.successColor,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: buildStatCard(
            'Inwestycje',
            '${investor.investmentCount}',
            Icons.trending_up,
            AppTheme.primaryAccent,
          ),
        ),
      ],
    );
  }

  /// Sekcja tagów
  static Widget buildTagsSection(InvestorSummary investor) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        buildModernStatusChip(
          VotingStatusHelper.getText(investor.client.votingStatus),
          VotingStatusHelper.getIcon(investor.client.votingStatus),
          VotingStatusHelper.getColor(investor.client.votingStatus),
        ),
        buildModernStatusChip(
          investor.client.type.displayName,
          Icons.person,
          AppTheme.textSecondary,
        ),
        if (investor.hasUnviableInvestments)
          buildModernStatusChip(
            'Niewykonalne',
            Icons.warning,
            AppTheme.errorColor,
          ),
        if (investor.client.email.isNotEmpty)
          buildModernStatusChip('Email', Icons.email, AppTheme.successColor),
      ],
    );
  }

  /// Karta notatek
  static Widget buildNotesCard(InvestorSummary investor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundSecondary, AppTheme.surfaceCard],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSecondary, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.notes, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              investor.client.notes.isNotEmpty
                  ? investor.client.notes
                  : 'Brak notatek',
              style: TextStyle(
                color: investor.client.notes.isNotEmpty
                    ? AppTheme.textPrimary
                    : AppTheme.textTertiary,
                fontSize: 14,
                fontStyle: investor.client.notes.isNotEmpty
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Chip filtra
  static Widget buildFilterChip(
    String label,
    bool selected,
    Function(bool) onChanged,
  ) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? AppTheme.textOnSecondary : AppTheme.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      onSelected: onChanged,
      selectedColor: AppTheme.secondaryGold.withOpacity(0.2),
      backgroundColor: AppTheme.surfaceElevated,
      checkmarkColor: AppTheme.secondaryGold,
      side: BorderSide(
        color: selected ? AppTheme.secondaryGold : AppTheme.borderSecondary,
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

/// Helper klasy dla statusów głosowania
class VotingStatusHelper {
  static String getText(VotingStatus status) {
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

  static IconData getIcon(VotingStatus status) {
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

  static Color getColor(VotingStatus status) {
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
