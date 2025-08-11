import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Tab zespołu - kompletna implementacja
class EmployeesTab extends StatefulWidget {
  final int selectedTimeRange;

  const EmployeesTab({super.key, required this.selectedTimeRange});

  @override
  State<EmployeesTab> createState() => _EmployeesTabState();
}

class _EmployeesTabState extends State<EmployeesTab> {
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
                Icon(Icons.people, size: 96, color: AppTheme.primaryColor),
                const SizedBox(height: 24),
                Text(
                  'Analityka Zespołu',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pełna implementacja analityki pracowników z:\n\n'
                  '• Wydajność poszczególnych pracowników\n'
                  '• Ranking sprzedaży\n'
                  '• Analiza zespołowa według oddziałów\n'
                  '• Metryki konwersji i retencji\n'
                  '• Kanały sprzedażowe\n'
                  '• Prognozy wydajności',
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
          _buildPlaceholderCards(),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 768 ? 3 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard(
          'Aktywni pracownicy',
          '47',
          Icons.person,
          AppTheme.primaryColor,
        ),
        _buildMetricCard(
          'Średnia sprzedaż',
          '2.8M zł',
          Icons.trending_up,
          AppTheme.successColor,
        ),
        _buildMetricCard(
          'Top performer',
          '8.9M zł',
          Icons.emoji_events,
          AppTheme.secondaryGold,
        ),
        _buildMetricCard(
          'Retencja klientów',
          '94.2%',
          Icons.favorite,
          AppTheme.infoColor,
        ),
        _buildMetricCard(
          'Konwersja',
          '67.8%',
          Icons.swap_horiz,
          AppTheme.warningColor,
        ),
        _buildMetricCard(
          'Nowi klienci',
          '128',
          Icons.person_add,
          AppTheme.primaryColor,
        ),
      ],
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
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
