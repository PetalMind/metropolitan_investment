import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';

/// Debug widget do sprawdzania danych statystyk klientów
class ClientStatsDebugWidget extends StatefulWidget {
  const ClientStatsDebugWidget({super.key});

  @override
  State<ClientStatsDebugWidget> createState() => _ClientStatsDebugWidgetState();
}

class _ClientStatsDebugWidgetState extends State<ClientStatsDebugWidget> {
  Map<String, dynamic>? _debugData;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDebugData();
  }

  Future<void> _loadDebugData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final debugData = <String, dynamic>{};

      // 1. Sprawdź liczbę dokumentów w kolekcjach

      final clientsSnapshot = await FirebaseFirestore.instance
          .collection('clients')
          .limit(5)
          .get();

      final investmentsSnapshot = await FirebaseFirestore.instance
          .collection('investments')
          .limit(5)
          .get();

      debugData['collections'] = {
        'clients_count': clientsSnapshot.docs.length,
        'investments_count': investmentsSnapshot.docs.length,
        'clients_sample': clientsSnapshot.docs
            .map(
              (doc) => {
                'id': doc.id,
                'fields': doc.data().keys.toList(),
                'fullName': doc.data()['fullName'],
                'imie_nazwisko': doc.data()['imie_nazwisko'],
                'name': doc.data()['name'],
              },
            )
            .toList(),
        'investments_sample': investmentsSnapshot.docs
            .map(
              (doc) => {
                'id': doc.id,
                'fields': doc.data().keys.toList(),
                'kapital_pozostaly': doc.data()['kapital_pozostaly'],
                'remainingCapital': doc.data()['remainingCapital'],
                'kwota_inwestycji': doc.data()['kwota_inwestycji'],
                'investmentAmount': doc.data()['investmentAmount'],
                'productType': doc.data()['productType'],
                'productStatus': doc.data()['productStatus'],
                'status_produktu': doc.data()['status_produktu'],
              },
            )
            .toList(),
      };

      // 2. Sprawdź Firebase Functions
      try {
        final integratedService = IntegratedClientService();
        final stats = await integratedService.getClientStats(
          forceRefresh: true,
        );
        debugData['firebase_functions'] = {
          'success': true,
          'stats': {
            'totalClients': stats.totalClients,
            'totalInvestments': stats.totalInvestments,
            'totalRemainingCapital': stats.totalRemainingCapital,
            'averageCapitalPerClient': stats.averageCapitalPerClient,
            'source': stats.source,
            'lastUpdated': stats.lastUpdated,
          },
        };
      } catch (e) {
        debugData['firebase_functions'] = {
          'success': false,
          'error': e.toString(),
        };
      }

      // 3. Sprawdź zunifikowane statystyki
      try {
        final allInvestments = await FirebaseFirestore.instance
            .collection('investments')
            .get();

        final investmentsData = allInvestments.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();

        final unifiedStats = UnifiedSystemStats.fromInvestments(
          investmentsData,
        );

        debugData['unified_stats'] = {
          'success': true,
          'total_investments': investmentsData.length,
          'stats': {
            'totalValue': unifiedStats.totalValue,
            'viableCapital': unifiedStats.viableCapital,
            'majorityThreshold': unifiedStats.majorityThreshold,
          },
          'field_analysis': _analyzeInvestmentFields(investmentsData),
        };
      } catch (e) {
        debugData['unified_stats'] = {'success': false, 'error': e.toString()};
      }

      if (mounted) {
        setState(() {
          _debugData = debugData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Błąd podczas ładowania danych debug: $e';
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _analyzeInvestmentFields(
    List<Map<String, dynamic>> investments,
  ) {
    final analysis = <String, dynamic>{};

    if (investments.isEmpty) {
      return analysis;
    }

    // Sprawdź obecność kluczowych pól
    final keyFields = [
      'kapital_pozostaly',
      'remainingCapital',
      'kwota_inwestycji',
      'investmentAmount',
    ];
    final fieldPresence = <String, int>{};
    final fieldValues = <String, List<dynamic>>{};

    for (final investment in investments.take(10)) {
      // Analizuj pierwsze 10
      for (final field in keyFields) {
        if (investment.containsKey(field)) {
          fieldPresence[field] = (fieldPresence[field] ?? 0) + 1;
          fieldValues[field] = (fieldValues[field] ?? [])
            ..add(investment[field]);
        }
      }
    }

    analysis['field_presence'] = fieldPresence;
    analysis['sample_values'] = fieldValues;

    // Oblicz sumy
    double totalKapitalPozostaly = 0;
    double totalRemainingCapital = 0;

    for (final investment in investments) {
      final kapitaPolish = UnifiedFieldMapping.parseCapitalValue(
        investment['kapital_pozostaly'],
      );
      final capitalEnglish = UnifiedFieldMapping.parseCapitalValue(
        investment['remainingCapital'],
      );

      totalKapitalPozostaly += kapitaPolish;
      totalRemainingCapital += capitalEnglish;
    }

    analysis['field_totals'] = {
      'total_kapital_pozostaly': totalKapitalPozostaly,
      'total_remainingCapital': totalRemainingCapital,
    };

    return analysis;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug - Statystyki Klientów'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.textOnPrimary,
        actions: [
          IconButton(
            onPressed: _loadDebugData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDebugData,
                    child: const Text('Spróbuj ponownie'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildDebugContent(),
            ),
    );
  }

  Widget _buildDebugContent() {
    if (_debugData == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection('Kolekcje Firestore', _debugData!['collections']),
        const SizedBox(height: 24),
        _buildSection('Firebase Functions', _debugData!['firebase_functions']),
        const SizedBox(height: 24),
        _buildSection('Zunifikowane Statystyki', _debugData!['unified_stats']),
      ],
    );
  }

  Widget _buildSection(String title, Map<String, dynamic>? data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (data != null)
            ...data.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildDataItem(entry.key, entry.value),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataItem(String key, dynamic value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$key:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _formatValue(value),
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is Map) return _formatMap(value);
    if (value is List) return _formatList(value);
    return value.toString();
  }

  String _formatMap(Map map) {
    final buffer = StringBuffer('{\n');
    for (final entry in map.entries) {
      buffer.writeln('  ${entry.key}: ${_formatValue(entry.value)}');
    }
    buffer.write('}');
    return buffer.toString();
  }

  String _formatList(List list) {
    if (list.isEmpty) return '[]';
    if (list.length <= 3) {
      return '[${list.map(_formatValue).join(', ')}]';
    }
    return '[${list.take(3).map(_formatValue).join(', ')}, ... ${list.length} items]';
  }
}
