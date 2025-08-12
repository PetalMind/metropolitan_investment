import 'package:flutter/material.dart';
import '../models_and_services.dart';

/// Widget demonstracyjny pokazujący różne sposoby użycia ClientStatsWidget
class ClientStatsDemo extends StatefulWidget {
  const ClientStatsDemo({super.key});

  @override
  State<ClientStatsDemo> createState() => _ClientStatsDemoState();
}

class _ClientStatsDemoState extends State<ClientStatsDemo> {
  late IntegratedClientService _clientService;
  ClientStats? _clientStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _clientService = IntegratedClientService();
    _loadClientStats();
  }

  Future<void> _loadClientStats() async {
    try {
      setState(() => _isLoading = true);

      final stats = await _clientService.getClientStats();

      if (mounted) {
        setState(() {
          _clientStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas ładowania statystyk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo - Statystyki Klientów'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.textOnPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tytuł sekcji
            Text(
              'Różne warianty wyświetlania statystyk klientów',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Wariant 1: Pełny widok (domyślny)
            _buildSectionTitle('1. Wariant pełny (domyślny)'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderSecondary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClientStatsWidget(
                clientStats: _clientStats,
                isLoading: _isLoading,
              ),
            ),
            const SizedBox(height: 32),

            // Wariant 2: Kompaktowy
            _buildSectionTitle('2. Wariant kompaktowy'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderSecondary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClientStatsWidget(
                clientStats: _clientStats,
                isLoading: _isLoading,
                isCompact: true,
              ),
            ),
            const SizedBox(height: 32),

            // Wariant 3: Z customowym tłem
            _buildSectionTitle('3. Z customowym tłem i padding'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClientStatsWidget(
                clientStats: _clientStats,
                isLoading: _isLoading,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 32),

            // Wariant 4: Kompaktowy z customowym tłem
            _buildSectionTitle('4. Kompaktowy z customowym tłem'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClientStatsWidget(
                clientStats: _clientStats,
                isLoading: _isLoading,
                isCompact: true,
                backgroundColor: AppTheme.successColor.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),

            // Wariant 5: Stan ładowania
            _buildSectionTitle('5. Stan ładowania'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderSecondary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const ClientStatsWidget(
                clientStats: null,
                isLoading: true,
              ),
            ),
            const SizedBox(height: 32),

            // Przycisk do odświeżenia
            Center(
              child: ElevatedButton.icon(
                onPressed: _loadClientStats,
                icon: const Icon(Icons.refresh),
                label: const Text('Odśwież statystyki'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.textOnPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Informacje o danych
            if (_clientStats != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              _buildSectionTitle('Szczegóły pobranych danych:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderSecondary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Źródło danych: ${_clientStats!.source}'),
                    Text('Ostatnia aktualizacja: ${_clientStats!.lastUpdated}'),
                    Text('Łącznie klientów: ${_clientStats!.totalClients}'),
                    Text(
                      'Łącznie inwestycji: ${_clientStats!.totalInvestments}',
                    ),
                    Text(
                      'Pozostały kapitał: ${_clientStats!.totalRemainingCapital.toStringAsFixed(2)} PLN',
                    ),
                    Text(
                      'Średnia na klienta: ${_clientStats!.averageCapitalPerClient.toStringAsFixed(2)} PLN',
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
