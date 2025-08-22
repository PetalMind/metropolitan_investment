import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/analytics/overview_analytics_models.dart';
import '../../../utils/currency_formatter.dart';

/// Widget karty podsumowania klientów
class ClientSummaryCard extends StatelessWidget {
  final ClientMetricsData clientMetrics;

  const ClientSummaryCard({super.key, required this.clientMetrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Statystyki klientów',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Icon(Icons.people, color: AppTheme.primaryColor),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            'Łączna liczba klientów',
            '${clientMetrics.totalClients}',
            Icons.people,
          ),
          _buildStatItem(
            'Aktywni klienci',
            '${clientMetrics.activeClients}',
            Icons.person_outline,
          ),
          _buildStatItem(
            'Nowi klienci (miesiąc)',
            '${clientMetrics.newClientsThisMonth}',
            Icons.person_add,
          ),
          _buildStatItem(
            'Retencja klientów',
            '${clientMetrics.clientRetentionRate.toStringAsFixed(1)}%',
            Icons.favorite,
          ),
          _buildStatItem(
            'Średnia wartość klienta',
            CurrencyFormatter.formatCurrencyShort(
              clientMetrics.averageClientValue,
            ),
            Icons.account_balance_wallet,
          ),
          if (clientMetrics.topClients.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Top 3 klientów',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            ...clientMetrics.topClients
                .take(3)
                .map((client) => _buildTopClientItem(client))
                ,
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopClientItem(TopClientItem client) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name.length > 25
                      ? '${client.name.substring(0, 25)}...'
                      : client.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${client.investmentCount} inwestycji',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.formatCurrencyShort(client.value),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
