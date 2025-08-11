import 'package:flutter/material.dart';
import '../../../theme/app_theme_professional.dart';

/// Tab ryzyka - profesjonalna implementacja z AppThemePro
class RiskTab extends StatefulWidget {
  final int selectedTimeRange;

  const RiskTab({super.key, required this.selectedTimeRange});

  @override
  State<RiskTab> createState() => _RiskTabState();
}

class _RiskTabState extends State<RiskTab> with TickerProviderStateMixin {
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
              'Analizowanie metryk ryzyka...',
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
            _buildRiskMetricsGrid(),
            const SizedBox(height: 24),
            _buildRiskAnalysisDetails(),
            const SizedBox(height: 24),
            _buildStressTestResults(),
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
              color: AppThemePro.statusWarning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: AppThemePro.statusWarning.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.security,
              size: 64,
              color: AppThemePro.statusWarning,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Analiza Ryzyka Portfela',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppThemePro.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Komprehensywna analiza ryzyka finansowego z wykorzystaniem\n'
            'zaawansowanych metryk i modeli statystycznych',
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

  Widget _buildRiskMetricsGrid() {
    final isTablet = MediaQuery.of(context).size.width > 768;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isTablet ? 3 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isTablet ? 1.3 : 1.1,
      children: [
        _buildRiskMetricCard(
          'Value at Risk (95%)',
          '5.24%',
          '~2.8M zł',
          Icons.warning_amber,
          AppThemePro.statusError,
        ),
        _buildRiskMetricCard(
          'Volatilność Portfela',
          '12.84%',
          'Umiarkowana',
          Icons.show_chart,
          AppThemePro.statusWarning,
        ),
        _buildRiskMetricCard(
          'Maximum Drawdown',
          '8.67%',
          'Akceptowalne',
          Icons.trending_down,
          AppThemePro.statusInfo,
        ),
        _buildRiskMetricCard(
          'Koncentracja Ryzyka',
          '23.12%',
          'Zdywersyfikowany',
          Icons.pie_chart,
          AppThemePro.accentGold,
        ),
        _buildRiskMetricCard(
          'Beta Portfela',
          '1.15',
          'vs. Rynek',
          Icons.timeline,
          AppThemePro.statusInfo,
        ),
        _buildRiskMetricCard(
          'Sharpe Ratio',
          '1.847',
          'Doskonały',
          Icons.functions,
          AppThemePro.statusSuccess,
        ),
      ],
    );
  }

  Widget _buildRiskMetricCard(
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
            style: TextStyle(
              fontSize: 12,
              color: AppThemePro.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAnalysisDetails() {
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
                  'Szczegółowa Analiza Ryzyka',
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
                _buildRiskDetailRow(
                  'Ryzyko Kredytowe',
                  'Niskie',
                  '2.1%',
                  AppThemePro.statusSuccess,
                  Icons.account_balance,
                ),
                _buildRiskDetailRow(
                  'Ryzyko Płynności',
                  'Umiarkowane',
                  '7.3%',
                  AppThemePro.statusWarning,
                  Icons.water_drop,
                ),
                _buildRiskDetailRow(
                  'Ryzyko Rynkowe',
                  'Podwyższone',
                  '15.8%',
                  AppThemePro.statusError,
                  Icons.trending_up,
                ),
                _buildRiskDetailRow(
                  'Ryzyko Operacyjne',
                  'Kontrolowane',
                  '4.2%',
                  AppThemePro.statusSuccess,
                  Icons.settings,
                ),
                _buildRiskDetailRow(
                  'Ryzyko Regulacyjne',
                  'Minimalne',
                  '1.8%',
                  AppThemePro.statusSuccess,
                  Icons.gavel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDetailRow(
    String riskType,
    String assessment,
    String percentage,
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
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riskType,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppThemePro.textPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  assessment,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Text(
              percentage,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStressTestResults() {
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
                  AppThemePro.statusError.withOpacity(0.1),
                  AppThemePro.statusWarning.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.science, color: AppThemePro.statusError, size: 28),
                const SizedBox(width: 16),
                Text(
                  'Testy Stresowe',
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
                _buildStressTestRow(
                  'Krach rynkowy (-30%)',
                  '-18.4M zł',
                  '-24.7%',
                  AppThemePro.statusError,
                ),
                _buildStressTestRow(
                  'Recesja gospodarcza',
                  '-12.8M zł',
                  '-17.2%',
                  AppThemePro.statusWarning,
                ),
                _buildStressTestRow(
                  'Kryzys płynności',
                  '-8.9M zł',
                  '-11.9%',
                  AppThemePro.statusWarning,
                ),
                _buildStressTestRow(
                  'Wzrost stóp procentowych',
                  '-6.2M zł',
                  '-8.3%',
                  AppThemePro.statusInfo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStressTestRow(
    String scenario,
    String impact,
    String percentage,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              scenario,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppThemePro.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                impact,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
              Text(
                percentage,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
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
