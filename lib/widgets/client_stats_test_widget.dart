import 'package:flutter/material.dart';
import '../models_and_services.dart';

/// Widget testowy do debugowania statystyk klientów
class ClientStatsTestWidget extends StatefulWidget {
  const ClientStatsTestWidget({super.key});

  @override
  State<ClientStatsTestWidget> createState() => _ClientStatsTestWidgetState();
}

class _ClientStatsTestWidgetState extends State<ClientStatsTestWidget> {
  final IntegratedClientService _service = IntegratedClientService();
  ClientStats? _stats;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _testStats();
  }

  Future<void> _testStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _service.getClientStats(forceRefresh: true);

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: AppTheme.secondaryGold),
              const SizedBox(width: 8),
              Text(
                'Test Statystyk Klientów',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _testStats,
                icon: Icon(Icons.refresh, color: AppTheme.secondaryGold),
                tooltip: 'Odśwież test',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Testowanie...'),
              ],
            )
          else if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: AppTheme.errorColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Błąd: $_error',
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_stats != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTestResult(
                  'Klienci',
                  '${_stats!.totalClients}',
                  Icons.people,
                ),
                _buildTestResult(
                  'Inwestycje',
                  '${_stats!.totalInvestments}',
                  Icons.trending_up,
                ),
                _buildTestResult(
                  'Kapitał pozostały',
                  '${(_stats!.totalRemainingCapital / 1000000).toStringAsFixed(1)}M PLN',
                  Icons.account_balance_wallet,
                ),
                _buildTestResult(
                  'Średnia na klienta',
                  '${(_stats!.averageCapitalPerClient / 1000).toStringAsFixed(1)}K PLN',
                  Icons.analytics,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getSourceColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _getSourceColor().withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Źródło: ${_stats!.source}',
                    style: TextStyle(
                      color: _getSourceColor(),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTestResult(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSourceColor() {
    if (_stats == null) return AppTheme.textSecondary;

    switch (_stats!.source) {
      case 'firebase-functions':
        return AppTheme.successColor;
      case 'unified-statistics-direct':
      case 'advanced-fallback':
        return AppTheme.infoColor;
      case 'basic-fallback':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondary;
    }
  }
}
