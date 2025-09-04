import 'package:flutter/material.dart';
import '../../theme/app_theme_professional.dart';

class DataDiagnosticsTab extends StatefulWidget {
  const DataDiagnosticsTab({super.key});

  @override
  State<DataDiagnosticsTab> createState() => _DataDiagnosticsTabState();
}

class _DataDiagnosticsTabState extends State<DataDiagnosticsTab>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Diagnostics data
  bool _isLoading = true;
  bool _isRunningDiagnostics = false;
  Map<String, dynamic> _diagnosticsResults = {};
  Map<String, dynamic> _databaseHealth = {};
  Map<String, dynamic> _fieldMappingStatus = {};
  List<Map<String, dynamic>> _dataIssues = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDiagnosticsData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  Future<void> _loadDiagnosticsData() async {
    try {
      // Ładowanie podstawowych danych diagnostycznych
      await Future.wait([
        _loadDatabaseHealth(),
        _loadFieldMappingStatus(),
        _loadDataIssues(),
      ]);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Błąd podczas ładowania diagnostyki: $e');
      }
    }
  }

  Future<void> _loadDatabaseHealth() async {
    try {
      // Symulacja sprawdzenia zdrowia bazy danych
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        setState(() {
          _databaseHealth = {
            'totalDocuments': 15847,
            'healthScore': 94.2,
            'lastBackup': DateTime.now().subtract(const Duration(hours: 6)),
            'indexHealth': 'Optymalne',
            'storageUsed': '2.4 GB',
            'queryPerformance': 'Dobra',
            'connectionStatus': 'Stabilne',
            'replicationLag': '< 1s',
          };
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Błąd podczas sprawdzania zdrowia bazy: $e');
      }
    }
  }

  Future<void> _loadFieldMappingStatus() async {
    try {
      // Symulacja sprawdzenia mapowania pól
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        setState(() {
          _fieldMappingStatus = {
            'totalMappings': 247,
            'validMappings': 241,
            'invalidMappings': 6,
            'polishFields': 156,
            'englishFields': 91,
            'lastValidation': DateTime.now().subtract(
              const Duration(minutes: 15),
            ),
            'mappingAccuracy': 97.6,
            'conflictingFields': [
              'kwota_inwestycji vs investmentAmount',
              'data_podpisania vs signingDate',
            ],
          };
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Błąd podczas sprawdzania mapowania pól: $e');
      }
    }
  }

  Future<void> _loadDataIssues() async {
    try {
      // Symulacja wykrywania problemów z danymi
      await Future.delayed(const Duration(milliseconds: 700));

      if (mounted) {
        setState(() {
          _dataIssues = [
            {
              'type': 'MISSING_FIELD',
              'severity': 'medium',
              'message': '6 dokumentów bez pola "remainingCapital"',
              'collection': 'investments',
              'count': 6,
              'fixable': true,
            },
            {
              'type': 'INVALID_FORMAT',
              'severity': 'low',
              'message': '3 daty w niepoprawnym formacie',
              'collection': 'clients',
              'count': 3,
              'fixable': true,
            },
            {
              'type': 'DUPLICATE_ID',
              'severity': 'high',
              'message': '2 duplikaty ID w kolekcji apartamentów',
              'collection': 'investments',
              'count': 2,
              'fixable': false,
            },
            {
              'type': 'ORPHANED_REFERENCE',
              'severity': 'medium',
              'message': '12 referencji do nieistniejących klientów',
              'collection': 'investments',
              'count': 12,
              'fixable': true,
            },
          ];
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Błąd podczas wykrywania problemów: $e');
      }
    }
  }

  Future<void> _runComprehensiveDiagnostics() async {
    setState(() => _isRunningDiagnostics = true);

    try {
      // Symulacja uruchomienia pełnej diagnostyki przez Firebase Functions
      // W rzeczywistości wywołałbyś Firebase Function:
      // final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      // final result = await functions
      //     .httpsCallable('runDataDiagnostics')
      //     .call();

      // Symulacja
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() {
          _diagnosticsResults = {
            'timestamp': DateTime.now(),
            'totalChecks': 25,
            'passedChecks': 22,
            'failedChecks': 3,
            'warningChecks': 2,
            'executionTime': '2.8s',
            'recommendations': [
              'Napraw duplikaty ID w kolekcji investments',
              'Aktualizuj 6 brakujących pól remainingCapital',
              'Zoptymalizuj indeksy dla lepszej wydajności',
            ],
          };
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🔍 Diagnostyka zakończona'),
            backgroundColor: AppThemePro.statusSuccess,
          ),
        );
      }
    } catch (e) {
      _showError('Błąd podczas uruchamiania diagnostyki: $e');
    } finally {
      if (mounted) {
        setState(() => _isRunningDiagnostics = false);
      }
    }
  }

  Future<void> _fixDataIssue(Map<String, dynamic> issue) async {
    try {
      if (!issue['fixable']) {
        _showError('Ten problem wymaga ręcznej interwencji');
        return;
      }

      // Symulacja naprawienia problemu
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        setState(() {
          _dataIssues.remove(issue);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Naprawiono: ${issue['message']}'),
            backgroundColor: AppThemePro.statusSuccess,
          ),
        );
      }
    } catch (e) {
      _showError('Błąd podczas naprawiania problemu: $e');
    }
  }

  Future<void> _exportDiagnosticsReport() async {
    try {
      // Symulacja eksportu raportu diagnostycznego
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '📄 Raport diagnostyczny został wyeksportowany',
            ),
            backgroundColor: AppThemePro.statusInfo,
          ),
        );
      }
    } catch (e) {
      _showError('Błąd podczas eksportu raportu: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppThemePro.statusError,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppThemePro.accentGold),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildDatabaseHealthSection(),
            const SizedBox(height: 24),
            _buildFieldMappingSection(),
            const SizedBox(height: 24),
            _buildDataIssuesSection(),
            const SizedBox(height: 24),
            if (_diagnosticsResults.isNotEmpty) ...[
              _buildDiagnosticsResultsSection(),
              const SizedBox(height: 24),
            ],
            _buildActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.statusInfo.withOpacity(0.1),
            AppThemePro.statusInfo.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.statusInfo.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemePro.statusInfo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.analytics_rounded,
              color: AppThemePro.statusInfo,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diagnostyka danych',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Analiza integralności i jakości danych w systemie',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemePro.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseHealthSection() {
    final healthScore = _databaseHealth['healthScore'] ?? 0.0;
    final healthColor = healthScore >= 90
        ? AppThemePro.statusSuccess
        : healthScore >= 70
        ? AppThemePro.statusWarning
        : AppThemePro.statusError;

    return _buildDiagnosticCard(
      'Zdrowie bazy danych',
      Icons.favorite_rounded,
      healthColor,
      [
        _buildHealthScoreWidget(healthScore, healthColor),
        const SizedBox(height: 16),
        _buildHealthMetric(
          'Dokumenty ogółem',
          '${_databaseHealth['totalDocuments'] ?? 0}',
        ),
        _buildHealthMetric(
          'Ostatnia kopia zapasowa',
          _formatDateTime(_databaseHealth['lastBackup']),
        ),
        _buildHealthMetric(
          'Zdrowie indeksów',
          _databaseHealth['indexHealth'] ?? 'N/A',
        ),
        _buildHealthMetric(
          'Użyte miejsce',
          _databaseHealth['storageUsed'] ?? 'N/A',
        ),
        _buildHealthMetric(
          'Wydajność zapytań',
          _databaseHealth['queryPerformance'] ?? 'N/A',
        ),
        _buildHealthMetric(
          'Status połączenia',
          _databaseHealth['connectionStatus'] ?? 'N/A',
        ),
      ],
    );
  }

  Widget _buildFieldMappingSection() {
    final accuracy = _fieldMappingStatus['mappingAccuracy'] ?? 0.0;
    final accuracyColor = accuracy >= 95
        ? AppThemePro.statusSuccess
        : accuracy >= 85
        ? AppThemePro.statusWarning
        : AppThemePro.statusError;

    return _buildDiagnosticCard(
      'Mapowanie pól (Polski ↔ Angielski)',
      Icons.translate_rounded,
      accuracyColor,
      [
        _buildMappingAccuracyWidget(accuracy, accuracyColor),
        const SizedBox(height: 16),
        _buildHealthMetric(
          'Mapowania ogółem',
          '${_fieldMappingStatus['totalMappings'] ?? 0}',
        ),
        _buildHealthMetric(
          'Poprawne mapowania',
          '${_fieldMappingStatus['validMappings'] ?? 0}',
        ),
        _buildHealthMetric(
          'Niepoprawne mapowania',
          '${_fieldMappingStatus['invalidMappings'] ?? 0}',
        ),
        _buildHealthMetric(
          'Pola polskie',
          '${_fieldMappingStatus['polishFields'] ?? 0}',
        ),
        _buildHealthMetric(
          'Pola angielskie',
          '${_fieldMappingStatus['englishFields'] ?? 0}',
        ),
        _buildHealthMetric(
          'Ostatnia walidacja',
          _formatDateTime(_fieldMappingStatus['lastValidation']),
        ),
        if (_fieldMappingStatus['conflictingFields'] != null) ...[
          const SizedBox(height: 12),
          Text(
            'Konflikty pól:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppThemePro.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          ..._fieldMappingStatus['conflictingFields'].map<Widget>(
            (field) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text(
                '• $field',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppThemePro.statusWarning,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDataIssuesSection() {
    return _buildDiagnosticCard(
      'Wykryte problemy (${_dataIssues.length})',
      Icons.error_outline_rounded,
      _dataIssues.isEmpty
          ? AppThemePro.statusSuccess
          : AppThemePro.statusWarning,
      [
        if (_dataIssues.isEmpty)
          _buildNoIssuesWidget()
        else
          ..._dataIssues.map((issue) => _buildIssueWidget(issue)),
      ],
    );
  }

  Widget _buildDiagnosticsResultsSection() {
    final results = _diagnosticsResults;
    final passedChecks = results['passedChecks'] ?? 0;
    final totalChecks = results['totalChecks'] ?? 1;
    final successRate = (passedChecks / totalChecks * 100);

    return _buildDiagnosticCard(
      'Wyniki ostatniej diagnostyki',
      Icons.fact_check_rounded,
      AppThemePro.statusInfo,
      [
        _buildDiagnosticsProgressWidget(successRate),
        const SizedBox(height: 16),
        _buildHealthMetric('Czas wykonania', results['executionTime'] ?? 'N/A'),
        _buildHealthMetric(
          'Sprawdzenia ogółem',
          '${results['totalChecks'] ?? 0}',
        ),
        _buildHealthMetric(
          'Sprawdzenia pomyślne',
          '${results['passedChecks'] ?? 0}',
        ),
        _buildHealthMetric(
          'Sprawdzenia niepomyślne',
          '${results['failedChecks'] ?? 0}',
        ),
        _buildHealthMetric('Ostrzeżenia', '${results['warningChecks'] ?? 0}'),
        if (results['recommendations'] != null) ...[
          const SizedBox(height: 12),
          Text(
            'Rekomendacje:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppThemePro.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          ...results['recommendations'].map<Widget>(
            (rec) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text(
                '• $rec',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isRunningDiagnostics
                    ? null
                    : _runComprehensiveDiagnostics,
                icon: _isRunningDiagnostics
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppThemePro.primaryDark,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(
                  _isRunningDiagnostics
                      ? 'Uruchamianie...'
                      : 'Uruchom pełną diagnostykę',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.accentGold,
                  foregroundColor: AppThemePro.primaryDark,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exportDiagnosticsReport,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Eksportuj raport'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiagnosticCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildHealthScoreWidget(double score, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.health_and_safety_rounded, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ogólny wskaźnik zdrowia',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemePro.textSecondary,
                  ),
                ),
                Text(
                  '${score.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingAccuracyWidget(double accuracy, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.track_changes_rounded, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dokładność mapowania',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemePro.textSecondary,
                  ),
                ),
                Text(
                  '${accuracy.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsProgressWidget(double successRate) {
    final color = successRate >= 90
        ? AppThemePro.statusSuccess
        : successRate >= 70
        ? AppThemePro.statusWarning
        : AppThemePro.statusError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.assessment_rounded, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wskaźnik powodzenia',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemePro.textSecondary,
                  ),
                ),
                Text(
                  '${successRate.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppThemePro.textSecondary),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoIssuesWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.statusSuccess.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.statusSuccess.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppThemePro.statusSuccess,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Nie wykryto żadnych problemów z danymi',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppThemePro.statusSuccess,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueWidget(Map<String, dynamic> issue) {
    final severity = issue['severity'] as String;
    final isFixable = issue['fixable'] as bool;

    Color severityColor;
    IconData severityIcon;

    switch (severity) {
      case 'high':
        severityColor = AppThemePro.statusError;
        severityIcon = Icons.error_rounded;
        break;
      case 'medium':
        severityColor = AppThemePro.statusWarning;
        severityIcon = Icons.warning_rounded;
        break;
      default:
        severityColor = AppThemePro.statusInfo;
        severityIcon = Icons.info_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(severityIcon, color: severityColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  issue['message'] ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isFixable)
                TextButton.icon(
                  onPressed: () => _fixDataIssue(issue),
                  icon: const Icon(Icons.build_rounded, size: 16),
                  label: const Text('Napraw'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppThemePro.accentGold,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Kolekcja: ${issue['collection']}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
              ),
              const SizedBox(width: 16),
              Text(
                'Wpływ: ${issue['count']} dokumentów',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
              ),
              const Spacer(),
              Text(
                isFixable
                    ? 'Automatyczna naprawa'
                    : 'Wymaga ręcznej interwencji',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isFixable
                      ? AppThemePro.statusSuccess
                      : AppThemePro.statusError,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m temu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h temu';
    } else {
      return '${diff.inDays}d temu';
    }
  }
}
