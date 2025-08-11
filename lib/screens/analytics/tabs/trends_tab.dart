import 'package:flutter/material.dart';
import '../../../theme/app_theme_professional.dart';

/// Tab trendów - profesjonalna implementacja z AppThemePro
class TrendsTab extends StatefulWidget {
  final int selectedTimeRange;

  const TrendsTab({super.key, required this.selectedTimeRange});

  @override
  State<TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends State<TrendsTab> with TickerProviderStateMixin {
  bool _isLoading = false;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppThemePro.accentGold,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Analizowanie trendów rynkowych...',
              style: TextStyle(color: AppThemePro.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppThemePro.statusError),
            const SizedBox(height: 16),
            Text(
              'Błąd ładowania danych',
              style: TextStyle(
                color: AppThemePro.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: AppThemePro.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() => _error = null),
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemePro.accentGold,
                foregroundColor: AppThemePro.primaryDark,
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            _buildTrendMetrics(),
            const SizedBox(height: 24),
            _buildTrendPredictions(),
            const SizedBox(height: 24),
            _buildMarketAnalysis(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemePro.accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: AppThemePro.accentGold.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.trending_up,
              size: 64,
              color: AppThemePro.accentGold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Analiza Trendów',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppThemePro.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Zaawansowana analiza trendów rynkowych z prognozami,\n'
            'identyfikacją wzorców i predykcją zachowań',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppThemePro.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppThemePro.accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppThemePro.accentGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              'Okres analizy: ${_getTimeRangeName(widget.selectedTimeRange)}',
              style: TextStyle(
                color: AppThemePro.accentGold,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendMetrics() {
    final isTablet = MediaQuery.of(context).size.width > 768;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isTablet ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isTablet ? 1.3 : 1.1,
      children: [
        _buildTrendMetricCard(
          'Trend Główny',
          '+12.4%',
          'Wzrostowy',
          Icons.trending_up,
          AppThemePro.statusSuccess,
        ),
        _buildTrendMetricCard(
          'Volatilność',
          '8.7%',
          'Umiarkowana',
          Icons.show_chart,
          AppThemePro.statusWarning,
        ),
        _buildTrendMetricCard(
          'Prognoza 3M',
          '+18.2%',
          'Optymistyczna',
          Icons.trending_up,
          AppThemePro.statusSuccess,
        ),
        _buildTrendMetricCard(
          'Współczynnik R²',
          '0.847',
          'Wysokie dopasowanie',
          Icons.analytics,
          AppThemePro.accentGold,
        ),
      ],
    );
  }

  Widget _buildTrendMetricCard(
    String title,
    String primaryValue,
    String secondaryValue,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.premiumCardDecoration.copyWith(
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            primaryValue,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppThemePro.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            secondaryValue,
            style: TextStyle(fontSize: 12, color: AppThemePro.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendPredictions() {
    final predictions = [
      {
        'period': 'Najbliższe 30 dni',
        'trend': 'Wzrostowy',
        'probability': '87.3%',
        'change': '+6.4%',
        'confidence': 'Wysoka',
        'icon': Icons.calendar_view_month,
        'color': AppThemePro.statusSuccess,
      },
      {
        'period': 'Następne 3 miesiące',
        'trend': 'Stabilizacja',
        'probability': '72.1%',
        'change': '+2.8%',
        'confidence': 'Średnia',
        'icon': Icons.calendar_view_week,
        'color': AppThemePro.statusInfo,
      },
      {
        'period': 'Półrocze',
        'trend': 'Korekta',
        'probability': '64.5%',
        'change': '-1.2%',
        'confidence': 'Średnia',
        'icon': Icons.date_range,
        'color': AppThemePro.statusWarning,
      },
      {
        'period': 'Długoterminowo (1 rok)',
        'trend': 'Wzrost',
        'probability': '79.8%',
        'change': '+15.7%',
        'confidence': 'Wysoka',
        'icon': Icons.timeline,
        'color': AppThemePro.accentGold,
      },
    ];

    return Container(
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppThemePro.statusSuccess.withOpacity(0.1),
                  AppThemePro.accentGold.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: AppThemePro.statusSuccess,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Text(
                  'Prognozy i Predykcje',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppThemePro.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: predictions.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: AppThemePro.borderPrimary),
            itemBuilder: (context, index) {
              final prediction = predictions[index];
              final color = prediction['color'] as Color;

              return Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        prediction['icon'] as IconData,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prediction['period'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppThemePro.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${prediction['trend']} • ',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Pewność: ${prediction['confidence']}',
                                style: TextStyle(
                                  color: AppThemePro.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          prediction['change'] as String,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            prediction['probability'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildMarketAnalysis() {
    return Container(
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppThemePro.statusInfo.withOpacity(0.1),
                  AppThemePro.accentGold.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.insights, color: AppThemePro.statusInfo, size: 28),
                const SizedBox(width: 16),
                Text(
                  'Analiza Rynkowa',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppThemePro.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildAnalysisRow(
                  'Momentum rynkowy',
                  'Silny wzrost',
                  'Pozytywne wskaźniki techniczne',
                  AppThemePro.statusSuccess,
                  Icons.rocket_launch,
                ),
                _buildAnalysisRow(
                  'Sentiment inwestorski',
                  'Optymistyczny',
                  'Indeks strachu i chciwości: 76/100',
                  AppThemePro.accentGold,
                  Icons.psychology_alt,
                ),
                _buildAnalysisRow(
                  'Cykle rynkowe',
                  'Faza wzrostowa',
                  'Początek cyklu hossy',
                  AppThemePro.statusSuccess,
                  Icons.autorenew,
                ),
                _buildAnalysisRow(
                  'Korelacje sektorowe',
                  'Wysokie',
                  'Wzrost w większości sektorów',
                  AppThemePro.statusInfo,
                  Icons.hub,
                ),
                _buildAnalysisRow(
                  'Wskaźniki makroekonomiczne',
                  'Stabilne',
                  'PKB +3.2%, inflacja pod kontrolą',
                  AppThemePro.statusSuccess,
                  Icons.trending_up,
                ),
                _buildAnalysisRow(
                  'Płynność rynku',
                  'Bardzo dobra',
                  'Wysokie wolumeny transakcji',
                  AppThemePro.statusSuccess,
                  Icons.water_drop,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(
    String metric,
    String value,
    String description,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppThemePro.textPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
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
