import 'package:flutter/material.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import '../../utils/currency_formatter.dart';

class MajorityAnalysisWidget extends StatefulWidget {
  final List<InvestorSummary> majorityHolders;
  final double majorityThreshold;
  final double totalViableCapital;
  final bool isTablet;
  final bool isLoading;
  final ViewMode viewMode;
  final Function(InvestorSummary) onInvestorTap;

  const MajorityAnalysisWidget({
    super.key,
    required this.majorityHolders,
    required this.majorityThreshold,
    required this.totalViableCapital,
    required this.isTablet,
    required this.isLoading,
    required this.viewMode,
    required this.onInvestorTap,
  });

  @override
  State<MajorityAnalysisWidget> createState() => _MajorityAnalysisWidgetState();
}

class _MajorityAnalysisWidgetState extends State<MajorityAnalysisWidget>
    with TickerProviderStateMixin {
  late AnimationController _primaryAnimationController;
  late AnimationController _statsAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _primaryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _primaryAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _primaryAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _primaryAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.decelerate),
    ));

    if (!widget.isLoading) {
      _primaryAnimationController.forward();
      _statsAnimationController.forward();
    }
  }

  @override
  void didUpdateWidget(MajorityAnalysisWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLoading && oldWidget.isLoading) {
      _primaryAnimationController.forward();
      _statsAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _primaryAnimationController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildMajorityStatsCard(),
          const SizedBox(height: 16),
          _buildMajorityHoldersList(),
        ],
      ),
    );
  }

  Widget _buildMajorityStatsCard() {
    if (widget.isLoading) {
      return _buildLoadingStats();
    }

    final majorityCapital = widget.majorityHolders.fold<double>(
      0.0,
      (sum, investor) => sum + investor.totalRemainingCapital,
    );
    final majorityPercentage = widget.totalViableCapital > 0
        ? (majorityCapital / widget.totalViableCapital) * 100
        : 0.0;

    final hasControl = majorityPercentage >= widget.majorityThreshold;

    return AnimatedBuilder(
      animation: _primaryAnimationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: widget.isTablet ? 24 : 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      hasControl
                          ? AppThemePro.statusSuccess.withValues(alpha: 0.1)
                          : AppThemePro.statusWarning.withValues(alpha: 0.1),
                      AppThemePro.surfaceCard,
                      AppThemePro.backgroundSecondary,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasControl
                        ? AppThemePro.statusSuccess.withValues(alpha: 0.3)
                        : AppThemePro.statusWarning.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: (hasControl
                              ? AppThemePro.statusSuccess
                              : AppThemePro.statusWarning)
                          .withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildStatsHeader(hasControl),
                      const SizedBox(height: 24),
                      _buildStatsGrid(
                          majorityCapital, majorityPercentage, hasControl),
                      const SizedBox(height: 20),
                      _buildControlIndicator(hasControl, majorityPercentage),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsHeader(bool hasControl) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                hasControl ? AppThemePro.statusSuccess : AppThemePro.statusWarning,
                (hasControl ? AppThemePro.statusSuccess : AppThemePro.statusWarning)
                    .withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (hasControl ? AppThemePro.statusSuccess : AppThemePro.statusWarning)
                    .withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            hasControl ? Icons.verified_user_rounded : Icons.groups_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analiza większości posiadaczy',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppThemePro.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                hasControl
                    ? 'Grupa posiada kontrolę większościową'
                    : 'Grupa nie osiąga progu większości',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: hasControl
                          ? AppThemePro.statusSuccess
                          : AppThemePro.statusWarning,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
      double majorityCapital, double majorityPercentage, bool hasControl) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: widget.isTablet ? 4 : 2,
      childAspectRatio: widget.isTablet ? 1.6 : 1.4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildAnimatedStatCard(
          'Próg większości',
          '${widget.majorityThreshold.toStringAsFixed(0)}%',
          Icons.flag_rounded,
          AppThemePro.accentGold,
          0,
        ),
        _buildAnimatedStatCard(
          'Posiadaczy większości',
          '${widget.majorityHolders.length}',
          Icons.group_rounded,
          AppThemePro.statusInfo,
          1,
        ),
        _buildAnimatedStatCard(
          'Kapitał grupy',
          CurrencyFormatter.formatCurrencyShort(majorityCapital),
          Icons.account_balance_wallet_rounded,
          AppThemePro.statusSuccess,
          2,
        ),
        _buildAnimatedStatCard(
          'Udział w całości',
          '${majorityPercentage.toStringAsFixed(1)}%',
          Icons.pie_chart_rounded,
          hasControl ? AppThemePro.statusSuccess : AppThemePro.statusWarning,
          3,
        ),
      ],
    );
  }

  Widget _buildAnimatedStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 200)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppThemePro.backgroundTertiary,
                  AppThemePro.surfaceElevated,
                  color.withValues(alpha: 0.05),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontSize: widget.isTablet ? 20 : 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlIndicator(bool hasControl, double majorityPercentage) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (hasControl ? AppThemePro.statusSuccess : AppThemePro.statusWarning)
                .withValues(alpha: 0.1),
            (hasControl ? AppThemePro.statusSuccess : AppThemePro.statusWarning)
                .withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (hasControl ? AppThemePro.statusSuccess : AppThemePro.statusWarning)
              .withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (hasControl ? AppThemePro.statusSuccess : AppThemePro.statusWarning)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasControl ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: hasControl ? AppThemePro.statusSuccess : AppThemePro.statusWarning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasControl ? 'KONTROLA WIĘKSZOŚCIOWA' : 'BRAK KONTROLI WIĘKSZOŚCIOWEJ',
                  style: TextStyle(
                    color: hasControl ? AppThemePro.statusSuccess : AppThemePro.statusWarning,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  hasControl
                      ? 'Grupa posiada wystarczającą ilość kapitału do podejmowania decyzji'
                      : 'Do osiągnięcia kontroli brakuje ${(widget.majorityThreshold - majorityPercentage).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMajorityHoldersList() {
    if (widget.isLoading) {
      return _buildLoadingList();
    }

    if (widget.majorityHolders.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 24 : 16,
        vertical: 8,
      ),
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
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppThemePro.accentGold.withValues(alpha: 0.1),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListHeader(),
          const Divider(color: AppThemePro.borderSecondary, height: 1),
          _buildHoldersList(),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
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
              Icons.leaderboard_rounded,
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
                  'Posiadacze większości',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppThemePro.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                ),
                Text(
                  '${widget.majorityHolders.length} posiadaczy według udziału',
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

  Widget _buildHoldersList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.majorityHolders.length,
      separatorBuilder: (context, index) => const Divider(
        color: AppThemePro.borderSecondary,
        height: 1,
        indent: 20,
        endIndent: 20,
      ),
      itemBuilder: (context, index) => _buildHolderTile(
        widget.majorityHolders[index],
        index,
      ),
    );
  }

  Widget _buildHolderTile(InvestorSummary holder, int index) {
    final percentage = widget.totalViableCapital > 0
        ? (holder.totalRemainingCapital / widget.totalViableCapital * 100)
        : 0.0;

    // Skumulowany procent do tej pozycji
    double cumulativeCapital = 0.0;
    for (int i = 0; i <= index; i++) {
      cumulativeCapital += widget.majorityHolders[i].totalRemainingCapital;
    }
    final cumulativePercentage = widget.totalViableCapital > 0
        ? (cumulativeCapital / widget.totalViableCapital * 100)
        : 0.0;

    final position = index + 1;
    final isTopHolder = index < 3;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onInvestorTap(holder),
        child: TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, animationValue, child) {
            return Transform.translate(
              offset: Offset(0, (1 - animationValue) * 20),
              child: Opacity(
                opacity: animationValue,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Position badge
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isTopHolder
                                ? [AppThemePro.accentGold, AppThemePro.accentGoldMuted]
                                : [
                                    AppThemePro.textSecondary.withValues(alpha: 0.2),
                                    AppThemePro.textSecondary.withValues(alpha: 0.1)
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isTopHolder
                                ? AppThemePro.accentGold.withValues(alpha: 0.4)
                                : AppThemePro.textSecondary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                '$position',
                                style: TextStyle(
                                  color: isTopHolder
                                      ? AppThemePro.primaryDark
                                      : AppThemePro.textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (position == 1)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: AppThemePro.statusSuccess,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppThemePro.backgroundSecondary,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.star_rounded,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Investor info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              holder.client.name,
                              style: TextStyle(
                                color: AppThemePro.textPrimary,
                                fontSize: widget.isTablet ? 16 : 14,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Udział: ${percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: AppThemePro.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Skumulowane: ${cumulativePercentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: cumulativePercentage >= widget.majorityThreshold
                                        ? AppThemePro.statusSuccess
                                        : AppThemePro.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Capital amount
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppThemePro.statusSuccess.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppThemePro.statusSuccess.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          CurrencyFormatter.formatCurrencyShort(holder.totalRemainingCapital),
                          style: TextStyle(
                            color: AppThemePro.statusSuccess,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingStats() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 24 : 16,
        vertical: 12,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemePro.borderSecondary),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppThemePro.backgroundTertiary,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 200,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppThemePro.backgroundTertiary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 150,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppThemePro.backgroundTertiary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: widget.isTablet ? 4 : 2,
            childAspectRatio: widget.isTablet ? 1.6 : 1.4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: List.generate(
              4,
              (index) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppThemePro.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppThemePro.borderSecondary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppThemePro.backgroundTertiary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppThemePro.backgroundTertiary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 24 : 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemePro.borderSecondary),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppThemePro.backgroundTertiary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 150,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppThemePro.backgroundTertiary,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppThemePro.backgroundTertiary,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(3, (index) => _buildShimmerListItem()),
        ],
      ),
    );
  }

  Widget _buildShimmerListItem() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppThemePro.backgroundTertiary,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppThemePro.backgroundTertiary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppThemePro.backgroundTertiary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 20,
            decoration: BoxDecoration(
              color: AppThemePro.backgroundTertiary,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 24 : 16,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemePro.borderSecondary),
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
            'Brak posiadaczy większości',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppThemePro.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Żaden inwestor nie posiada ≥${widget.majorityThreshold.toStringAsFixed(0)}% kapitału',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppThemePro.textMuted,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}