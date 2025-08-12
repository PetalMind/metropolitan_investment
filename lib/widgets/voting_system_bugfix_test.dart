import 'package:flutter/material.dart';
import '../models_and_services.dart';

/// Test dla weryfikacji poprawki błędu arrayUnion + serverTimestamp
class VotingSystemBugfixTest extends StatefulWidget {
  const VotingSystemBugfixTest({super.key});

  @override
  State<VotingSystemBugfixTest> createState() => _VotingSystemBugfixTestState();
}

class _VotingSystemBugfixTestState extends State<VotingSystemBugfixTest> {
  final UnifiedVotingService _votingService = UnifiedVotingService();
  final ClientService _clientService = ClientService();

  List<Client> _testClients = [];
  bool _isLoading = false;
  List<String> _testResults = [];

  @override
  void initState() {
    super.initState();
    _loadTestClients();
  }

  Future<void> _loadTestClients() async {
    setState(() => _isLoading = true);

    try {
      final clientsStream = _clientService.getClients();
      final clients = await clientsStream.first;

      setState(() {
        _testClients = clients.take(3).toList();
      });
    } catch (e) {
      _addTestResult('❌ Błąd ładowania klientów: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addTestResult(String result) {
    setState(() {
      _testResults.add(
        '${DateTime.now().toString().substring(11, 19)} - $result',
      );
    });
  }

  Future<void> _testVotingStatusUpdate(
    String clientId,
    String clientName,
  ) async {
    _addTestResult('🧪 Testowanie klienta: $clientName');

    try {
      // Test 1: Zmiana na YES
      await _votingService.updateVotingStatus(
        clientId,
        VotingStatus.yes,
        reason: 'Test update to YES - fixing arrayUnion bug',
      );
      _addTestResult('✅ Test 1 (YES): Sukces');

      // Odczekaj chwilę
      await Future.delayed(const Duration(seconds: 1));

      // Test 2: Zmiana na NO
      await _votingService.updateVotingStatus(
        clientId,
        VotingStatus.no,
        reason: 'Test update to NO - fixing arrayUnion bug',
      );
      _addTestResult('✅ Test 2 (NO): Sukces');

      // Test 3: Sprawdź historię
      final history = await _votingService.getVotingStatusHistory(clientId);
      _addTestResult('✅ Test 3 (Historia): ${history.length} rekordów');
    } catch (e) {
      _addTestResult('❌ Test błędu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voting System Bugfix Test'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bug_report, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Text(
                          'ArrayUnion + ServerTimestamp Bugfix Test',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ten test sprawdza czy naprawka problemu z arrayUnion + serverTimestamp działa poprawnie.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Client list
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_testClients.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Brak klientów do testowania'),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wybierz klienta do testowania:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ..._testClients.map(
                        (client) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ElevatedButton(
                            onPressed: () =>
                                _testVotingStatusUpdate(client.id, client.name),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              'Test: ${client.name} (${client.votingStatus.displayName})',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Test results
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.list, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Wyniki testów (${_testResults.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () =>
                                setState(() => _testResults.clear()),
                            icon: const Icon(Icons.clear),
                            tooltip: 'Wyczyść logi',
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: _testResults.isEmpty
                            ? const Center(
                                child: Text(
                                  'Brak wyników testów',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _testResults.length,
                                itemBuilder: (context, index) {
                                  final result = _testResults[index];
                                  final isError = result.contains('❌');
                                  final isSuccess = result.contains('✅');

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    color: isError
                                        ? Colors.red[50]
                                        : isSuccess
                                        ? Colors.green[50]
                                        : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        result,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          color: isError
                                              ? Colors.red[700]
                                              : isSuccess
                                              ? Colors.green[700]
                                              : null,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
