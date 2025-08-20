import 'package:flutter/material.dart';
import '../../../models_and_services.dart';
import '../../../theme/app_theme.dart';

/// Voting changes tab that displays voting status history for an investor
class VotingChangesTab extends StatefulWidget {
  final InvestorSummary investor;

  const VotingChangesTab({super.key, required this.investor});

  @override
  State<VotingChangesTab> createState() => _VotingChangesTabState();
}

class _VotingChangesTabState extends State<VotingChangesTab> {
  final UnifiedVotingStatusService _changeService =
      UnifiedVotingStatusService();

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

      List<VotingStatusChange> changes = [];

      // Try by client ID first
      print('🔍 [VotingChangesTab] Pobieranie zmian dla klienta:');
      print('  - Nazwa: ${widget.investor.client.name}');
      print('  - Client ID: "${widget.investor.client.id}"');
      print('  - Excel ID: "${widget.investor.client.excelId}"');

      changes = await _changeService.getVotingStatusHistory(
        widget.investor.client.id,
      );

      // If empty and excelId exists, try that
      if (changes.isEmpty && widget.investor.client.excelId != null) {
        print(
          '🔍 [VotingChangesTab] Brak zmian dla ID ${widget.investor.client.id}, próbuję excelId: ${widget.investor.client.excelId}',
        );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundSecondary, AppTheme.backgroundTertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.history, color: AppTheme.secondaryGold, size: 24),
          ),
          const SizedBox(width: 12),
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundModal.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.secondaryGold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSecondary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.secondaryGold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Ładowanie historii zmian...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.errorBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.errorPrimary.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.errorPrimary.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppTheme.errorPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Błąd podczas ładowania historii',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorPrimary,
                  foregroundColor: AppTheme.textOnPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, size: 18),
                    const SizedBox(width: 8),
                    const Text('Spróbuj ponownie'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_changes.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSecondary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.neutralPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.history_toggle_off,
                  size: 48,
                  color: AppTheme.neutralPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Brak historii zmian',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ten inwestor nie ma jeszcze żadnych zapisanych zmian statusu głosowania.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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

  Widget _buildChangeCard(VotingStatusChange change) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.backgroundSecondary,
            AppTheme.backgroundTertiary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(
            change.newStatus?.name ?? 'undecided',
          ).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: _getStatusColor(
              change.newStatus?.name ?? 'undecided',
            ).withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor(
                          change.newStatus?.name ?? 'undecided',
                        ).withOpacity(0.2),
                        _getStatusColor(
                          change.newStatus?.name ?? 'undecided',
                        ).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(
                        change.newStatus?.name ?? 'undecided',
                      ).withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.how_to_vote,
                    size: 24,
                    color: _getStatusColor(
                      change.newStatus?.name ?? 'undecided',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zmiana statusu głosowania',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundModal.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatDate(change.timestamp),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status change container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundModal.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.borderSecondary.withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badges row
                  Row(
                    children: [
                      _buildStatusBadge(
                        change.oldStatus?.displayName ?? 'Nieznany',
                        _getStatusColor(change.oldStatus?.name ?? 'undecided'),
                        isOld: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryGold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: AppTheme.secondaryGold,
                          ),
                        ),
                      ),
                      _buildStatusBadge(
                        change.newStatus?.displayName ?? 'Nieznany',
                        _getStatusColor(change.newStatus?.name ?? 'undecided'),
                      ),
                    ],
                  ),

                  // Reason section
                  if (change.reason != null && change.reason!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundSecondary.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.borderPrimary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.comment,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Powód: ${change.reason}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Changed by section
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundModal.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.secondaryGold.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: AppTheme.secondaryGold,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Zmiana wykonana przez: ${_getChangedBy(change)}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: isOld
            ? LinearGradient(
                colors: [
                  AppTheme.neutralBackground,
                  AppTheme.backgroundModal.withOpacity(0.8),
                ],
              )
            : LinearGradient(
                colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOld ? AppTheme.borderSecondary : color.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isOld ? AppTheme.neutralPrimary : color).withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOld ? AppTheme.textTertiary : color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              color: isOld ? AppTheme.textTertiary : color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    // Handle both VotingStatus enum and string
    final statusString = status.toString().toLowerCase();

    if (statusString.contains('yes') || statusString.contains('tak')) {
      return AppTheme.successPrimary;
    } else if (statusString.contains('no') || statusString.contains('nie')) {
      return AppTheme.errorPrimary;
    } else if (statusString.contains('abstain') ||
        statusString.contains('wstrzymuje')) {
      return AppTheme.warningPrimary;
    } else {
      return AppTheme.neutralPrimary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getChangedBy(VotingStatusChange change) {
    // Sprawdź czy jest dostępne pole editedByName (preferowane - pełna nazwa)
    if (change.editedByName != null && change.editedByName!.isNotEmpty) {
      return change.editedByName!;
    }

    // Sprawdź czy jest dostępne pole editedBy (główne pole z Firebase)
    if (change.editedBy.isNotEmpty) {
      return change.editedBy;
    }

    // Sprawdź czy jest dostępne pole editedByEmail
    if (change.editedByEmail.isNotEmpty) {
      return change.editedByEmail;
    }

    // Fallback - sprawdź w metadata (dla starszych zapisów)
    if (change.metadata.containsKey('editedByName')) {
      return change.metadata['editedByName'].toString();
    }

    if (change.metadata.containsKey('editedBy')) {
      return change.metadata['editedBy'].toString();
    }

    if (change.metadata.containsKey('editedByEmail')) {
      return change.metadata['editedByEmail'].toString();
    }

    if (change.metadata.containsKey('changedBy')) {
      return change.metadata['changedBy'].toString();
    }

    if (change.metadata.containsKey('userId')) {
      return 'ID: ${change.metadata['userId']}';
    }

    if (change.metadata.containsKey('userName')) {
      return change.metadata['userName'].toString();
    }

    // Fallback - system
    return 'System';
  }
}
