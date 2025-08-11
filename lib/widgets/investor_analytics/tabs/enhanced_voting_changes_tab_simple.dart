import 'package:flutter/material.dart';
import '../../../models/investor_summary.dart';
import '../../../services/voting_status_change_service.dart';
import '../../../theme/app_theme.dart';

/// Enhanced voting changes tab with statistics
class EnhancedVotingChangesTab extends StatefulWidget {
  final InvestorSummary investor;

  const EnhancedVotingChangesTab({super.key, required this.investor});

  @override
  State<EnhancedVotingChangesTab> createState() =>
      _EnhancedVotingChangesTabState();
}

class _EnhancedVotingChangesTabState extends State<EnhancedVotingChangesTab> {
  final VotingStatusChangeService _changeService = VotingStatusChangeService();

  List<VotingStatusChangeRecord> _changes = [];
  bool _isLoading = true;
  String? _error;
  bool _showStatistics = false;

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

      List<VotingStatusChangeRecord> changes = [];

      changes = await _changeService.getClientVotingStatusHistory(
        widget.investor.client.id,
      );

      if (changes.isEmpty && widget.investor.client.excelId != null) {
        changes = await _changeService.getClientVotingStatusHistory(
          widget.investor.client.excelId!,
        );
      }

      if (mounted) {
        setState(() {
          _changes = changes;
          _isLoading = false;
        });
      }
    } catch (e) {
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
        Icon(Icons.analytics, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          'Zaawansowana Historia Zmian',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: _loadChanges,
          icon: const Icon(Icons.refresh),
          tooltip: 'Odśwież',
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Błąd: $_error'),
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
      return const Center(child: Text('Brak danych'));
    }

    return ListView.builder(
      itemCount: _changes.length,
      itemBuilder: (context, index) {
        final change = _changes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text('Zmiana statusu'),
            subtitle: Text(
              '${change.oldStatus.displayName} → ${change.newStatus.displayName}',
            ),
            trailing: Text(_formatDate(change.timestamp)),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
