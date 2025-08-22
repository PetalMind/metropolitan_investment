import 'package:flutter/material.dart';
import '../../../theme/app_theme_professional.dart';

/// Tab zespołu - profesjonalna implementacja z AppThemePro
class EmployeesTab extends StatefulWidget {
  final int selectedTimeRange;

  const EmployeesTab({super.key, required this.selectedTimeRange});

  @override
  State<EmployeesTab> createState() => _EmployeesTabState();
}

class _EmployeesTabState extends State<EmployeesTab>
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
              'Analizowanie danych zespołu...',
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
            _buildTeamMetricsGrid(),
            const SizedBox(height: 24),
            _buildTopPerformersCard(),
            const SizedBox(height: 24),
            _buildTeamAnalysisCard(),
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
              color: AppThemePro.statusSuccess.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: AppThemePro.statusSuccess.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.people,
              size: 64,
              color: AppThemePro.statusSuccess,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Analityka Zespołu',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppThemePro.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Kompleksowa analiza wydajności zespołu sprzedażowego\n'
            'z metrykami konwersji, retencji i progresji kariery',
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

  Widget _buildTeamMetricsGrid() {
    final isTablet = MediaQuery.of(context).size.width > 768;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isTablet ? 3 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isTablet ? 1.3 : 1.1,
      children: [
        _buildTeamMetricCard(
          'Aktywni Pracownicy',
          '47',
          '+3 w tym miesiącu',
          Icons.person,
          AppThemePro.statusInfo,
        ),
        _buildTeamMetricCard(
          'Średnia Sprzedaż',
          '2.84M zł',
          '+12.5% vs poprzedni okres',
          Icons.trending_up,
          AppThemePro.statusSuccess,
        ),
        _buildTeamMetricCard(
          'Top Performer',
          '8.92M zł',
          'Anna Kowalska',
          Icons.emoji_events,
          AppThemePro.accentGold,
        ),
        _buildTeamMetricCard(
          'Retencja Klientów',
          '94.2%',
          'Doskonały wynik',
          Icons.favorite,
          AppThemePro.statusSuccess,
        ),
        _buildTeamMetricCard(
          'Wskaźnik Konwersji',
          '67.8%',
          '+4.2% vs cel',
          Icons.swap_horiz,
          AppThemePro.statusWarning,
        ),
        _buildTeamMetricCard(
          'Nowi Klienci',
          '128',
          'W tym okresie',
          Icons.person_add,
          AppThemePro.statusInfo,
        ),
      ],
    );
  }

  Widget _buildTeamMetricCard(
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

  Widget _buildTopPerformersCard() {
    final topPerformers = [
      {
        'name': 'Anna Kowalska',
        'sales': '8.92M zł',
        'clients': '156',
        'conversion': '84.2%',
        'position': 1,
      },
      {
        'name': 'Marcin Nowak',
        'sales': '7.68M zł',
        'clients': '142',
        'conversion': '79.1%',
        'position': 2,
      },
      {
        'name': 'Katarzyna Wiśniewska',
        'sales': '6.84M zł',
        'clients': '128',
        'conversion': '76.8%',
        'position': 3,
      },
      {
        'name': 'Piotr Kowalczyk',
        'sales': '6.12M zł',
        'clients': '119',
        'conversion': '73.4%',
        'position': 4,
      },
      {
        'name': 'Magdalena Zielińska',
        'sales': '5.87M zł',
        'clients': '108',
        'conversion': '71.9%',
        'position': 5,
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
                  'Top 5 Pracowników',
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
            itemCount: topPerformers.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: AppThemePro.borderPrimary),
            itemBuilder: (context, index) {
              final performer = topPerformers[index];
              final position = performer['position'] as int;
              Color positionColor;

              switch (position) {
                case 1:
                  positionColor = AppThemePro.accentGold;
                  break;
                case 2:
                  positionColor = AppThemePro.textSecondary;
                  break;
                case 3:
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
                          '$position',
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
                            performer['name'] as String,
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
                                '${performer['clients']} klientów',
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
                                '${performer['conversion']} konwersja',
                                style: TextStyle(
                                  color: AppThemePro.statusSuccess,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
                          performer['sales'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: positionColor,
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

  Widget _buildTeamAnalysisCard() {
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
                  'Analiza Zespołowa',
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
                  'Średni czas zamknięcia transakcji',
                  '12.4 dni',
                  '-2.1 dni vs poprzedni okres',
                  AppThemePro.statusSuccess,
                  Icons.schedule,
                ),
                _buildAnalysisRow(
                  'Wskaźnik satysfakcji klientów',
                  '4.7/5.0',
                  '+0.3 punktu vs cel',
                  AppThemePro.statusSuccess,
                  Icons.star,
                ),
                _buildAnalysisRow(
                  'Średnia wartość transakcji',
                  '127K zł',
                  '+18.5% vs poprzedni okres',
                  AppThemePro.statusSuccess,
                  Icons.account_balance,
                ),
                _buildAnalysisRow(
                  'Rotacja zespołu',
                  '3.2%',
                  'Bardzo niski wskaźnik',
                  AppThemePro.statusSuccess,
                  Icons.people_alt,
                ),
                _buildAnalysisRow(
                  'Efektywność szkoleń',
                  '89.4%',
                  'Ukończenie programu',
                  AppThemePro.statusSuccess,
                  Icons.school,
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
