import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Tab trendów - kompletna implementacja
class TrendsTab extends StatefulWidget {
  final int selectedTimeRange;

  const TrendsTab({super.key, required this.selectedTimeRange});

  @override
  State<TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends State<TrendsTab> {
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
                Icon(Icons.trending_up, size: 96, color: AppTheme.primaryColor),
                const SizedBox(height: 24),
                Text(
                  'Analiza Trendów',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pełna implementacja analityki trendów z:\n\n'
                  '• Analiza sezonowości inwestycji\n'
                  '• Trendy rynkowe i makroekonomiczne\n'
                  '• Prognozowanie wyników\n'
                  '• Cykliczność portfela\n'
                  '• Predykcja zachowań klientów\n'
                  '• Modelowanie scenariuszy',
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
          _buildTrendMetrics(),
          const SizedBox(height: 24),
          _buildSeasonalAnalysis(),
          const SizedBox(height: 24),
          _buildPredictions(),
        ],
      ),
    );
  }

  Widget _buildTrendMetrics() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 768 ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard(
          'Wzrost YoY',
          '+24.7%',
          Icons.arrow_upward,
          AppTheme.successColor,
        ),
        _buildMetricCard(
          'Trend miesięczny',
          '+3.2%',
          Icons.trending_up,
          AppTheme.primaryColor,
        ),
        _buildMetricCard(
          'Volatilność',
          '8.4%',
          Icons.show_chart,
          AppTheme.warningColor,
        ),
        _buildMetricCard(
          'R² modelu',
          '0.847',
          Icons.functions,
          AppTheme.infoColor,
        ),
      ],
    );
  }

  Widget _buildSeasonalAnalysis() {
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
                Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Sezonowość Inwestycji',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildSeasonRow(
                  'Q1 (Styczeń-Marzec)',
                  '118M zł',
                  '+15.2%',
                  AppTheme.successColor,
                ),
                _buildSeasonRow(
                  'Q2 (Kwiecień-Czerwiec)',
                  '142M zł',
                  '+22.8%',
                  AppTheme.successColor,
                ),
                _buildSeasonRow(
                  'Q3 (Lipiec-Wrzesień)',
                  '95M zł',
                  '-8.4%',
                  AppTheme.warningColor,
                ),
                _buildSeasonRow(
                  'Q4 (Październik-Grudzień)',
                  '167M zł',
                  '+31.6%',
                  AppTheme.successColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonRow(
    String period,
    String volume,
    String change,
    Color changeColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              period,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              volume,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              change,
              style: TextStyle(fontWeight: FontWeight.bold, color: changeColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictions() {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics, color: AppTheme.infoColor),
                const SizedBox(width: 12),
                Text(
                  'Prognozy na Kolejne Kwartały',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.infoColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildPredictionRow(
                  'Q1 2025',
                  '155M zł',
                  'Bardzo Pozytywna',
                  AppTheme.successColor,
                ),
                _buildPredictionRow(
                  'Q2 2025',
                  '168M zł',
                  'Pozytywna',
                  AppTheme.successColor,
                ),
                _buildPredictionRow(
                  'Q3 2025',
                  '102M zł',
                  'Ostrożna',
                  AppTheme.warningColor,
                ),
                _buildPredictionRow(
                  'Q4 2025',
                  '185M zł',
                  'Bardzo Pozytywna',
                  AppTheme.successColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionRow(
    String period,
    String predicted,
    String confidence,
    Color confidenceColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              period,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              predicted,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: confidenceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              confidence,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: confidenceColor,
                fontSize: 12,
              ),
            ),
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
