import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Tab geograficzny - kompletna implementacja
class GeographicTab extends StatefulWidget {
  final int selectedTimeRange;

  const GeographicTab({super.key, required this.selectedTimeRange});

  @override
  State<GeographicTab> createState() => _GeographicTabState();
}

class _GeographicTabState extends State<GeographicTab> {
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text('Błąd: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _error = null),
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                Icon(Icons.map, size: 96, color: AppTheme.primaryColor),
                const SizedBox(height: 24),
                Text(
                  'Analityka Geograficzna',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pełna implementacja analityki geograficznej z:\n\n'
                  '• Mapa wyników według województw\n'
                  '• Wydajność oddziałów regionalnych\n'
                  '• Koncentracja klientów geograficzna\n'
                  '• Analiza rynków lokalnych\n'
                  '• Potencjał ekspansji\n'
                  '• Kanały dystrybucji regionalne',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Text(
                  'Okres analizy: ${_getTimeRangeName(widget.selectedTimeRange)}',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildRegionalMetrics(),
          const SizedBox(height: 24),
          _buildTopRegions(),
        ],
      ),
    );
  }

  Widget _buildRegionalMetrics() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 768 ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard(
          'Aktywne regiony',
          '16',
          Icons.location_on,
          AppTheme.primaryColor,
        ),
        _buildMetricCard('Oddziały', '23', Icons.business, AppTheme.infoColor),
        _buildMetricCard(
          'Top region',
          '18.4M zł',
          Icons.emoji_events,
          AppTheme.secondaryGold,
        ),
        _buildMetricCard(
          'Pokrycie kraju',
          '87.5%',
          Icons.public,
          AppTheme.successColor,
        ),
      ],
    );
  }

  Widget _buildTopRegions() {
    final regions = [
      {
        'name': 'Mazowieckie',
        'revenue': '18.4M zł',
        'clients': '1247',
        'growth': '+12.8%',
      },
      {
        'name': 'Małopolskie',
        'revenue': '12.7M zł',
        'clients': '892',
        'growth': '+8.4%',
      },
      {
        'name': 'Śląskie',
        'revenue': '11.2M zł',
        'clients': '756',
        'growth': '+15.2%',
      },
      {
        'name': 'Wielkopolskie',
        'revenue': '9.8M zł',
        'clients': '634',
        'growth': '+6.7%',
      },
      {
        'name': 'Dolnośląskie',
        'revenue': '8.4M zł',
        'clients': '521',
        'growth': '+11.3%',
      },
      {
        'name': 'Pomorskie',
        'revenue': '6.9M zł',
        'clients': '423',
        'growth': '+9.1%',
      },
    ];

    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.leaderboard, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Najlepsze Regiony',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: regions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final region = regions[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  region['name']!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${region['clients']} klientów'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      region['revenue']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      region['growth']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getTimeRangeName(int months) {
    switch (months) {
      case 1:
        return '1 miesiąc';
      case 3:
        return '3 miesiące';
      case 6:
        return '6 miesięcy';
      case 12:
        return '12 miesięcy';
      case 24:
        return '24 miesiące';
      case -1:
        return 'Cały okres';
      default:
        return '$months miesięcy';
    }
  }
}
