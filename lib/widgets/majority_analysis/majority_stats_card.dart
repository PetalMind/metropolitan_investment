import 'package:flutter/material.dart';
import '../../theme/app_theme_professional.dart';
import '../../models_and_services.dart';

/// Komponent wyświetlający statystyki grupy większościowej z animacjami
class MajorityStatsCard extends StatefulWidget {
  final List<InvestorSummary> majorityHolders;
  final double majorityThreshold;
  final double totalCapital;
  final bool isTablet;

  const MajorityStatsCard({
    super.key,
    required this.majorityHolders,
    required this.majorityThreshold,
    required this.totalCapital,
    this.isTablet = false,
  });

  @override
  State<MajorityStatsCard> createState() => _MajorityStatsCardState();
}

class _MajorityStatsCardState extends State<MajorityStatsCard>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _countController;
  late AnimationController _capitalController;
  late AnimationController _percentageController;

  late Animation<double> _progressAnimation;
  late Animation<int> _countAnimation;
  late Animation<double> _capitalAnimation;
  late Animation<double> _percentageAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Kontrolery animacji
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _countController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _capitalController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _percentageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Obliczenia
    final majorityCapital = widget.majorityHolders.fold<double>(
      0.0,
      (sum, investor) => sum + investor.totalRemainingCapital,
    );
    final majorityPercentage = widget.totalCapital > 0
        ? (majorityCapital / widget.totalCapital) * 100
        : 0.0;

    // Definicje animacji
    _progressAnimation =
        Tween<double>(begin: 0.0, end: majorityPercentage / 100).animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeOutCubic,
          ),
        );

    _countAnimation = IntTween(begin: 0, end: widget.majorityHolders.length)
        .animate(
          CurvedAnimation(parent: _countController, curve: Curves.easeOutBack),
        );

    _capitalAnimation = Tween<double>(begin: 0.0, end: majorityCapital).animate(
      CurvedAnimation(parent: _capitalController, curve: Curves.easeOutQuart),
    );

    _percentageAnimation = Tween<double>(begin: 0.0, end: majorityPercentage)
        .animate(
          CurvedAnimation(
            parent: _percentageController,
            curve: Curves.elasticOut,
          ),
        );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _countController.forward();
        _capitalController.forward();
        _percentageController.forward();
        _progressController.forward();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _countController.dispose();
    _capitalController.dispose();
    _percentageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.backgroundSecondary,
            AppThemePro.backgroundTertiary.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemePro.borderSecondary, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.primaryDark.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProgressSection(),
          const SizedBox(height: 32),
          _buildStatsGrid(),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kontrola kapitału',
              style: TextStyle(
                color: AppThemePro.textSecondary,
                fontSize: widget.isTablet ? 16 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            title: 'Liczba inwestorów',
            animation: _countAnimation,
            suffix: '',
            color: AppThemePro.statusInfo,
            icon: Icons.people_rounded,
            isInteger: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatTile(
            title: 'Łączny kapitał',
            animation: _capitalAnimation,
            suffix: ' PLN',
            color: AppThemePro.statusSuccess,
            icon: Icons.monetization_on_rounded,
            isInteger: false,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String title,
    required Animation animation,
    required String suffix,
    required Color color,
    required IconData icon,
    required bool isInteger,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: widget.isTablet ? 28 : 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: AppThemePro.textSecondary,
              fontSize: widget.isTablet ? 13 : 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final value = animation.value;
              String displayValue;

              if (isInteger) {
                displayValue = value.toString();
              } else {
                if (value >= 1000000) {
                  displayValue = '${(value / 1000000).toStringAsFixed(1)}M';
                } else if (value >= 1000) {
                  displayValue = '${(value / 1000).toStringAsFixed(1)}K';
                } else {
                  displayValue = value.toStringAsFixed(0);
                }
              }

              return Text(
                displayValue + suffix,
                style: TextStyle(
                  color: color,
                  fontSize: widget.isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
        ],
      ),
    );
  }
}
