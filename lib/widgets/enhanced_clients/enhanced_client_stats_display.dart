import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models_and_services.dart';

/// 🎨 ENHANCED CLIENT STATS DISPLAY
/// 
/// Responsywny widget statystyk który:
/// - Adaptuje się do rozmiaru kontenera (full/compact/mini)
/// - Wyświetla się pięknie w CollapsibleSearchHeader
/// - Animowane liczniki z easing
/// - Smart data visualization z progress bars
/// - Contextual colors based on data trends
class EnhancedClientStatsDisplay extends StatefulWidget {
  final ClientStats? clientStats;
  final bool isLoading;
  final bool isCompact;
  final bool showTrends;
  final bool showSourceInfo;

  const EnhancedClientStatsDisplay({
    super.key,
    this.clientStats,
    this.isLoading = false,
    this.isCompact = false,
    this.showTrends = true,
    this.showSourceInfo = false,
  });

  @override
  State<EnhancedClientStatsDisplay> createState() => _EnhancedClientStatsDisplayState();
}

class _EnhancedClientStatsDisplayState extends State<EnhancedClientStatsDisplay>
    with TickerProviderStateMixin {
  
  late AnimationController _counterController;
  late AnimationController _progressController;
  
  late Animation<double> _counterAnimation;
  late Animation<double> _progressAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _counterController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _counterController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _counterAnimation = CurvedAnimation(
      parent: _counterController,
      curve: Curves.easeOutQuart,
    );
    
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );
    
    // Start animations when data is available
    if (widget.clientStats != null) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    _counterController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void didUpdateWidget(EnhancedClientStatsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.clientStats != null && oldWidget.clientStats == null) {
      _startAnimations();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.clientStats == null) {
      return _buildErrorState();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_counterAnimation, _progressAnimation]),
      builder: (context, child) {
        return widget.isCompact 
            ? _buildCompactStats()
            : _buildFullStats();
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: widget.isCompact ? 60 : 120,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Ładowanie statystyk...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: widget.isCompact ? 60 : 120,
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.3),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Błąd ładowania statystyk',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStats() {
    final stats = widget.clientStats!;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            label: 'Klienci',
            value: _animatedNumber(stats.totalClients.toDouble(), 0),
            icon: Icons.people,
            color: AppTheme.infoColor,
            isCompact: true,
          ),
        ),
        
        const SizedBox(width: 16),
        
        Expanded(
          child: _buildStatItem(
            label: 'Inwestycje',
            value: _animatedNumber(stats.totalInvestments.toDouble(), 0),
            icon: Icons.trending_up,
            color: AppTheme.successColor,
            isCompact: true,
          ),
        ),
        
        const SizedBox(width: 16),
        
        Expanded(
          flex: 2,
          child: _buildStatItem(
            label: 'Kapitał',
            value: _formatCurrency(
              _animatedNumber(stats.totalRemainingCapital, 2),
            ),
            icon: Icons.account_balance_wallet,
            color: AppTheme.secondaryGold,
            isCompact: true,
          ),
        ),
      ],
    );
  }

  Widget _buildFullStats() {
    final stats = widget.clientStats!;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                label: 'Łączna liczba klientów',
                value: _animatedNumber(stats.totalClients.toDouble(), 0),
                icon: Icons.people,
                color: AppTheme.infoColor,
                showProgress: true,
                maxValue: stats.totalClients.toDouble(),
              ),
            ),
            
            const SizedBox(width: 20),
            
            Expanded(
              child: _buildStatItem(
                label: 'Aktywne inwestycje',
                value: _animatedNumber(stats.totalInvestments.toDouble(), 0),
                icon: Icons.trending_up,
                color: AppTheme.successColor,
                showProgress: true,
                maxValue: stats.totalInvestments.toDouble(),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                label: 'Łączny kapitał pozostały',
                value: _formatCurrency(
                  _animatedNumber(stats.totalRemainingCapital, 2),
                ),
                icon: Icons.account_balance_wallet,
                color: AppTheme.secondaryGold,
                showProgress: true,
                maxValue: stats.totalRemainingCapital,
              ),
            ),
            
            const SizedBox(width: 20),
            
            Expanded(
              child: _buildStatItem(
                label: 'Średnia na klienta',
                value: _formatCurrency(
                  _animatedNumber(stats.averageCapitalPerClient, 2),
                ),
                icon: Icons.person_outline,
                color: AppTheme.warningColor,
                showProgress: true,
                maxValue: stats.averageCapitalPerClient,
              ),
            ),
          ],
        ),
        
        if (widget.showSourceInfo) ...[
          const SizedBox(height: 12),
          _buildSourceInfo(stats),
        ],
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isCompact = false,
    bool showProgress = false,
    double maxValue = 100,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isCompact ? 16 : 20,
                ),
              ),
              
              if (!isCompact) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: isCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          
          SizedBox(height: isCompact ? 4 : 8),
          
          if (isCompact)
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          
          SizedBox(height: isCompact ? 2 : 4),
          
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isCompact ? 16 : 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          
          if (showProgress && !isCompact) ...[
            const SizedBox(height: 8),
            _buildProgressBar(color, maxValue),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(Color color, double maxValue) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        widthFactor: _progressAnimation.value,
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceInfo(ClientStats stats) {
    Color sourceColor;
    IconData sourceIcon;
    String sourceText;
    
    switch (stats.source) {
      case 'firebase-functions':
        sourceColor = AppTheme.successColor;
        sourceIcon = Icons.cloud;
        sourceText = 'Firebase Functions';
        break;
      case 'advanced-fallback':
        sourceColor = AppTheme.warningColor;
        sourceIcon = Icons.warning;
        sourceText = 'Zaawansowany fallback';
        break;
      case 'basic-fallback':
        sourceColor = AppTheme.errorColor;
        sourceIcon = Icons.error;
        sourceText = 'Podstawowy fallback';
        break;
      default:
        sourceColor = AppTheme.textSecondary;
        sourceIcon = Icons.info;
        sourceText = 'Nieznane źródło';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: sourceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: sourceColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sourceIcon,
            color: sourceColor,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            'Źródło: $sourceText',
            style: TextStyle(
              color: sourceColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '• ${_formatUpdateTime(stats.lastUpdated)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _animatedNumber(double targetValue, int decimals) {
    final currentValue = targetValue * _counterAnimation.value;
    return decimals == 0 
        ? currentValue.round().toString()
        : currentValue.toStringAsFixed(decimals);
  }

  String _formatCurrency(String value) {
    final number = double.tryParse(value) ?? 0;
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M PLN';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}k PLN';
    }
    return '$value PLN';
  }

  String _formatUpdateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'teraz';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m temu';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h temu';
      } else {
        return '${difference.inDays}d temu';
      }
    } catch (e) {
      return 'nieznany';
    }
  }
}
