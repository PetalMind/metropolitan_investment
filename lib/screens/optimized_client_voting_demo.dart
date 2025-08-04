import 'package:flutter/material.dart';
import '../models_and_services.dart';
import '../widgets/optimized_voting_status_widget.dart';

/// Przykładowy ekran demonstrujący poprawne użycie systemu statusu głosowania
/// Zgodny z architekturą projektu Metropolitan Investment
class OptimizedClientVotingDemo extends StatefulWidget {
  const OptimizedClientVotingDemo({super.key});

  @override
  State<OptimizedClientVotingDemo> createState() =>
      _OptimizedClientVotingDemoState();
}

class _OptimizedClientVotingDemoState extends State<OptimizedClientVotingDemo> {
  final OptimizedClientVotingService _votingService =
      OptimizedClientVotingService();
  final ClientService _clientService = ClientService();

  List<Client> _clients = [];
  Map<VotingStatus, int> _votingStats = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Załaduj klientów i statystyki równolegle
      final futures = await Future.wait([
        _clientService.getAllClients(),
        _votingService.getVotingStatistics(),
      ]);

      setState(() {
        _clients = futures[0] as List<Client>;
        _votingStats = futures[1] as Map<VotingStatus, int>;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status głosowania - Demo'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Odśwież dane',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _showStatistics,
            tooltip: 'Pokaż statystyki',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showBulkUpdateDialog,
        icon: const Icon(Icons.edit),
        label: const Text('Masowa aktualizacja'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Ładowanie danych...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Błąd: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    if (_clients.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Brak klientów w systemie',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildStatisticsHeader(),
        const Divider(),
        Expanded(child: _buildClientsList()),
      ],
    );
  }

  Widget _buildStatisticsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statystyki głosowania',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: VotingStatus.values.map((status) {
              final count = _votingStats[status] ?? 0;
              final total = _votingStats.values.fold(
                0,
                (sum, count) => sum + count,
              );
              final percentage = total > 0 ? (count / total * 100) : 0.0;

              return Expanded(
                child: Card(
                  color: _getVotingStatusColor(status).withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Icon(
                          _getVotingStatusIcon(status),
                          color: _getVotingStatusColor(status),
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getVotingStatusColor(status),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getVotingStatusColor(status),
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: _getVotingStatusColor(status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClientsList() {
    return ListView.builder(
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        final client = _clients[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getVotingStatusColor(client.votingStatus),
              child: Icon(
                _getVotingStatusIcon(client.votingStatus),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              client.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.email),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _getVotingStatusIcon(client.votingStatus),
                      size: 16,
                      color: _getVotingStatusColor(client.votingStatus),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      client.votingStatus.displayName,
                      style: TextStyle(
                        color: _getVotingStatusColor(client.votingStatus),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: OptimizedVotingStatusSelector(
              currentStatus: client.votingStatus,
              onStatusChanged: (newStatus) =>
                  _updateClientVotingStatus(client, newStatus),
              isCompact: true,
              showLabels: false,
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateClientVotingStatus(
    Client client,
    VotingStatus newStatus,
  ) async {
    try {
      // Pokaż loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aktualizowanie statusu dla ${client.name}...'),
          duration: const Duration(seconds: 1),
        ),
      );

      // Aktualizuj status przez zoptymalizowany serwis
      await _votingService.updateVotingStatus(
        client.id,
        newStatus,
        updateReason: 'Zmiana z poziomu interfejsu użytkownika',
      );

      // Przeładuj dane
      await _loadData();

      // Pokaż sukces
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status głosowania dla ${client.name} zaktualizowany na: ${newStatus.displayName}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd aktualizacji: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Szczegółowe statystyki głosowania'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: VotingStatus.values.map((status) {
              final count = _votingStats[status] ?? 0;
              final total = _votingStats.values.fold(
                0,
                (sum, count) => sum + count,
              );
              final percentage = total > 0 ? (count / total * 100) : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _getVotingStatusIcon(status),
                      color: _getVotingStatusColor(status),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '$count klientów (${percentage.toStringAsFixed(1)}%)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  void _showBulkUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => BulkVotingStatusDialog(
        clients: _clients,
        onUpdateComplete: (updates, reason) async {
          await _votingService.bulkUpdateVotingStatus(
            updates,
            updateReason: reason,
          );
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Zaktualizowano status głosowania dla ${updates.length} klientów',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  IconData _getVotingStatusIcon(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return Icons.check_circle;
      case VotingStatus.no:
        return Icons.cancel;
      case VotingStatus.abstain:
        return Icons.remove_circle;
      case VotingStatus.undecided:
        return Icons.help_outline;
    }
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return Colors.green;
      case VotingStatus.no:
        return Colors.red;
      case VotingStatus.abstain:
        return Colors.orange;
      case VotingStatus.undecided:
        return Colors.grey;
    }
  }
}
