import 'package:flutter/material.dart';
import '../models_and_services.dart';

/// Diagnostic screen to debug arrayUnion + serverTimestamp issue
class ArrayUnionDiagnosticScreen extends StatefulWidget {
  const ArrayUnionDiagnosticScreen({super.key});

  @override
  State<ArrayUnionDiagnosticScreen> createState() =>
      _ArrayUnionDiagnosticScreenState();
}

class _ArrayUnionDiagnosticScreenState
    extends State<ArrayUnionDiagnosticScreen> {
  final ClientService _clientService = ClientService();
  final EnhancedVotingStatusService _enhancedService =
      EnhancedVotingStatusService();
  final UnifiedVotingService _unifiedService = UnifiedVotingService();
  final InvestorAnalyticsService _analyticsService = InvestorAnalyticsService();

  List<String> _diagnosticLogs = [];
  bool _isRunning = false;

  void _log(String message) {
    setState(() {
      _diagnosticLogs.add(
        '${DateTime.now().toString().substring(11, 19)} - $message',
      );
    });
    print(message);
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunning = true;
      _diagnosticLogs.clear();
    });

    try {
      _log('🔍 Starting ArrayUnion + ServerTimestamp diagnostic...');

      // Get test client
      final clientsStream = _clientService.getClients();
      final clients = await clientsStream.first;

      if (clients.isEmpty) {
        _log('❌ No clients available for testing');
        return;
      }

      final testClient = clients.first;
      _log('📋 Using test client: ${testClient.name} (ID: ${testClient.id})');

      // Test 1: Direct ClientService update (should work)
      _log('🧪 Test 1: Direct ClientService.updateClientFields');
      try {
        await _clientService.updateClientFields(testClient.id, {
          'notes': 'Test update ${DateTime.now().millisecondsSinceEpoch}',
        });
        _log('✅ Test 1: ClientService.updateClientFields - SUCCESS');
      } catch (e) {
        _log('❌ Test 1: ClientService.updateClientFields - FAILED: $e');
      }

      await Future.delayed(const Duration(seconds: 1));

      // Test 2: EnhancedVotingStatusService (this should reveal the problem)
      _log(
        '🧪 Test 2: EnhancedVotingStatusService.updateVotingStatusWithHistory',
      );
      try {
        final result = await _enhancedService.updateVotingStatusWithHistory(
          testClient.id,
          testClient.votingStatus == VotingStatus.yes
              ? VotingStatus.no
              : VotingStatus.yes,
          reason: 'ArrayUnion diagnostic test',
        );
        _log(
          '✅ Test 2: EnhancedVotingStatusService - SUCCESS: ${result.isSuccess}',
        );
      } catch (e) {
        _log('❌ Test 2: EnhancedVotingStatusService - FAILED: $e');
        if (e.toString().contains('arrayUnion') &&
            e.toString().contains('serverTimestamp')) {
          _log('🚨 CONFIRMED: ArrayUnion + ServerTimestamp bug detected!');
        }
      }

      await Future.delayed(const Duration(seconds: 1));

      // Test 3: UnifiedVotingService
      _log('🧪 Test 3: UnifiedVotingService.updateVotingStatus');
      try {
        final result = await _unifiedService.updateVotingStatus(
          testClient.id,
          testClient.votingStatus == VotingStatus.abstain
              ? VotingStatus.undecided
              : VotingStatus.abstain,
          reason: 'UnifiedService diagnostic test',
        );
        _log('✅ Test 3: UnifiedVotingService - SUCCESS: ${result.isSuccess}');
      } catch (e) {
        _log('❌ Test 3: UnifiedVotingService - FAILED: $e');
      }

      await Future.delayed(const Duration(seconds: 1));

      // Test 4: InvestorAnalyticsService (this is what fails in the modal)
      _log('🧪 Test 4: InvestorAnalyticsService.updateInvestorDetails');
      try {
        await _analyticsService.updateInvestorDetails(
          testClient.id,
          votingStatus: testClient.votingStatus == VotingStatus.yes
              ? VotingStatus.no
              : VotingStatus.yes,
          updateReason: 'InvestorAnalyticsService diagnostic test',
        );
        _log('✅ Test 4: InvestorAnalyticsService - SUCCESS');
      } catch (e) {
        _log('❌ Test 4: InvestorAnalyticsService - FAILED: $e');
        if (e.toString().contains('arrayUnion') &&
            e.toString().contains('serverTimestamp')) {
          _log(
            '🚨 CONFIRMED: InvestorAnalyticsService has the ArrayUnion bug!',
          );
        }
      }

      _log('🏁 Diagnostic completed');
    } catch (e) {
      _log('💥 Diagnostic crashed: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ArrayUnion + ServerTimestamp Diagnostic'),
        backgroundColor: Colors.red[700],
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
                        Icon(
                          Icons.bug_report,
                          color: Colors.red[700],
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ArrayUnion + ServerTimestamp Bug Diagnostic',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This diagnostic tests different services to identify where the arrayUnion + serverTimestamp bug occurs.',
                      style: TextStyle(fontSize: 12, color: Colors.red[600]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Run diagnostic button
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? null : _runDiagnostics,
                    icon: _isRunning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(
                      _isRunning
                          ? 'Running Diagnostic...'
                          : 'Run Diagnostic Tests',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Diagnostic logs
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.terminal, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Diagnostic Logs (${_diagnosticLogs.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () =>
                                setState(() => _diagnosticLogs.clear()),
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear logs',
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: _diagnosticLogs.isEmpty
                            ? const Center(
                                child: Text(
                                  'No diagnostic logs yet. Run the diagnostic to see results.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _diagnosticLogs.length,
                                itemBuilder: (context, index) {
                                  final log = _diagnosticLogs[index];
                                  final isError =
                                      log.contains('❌') || log.contains('💥');
                                  final isSuccess = log.contains('✅');
                                  final isCritical = log.contains('🚨');

                                  Color? bgColor;
                                  Color? textColor;

                                  if (isCritical) {
                                    bgColor = Colors.red[100];
                                    textColor = Colors.red[800];
                                  } else if (isError) {
                                    bgColor = Colors.orange[50];
                                    textColor = Colors.orange[700];
                                  } else if (isSuccess) {
                                    bgColor = Colors.green[50];
                                    textColor = Colors.green[700];
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 2),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      log,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        color: textColor,
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
