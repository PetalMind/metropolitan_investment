import 'package:flutter/material.dart';
import '../../../models_and_services.dart';

/// Widget podsumowania portfela z animacjami i statystykami
class InvestorSummarySection extends StatelessWidget {
  final List<InvestorSummary> allInvestors;
  final List<InvestorSummary> filteredInvestors;
  final double totalPortfolioValue;
  final MajorityControlAnalysis? majorityControlAnalysis;
  final bool isTablet;

  const InvestorSummarySection({
    super.key,
    required this.allInvestors,
    required this.filteredInvestors,
    required this.totalPortfolioValue,
    required this.majorityControlAnalysis,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surfaceCard, AppTheme.backgroundSecondary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryGold.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppTheme.secondaryGold.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryHeader(),
            const SizedBox(height: 24),
            if (isTablet)
              _buildTabletSummaryGrid()
            else
              _buildMobileSummaryColumn(),
            if (majorityControlAnalysis != null &&
                majorityControlAnalysis!.hasControlGroup) ...[
              const SizedBox(height: 24),
              _buildMajorityControlInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.secondaryGold,
                AppTheme.secondaryGold.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryGold.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.analytics_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Podsumowanie portfela',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Analiza inwestorów i wartości',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.secondaryGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.secondaryGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: TextStyle(
                  color: AppTheme.secondaryGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletSummaryGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildAnimatedSummaryItem(
            'Łączna liczba inwestorów',
            '${allInvestors.length}',
            Icons.people_alt_rounded,
            AppTheme.primaryColor,
            0,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAnimatedSummaryItem(
            'Wyświetlanych',
            '${filteredInvestors.length}',
            Icons.visibility_rounded,
            AppTheme.secondaryGold,
            100,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAnimatedSummaryItem(
            'Wartość portfela',
            CurrencyFormatter.formatCurrencyShort(totalPortfolioValue),
            Icons.account_balance_wallet_rounded,
            AppTheme.successColor,
            200,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSummaryColumn() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAnimatedSummaryItem(
                'Inwestorzy',
                '${filteredInvestors.length}/${allInvestors.length}',
                Icons.people_alt_rounded,
                AppTheme.primaryColor,
                0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnimatedSummaryItem(
                'Portfel',
                CurrencyFormatter.formatCurrencyShort(totalPortfolioValue),
                Icons.account_balance_wallet_rounded,
                AppTheme.successColor,
                100,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
    int delay,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animationValue),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.08), color.withOpacity(0.03)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      Container(
                        width: 4,
                        height: 40 * animationValue,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [color, color.withOpacity(0.3)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: isTablet ? 24 : 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: isTablet ? 13 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMajorityControlInfo() {
    final analysis = majorityControlAnalysis!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warningColor.withOpacity(0.1),
            AppTheme.warningColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warningColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.pie_chart_rounded,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Punkt kontroli ${analysis.controlThreshold.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '${analysis.controlGroupPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isTablet)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${analysis.controlGroupCount} największych inwestorów kontroluje ${analysis.controlGroupPercentage.toStringAsFixed(1)}% portfela',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    CurrencyFormatter.formatCurrencyShort(
                      analysis.controlGroupCapital,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warningColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${analysis.controlGroupCount} inwestorów → ${analysis.controlGroupPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    CurrencyFormatter.formatCurrencyShort(
                      analysis.controlGroupCapital,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warningColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
