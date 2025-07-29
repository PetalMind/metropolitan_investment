import 'package:flutter/material.dart';
import '../services/data_cache_service.dart';

class CacheDebugWidget extends StatefulWidget {
  const CacheDebugWidget({super.key});

  @override
  State<CacheDebugWidget> createState() => _CacheDebugWidgetState();
}

class _CacheDebugWidgetState extends State<CacheDebugWidget> {
  final DataCacheService _cacheService = DataCacheService();
  Map<String, dynamic>? _cacheStats;
  Map<String, dynamic>? _persistentStats;
  bool _isLoading = false;
  int? _investmentCount;

  @override
  void initState() {
    super.initState();
    _updateStats();
  }

  Future<void> _updateStats() async {
    setState(() => _isLoading = true);
    try {
      final cacheStats = _cacheService.getCacheStats();
      final persistentStats = await _cacheService.getPersistentCacheStats();

      setState(() {
        _cacheStats = cacheStats;
        _persistentStats = persistentStats;
      });
    } catch (e) {
      print('Błąd podczas pobierania statystyk cache: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testCache() async {
    setState(() => _isLoading = true);
    try {
      final investments = await _cacheService.getAllInvestments();
      setState(() {
        _investmentCount = investments.length;
      });
      await _updateStats();
    } catch (e) {
      print('Błąd podczas testowania cache: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _forceRefresh() async {
    setState(() => _isLoading = true);
    try {
      final investments = await _cacheService.forceRefreshFromFirebase();
      setState(() {
        _investmentCount = investments.length;
      });
      await _updateStats();
    } catch (e) {
      print('Błąd podczas force refresh: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Cache Debug Panel',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isLoading) const CircularProgressIndicator(strokeWidth: 2),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testCache,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Test Cache'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _forceRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Force Refresh'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _updateStats,
                  icon: const Icon(Icons.info),
                  label: const Text('Update Stats'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Results
            if (_investmentCount != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Załadowano $_investmentCount inwestycji',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Cache stats
            if (_cacheStats != null) ...[
              const Text(
                'Memory Cache Stats:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildStatsTable(_cacheStats!),
            ],

            const SizedBox(height: 16),

            // Persistent cache stats
            if (_persistentStats != null) ...[
              const Text(
                'Persistent Cache Stats (localStorage/SharedPreferences):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildPersistentStatsTable(_persistentStats!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTable(Map<String, dynamic> stats) {
    final allInvestments = stats['allInvestmentsCache'] as Map<String, dynamic>;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatRow('Valid', allInvestments['isValid'].toString()),
          _buildStatRow('Count', allInvestments['count'].toString()),
          _buildStatRow(
            'Last Update',
            allInvestments['lastUpdate']?.toString() ?? 'Never',
          ),
        ],
      ),
    );
  }

  Widget _buildPersistentStatsTable(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: stats['isValid'] ? Colors.green.shade50 : Colors.orange.shade50,
        border: Border.all(
          color: stats['isValid']
              ? Colors.green.shade200
              : Colors.orange.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatRow('Has Data', stats['hasPersistedData'].toString()),
          _buildStatRow('Valid', stats['isValid'].toString()),
          _buildStatRow('Timestamp', stats['timestamp']?.toString() ?? 'Never'),
          if (stats['timeToExpiry'] != null)
            _buildStatRow('Expires in', '${stats['timeToExpiry']} minutes'),
          if (stats['error'] != null)
            _buildStatRow('Error', stats['error'].toString(), isError: true),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : null,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
