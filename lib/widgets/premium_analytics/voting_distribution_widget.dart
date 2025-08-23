import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';

class VotingDistributionWidget extends StatefulWidget {
  final bool isLoading;
  final bool isTablet;
  final Map<VotingStatus, double> votingDistribution;
  final Map<VotingStatus, int> votingCounts;
  final int totalCount;

  const VotingDistributionWidget({
    super.key,
    required this.isLoading,
    required this.isTablet,
    required this.votingDistribution,
    required this.votingCounts,
    required this.totalCount,
  });

  @override
  State<VotingDistributionWidget> createState() => _VotingDistributionWidgetState();
}

class _VotingDistributionWidgetState extends State<VotingDistributionWidget> {
  int _hoveredSectionIndex = -1;
  VotingStatus? _selectedSection;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(widget.isTablet ? 16 : 12),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          if (widget.isLoading)
            _buildLoadingChart()
          else ...[
            _buildVotingChart(),
            const SizedBox(height: 24),
            _buildCenteredLegend(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppThemePro.statusInfo,
                AppThemePro.statusInfo.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppThemePro.statusInfo.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.how_to_vote_rounded,
            color: AppThemePro.textPrimary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          children: [
            Text(
              'Rozkład głosowania',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Procentowy podział głosów inwestorów',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingChart() {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: AppThemePro.backgroundTertiary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppThemePro.accentGold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ładowanie rozkładu głosowania...',
              style: TextStyle(
                color: AppThemePro.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingChart() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            AppThemePro.backgroundTertiary.withValues(alpha: 0.1),
            AppThemePro.backgroundSecondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main pie chart
          PieChart(
            PieChartData(
              sectionsSpace: _hoveredSectionIndex >= 0 ? 6 : 4,
              centerSpaceRadius: _hoveredSectionIndex >= 0 ? 75 : 80,
              startDegreeOffset: -90,
              sections: _buildPieChartSections(),
              pieTouchData: PieTouchData(
                enabled: true,
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _hoveredSectionIndex = -1;
                      _selectedSection = null;
                      return;
                    }

                    final touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                    final votingStatuses = VotingStatus.values;

                    if (touchedIndex >= 0 && touchedIndex < votingStatuses.length) {
                      _hoveredSectionIndex = touchedIndex;
                      _selectedSection = votingStatuses[touchedIndex];
                    }
                  });
                },
              ),
            ),
          ),
          // Center content with dynamic info
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCenterContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterContent() {
    if (_hoveredSectionIndex >= 0 && _selectedSection != null) {
      // Show detailed info for hovered section
      final percentage = widget.votingDistribution[_selectedSection] ?? 0.0;
      final count = widget.votingCounts[_selectedSection] ?? 0;
      final emoji = _getVotingStatusEmoji(_selectedSection!);

      return Container(
        key: ValueKey('detailed_${_selectedSection.toString()}'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppThemePro.backgroundPrimary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getVotingStatusColor(_selectedSection!).withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              _selectedSection!.displayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppThemePro.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _getVotingStatusColor(_selectedSection!),
              ),
            ),
            Text(
              '$count ${count == 1 ? 'osoba' : 'osób'}',
              style: TextStyle(
                fontSize: 12,
                color: AppThemePro.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Default center content
    return Container(
      key: const ValueKey('default'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundPrimary.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.accentGold.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('📊', style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            'Rozkład głosów',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppThemePro.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.totalCount} ${widget.totalCount == 1 ? 'inwestor' : 'inwestorów'}',
            style: TextStyle(
              fontSize: 12,
              color: AppThemePro.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenteredLegend() {
    if (widget.isLoading) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: List.generate(
          4,
          (index) => Container(
            width: 140,
            height: 48,
            decoration: BoxDecoration(
              color: AppThemePro.backgroundTertiary,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: VotingStatus.values.asMap().entries.map((entry) {
          final index = entry.key;
          final status = entry.value;
          final percentage = widget.votingDistribution[status] ?? 0.0;
          final count = widget.votingCounts[status] ?? 0;
          final color = _getVotingStatusColor(status);
          final emoji = _getVotingStatusEmoji(status);
          final isHighlighted =
              _hoveredSectionIndex == index || _selectedSection == status;

          return MouseRegion(
            onEnter: (_) {
              setState(() {
                _hoveredSectionIndex = index;
                _selectedSection = status;
              });
            },
            onExit: (_) {
              setState(() {
                _hoveredSectionIndex = -1;
                _selectedSection = null;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              constraints: const BoxConstraints(minWidth: 130),
              padding: EdgeInsets.symmetric(
                horizontal: isHighlighted ? 20 : 16,
                vertical: isHighlighted ? 12 : 10,
              ),
              decoration: BoxDecoration(
                gradient: isHighlighted
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.2),
                          color.withValues(alpha: 0.1),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.1),
                          color.withValues(alpha: 0.05),
                        ],
                      ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isHighlighted
                      ? color.withValues(alpha: 0.6)
                      : color.withValues(alpha: 0.3),
                  width: isHighlighted ? 2 : 1,
                ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(fontSize: isHighlighted ? 24 : 20),
                    child: Text(emoji),
                  ),
                  SizedBox(width: isHighlighted ? 12 : 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: AppThemePro.textPrimary,
                          fontWeight: isHighlighted
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: isHighlighted ? 14 : 13,
                        ),
                        child: Text(status.displayName),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: isHighlighted ? color : AppThemePro.textSecondary,
                          fontSize: isHighlighted ? 12 : 11,
                          fontWeight: isHighlighted
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        child: Text(
                          '$count ${count == 1 ? 'osoba' : 'osób'} (${percentage.toStringAsFixed(1)}%)',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    return VotingStatus.values.asMap().entries.map((entry) {
      final index = entry.key;
      final status = entry.value;
      final percentage = widget.votingDistribution[status] ?? 0.0;
      final color = _getVotingStatusColor(status);
      final emoji = _getVotingStatusEmoji(status);
      final isHovered = index == _hoveredSectionIndex;

      return PieChartSectionData(
        color: color,
        value: percentage,
        title: percentage > 5 && !isHovered
            ? '$emoji\n${percentage.toStringAsFixed(1)}%'
            : '',
        radius: isHovered ? 85 : 70,
        titleStyle: TextStyle(
          fontSize: isHovered ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.7),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
        badgeWidget: (percentage > 15 && !isHovered)
            ? Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppThemePro.backgroundPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              )
            : null,
        badgePositionPercentageOffset: isHovered ? 1.5 : 1.3,
        borderSide: isHovered
            ? BorderSide(color: Colors.white, width: 4)
            : BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1),
      );
    }).toList();
  }

  String _getVotingStatusEmoji(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return '😊';
      case VotingStatus.no:
        return '😔';
      case VotingStatus.abstain:
        return '😐';
      case VotingStatus.undecided:
        return '🤔';
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
        return AppThemePro.neutralGray;
    }
  }
}