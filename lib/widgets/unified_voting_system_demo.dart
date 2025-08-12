import 'package:flutter/material.dart';
import '../models_and_services.dart';
import '../theme/app_theme.dart';
import 'optimized_voting_status_widget.dart';

/// Demo screen dla testowania UnifiedVotingService w dialogach
class UnifiedVotingSystemDemo extends StatefulWidget {
  const UnifiedVotingSystemDemo({super.key});

  @override
  State<UnifiedVotingSystemDemo> createState() => _UnifiedVotingSystemDemoState();
}

class _UnifiedVotingSystemDemoState extends State<UnifiedVotingSystemDemo> {
  final UnifiedVotingService _votingService = UnifiedVotingService();
  final ClientService _clientService = ClientService();
  
  List<Client> _testClients = [];
  List<VotingStatusChangeRecord> _votingHistory = [];
  bool _isLoading = false;
  String? _selectedClientId;

  @override
  void initState() {
    super.initState();
    _loadTestClients();
  }

  Future<void> _loadTestClients() async {
    setState(() => _isLoading = true);

    try {
      // Pobierz kilku klientów do testowania - użyj stream
      final clientsStream = _clientService.getClients();
      final clients = await clientsStream.first;
      
      setState(() {
        _testClients = clients.take(5).toList();
        if (_testClients.isNotEmpty) {
          _selectedClientId = _testClients.first.id;
          _loadVotingHistory(_testClients.first.id);
        }
      });
    } catch (e) {
      print('❌ Błąd podczas pobierania klientów: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVotingHistory(String clientId) async {
    try {
      final history = await _votingService.getVotingStatusHistory(clientId);
      setState(() {
        _votingHistory = history;
      });
    } catch (e) {
      print('❌ Błąd podczas pobierania historii: $e');
    }
  }

  Future<void> _updateVotingStatus(String clientId, VotingStatus newStatus) async {
    setState(() => _isLoading = true);

    try {
      await _votingService.updateVotingStatus(
        clientId,
        newStatus,
        reason: 'Updated via Unified Voting System Demo',
      );

      // Odśwież dane
      await _loadTestClients();
      await _loadVotingHistory(clientId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Status głosowania zaktualizowany na: ${newStatus.displayName}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Błąd aktualizacji: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testClientDialog() async {
    if (_selectedClientId == null) return;

    final client = _testClients.firstWhere(
      (c) => c.id == _selectedClientId,
    );

    // Symuluj ClientDialog
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test Client Dialog'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Klient: ${client.name}'),
            const SizedBox(height: 16),
            OptimizedVotingStatusSelector(
              currentStatus: client.votingStatus,
              onStatusChanged: (newStatus) {
                Navigator.of(context).pop();
                _updateVotingStatus(client.id, newStatus);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
        ],
      ),
    );
  }

  Future<void> _testInvestorDialog() async {
    if (_selectedClientId == null) return;

    final client = _testClients.firstWhere(
      (c) => c.id == _selectedClientId,
    );

    // Symuluj InvestorDetailsDialog
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test Investor Dialog'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Inwestor: ${client.name}'),
            const SizedBox(height: 16),
            OptimizedVotingStatusSelector(
              currentStatus: client.votingStatus,
              onStatusChanged: (newStatus) {
                Navigator.of(context).pop();
                _updateVotingStatus(client.id, newStatus);
              },
              isCompact: false,
              showLabels: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UnifiedVotingSystem Demo'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Test UnifiedVotingService w dialogach',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ten demo testuje integrację UnifiedVotingService z dialogami klientów i inwestorów.',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Client selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Wybierz klienta do testowania',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedClientId,
                            decoration: const InputDecoration(
                              labelText: 'Klient',
                              border: OutlineInputBorder(),
                            ),
                            items: _testClients
                                .map((client) => DropdownMenuItem(
                                      value: client.id,
                                      child: Text(
                                        '${client.name} (${client.votingStatus.displayName})',
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedClientId = value);
                              if (value != null) {
                                _loadVotingHistory(value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Test buttons
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Testuj dialogi',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _selectedClientId != null
                                      ? _testClientDialog
                                      : null,
                                  icon: const Icon(Icons.person),
                                  label: const Text('Client Dialog'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _selectedClientId != null
                                      ? _testInvestorDialog
                                      : null,
                                  icon: const Icon(Icons.analytics),
                                  label: const Text('Investor Dialog'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.secondaryGold,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Voting history
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Historia głosowania (${_votingHistory.length})',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: _selectedClientId != null
                                      ? () => _loadVotingHistory(_selectedClientId!)
                                      : null,
                                  icon: const Icon(Icons.refresh),
                                  tooltip: 'Odśwież historię',
                                ),
                              ],
                            ),
                            const Divider(),
                            Expanded(
                              child: _votingHistory.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Brak historii głosowania',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _votingHistory.length,
                                      itemBuilder: (context, index) {
                                        final event = _votingHistory[index];
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          child: ListTile(
                                            leading: Icon(
                                              Icons.swap_horiz,
                                              color: AppTheme.secondaryGold,
                                            ),
                                            title: Text(
                                              '${event.oldStatus.displayName} → ${event.newStatus.displayName}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${event.reason}\n${event.timestamp.toLocal().toString().substring(0, 19)}',
                                            ),
                                            isThreeLine: true,
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
