import 'package:flutter/material.dart';
import '../models_and_services.dart';

/// Widget wyświetlający statystyki klientów - używany w różnych miejscach aplikacji
/// Zgodny z zunifikowanym systemem statystyk (STATISTICS_UNIFICATION_GUIDE)
class ClientStatsWidget extends StatelessWidget {
  final ClientStats? clientStats;
  final bool isLoading;
  final bool isCompact;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final bool showSourceInfo;

  const ClientStatsWidget({
    super.key,
    this.clientStats,
    this.isLoading = false,
    this.isCompact = false,
    this.padding,
    this.backgroundColor,
    this.showSourceInfo = false,
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
      padding:
          padding ??
          (isCompact
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
      decoration: backgroundColor != null
          ? BoxDecoration(color: backgroundColor)
          : BoxDecoration(
              color: AppTheme.backgroundSecondary,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderSecondary, width: 1),
              ),
            ),
      child: Column(
        children: [
          isCompact ? _buildCompactLayout() : _buildFullLayout(),
          if (showSourceInfo && clientStats != null) ...[
            const SizedBox(height: 8),
            _buildSourceInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSecondary, width: 1),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 16),
          Text(
            'Ładowanie statystyk klientów...',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFullLayout() {
    return Row(
      children: [
        _buildStatChip(
          icon: Icons.people,
          label: 'Łącznie klientów',
          value: '${clientStats!.totalClients}',
          color: AppTheme.primaryColor,
          subtitle: _getClientStatusText(),
        ),
        const SizedBox(width: 16),
        _buildStatChip(
          icon: Icons.trending_up,
          label: 'Inwestycje',
          value: '${clientStats!.totalInvestments}',
          color: AppTheme.secondaryGold,
          subtitle: _getInvestmentStatusText(),
        ),
        const SizedBox(width: 16),
        _buildStatChip(
          icon: Icons.account_balance_wallet,
          label: 'Kapitał pozostały',
          value: _formatRemainingCapital(clientStats!.totalRemainingCapital),
          color: _getCapitalColor(),
          subtitle: 'Zunifikowane obliczenia',
        ),
        const SizedBox(width: 16),
        _buildStatChip(
          icon: Icons.analytics,
          label: 'Średnia na klienta',
          value: _formatAverageCapital(clientStats!.averageCapitalPerClient),
          color: AppTheme.infoColor,
          subtitle: _getAverageStatusText(),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCompactStat(
          icon: Icons.people,
          value: '${clientStats!.totalClients}',
          label: 'Klienci',
          color: AppTheme.primaryColor,
        ),
        _buildCompactStat(
          icon: Icons.trending_up,
          value: '${clientStats!.totalInvestments}',
          label: 'Inwestycje',
          color: AppTheme.secondaryGold,
        ),
        _buildCompactStat(
          icon: Icons.account_balance_wallet,
          value: _formatRemainingCapitalShort(
            clientStats!.totalRemainingCapital,
          ),
          label: 'Kapitał',
          color: AppTheme.successColor,
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatRemainingCapital(double capital) {
    if (capital >= 1000000) {
      return '${(capital / 1000000).toStringAsFixed(1)}M PLN';
    } else if (capital >= 1000) {
      return '${(capital / 1000).toStringAsFixed(1)}K PLN';
    } else {
      return '${capital.toStringAsFixed(0)} PLN';
    }
  }

  String _formatRemainingCapitalShort(double capital) {
    if (capital >= 1000000) {
      return '${(capital / 1000000).toStringAsFixed(1)}M';
    } else if (capital >= 1000) {
      return '${(capital / 1000).toStringAsFixed(1)}K';
    } else {
      return '${capital.toStringAsFixed(0)}';
    }
  }

  String _formatAverageCapital(double capital) {
    return _formatRemainingCapital(capital);
  }

  /// Pobranie koloru dla kapitału na podstawie jego wartości
  Color _getCapitalColor() {
    if (clientStats == null) return AppTheme.successColor;

    final capital = clientStats!.totalRemainingCapital;
    if (capital == 0) return AppTheme.errorColor;
    if (capital < 100000) return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  /// Tekst statusu dla klientów
  String _getClientStatusText() {
    if (clientStats == null) return '';
    return clientStats!.source == 'firebase-functions' ? 'Live' : 'Cache';
  }

  /// Tekst statusu dla inwestycji
  String _getInvestmentStatusText() {
    if (clientStats == null) return '';
    return clientStats!.totalClients > 0
        ? '${(clientStats!.totalInvestments / clientStats!.totalClients).toStringAsFixed(1)}/klient'
        : 'Brak danych';
  }

  /// Tekst statusu dla średniej
  String _getAverageStatusText() {
    if (clientStats == null) return '';
    final avg = clientStats!.averageCapitalPerClient;
    if (avg == 0) return 'Brak kapitału';
    return avg > 50000 ? 'Wysoka' : 'Standardowa';
  }

  /// Informacje o źródle danych
  Widget _buildSourceInfo() {
    if (clientStats == null) return const SizedBox.shrink();

    final source = clientStats!.source;
    Color sourceColor;
    IconData sourceIcon;
    String sourceText;

    switch (source) {
      case 'firebase-functions':
        sourceColor = AppTheme.successColor;
        sourceIcon = Icons.cloud_done;
        sourceText = 'Firebase Functions';
        break;
      case 'unified-statistics-direct':
        sourceColor = AppTheme.infoColor;
        sourceIcon = Icons.analytics;
        sourceText = 'Zunifikowane statystyki';
        break;
      case 'advanced-fallback':
        sourceColor = AppTheme.warningColor;
        sourceIcon = Icons.cached;
        sourceText = 'Zaawansowany fallback';
        break;
      case 'basic-fallback':
        sourceColor = AppTheme.errorColor;
        sourceIcon = Icons.warning;
        sourceText = 'Podstawowy fallback';
        break;
      default:
        sourceColor = AppTheme.textSecondary;
        sourceIcon = Icons.help;
        sourceText = 'Nieznane źródło';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: sourceColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: sourceColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(sourceIcon, color: sourceColor, size: 12),
          const SizedBox(width: 4),
          Text(
            '$sourceText • Zaktualizowano: ${_formatLastUpdated()}',
            style: TextStyle(
              color: sourceColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Formatowanie czasu ostatniej aktualizacji
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
