import 'package:flutter/material.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';

class SystemStatsWidget extends StatelessWidget {
  final bool isLoading;
  final bool isTablet;
  final List<InvestorSummary> allInvestors;
  final UnifiedDashboardStatistics? dashboardStatistics;
  final PremiumAnalyticsResult? premiumResult;

  const SystemStatsWidget({
    super.key,
    required this.isLoading,
    required this.isTablet,
    required this.allInvestors,
    this.dashboardStatistics,
    this.premiumResult,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 16 : 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.surfaceCard,
            AppThemePro.backgroundSecondary,
            AppThemePro.surfaceCard.withValues(alpha: 0.8),
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
          const SizedBox(height: 24),
          _buildStatsGrid(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
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
            Icons.analytics_rounded,
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
                'Statystyki systemowe',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              Text(
                'Kluczowe metryki portfela inwestycyjnego',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppThemePro.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (isLoading)
          Container(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppThemePro.accentGold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    if (isLoading) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 4 : 2,
          childAspectRatio: isTablet ? 1.4 : 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => _buildShimmerCard(),
      );
    }

    // Calculate statistics
    final stats = _calculateStatistics();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isTablet ? 3 : 2,
      childAspectRatio: isTablet ? 1.4 : 1.2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Łączny kapitał',
          stats.totalCapital,
          Icons.account_balance_wallet_rounded,
          AppThemePro.accentGold,
          'Całkowita wartość inwestycji',
        ),
        _buildStatCard(
          'Kapitał pozostały',
          stats.totalViableCapital,
          Icons.trending_up_rounded,
          AppThemePro.statusSuccess,
          'Aktywny kapitał do zwrotu',
        ),
        _buildStatCard(
          'Liczba inwestorów',
          stats.totalInvestors.toDouble(),
          Icons.people_rounded,
          AppThemePro.statusInfo,
          'Aktywni klienci systemu',
          isCount: true,
        ),
        _buildStatCard(
          'Kapitał zabezpieczony nieruchomościami',
          stats.capitalSecuredByRealEstate,
          Icons.home_work_rounded,
          AppThemePro.realEstateViolet,
          'Kapitał zabezpieczony nieruchomościami',
        ),
        _buildStatCard(
          'Łączny kapitał w restrukturyzacji',
          stats.capitalForRestructuring,
          Icons.build_circle_rounded,
          AppThemePro.statusWarning,
          'Kapitał wymagający restrukturyzacji',
        ),
        _buildStatCard(
          'Średni kapitał na inwestora',
          stats.averageCapitalPerInvestor,
          Icons.person_rounded,
          AppThemePro.textSecondary,
          'Średnia wartość na inwestora',
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    double value,
    IconData icon,
    Color color,
    String subtitle, {
    bool isCount = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.backgroundTertiary,
            AppThemePro.surfaceCard,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCount ? 'LICZBA' : 'PLN',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: AppThemePro.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            isCount 
                ? value.toInt().toString()
                : '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} zł',
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            subtitle,
            style: TextStyle(
              color: AppThemePro.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.borderSecondary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppThemePro.backgroundTertiary,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                width: 40,
                height: 20,
                decoration: BoxDecoration(
                  color: AppThemePro.backgroundTertiary,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: AppThemePro.backgroundTertiary,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 100,
            height: 20,
            decoration: BoxDecoration(
              color: AppThemePro.backgroundTertiary,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const Spacer(),
          Container(
            width: 80,
            height: 10,
            decoration: BoxDecoration(
              color: AppThemePro.backgroundTertiary,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  SystemStatistics _calculateStatistics() {
    double totalViableCapital = 0.0;
    double totalCapital = 0.0;
    double capitalSecuredByRealEstate = 0.0;
    double capitalForRestructuring = 0.0;

    if (premiumResult != null) {
      // Use premium analytics data when available
      totalViableCapital = premiumResult!.performanceMetrics.totalCapital;
      if (dashboardStatistics != null) {
        totalCapital = dashboardStatistics!.totalInvestmentAmount;
      }
    } else if (dashboardStatistics != null) {
      // Use dashboard statistics as fallback
      totalCapital = dashboardStatistics!.totalInvestmentAmount;
      totalViableCapital = dashboardStatistics!.totalRemainingCapital;
    } else {
      // Calculate from investor summaries
      for (final investor in allInvestors) {
        totalViableCapital += investor.totalRemainingCapital;
        totalCapital += investor.totalInvestmentAmount;
        capitalSecuredByRealEstate += investor.capitalSecuredByRealEstate;
        capitalForRestructuring += investor.capitalForRestructuring;
      }
    }

    // If we have dashboard statistics, use those for specific metrics
    if (dashboardStatistics != null) {
      capitalSecuredByRealEstate = allInvestors.fold<double>(
        0.0,
        (sum, investor) => sum + investor.capitalSecuredByRealEstate,
      );
      capitalForRestructuring = allInvestors.fold<double>(
        0.0,
        (sum, investor) => sum + investor.capitalForRestructuring,
      );
    }

    final averageCapitalPerInvestor = allInvestors.isNotEmpty 
        ? totalViableCapital / allInvestors.length
        : 0.0;

    return SystemStatistics(
      totalCapital: totalCapital,
      totalViableCapital: totalViableCapital,
      totalInvestors: allInvestors.length,
      capitalSecuredByRealEstate: capitalSecuredByRealEstate,
      capitalForRestructuring: capitalForRestructuring,
      averageCapitalPerInvestor: averageCapitalPerInvestor,
    );
  }
}

class SystemStatistics {
  final double totalCapital;
  final double totalViableCapital;
  final int totalInvestors;
  final double capitalSecuredByRealEstate;
  final double capitalForRestructuring;
  final double averageCapitalPerInvestor;

  SystemStatistics({
    required this.totalCapital,
    required this.totalViableCapital,
    required this.totalInvestors,
    required this.capitalSecuredByRealEstate,
    required this.capitalForRestructuring,
    required this.averageCapitalPerInvestor,
  });
}