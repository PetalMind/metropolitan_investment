import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// 🎨 ENHANCED APP BAR FOR INVESTOR ANALYTICS
/// Zaawansowany app bar z animacjami, statystykami i akcjami
class EnhancedInvestorAppBar extends StatelessWidget {
  final double expandedHeight;
  final bool isTablet;
  final bool usePremiumMode;
  final int totalCount;
  final double totalCapital;
  final int majorityHoldersCount;
  final VoidCallback onTogglePremiumMode;
  final VoidCallback onToggleFilters;
  final VoidCallback onRefresh;
  final Animation<double> statsOpacityAnimation;

  const EnhancedInvestorAppBar({
    super.key,
    required this.expandedHeight,
    required this.isTablet,
    required this.usePremiumMode,
    required this.totalCount,
    required this.totalCapital,
    required this.majorityHoldersCount,
    required this.onTogglePremiumMode,
    required this.onToggleFilters,
    required this.onRefresh,
    required this.statsOpacityAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.backgroundSecondary,
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          children: [
            const Text(
              'Analityka Inwestorów',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (usePremiumMode) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: AppTheme.backgroundPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundSecondary,
                AppTheme.surfaceCard.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildStatsRow(),
                  if (isTablet) ...[
                    const SizedBox(height: 12),
                    _buildQuickActions(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(usePremiumMode ? Icons.cloud : Icons.cloud_off),
          tooltip: usePremiumMode ? 'Tryb Premium (Firebase)' : 'Tryb Lokalny',
          onPressed: onTogglePremiumMode,
        ),
        IconButton(icon: const Icon(Icons.tune), onPressed: onToggleFilters),
        IconButton(icon: const Icon(Icons.refresh), onPressed: onRefresh),
      ],
    );
  }

  Widget _buildStatsRow() {
    return FadeTransition(
      opacity: statsOpacityAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Inwestorzy', totalCount.toString(), Icons.people),
          _buildStatCard(
            'Kapitał',
            '${(totalCapital / 1000000).toStringAsFixed(1)}M',
            Icons.trending_up,
          ),
          _buildStatCard(
            'Większość',
            majorityHoldersCount.toString(),
            Icons.gavel,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondaryGold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.secondaryGold, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionChip('Wszyscy', true, () {}),
        _buildActionChip('Większość', false, () {}),
        _buildActionChip('Export', false, () {}),
      ],
    );
  }

  Widget _buildActionChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.secondaryGold : AppTheme.textSecondary,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppTheme.backgroundPrimary
                : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
