import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/investor_summary.dart';
import '../../../models/voting_status_change.dart';
import '../../../services/enhanced_voting_status_service.dart';
import '../../../services/voting_status_change_service.dart';
import '../../../theme/app_theme.dart';

class EnhancedVotingChangesTab extends StatefulWidget {
  final InvestorSummary investor;

  const EnhancedVotingChangesTab({
    super.key,
    required this.investor,
  });

  @override
  State<EnhancedVotingChangesTab> createState() => _EnhancedVotingChangesTabState();
}

class _EnhancedVotingChangesTabState extends State<EnhancedVotingChangesTab> {
  final EnhancedVotingStatusService _votingService = EnhancedVotingStatusService();
  
  List<VotingStatusChange> _changes = [];
  VotingStatusStatistics? _statistics;
  bool _isLoading = true;
  String? _error;
  bool _showStatistics = false;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadChanges();
    _loadStatistics();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreChanges();
    }
  }

  Future<void> _loadChanges() async {
    try {
      print('🔍 [EnhancedVotingChangesTab] Ładowanie historii zmian dla: ${widget.investor.client.name}');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Spróbuj różne metody identyfikacji klienta
      List<VotingStatusChange> changes = [];

      // 1. Sprawdź po investorId (główny identyfikator)
      changes = await _votingService.getVotingStatusHistory(
        widget.investor.client.id,
        limit: 20,
      );

      if (changes.isEmpty) {
        // 2. Sprawdź po clientId przez VotingStatusChangeService
        final changeService = VotingStatusChangeService();
        changes = await changeService.getChangesForClient(widget.investor.client.id);
        changes = changes.take(20).toList();
      }

      // 3. Sprawdź po excelId jeśli istnieje
      if (changes.isEmpty && widget.investor.client.excelId != null && widget.investor.client.excelId!.isNotEmpty) {
        final changeService = VotingStatusChangeService();
        changes = await changeService.getChangesForClient(widget.investor.client.excelId!);
        changes = changes.take(20).toList();
      }

      print('✅ [EnhancedVotingChangesTab] Znaleziono ${changes.length} zmian w historii');

      if (mounted) {
        setState(() {
          _changes = changes;
          _lastDocument = changes.isNotEmpty ? null : null;
          _hasMoreData = changes.length == 20;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [EnhancedVotingChangesTab] Błąd ładowania historii: $e');
      if (mounted) {
        setState(() {
          _error = 'Błąd ładowania historii zmian: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreChanges() async {
    if (!_hasMoreData || _isLoading) return;

    try {
      final moreChanges = await _votingService.getVotingStatusHistory(
        widget.investor.client.id,
        limit: 20,
        startAfter: _lastDocument,
      );

      setState(() {
        _changes.addAll(moreChanges);
        _hasMoreData = moreChanges.length == 20;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd ładowania kolejnych zmian: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _votingService.getStatistics(
        useCache: true,
      );
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      print('Error loading statistics: $e');
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
          if (_showStatistics && _statistics != null) ...[
            _buildStatisticsSection(),
            const SizedBox(height: 16),
          ],
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
          onPressed: () {
            setState(() {
              _showStatistics = !_showStatistics;
            });
          },
          icon: Icon(
            _showStatistics ? Icons.analytics_outlined : Icons.analytics,
            color: AppTheme.secondaryGold,
          ),
          tooltip: _showStatistics ? 'Ukryj statystyki' : 'Pokaż statystyki',
        ),
        IconButton(
          onPressed: _refreshData,
          icon: const Icon(Icons.refresh),
          tooltip: 'Odśwież dane',
        ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    if (_statistics == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.premiumCardDecoration.copyWith(
        border: Border.all(
          color: AppTheme.secondaryGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppTheme.secondaryGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Statystyki zmian',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.secondaryGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildStatChip(
                'Łącznie zmian',
                _statistics!.totalChanges.toString(),
                Icons.edit,
                AppTheme.infoColor,
              ),
              if (_statistics!.changesByType.isNotEmpty)
                _buildStatChip(
                  'Najczęstszy typ',
                  _getMostFrequentChangeType(),
                  Icons.trending_up,
                  AppTheme.successColor,
                ),
              if (_statistics!.changesByUser.isNotEmpty)
                _buildStatChip(
                  'Najaktywniejszy użytkownik',
                  _getMostActiveUser(),
                  Icons.person,
                  AppTheme.cryptoColor,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMostFrequentChangeType() {
    if (_statistics!.changesByType.isEmpty) return 'N/A';
    
    final mostFrequent = _statistics!.changesByType.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    return '${mostFrequent.key.name} (${mostFrequent.value})';
  }

  String _getMostActiveUser() {
    if (_statistics!.changesByUser.isEmpty) return 'N/A';
    
    final mostActive = _statistics!.changesByUser.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    return '${mostActive.key} (${mostActive.value})';
  }

  Widget _buildContent() {
    if (_isLoading && _changes.isEmpty) {
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
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
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
      controller: _scrollController,
      itemCount: _changes.length + (_hasMoreData ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _changes.length) {
          // Loading indicator for pagination
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final change = _changes[index];
        return _buildEnhancedChangeCard(change);
      },
    );
  }

  Widget _buildEnhancedChangeCard(VotingStatusChange change) {
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      change.changeDescription,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'przez ${change.editedBy} • ${change.formattedDate}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (change.isVotingStatusChange && 
              change.previousVotingStatus != null &&
              change.newVotingStatus != null) ...[
            const SizedBox(height: 12),
            _buildStatusChangeRow(
              change.previousVotingStatus!,
              change.newVotingStatus!,
            ),
          ],
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

  Widget _buildStatusChangeRow(String previousStatus, String newStatus) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.borderPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.swap_horiz,
            size: 16,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Container(
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
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                Flexible(
                  child: Container(
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
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Future<void> _refreshData() async {
    setState(() {
      _changes.clear();
      _lastDocument = null;
      _hasMoreData = true;
      _statistics = null;
    });
    
    await Future.wait([
      _loadChanges(),
      _loadStatistics(),
    ]);
  }
}