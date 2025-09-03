import 'package:flutter/material.dart';
import '../../theme/app_theme_professional.dart';
import '../../models_and_services.dart';

/// Komponent wyświetlający listę inwestorów większościowych z animacjami
class MajorityHoldersList extends StatefulWidget {
  final List<InvestorSummary> majorityHolders;
  final bool isTablet;
  final VoidCallback? onInvestorTap;
  final Function(InvestorSummary)? onInvestorSelected;

  const MajorityHoldersList({
    super.key,
    required this.majorityHolders,
    this.isTablet = false,
    this.onInvestorTap,
    this.onInvestorSelected,
  });

  @override
  State<MajorityHoldersList> createState() => _MajorityHoldersListState();
}

class _MajorityHoldersListState extends State<MajorityHoldersList>
    with TickerProviderStateMixin {
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStaggeredAnimations();
  }

  void _initializeAnimations() {
    _listController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  void _startStaggeredAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _listController.forward();
      }
    });
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _listController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _listController.value)),
          child: Opacity(
            opacity: _listController.value,
            child: Container(
              decoration: BoxDecoration(
                color: AppThemePro.backgroundSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppThemePro.borderSecondary,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppThemePro.backgroundPrimary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildHeader(), _buildInvestorsList()],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.accentGold.withValues(alpha: 0.1),
            AppThemePro.accentGoldMuted.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppThemePro.accentGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.star_rounded,
              color: AppThemePro.accentGold,
              size: widget.isTablet ? 24 : 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inwestorzy większościowi',
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontSize: widget.isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.majorityHolders.length} inwestorów kontroluje większość',
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: widget.isTablet ? 14 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestorsList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: widget.majorityHolders.asMap().entries.map((entry) {
          final index = entry.key;
          final investor = entry.value;

          return _buildInvestorCard(investor, index);
        }).toList(),
      ),
    );
  }

  Widget _buildInvestorCard(InvestorSummary investor, int index) {
    final totalCapital = widget.majorityHolders.fold<double>(
      0.0,
      (sum, inv) => sum + inv.totalRemainingCapital,
    );

    final percentage = totalCapital > 0
        ? (investor.totalRemainingCapital / totalCapital) * 100
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            widget.onInvestorSelected?.call(investor);
            widget.onInvestorTap?.call();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemePro.backgroundTertiary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppThemePro.borderSecondary, width: 1),
            ),
            child: Row(
              children: [
                _buildInvestorAvatar(investor, index),
                const SizedBox(width: 16),
                Expanded(child: _buildInvestorInfo(investor)),
                const SizedBox(width: 16),
                _buildInvestorStats(investor, percentage),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvestorAvatar(InvestorSummary investor, int index) {
    final avatarColors = [
      AppThemePro.accentGold,
      AppThemePro.statusSuccess,
      AppThemePro.statusInfo,
      AppThemePro.statusWarning,
    ];

    final color = avatarColors[index % avatarColors.length];
    final initials = _getInitials(investor.client.name);

    return Container(
      width: widget.isTablet ? 48 : 40,
      height: widget.isTablet ? 48 : 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.isTablet ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInvestorInfo(InvestorSummary investor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          investor.client.name,
          style: TextStyle(
            color: AppThemePro.textPrimary,
            fontSize: widget.isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${investor.investmentCount} inwestycji',
          style: TextStyle(
            color: AppThemePro.textSecondary,
            fontSize: widget.isTablet ? 13 : 11,
          ),
        ),
      ],
    );
  }

  Widget _buildInvestorStats(InvestorSummary investor, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatCurrency(investor.totalRemainingCapital),
          style: TextStyle(
            color: AppThemePro.statusSuccess,
            fontSize: widget.isTablet ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppThemePro.accentGold.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: AppThemePro.accentGold,
              fontSize: widget.isTablet ? 12 : 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0].substring(0, words[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'IN';
  }

  String _formatCurrency(double amount) {
    // Format tysiączny z separatorami
    final formattedValue = amount.toStringAsFixed(0);
    return '${_formatWithThousandsSeparator(formattedValue)} PLN';
  }

  /// Formatuje liczbę z separatorami tysięcy (np. 1 000 000)
  String _formatWithThousandsSeparator(String value) {
    // Usuń ewentualne przecinki i kropki
    value = value.replaceAll(RegExp(r'[,.]'), '');

    // Dodaj separatory tysięcy
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return value.replaceAllMapped(regex, (match) => '${match[1]} ');
  }
}
