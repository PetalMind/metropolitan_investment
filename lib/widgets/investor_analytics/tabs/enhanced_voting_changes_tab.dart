import 'package:flutter/material.dart';
import '../../../models/investor_summary.dart';
import '../../../models/client.dart'; // For VotingStatus enum
import '../../../services/voting_status_change_service.dart';
import '../../../services/enhanced_voting_status_service.dart';

/// Enhanced voting changes tab with pagination, filtering and statistics
class EnhancedVotingChangesTab extends StatefulWidget {
  final InvestorSummary investor;

  const EnhancedVotingChangesTab({super.key, required this.investor});

  @override
  State<EnhancedVotingChangesTab> createState() => _EnhancedVotingChangesTabState();
}

class _EnhancedVotingChangesTabState extends State<EnhancedVotingChangesTab> {
  final VotingStatusChangeService _changeService = VotingStatusChangeService();
  final EnhancedVotingStatusService _votingService = EnhancedVotingStatusService();

  List<VotingStatusChangeRecord> _changes = [];
  VotingStatusStatistics? _statistics;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  
  // Pagination
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMorePages = true;

  // Filtering
  String? _selectedChangeType;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadChanges(refresh: true),
      _loadStatistics(),
    ]);
  }

  Future<void> _loadChanges({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
        _hasMorePages = true;
        _changes.clear();
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      List<VotingStatusChangeRecord> newChanges = [];
      
      // Get changes for this client
      newChanges = await _changeService.getClientVotingStatusHistory(widget.investor.client.id);
      
      // If no changes found and excelId exists, try that
      if (newChanges.isEmpty && widget.investor.client.excelId != null) {
        newChanges = await _changeService.getClientVotingStatusHistory(widget.investor.client.excelId!);
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
      return const Center(
        child: CircularProgressIndicator(),
      );
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
      return const Center(
        child: Text('Brak danych'),
      );
    }

    return ListView.builder(
      itemCount: _changes.length,
      itemBuilder: (context, index) {
        final change = _changes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text('Zmiana statusu'),
            subtitle: Text('${change.oldStatus.displayName} → ${change.newStatus.displayName}'),
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
      
      changes = await _changeService.getClientVotingStatusHistory(widget.investor.client.id);
      
      if (changes.isEmpty && widget.investor.client.excelId != null) {
        changes = await _changeService.getClientVotingStatusHistory(widget.investor.client.excelId!);
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
      return const Center(
        child: CircularProgressIndicator(),
      );
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
      return const Center(
        child: Text('Brak danych'),
      );
    }

    return ListView.builder(
      itemCount: _changes.length,
      itemBuilder: (context, index) {
        final change = _changes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text('Zmiana statusu'),
            subtitle: Text('${change.oldStatus.displayName} → ${change.newStatus.displayName}'),
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
      
      // Try by client ID first
      changes = await _changeService.getClientVotingStatusHistory(widget.investor.client.id);
      
      // If empty and excelId exists, try that
      if (changes.isEmpty && widget.investor.client.excelId != null) {
        changes = await _changeService.getClientVotingStatusHistory(widget.investor.client.excelId!);
      }

      print('✅ [EnhancedVotingChangesTab] Loaded ${changes.length} changes for ${widget.investor.client.name}');

      if (mounted) {
        setState(() {
          _changes = changes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [EnhancedVotingChangesTab] Error loading changes: $e');
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
          if (_showStatistics) ...[
            _buildStatisticsCard(),
            const SizedBox(height: 16),
          ],
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
          onPressed: () {
            setState(() {
              _showStatistics = !_showStatistics;
            });
          },
          icon: Icon(_showStatistics ? Icons.analytics_outlined : Icons.analytics),
          tooltip: _showStatistics ? 'Ukryj statystyki' : 'Pokaż statystyki',
        ),
        IconButton(
          onPressed: _loadChanges,
          icon: const Icon(Icons.refresh),
          tooltip: 'Odśwież',
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    final totalChanges = _changes.length;
    if (totalChanges == 0) {
      return const SizedBox.shrink();
    }

    // Calculate basic statistics
    final statusChanges = <String, int>{};
    DateTime? earliest, latest;

    for (final change in _changes) {
      final status = change.newStatus.displayName;
      statusChanges[status] = (statusChanges[status] ?? 0) + 1;
      
      if (earliest == null || change.timestamp.isBefore(earliest)) {
        earliest = change.timestamp;
      }
      if (latest == null || change.timestamp.isAfter(latest)) {
        latest = change.timestamp;
      }
    }

    final mostCommonStatus = statusChanges.entries.isEmpty 
        ? 'N/A' 
        : statusChanges.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Statystyki zmian',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Łączna liczba zmian',
                    totalChanges.toString(),
                    Icons.timeline,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Najczęstszy status',
                    mostCommonStatus,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            if (earliest != null && latest != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Pierwsza zmiana',
                      _formatDate(earliest),
                      Icons.first_page,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Ostatnia zmiana',
                      _formatDate(latest),
                      Icons.last_page,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
            Text('Ładowanie zaawansowanych danych...'),
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
              'Błąd podczas ładowania danych',
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
              'Brak danych do analizy',
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
        return _buildEnhancedChangeCard(change, index);
      },
    );
  }

  Widget _buildEnhancedChangeCard(VotingStatusChangeRecord change, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _getStatusColor(change.newStatus).withOpacity(0.2),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(change.newStatus),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zmiana statusu głosowania',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(change.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(change.newStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(change.newStatus).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    change.newStatus.displayName,
                    style: TextStyle(
                      color: _getStatusColor(change.newStatus),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailedStatusChange(change),
            if (change.reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildReasonSection(change.reason),
            ],
            if (change.metadata.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildMetadataSection(change.metadata),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStatusChange(VotingStatusChangeRecord change) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Poprzedni status',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    change.oldStatus.displayName,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.arrow_forward, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Nowy status',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(change.newStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(change.newStatus).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    change.newStatus.displayName,
                    style: TextStyle(
                      color: _getStatusColor(change.newStatus),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
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
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.comment, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Powód zmiany',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(Map<String, dynamic> metadata) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Dodatkowe informacje',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...metadata.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    '${entry.key}:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    final statusString = status.toString().toLowerCase();
    
    if (statusString.contains('yes') || statusString.contains('tak')) {
      return Colors.green;
    } else if (statusString.contains('no') || statusString.contains('nie')) {
      return Colors.red;
    } else if (statusString.contains('abstain') || statusString.contains('wstrzymuje')) {
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

      // Use VotingStatusChangeService to get the data
      List<VotingStatusChangeRecord> changes = [];
      final changeService = VotingStatusChangeService();

      // 1. Try by client ID first
      changes = await changeService.getClientVotingStatusHistory(widget.investor.client.id);
      
      // 2. If empty and excelId exists, try that
      if (changes.isEmpty && widget.investor.client.excelId != null) {
        changes = await changeService.getClientVotingStatusHistory(widget.investor.client.excelId!);
      }
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
    } void catch (e) {
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