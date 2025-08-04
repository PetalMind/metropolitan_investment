import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models_and_services.dart';

/// 🗳️ VOTING ANALYSIS CARD
/// Zaawansowana analiza głosowania z wizualizacją rozkładu głosów
class VotingAnalysisCard extends StatelessWidget {
  final Map<VotingStatus, double> votingDistribution;
  final Map<VotingStatus, int> votingCounts;

  const VotingAnalysisCard({
    super.key,
    required this.votingDistribution,
    required this.votingCounts,
  });

  @override
  Widget build(BuildContext context) {
    if (votingDistribution.isEmpty) return const SizedBox.shrink();

    return Card(
      color: AppTheme.surfaceCard,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.how_to_vote, color: AppTheme.secondaryGold),
                const SizedBox(width: 8),
                const Text(
                  'Analiza Głosowania',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Voting distribution bars
            ...votingDistribution.entries.map(
              (entry) => _buildVotingBar(
                entry.key,
                entry.value,
                votingCounts[entry.key] ?? 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingBar(VotingStatus status, double percentage, int count) {
    final color = _getVotingStatusColor(status);
    final label = _getVotingStatusLabel(status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppTheme.backgroundTertiary,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${percentage.toStringAsFixed(1)}% ($count)',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return Colors.green;
      case VotingStatus.no:
        return Colors.red;
      case VotingStatus.abstain:
        return Colors.orange;
      case VotingStatus.undecided:
        return AppTheme.textSecondary;
    }
  }

  String _getVotingStatusLabel(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return 'Za';
      case VotingStatus.no:
        return 'Przeciw';
      case VotingStatus.abstain:
        return 'Wstrzym.';
      case VotingStatus.undecided:
        return 'Niezdec.';
    }
  }
}

/// 🏛️ MAJORITY CONTROL CARD
/// Analiza kontroli większościowej kapitału
class MajorityControlCard extends StatelessWidget {
  final List<InvestorSummary> majorityHolders;
  final double totalCapital;

  const MajorityControlCard({
    super.key,
    required this.majorityHolders,
    required this.totalCapital,
  });

  @override
  Widget build(BuildContext context) {
    if (majorityHolders.isEmpty) return const SizedBox.shrink();

    return Card(
      color: AppTheme.surfaceCard,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.gavel, color: AppTheme.secondaryGold),
                const SizedBox(width: 8),
                const Text(
                  'Kontrola Większościowa',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Minimalna grupa ${majorityHolders.length} inwestorów kontroluje ≥51% kapitału',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            // Top majority holders
            ...(majorityHolders
                .take(3)
                .map((investor) => _buildMajorityHolderTile(investor))),
            if (majorityHolders.length > 3)
              Text(
                '... i ${majorityHolders.length - 3} innych',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMajorityHolderTile(InvestorSummary investor) {
    final percentage = totalCapital > 0
        ? (investor.viableRemainingCapital / totalCapital) * 100
        : 0.0;

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: AppTheme.secondaryGold,
        child: Text(
          investor.client.name.isNotEmpty
              ? investor.client.name[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: AppTheme.backgroundPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        investor.client.name,
        style: const TextStyle(color: AppTheme.textPrimary),
      ),
      trailing: Text(
        '${percentage.toStringAsFixed(1)}%',
        style: const TextStyle(
          color: AppTheme.secondaryGold,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
