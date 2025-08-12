import 'package:flutter/material.dart';
import '../models_and_services.dart';

/// Rozszerzony widget statystyk klientów z dodatkowymi metrykasmi
/// Zgodny z zunifikowanym systemem statystyk (STATISTICS_UNIFICATION_GUIDE)
class EnhancedClientStatsWidget extends StatelessWidget {
  final ClientStats? clientStats;
  final bool isLoading;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final bool showAdvancedMetrics;
  final bool showSourceInfo;

  const EnhancedClientStatsWidget({
    super.key,
    this.clientStats,
    this.isLoading = false,
    this.padding,
    this.backgroundColor,
    this.showAdvancedMetrics = true,
    this.showSourceInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (clientStats == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: backgroundColor != null
          ? BoxDecoration(color: backgroundColor)
          : AppTheme.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildMainMetrics(),
          if (showAdvancedMetrics) ...[
            const SizedBox(height: 16),
            _buildAdvancedMetrics(),
          ],
          if (showSourceInfo) ...[
            const SizedBox(height: 12),
            _buildSourceInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCardDecoration,
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.secondaryGold,
            ),
          ),
          SizedBox(width: 16),
          Text(
            'Ładowanie rozszerzonych statystyk klientów...',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.analytics_outlined, color: AppTheme.secondaryGold, size: 24),
        const SizedBox(width: 12),
        Text(
          'Statystyki Klientów',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (clientStats != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.secondaryGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.secondaryGold.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'LIVE',
              style: TextStyle(
                color: AppTheme.secondaryGold,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Łącznie Klientów',
            value: clientStats!.totalClients.toString(),
            subtitle: _getClientTypeBreakdown(),
            icon: Icons.people_outline,
            color: AppTheme.primaryColor,
            trend: _getClientTrend(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Inwestycje',
            value: clientStats!.totalInvestments.toString(),
            subtitle: '${_getInvestmentRatio()} na klienta',
            icon: Icons.trending_up,
            color: AppTheme.secondaryGold,
            trend: _getInvestmentTrend(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Kapitał Pozostały',
            value: _formatCapital(clientStats!.totalRemainingCapital),
            subtitle: _getCapitalStatus(),
            icon: Icons.account_balance_wallet,
            color: _getCapitalColor(),
            trend: _getCapitalTrend(),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Średnia na Klienta',
            value: _formatCapital(clientStats!.averageCapitalPerClient),
            subtitle: _getAverageCapitalStatus(),
            icon: Icons.analytics,
            color: AppTheme.infoColor,
            isCompact: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Wskaźnik Aktywności',
            value: '${_getActivityRate().toStringAsFixed(1)}%',
            subtitle: _getActivityStatus(),
            icon: Icons.local_fire_department,
            color: AppTheme.warningColor,
            isCompact: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Kapitalizacja',
            value: _getCapitalizationLevel(),
            subtitle: 'Poziom inwestycji',
            icon: Icons.business_center,
            color: AppTheme.successColor,
            isCompact: true,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? trend,
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: isCompact ? 16 : 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: isCompact ? 11 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isCompact ? 6 : 8),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: isCompact ? 16 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isCompact ? 2 : 4),
          Text(
            subtitle,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: isCompact ? 9 : 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceInfo() {
    if (clientStats == null) return const SizedBox.shrink();

    final source = clientStats!.source;
    Color sourceColor;
    IconData sourceIcon;
    String sourceText;
    String description;

    switch (source) {
      case 'firebase-functions':
        sourceColor = AppTheme.successColor;
        sourceIcon = Icons.cloud_done;
        sourceText = 'Firebase Functions';
        description = 'Dane w czasie rzeczywistym z serwera';
        break;
      case 'unified-statistics-direct':
        sourceColor = AppTheme.infoColor;
        sourceIcon = Icons.analytics;
        sourceText = 'Zunifikowane Statystyki';
        description = 'Obliczenia zgodne z STATISTICS_UNIFICATION_GUIDE';
        break;
      case 'advanced-fallback':
        sourceColor = AppTheme.warningColor;
        sourceIcon = Icons.cached;
        sourceText = 'Zaawansowany Fallback';
        description = 'Kombinacja cache i obliczenia na żywo';
        break;
      case 'basic-fallback':
        sourceColor = AppTheme.errorColor;
        sourceIcon = Icons.warning;
        sourceText = 'Podstawowy Fallback';
        description = 'Ograniczone dane, sprawdź połączenie';
        break;
      default:
        sourceColor = AppTheme.textSecondary;
        sourceIcon = Icons.help;
        sourceText = 'Nieznane źródło';
        description = 'Nietypowy stan systemu';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sourceColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: sourceColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(sourceIcon, color: sourceColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sourceText,
                  style: TextStyle(
                    color: sourceColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: sourceColor.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Zaktualizowano: ${_formatLastUpdated()}',
            style: TextStyle(
              color: sourceColor.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Metody pomocnicze do obliczania wskaźników

  String _getClientTypeBreakdown() {
    // Symulacja podziału na typy klientów
    if (clientStats == null) return '';
    return 'Indywidualni + Firmy';
  }

  String _getClientTrend() {
    // Symulacja trendu wzrostu
    return '+2.3%';
  }

  String _getInvestmentTrend() {
    return '+5.1%';
  }

  String _getCapitalTrend() {
    return '+12.4%';
  }

  String _getInvestmentRatio() {
    if (clientStats == null || clientStats!.totalClients == 0) {
      return '0.0';
    }
    return (clientStats!.totalInvestments / clientStats!.totalClients)
        .toStringAsFixed(1);
  }

  String _getCapitalStatus() {
    if (clientStats == null) return '';
    final capital = clientStats!.totalRemainingCapital;
    if (capital == 0) return 'Brak aktywnych';
    if (capital < 1000000) return 'Poniżej 1M PLN';
    if (capital < 10000000) return 'Średnia kapitalizacja';
    return 'Wysoka kapitalizacja';
  }

  Color _getCapitalColor() {
    if (clientStats == null) return AppTheme.successColor;

    final capital = clientStats!.totalRemainingCapital;
    if (capital == 0) return AppTheme.errorColor;
    if (capital < 1000000) return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  String _getAverageCapitalStatus() {
    if (clientStats == null) return '';
    final avg = clientStats!.averageCapitalPerClient;
    if (avg == 0) return 'Brak kapitału';
    if (avg < 25000) return 'Niski poziom';
    if (avg < 100000) return 'Standardowy poziom';
    return 'Wysoki poziom';
  }

  double _getActivityRate() {
    if (clientStats == null || clientStats!.totalClients == 0) return 0.0;
    // Symulowana aktywność na podstawie stosunku inwestycji do klientów
    return (clientStats!.totalInvestments / clientStats!.totalClients) * 30.0;
  }

  String _getActivityStatus() {
    final rate = _getActivityRate();
    if (rate < 20) return 'Niska aktywność';
    if (rate < 50) return 'Średnia aktywność';
    return 'Wysoka aktywność';
  }

  String _getCapitalizationLevel() {
    if (clientStats == null) return 'Brak';
    final capital = clientStats!.totalRemainingCapital;
    if (capital < 1000000) return 'Mała';
    if (capital < 10000000) return 'Średnia';
    if (capital < 50000000) return 'Duża';
    return 'Bardzo duża';
  }

  String _formatCapital(double capital) {
    if (capital >= 1000000) {
      return '${(capital / 1000000).toStringAsFixed(1)}M PLN';
    } else if (capital >= 1000) {
      return '${(capital / 1000).toStringAsFixed(1)}K PLN';
    } else {
      return '${capital.toStringAsFixed(0)} PLN';
    }
  }

  String _formatLastUpdated() {
    if (clientStats == null) return '';

    try {
      final lastUpdated = DateTime.parse(clientStats!.lastUpdated);
      final now = DateTime.now();
      final difference = now.difference(lastUpdated);

      if (difference.inMinutes < 1) {
        return 'przed chwilą';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m temu';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h temu';
      } else {
        return '${difference.inDays}d temu';
      }
    } catch (e) {
      return 'nieznana';
    }
  }
}
