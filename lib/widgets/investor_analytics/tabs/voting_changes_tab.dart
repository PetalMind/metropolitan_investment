import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/investor_summary.dart';
import '../../../models/voting_status_change.dart';
import '../../../services/optimized_investor_analytics_service.dart';
import '../../../theme/app_theme.dart';

class VotingChangesTab extends StatefulWidget {
  final InvestorSummary investor;

  const VotingChangesTab({super.key, required this.investor});

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
      print(
        '🔍 [VotingChangesTab] Ładowanie historii zmian dla klienta: ${widget.investor.client.id}',
      );
      print(
        '🔍 [VotingChangesTab] Nazwa klienta: ${widget.investor.client.name}',
      );
      print(
        '🔍 [VotingChangesTab] ExcelId klienta: ${widget.investor.client.excelId}',
      );

      setState(() {
        _isLoading = true;
        _error = null;
      });

      final changes = await _analyticsService.getVotingStatusHistory(
        widget.investor.client.id,
      );

      print('✅ [VotingChangesTab] Otrzymano ${changes.length} zmian');
      for (final change in changes) {
        print('   📝 ${change.formattedDate}: ${change.changeDescription}');
      }

      setState(() {
        _changes = changes;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [VotingChangesTab] Błąd ładowania historii: $e');
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
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.history, color: AppTheme.primaryColor, size: 24),
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
      return const Center(child: CircularProgressIndicator());
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
            Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // DEBUG: Tymczasowy przycisk testowy
            ElevatedButton.icon(
              onPressed: () async {
                print('🧪 [DEBUG] Wymuszanie ponownego ładowania danych...');
                print('🧪 [DEBUG] Szukane ID: ${widget.investor.client.id}');
                print(
                  '🧪 [DEBUG] Nazwa klienta: ${widget.investor.client.name}',
                );

                // Test 1: Bezpośrednie zapytanie po investorId (jak w kodzie)
                try {
                  print('🔍 [DEBUG] Test 1: Zapytanie po investorId...');
                  final investorQuery = await FirebaseFirestore.instance
                      .collection('voting_status_changes')
                      .where('investorId', isEqualTo: widget.investor.client.id)
                      .orderBy('changedAt', descending: true)
                      .limit(10)
                      .get();

                  print(
                    '� [DEBUG] Test 1 - znaleziono: ${investorQuery.docs.length} dokumentów',
                  );
                } catch (e) {
                  print('❌ [DEBUG] Test 1 błąd: $e');
                }

                // Test 2: Zapytanie po clientId
                try {
                  print('🔍 [DEBUG] Test 2: Zapytanie po clientId...');
                  final clientQuery = await FirebaseFirestore.instance
                      .collection('voting_status_changes')
                      .where('clientId', isEqualTo: widget.investor.client.id)
                      .orderBy('changedAt', descending: true)
                      .limit(10)
                      .get();

                  print(
                    '📊 [DEBUG] Test 2 - znaleziono: ${clientQuery.docs.length} dokumentów',
                  );
                } catch (e) {
                  print('❌ [DEBUG] Test 2 błąd: $e');
                }

                // Test 3: Zapytanie po nazwie klienta
                try {
                  print('🔍 [DEBUG] Test 3: Zapytanie po clientName...');
                  final nameQuery = await FirebaseFirestore.instance
                      .collection('voting_status_changes')
                      .where(
                        'clientName',
                        isEqualTo: widget.investor.client.name,
                      )
                      .orderBy('changedAt', descending: true)
                      .limit(10)
                      .get();

                  print(
                    '📊 [DEBUG] Test 3 - znaleziono: ${nameQuery.docs.length} dokumentów',
                  );

                  for (final doc in nameQuery.docs) {
                    final data = doc.data();
                    print(
                      '   📝 Dokument: clientId=${data['clientId']}, investorId=${data['investorId']}',
                    );
                    print(
                      '   📝 Data: ${data['changedAt']?.toDate()}, Zmiana: ${data['previousVotingStatus']} → ${data['newVotingStatus']}',
                    );
                  }
                } catch (e) {
                  print('❌ [DEBUG] Test 3 błąd: $e');
                }

                // Test 4: Pobierz kilka pierwszych dokumentów z kolekcji
                try {
                  print('🔍 [DEBUG] Test 4: Wszystkie dokumenty z kolekcji...');
                  final allQuery = await FirebaseFirestore.instance
                      .collection('voting_status_changes')
                      .orderBy('changedAt', descending: true)
                      .limit(5)
                      .get();

                  print(
                    '📊 [DEBUG] Test 4 - próbka z kolekcji (${allQuery.docs.length} dokumentów):',
                  );
                  for (final doc in allQuery.docs) {
                    final data = doc.data();
                    print(
                      '   📋 ${data['clientName']}: ID=${data['clientId']}',
                    );
                  }
                } catch (e) {
                  print('❌ [DEBUG] Test 4 błąd: $e');
                }

                // Następnie wywołaj normalną metodę
                await _loadChanges();
              },
              icon: Icon(Icons.bug_report),
              label: Text('DEBUG: Przeładuj'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
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
      child: Icon(icon, size: 20, color: color),
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
          _buildDetailRow('Data zmiany', change.formattedDate, Icons.schedule),
          const SizedBox(height: 8),
          _buildDetailRow('Edytowane przez', change.editedBy, Icons.person),
          if (change.editedByEmail.isNotEmpty &&
              change.editedByEmail != 'brak@email.com') ...[
            const SizedBox(height: 8),
            _buildDetailRow('Email', change.editedByEmail, Icons.email),
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
        Icon(icon, size: 16, color: AppTheme.textTertiary),
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChangeRow(String previousStatus, String newStatus) {
    return Row(
      children: [
        Icon(Icons.swap_horiz, size: 16, color: AppTheme.textTertiary),
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
              Icon(Icons.arrow_forward, size: 12, color: AppTheme.textTertiary),
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
              Icon(Icons.comment, size: 16, color: AppTheme.primaryColor),
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
