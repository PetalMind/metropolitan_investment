import 'package:flutter/material.dart';
import '../models_and_services.dart';

/// Demo screen to test the unified voting system
class VotingSystemDemo extends StatefulWidget {
  const VotingSystemDemo({super.key});

  @override
  State<VotingSystemDemo> createState() => _VotingSystemDemoState();
}

class _VotingSystemDemoState extends State<VotingSystemDemo> {
  final UnifiedVotingService _votingService = UnifiedVotingService();
  final ClientService _clientService = ClientService();
  
  List<Client> _clients = [];
  List<VotingStatusChangeRecord> _recentChanges = [];
  VotingStatusStatistics? _statistics;
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final clients = await _clientService.getAllClients();
      final recentChanges = await _votingService.getRecentVotingStatusChanges(limit: 10);
      final statistics = await _votingService.getVotingStatusStatistics();

      setState(() {
        _clients = clients.take(5).toList(); // Show first 5 clients for demo
        _recentChanges = recentChanges;
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateVotingStatus(String clientId, VotingStatus newStatus) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final result = await _votingService.updateVotingStatus(
        clientId,
        newStatus,
        reason: 'Demo test update',
      );

      if (result.isSuccess) {
        setState(() {
          _successMessage = 'Status updated successfully!';
        });
        await _loadData(); // Refresh data
      } else {
        setState(() {
          _error = result.error ?? 'Unknown error';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voting System Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                  if (_error != null) _buildErrorCard(),
                  if (_successMessage != null) _buildSuccessCard(),
                  _buildStatisticsCard(),
                  const SizedBox(height: 16),
                  _buildClientsCard(),
                  const SizedBox(height: 16),
                  _buildRecentChangesCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              _successMessage!,
              style: const TextStyle(color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voting Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_statistics != null) ...[
              Text('Total Clients: ${_statistics!.totalClients}'),
              const SizedBox(height: 8),
              for (final status in VotingStatus.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(status.displayName),
                      Text(
                        '${_statistics!.getCount(status)} (${_statistics!.getPercentage(status).toStringAsFixed(1)}%)',
                      ),
                    ],
                  ),
                ),
            ] else
              const Text('No statistics available'),
          ],
        ),
      ),
    );
  }

  Widget _buildClientsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sample Clients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_clients.isNotEmpty) ...[
              for (final client in _clients)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Current: ${client.votingStatus.displayName}',
                              style: TextStyle(
                                color: _getVotingStatusColor(client.votingStatus),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownButton<VotingStatus>(
                        value: client.votingStatus,
                        items: VotingStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.displayName),
                          );
                        }).toList(),
                        onChanged: _isLoading
                            ? null
                            : (newStatus) {
                                if (newStatus != null) {
                                  _updateVotingStatus(client.id, newStatus);
                                }
                              },
                      ),
                    ],
                  ),
                ),
            ] else
              const Text('No clients available'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentChangesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Voting Changes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_recentChanges.isNotEmpty) ...[
              for (final change in _recentChanges)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Client: ${change.clientId}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${change.oldStatus.displayName} → ${change.newStatus.displayName}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              change.reason,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatDate(change.timestamp),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
            ] else
              const Text('No recent changes'),
          ],
        ),
      ),
    );
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

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
