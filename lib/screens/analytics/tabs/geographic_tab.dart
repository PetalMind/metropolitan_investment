import 'package:flutter/material.dart';
import '../../../theme/app_theme_professional.dart';

/// Tab geograficzny - profesjonalna implementacja z AppThemePro
class GeographicTab extends StatefulWidget {
  final int selectedTimeRange;

  const GeographicTab({super.key, required this.selectedTimeRange});

  @override
  State<GeographicTab> createState() => _GeographicTabState();
}

class _GeographicTabState extends State<GeographicTab>
    with TickerProviderStateMixin {
  final bool _isLoading = false;
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
              'Analizowanie danych geograficznych...',
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
            _buildGeographicMetrics(),
            const SizedBox(height: 24),
            _buildTopRegions(),
            const SizedBox(height: 24),
            _buildRegionalAnalysis(),
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
              color: AppThemePro.statusInfo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: AppThemePro.statusInfo.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(Icons.public, size: 64, color: AppThemePro.statusInfo),
          ),
          const SizedBox(height: 24),
          Text(
            'Analityka Geograficzna',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppThemePro.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Kompleksowa analiza geograficzna z rozłożeniem wyników\n'
            'według regionów, potencjałem ekspansji i mapą rynków',
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

  Widget _buildGeographicMetrics() {
    final isTablet = MediaQuery.of(context).size.width > 768;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isTablet ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isTablet ? 1.3 : 1.1,
      children: [
        _buildGeographicMetricCard(
          'Aktywne Regiony',
          '16',
          'z 16 województw',
          Icons.location_on,
          AppThemePro.statusSuccess,
        ),
        _buildGeographicMetricCard(
          'Oddziały',
          '23',
          'Punkty sprzedaży',
          Icons.business,
          AppThemePro.statusInfo,
        ),
        _buildGeographicMetricCard(
          'Top Region',
          '18.4M zł',
          'Mazowieckie',
          Icons.emoji_events,
          AppThemePro.accentGold,
        ),
        _buildGeographicMetricCard(
          'Pokrycie Kraju',
          '87.5%',
          'Populacji objętej',
          Icons.map,
          AppThemePro.statusSuccess,
        ),
      ],
    );
  }

  Widget _buildGeographicMetricCard(
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

  Widget _buildTopRegions() {
    final regions = [
      {
        'name': 'Mazowieckie',
        'revenue': '18.4M zł',
        'clients': '1,247',
        'growth': '+12.8%',
        'share': '28.4%',
      },
      {
        'name': 'Małopolskie',
        'revenue': '12.7M zł',
        'clients': '892',
        'growth': '+8.4%',
        'share': '19.6%',
      },
      {
        'name': 'Śląskie',
        'revenue': '11.2M zł',
        'clients': '756',
        'growth': '+15.2%',
        'share': '17.3%',
      },
      {
        'name': 'Wielkopolskie',
        'revenue': '9.8M zł',
        'clients': '634',
        'growth': '+6.7%',
        'share': '15.1%',
      },
      {
        'name': 'Dolnośląskie',
        'revenue': '8.4M zł',
        'clients': '521',
        'growth': '+11.3%',
        'share': '12.9%',
      },
      {
        'name': 'Pomorskie',
        'revenue': '6.9M zł',
        'clients': '423',
        'growth': '+9.1%',
        'share': '10.6%',
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
                  AppThemePro.accentGold.withOpacity(0.1),
                  AppThemePro.statusSuccess.withOpacity(0.05),
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
                  Icons.leaderboard,
                  color: AppThemePro.accentGold,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Text(
                  'Najlepsze Regiony',
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
            itemCount: regions.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: AppThemePro.borderPrimary),
            itemBuilder: (context, index) {
              final region = regions[index];
              Color positionColor;

              switch (index) {
                case 0:
                  positionColor = AppThemePro.accentGold;
                  break;
                case 1:
                  positionColor = AppThemePro.textSecondary;
                  break;
                case 2:
                  positionColor = AppThemePro.statusWarning;
                  break;
                default:
                  positionColor = AppThemePro.statusInfo;
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: positionColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: positionColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: positionColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            region['name'] as String,
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
                                '${region['clients']} klientów',
                                style: TextStyle(
                                  color: AppThemePro.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                ' • ',
                                style: TextStyle(color: AppThemePro.textMuted),
                              ),
                              Text(
                                '${region['share']} udziału',
                                style: TextStyle(
                                  color: AppThemePro.textSecondary,
                                  fontSize: 12,
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
                          region['revenue'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: positionColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppThemePro.statusSuccess.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            region['growth'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppThemePro.statusSuccess,
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

  Widget _buildRegionalAnalysis() {
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
                Icon(Icons.analytics, color: AppThemePro.statusInfo, size: 28),
                const SizedBox(width: 16),
                Text(
                  'Analiza Regionalna',
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
                  'Penetracja rynku',
                  '23.7%',
                  'Średnia dla wszystkich regionów',
                  AppThemePro.statusSuccess,
                  Icons.trending_up,
                ),
                _buildAnalysisRow(
                  'Potencjał wzrostu',
                  'Wysoki',
                  'Szczególnie w regionach wschodnich',
                  AppThemePro.statusWarning,
                  Icons.landscape,
                ),
                _buildAnalysisRow(
                  'Konkurencja regionalna',
                  'Umiarkowana',
                  'Silna w dużych miastach',
                  AppThemePro.statusInfo,
                  Icons.group_work,
                ),
                _buildAnalysisRow(
                  'Efektywność kanałów',
                  '78.4%',
                  'Powyżej średniej krajowej',
                  AppThemePro.statusSuccess,
                  Icons.route,
                ),
                _buildAnalysisRow(
                  'Sezonowość regionalna',
                  'Stabilna',
                  'Niskie wahania międzysezonowe',
                  AppThemePro.statusSuccess,
                  Icons.calendar_today,
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
