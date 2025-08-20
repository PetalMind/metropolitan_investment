import 'package:flutter/material.dart';
import '../../../models_and_services.dart';
import '../../../theme/app_theme.dart';

/// Simplified voting changes tab that works with the current service architecture
class VotingChangesTab extends StatefulWidget {
  final InvestorSummary investor;

  const VotingChangesTab({super.key, required this.investor});

  @override
  State<VotingChangesTab> createState() => _VotingChangesTabState();
}

class _VotingChangesTabState extends State<VotingChangesTab> {
  final UnifiedVotingStatusService _changeService =
      UnifiedVotingStatusService();

  List<VotingStatusChangeRecord> _changes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChanges();
  }

  Future<void> _loadChanges() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Try to get changes for this client
      List<VotingStatusChangeRecord> changes = [];

      // 1. Try by client ID
      changes = await _changeService.getVotingStatusHistory(
        widget.investor.client.id,
      );

      // 2. If empty and excelId exists, try that
      if (changes.isEmpty && widget.investor.client.excelId != null) {
        changes = await _changeService.getVotingStatusHistory(
          widget.investor.client.excelId!,
        );
      }

      print(
        '✅ [VotingChangesTab] Loaded ${changes.length} changes for ${widget.investor.client.name}',
      );

      if (mounted) {
        setState(() {
          _changes = changes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [VotingChangesTab] Error loading changes: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.history, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          'Historia Zmian Statusu Głosowania',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const Spacer(),
        if (_isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Ładowanie historii zmian...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Błąd podczas ładowania historii',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChanges,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    if (_changes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Brak historii zmian',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Ten inwestor nie ma jeszcze żadnych zapisanych zmian statusu głosowania.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _changes.length,
      itemBuilder: (context, index) {
        final change = _changes[index];
        return _buildChangeCard(change);
      },
    );
  }

  Widget _buildChangeCard(VotingStatusChangeRecord change) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(change.newStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.how_to_vote,
                    size: 20,
                    color: _getStatusColor(change.newStatus),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatusBadge(
                        change.oldStatus.displayName,
                        _getStatusColor(change.oldStatus),
                        isOld: true,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.arrow_forward, size: 16),
                      ),
                      _buildStatusBadge(
                        change.newStatus.displayName,
                        _getStatusColor(change.newStatus),
                      ),
                    ],
                  ),
                  if (change.reason.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Powód: ${change.reason}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (change.metadata.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Dodatkowe informacje:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...change.metadata.entries.map(
                      (entry) => Text(
                        '${entry.key}: ${entry.value}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color, {bool isOld = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOld ? Colors.grey[300] : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOld ? Colors.grey[400]! : color.withOpacity(0.3),
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isOld ? Colors.grey[700] : color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    // Handle both VotingStatus enum and string
    final statusString = status.toString().toLowerCase();

    if (statusString.contains('yes') || statusString.contains('tak')) {
      return Colors.green;
    } else if (statusString.contains('no') || statusString.contains('nie')) {
      return Colors.red;
    } else if (statusString.contains('abstain') ||
        statusString.contains('wstrzymuje')) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
