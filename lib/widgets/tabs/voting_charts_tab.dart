import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/investor_summary.dart';
import '../../models/client.dart';
import '../../utils/currency_formatter.dart';
import '../premium_analytics_charts.dart';

/// 🗳️ TAB ANALIZA GŁOSOWANIA
///
/// Dedykowany tab do analizy rozkładu głosów i statusów głosowania inwestorów.
/// Zawiera wykresy kołowe, statystyki i szczegółowe podsumowania.

class VotingChartsTab extends StatefulWidget {
  final List<InvestorSummary> filteredInvestors;
  final Map<VotingStatus, double> filteredVotingDistribution;
  final Map<VotingStatus, int> filteredVotingCounts;
  final double filteredTotalCapital;
  final VoidCallback? onShowVotingDetails;

  const VotingChartsTab({
    super.key,
    required this.filteredInvestors,
    required this.filteredVotingDistribution,
    required this.filteredVotingCounts,
    required this.filteredTotalCapital,
    this.onShowVotingDetails,
  });

  @override
  State<VotingChartsTab> createState() => _VotingChartsTabState();
}

class _VotingChartsTabState extends State<VotingChartsTab>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTabHeader(),
                  const SizedBox(height: 24),
                  _buildVotingPieChart(),
                  const SizedBox(height: 30),
                  _buildVotingStatsGrid(),
                  const SizedBox(height: 30),
                  _buildVotingBreakdown(),
                  const SizedBox(height: 30),
                  _buildCapitalImpactAnalysis(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryGold.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.how_to_vote_rounded,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analiza Głosowania',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rozkład kapitału według statusów głosowania • '
                  '${widget.filteredInvestors.length} inwestorów',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuickActionButton(
          icon: Icons.info_outline_rounded,
          label: 'Szczegóły',
          onTap: widget.onShowVotingDetails,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        _buildQuickActionButton(
          icon: Icons.download_rounded,
          label: 'Eksport',
          onTap: _exportVotingData,
          color: AppTheme.secondaryGold,
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    required Color color,
  }) {
    return Tooltip(
      message: label,
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildVotingPieChart() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Rozkład Głosów',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pie_chart_rounded,
                        color: AppTheme.successColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Interaktywny',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Wykres kołowy statusów głosowania
          PremiumVotingPieChart(
            votingDistribution: widget.filteredVotingDistribution,
            votingCounts: widget.filteredVotingCounts,
            totalCapital: widget.filteredTotalCapital,
            onSegmentTap: widget.onShowVotingDetails,
          ),
        ],
      ),
    );
  }

  Widget _buildVotingStatsGrid() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Statystyki Głosowania',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: [
                _buildStatCard(
                  'Głosy ZA',
                  '${widget.filteredVotingCounts[VotingStatus.yes] ?? 0}',
                  '${_getVotingPercentage(VotingStatus.yes).toStringAsFixed(1)}%',
                  Icons.thumb_up_rounded,
                  const Color(0xFF00C851),
                ),
                _buildStatCard(
                  'Głosy PRZECIW',
                  '${widget.filteredVotingCounts[VotingStatus.no] ?? 0}',
                  '${_getVotingPercentage(VotingStatus.no).toStringAsFixed(1)}%',
                  Icons.thumb_down_rounded,
                  const Color(0xFFFF4444),
                ),
                _buildStatCard(
                  'Wstrzymania',
                  '${widget.filteredVotingCounts[VotingStatus.abstain] ?? 0}',
                  '${_getVotingPercentage(VotingStatus.abstain).toStringAsFixed(1)}%',
                  Icons.remove_circle_rounded,
                  const Color(0xFFFF8800),
                ),
                _buildStatCard(
                  'Niezdecydowani',
                  '${widget.filteredVotingCounts[VotingStatus.undecided] ?? 0}',
                  '${_getVotingPercentage(VotingStatus.undecided).toStringAsFixed(1)}%',
                  Icons.help_rounded,
                  const Color(0xFF9E9E9E),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingBreakdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Szczegółowy Rozkład Kapitału',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          ...VotingStatus.values.map((status) {
            final capital = widget.filteredVotingDistribution[status] ?? 0.0;
            final count = widget.filteredVotingCounts[status] ?? 0;
            final percentage = widget.filteredTotalCapital > 0
                ? (capital / widget.filteredTotalCapital) * 100
                : 0.0;

            return _buildVotingBreakdownItem(
              status,
              capital,
              count,
              percentage,
            );
          }),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildVotingBreakdownItem(
    VotingStatus status,
    double capital,
    int count,
    double percentage,
  ) {
    final color = _getVotingStatusColor(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              status.displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              CurrencyFormatter.formatCurrencyShort(capital),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$count',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapitalImpactAnalysis() {
    final totalCapital = widget.filteredTotalCapital;
    final yesCapital =
        widget.filteredVotingDistribution[VotingStatus.yes] ?? 0.0;
    final noCapital = widget.filteredVotingDistribution[VotingStatus.no] ?? 0.0;

    final yesPercentage = totalCapital > 0
        ? (yesCapital / totalCapital) * 100
        : 0.0;
    final noPercentage = totalCapital > 0
        ? (noCapital / totalCapital) * 100
        : 0.0;

    final isMajorityForYes = yesPercentage > 50;
    final isMajorityForNo = noPercentage > 50;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isMajorityForYes
                ? const Color(0xFF00C851).withOpacity(0.1)
                : isMajorityForNo
                ? const Color(0xFFFF4444).withOpacity(0.1)
                : AppTheme.warningColor.withOpacity(0.1),
            AppTheme.backgroundSecondary.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMajorityForYes
              ? const Color(0xFF00C851).withOpacity(0.3)
              : isMajorityForNo
              ? const Color(0xFFFF4444).withOpacity(0.3)
              : AppTheme.warningColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isMajorityForYes
                    ? Icons.check_circle_rounded
                    : isMajorityForNo
                    ? Icons.cancel_rounded
                    : Icons.warning_rounded,
                color: isMajorityForYes
                    ? const Color(0xFF00C851)
                    : isMajorityForNo
                    ? const Color(0xFFFF4444)
                    : AppTheme.warningColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Analiza Wpływu Kapitału',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getCapitalImpactMessage(yesPercentage, noPercentage),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildImpactMetric(
                  'Kapitał ZA',
                  CurrencyFormatter.formatCurrencyShort(yesCapital),
                  '${yesPercentage.toStringAsFixed(1)}%',
                  const Color(0xFF00C851),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildImpactMetric(
                  'Kapitał PRZECIW',
                  CurrencyFormatter.formatCurrencyShort(noCapital),
                  '${noPercentage.toStringAsFixed(1)}%',
                  const Color(0xFFFF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactMetric(
    String label,
    String value,
    String percentage,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            percentage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  double _getVotingPercentage(VotingStatus status) {
    final total = widget.filteredVotingCounts.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    final count = widget.filteredVotingCounts[status] ?? 0;
    return total > 0 ? (count / total) * 100 : 0.0;
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return const Color(0xFF00C851);
      case VotingStatus.no:
        return const Color(0xFFFF4444);
      case VotingStatus.abstain:
        return const Color(0xFFFF8800);
      case VotingStatus.undecided:
        return const Color(0xFF9E9E9E);
    }
  }

  String _getCapitalImpactMessage(double yesPercentage, double noPercentage) {
    if (yesPercentage > 50) {
      return 'Kapitał głosujący ZA stanowi większość (${yesPercentage.toStringAsFixed(1)}%). '
          'Propozycja ma silne poparcie kapitałowe i prawdopodobnie zostanie przyjęta.';
    } else if (noPercentage > 50) {
      return 'Kapitał głosujący PRZECIW stanowi większość (${noPercentage.toStringAsFixed(1)}%). '
          'Propozycja spotyka się z silnym sprzeciwem kapitałowym.';
    } else {
      return 'Brak wyraźnej większości kapitałowej. Wynik głosowania będzie zależał od '
          'niezdecydowanych inwestorów i tych którzy się wstrzymają.';
    }
  }

  void _exportVotingData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eksport danych głosowania - funkcja w przygotowaniu'),
      ),
    );
  }
}
