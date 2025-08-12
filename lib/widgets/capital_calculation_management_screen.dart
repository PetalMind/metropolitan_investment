import 'package:flutter/material.dart';
import '../models_and_services.dart';

/// 🔧 Capital Calculation Management Screen
/// Ekran do zarządzania obliczaniem kapitału zabezpieczonego nieruchomością
///
/// Funkcje:
/// - Sprawdzanie statusu obliczeń
/// - Uruchamianie aktualizacji (z trybem testowym)
/// - Monitorowanie postępów
/// - Wyświetlanie statystyk i rekomendacji
class CapitalCalculationManagementScreen extends StatefulWidget {
  const CapitalCalculationManagementScreen({super.key});

  @override
  State<CapitalCalculationManagementScreen> createState() =>
      _CapitalCalculationManagementScreenState();
}

class _CapitalCalculationManagementScreenState
    extends State<CapitalCalculationManagementScreen> {
  bool _isLoading = false;
  bool _isUpdating = false;
  CapitalCalculationStatusResult? _statusResult;
  CapitalCalculationUpdateResult? _lastUpdateResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final status =
          await FirebaseFunctionsCapitalCalculationService.checkCapitalCalculationStatus();

      setState(() {
        _statusResult = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Błąd sprawdzania statusu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _runUpdate({bool dryRun = false}) async {
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final result =
          await FirebaseFunctionsCapitalCalculationService.updateCapitalSecuredByRealEstate(
            batchSize: 500,
            dryRun: dryRun,
            includeDetails: true,
          );

      setState(() {
        _lastUpdateResult = result;
        _isUpdating = false;
      });

      // Po rzeczywistej aktualizacji odśwież status
      if (!dryRun && result != null && result.isSuccessful) {
        await _checkStatus();
      }

      // Pokaż wynik
      if (mounted) {
        _showUpdateResultDialog(result, dryRun);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Błąd aktualizacji: $e';
        _isUpdating = false;
      });
    }
  }

  void _showUpdateResultDialog(
    CapitalCalculationUpdateResult? result,
    bool wasDryRun,
  ) {
    if (result == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          wasDryRun ? '🧪 Wyniki symulacji' : '✅ Wyniki aktualizacji',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultRow('Przetworzonych', '${result.processed}'),
              _buildResultRow('Zaktualizowanych', '${result.updated}'),
              _buildResultRow('Błędów', '${result.errors}'),
              _buildResultRow('Czas wykonania', '${result.executionTimeMs}ms'),
              if (result.summary != null) ...[
                const Divider(),
                _buildResultRow(
                  'Wskaźnik sukcesu',
                  result.summary!.successRate,
                ),
                _buildResultRow(
                  'Wskaźnik aktualizacji',
                  result.summary!.updateRate,
                ),
              ],
              if (result.details.isNotEmpty) ...[
                const Divider(),
                Text(
                  'Próbka zmian (${result.details.length}):',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...result.details
                    .take(5)
                    .map(
                      (detail) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${detail.clientName}: ${detail.oldCapitalSecuredByRealEstate.toStringAsFixed(2)} → '
                          '${detail.newCapitalSecuredByRealEstate.toStringAsFixed(2)} PLN',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zamknij'),
          ),
          if (wasDryRun && result.updated > 0)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _runUpdate(dryRun: false);
              },
              child: const Text('Wykonaj rzeczywistą aktualizację'),
            ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zarządzanie obliczeniami kapitału'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _checkStatus,
            icon: const Icon(Icons.refresh),
            tooltip: 'Odśwież status',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage!)),
                          ],
                        ),
                      ),
                    ),

                  if (_statusResult != null) ...[
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    _buildActionsCard(),
                    const SizedBox(height: 16),
                    _buildRecommendationsCard(),
                    if (_statusResult!.samples.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildSamplesCard(),
                    ],
                  ],

                  if (_lastUpdateResult != null) ...[
                    const SizedBox(height: 16),
                    _buildLastUpdateCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final stats = _statusResult!.statistics;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics),
                SizedBox(width: 8),
                Text(
                  'Status obliczeń',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              children: [
                _buildStatItem(
                  'Łączna liczba inwestycji',
                  '${stats.totalInvestments}',
                ),
                _buildStatItem(
                  'Z obliczonym polem',
                  '${stats.withCalculatedField}',
                ),
                _buildStatItem(
                  'Z poprawnym obliczeniem',
                  '${stats.withCorrectCalculation}',
                ),
                _buildStatItem('Wymaga aktualizacji', '${stats.needsUpdate}'),
                _buildStatItem('Wskaźnik kompletności', stats.completionRate),
                _buildStatItem('Wskaźnik poprawności', stats.accuracyRate),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings),
                SizedBox(width: 8),
                Text(
                  'Akcje',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUpdating
                        ? null
                        : () => _runUpdate(dryRun: true),
                    icon: const Icon(Icons.science),
                    label: Text(
                      _isUpdating ? 'Testowanie...' : 'Test (Symulacja)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isUpdating ||
                            (_statusResult?.statistics.needsUpdate ?? 0) == 0
                        ? null
                        : () => _runUpdate(dryRun: false),
                    icon: const Icon(Icons.update),
                    label: Text(
                      _isUpdating
                          ? 'Aktualizowanie...'
                          : 'Aktualizuj bazę danych',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (_isUpdating)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    if (_statusResult!.recommendations.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb),
                SizedBox(width: 8),
                Text(
                  'Rekomendacje',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._statusResult!.recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(rec)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSamplesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.preview),
                SizedBox(width: 8),
                Text(
                  'Próbki do aktualizacji',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Klient')),
                  DataColumn(label: Text('Obecna wartość')),
                  DataColumn(label: Text('Powinna być')),
                  DataColumn(label: Text('Różnica')),
                ],
                rows: _statusResult!.samples
                    .take(10)
                    .map(
                      (sample) => DataRow(
                        cells: [
                          DataCell(Text(sample.clientName)),
                          DataCell(
                            Text(sample.currentValue.toStringAsFixed(2)),
                          ),
                          DataCell(Text(sample.shouldBe.toStringAsFixed(2))),
                          DataCell(
                            Text(
                              sample.difference.toStringAsFixed(2),
                              style: TextStyle(
                                color: sample.difference > 0
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdateCard() {
    final result = _lastUpdateResult!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history),
                SizedBox(width: 8),
                Text(
                  'Ostatnia aktualizacja',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Wykonano: ${result.timestamp}'),
            Text(
              'Tryb: ${result.dryRun ? 'Symulacja' : 'Rzeczywista aktualizacja'}',
            ),
            Text('Przetworzonych: ${result.processed}'),
            Text('Zaktualizowanych: ${result.updated}'),
            Text('Błędów: ${result.errors}'),
            Text('Czas: ${result.executionTimeMs}ms'),
            if (result.summary != null) ...[
              Text('Sukces: ${result.summary!.successRate}'),
              Text('Aktualizacja: ${result.summary!.updateRate}'),
            ],
          ],
        ),
      ),
    );
  }
}
