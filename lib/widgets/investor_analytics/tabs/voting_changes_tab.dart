import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/investor_summary.dart';
import '../../../models/voting_status_change.dart';
import '../../../services/optimized_investor_analytics_service.dart';
import '../../../theme/app_theme.dart';

class VotingChangesTab extends StatefulWidget {
  final InvestorSummary investor;

  const VotingChangesTab({
    super.key,
    required this.investor,
  });

  @override
  State<VotingChangesTab> createState() => _VotingChangesTabState();
}

class _VotingChangesTabState extends State<VotingChangesTab> {
  final OptimizedInvestorAnalyticsService _analyticsService = 
      OptimizedInvestorAnalyticsService();
  
  List<VotingStatusChange> _changes = [];
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

      final changes = await _analyticsService.getVotingStatusHistory(
        widget.investor.client.id,
      );

      setState(() {
        _changes = changes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Błąd ładowania historii zmian: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.history,
          color: AppTheme.primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Historia zmian statusu głosowania',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: _loadChanges,
          icon: const Icon(Icons.refresh),
          tooltip: 'Odśwież historię',
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_changes.isEmpty) {
      return _buildEmptyState();
    }

    return _buildChangesList();
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.premiumCardDecoration.copyWith(
          border: Border.all(
            color: AppTheme.errorColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Błąd ładowania danych',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadChanges,
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.textOnPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: AppTheme.premiumCardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Brak historii zmian',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ten inwestor nie ma jeszcze żadnych zapisanych zmian statusu głosowania.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangesList() {
    return ListView.separated(
      itemCount: _changes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final change = _changes[index];
        return _buildChangeCard(change);
      },
    );
  }

  Widget _buildChangeCard(VotingStatusChange change) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.premiumCardDecoration.copyWith(
        border: Border.all(
          color: _getChangeTypeColor(change.changeType).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildChangeTypeIcon(change.changeType),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  change.changeDescription,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildChangeDetails(change),
          if (change.reason != null) ...[
            const SizedBox(height: 12),
            _buildReasonSection(change.reason!),
          ],
        ],
      ),
    );
  }

  Widget _buildChangeTypeIcon(VotingStatusChangeType changeType) {
    IconData icon;
    Color color;

    switch (changeType) {
      case VotingStatusChangeType.created:
        icon = Icons.add_circle;
        color = AppTheme.successColor;
        break;
      case VotingStatusChangeType.updated:
      case VotingStatusChangeType.statusChanged:
        icon = Icons.edit_rounded;
        color = AppTheme.warningColor;
        break;
      case VotingStatusChangeType.deleted:
        icon = Icons.delete_rounded;
        color = AppTheme.errorColor;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
    );
  }

  Color _getChangeTypeColor(VotingStatusChangeType changeType) {
    switch (changeType) {
      case VotingStatusChangeType.created:
        return AppTheme.successColor;
      case VotingStatusChangeType.updated:
      case VotingStatusChangeType.statusChanged:
        return AppTheme.warningColor;
      case VotingStatusChangeType.deleted:
        return AppTheme.errorColor;
    }
  }

  Widget _buildChangeDetails(VotingStatusChange change) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.borderPrimary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            'Data zmiany',
            change.formattedDate,
            Icons.schedule,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Edytowane przez',
            change.editedBy,
            Icons.person,
          ),
          if (change.editedByEmail.isNotEmpty && 
              change.editedByEmail != 'brak@email.com') ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              'Email',
              change.editedByEmail,
              Icons.email,
            ),
          ],
          if (change.isVotingStatusChange && 
              change.previousVotingStatus != null &&
              change.newVotingStatus != null) ...[
            const SizedBox(height: 8),
            _buildStatusChangeRow(
              change.previousVotingStatus!,
              change.newVotingStatus!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textTertiary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChangeRow(String previousStatus, String newStatus) {
    return Row(
      children: [
        Icon(
          Icons.swap_horiz,
          size: 16,
          color: AppTheme.textTertiary,
        ),
        const SizedBox(width: 8),
        Text(
          'Zmiana statusu:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppTheme.errorColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  previousStatus,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.errorColor,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward,
                size: 12,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppTheme.successColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  newStatus,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.successColor,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasonSection(String reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.comment,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Powód zmiany:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            reason,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}