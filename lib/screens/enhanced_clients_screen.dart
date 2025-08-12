import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../models_and_services.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/custom_loading_widget.dart';
import '../widgets/client_form.dart';

class EnhancedClientsScreen extends StatefulWidget {
  const EnhancedClientsScreen({super.key});

  @override
  State<EnhancedClientsScreen> createState() => _EnhancedClientsScreenState();
}

class _EnhancedClientsScreenState extends State<EnhancedClientsScreen> {
  // Używamy nowego zintegrowanego serwisu
  final IntegratedClientService _clientService = IntegratedClientService();
  final TextEditingController _searchController = TextEditingController();

  List<Client> _allClients = []; // Przechowuje wszystkich klientów
  List<Client> _activeClients = [];
  ClientStats? _clientStats;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _showActiveOnly = false;
  String _errorMessage = '';

  // Parametry filtrowania i sortowania
  String _sortBy = 'fullName';
  String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Załaduj dane początkowe wykorzystując IntegratedClientService
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Równoległe ładowanie danych z progress tracking
      final futures = await Future.wait([
        // Pobierz wszystkich klientów
        _clientService.getAllClients(
          page: 1,
          pageSize: 10000, // Pobierz wszystkich
          sortBy: _sortBy,
          forceRefresh: false,
          onProgress: (progress, stage) {
            // Progress tracking bez modyfikacji stanu
          },
        ),
        // Pobierz aktywnych klientów
        _clientService.getActiveClients(),
        // Pobierz statystyki
        _clientService.getClientStats(),
      ]);

      if (mounted) {
        setState(() {
          _allClients = futures[0] as List<Client>;
          _activeClients = futures[1] as List<Client>;
          _clientStats = futures[2] as ClientStats;
          _isLoading = false;
        });

        // Debug - sprawdź co otrzymaliśmy
        print('🔍 [EnhancedClientsScreen] Załadowano:');
        print('   - Wszyscy klienci: ${_allClients.length}');
        print('   - Aktywni klienci: ${_activeClients.length}');
        print('   - Stats - totalClients: ${_clientStats?.totalClients}');
        print(
          '   - Stats - totalInvestments: ${_clientStats?.totalInvestments}',
        );
        print(
          '   - Stats - totalRemainingCapital: ${_clientStats?.totalRemainingCapital}',
        );
        print('   - Stats - source: ${_clientStats?.source}');
        
        // ⚠️ DODATKOWE DEBUGOWANIE
        if (_clientStats?.totalRemainingCapital == 0) {
          print('⚠️ [WARNING] Total remaining capital is 0! Checking fallback...');
          print('   - LastUpdated: ${_clientStats?.lastUpdated}');
          print('   - AverageCapitalPerClient: ${_clientStats?.averageCapitalPerClient}');
        }

        // Zastosuj filtrowanie jeśli potrzeba
        _applyCurrentFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Błąd podczas ładowania danych: $e';
        });
      }
    }
  }

  /// Zastosuj obecne filtry do listy klientów
  void _applyCurrentFilters() {
    // Filtrowanie zostanie zastosowane przez getter _displayedClients
    setState(() {});
  }

  /// Obsługa zmiany wyszukiwania z debouncing
  Timer? _searchTimer;
  void _onSearchChanged() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  /// Wykonaj wyszukiwanie i filtrowanie
  Future<void> _performSearch() async {
    if (!mounted) return;

    final query = _searchController.text.trim();

    setState(() {
      _currentSearchQuery = query;
      _isLoading = true;
    });

    try {
      if (query.isNotEmpty) {
        // Użyj Firebase Functions/Integrated Service do wyszukiwania
        final results = await _clientService.getAllClients(
          page: 1,
          pageSize: 5000,
          searchQuery: query,
          sortBy: _sortBy,
          forceRefresh: false,
        );

        setState(() {
          _allClients = results;
          _isLoading = false;
        });
      } else {
        // Jeśli brak zapytania, przeładuj wszystkich klientów
        await _loadInitialData();
      }

      // Zastosuj filtry po wczytaniu
      _applyCurrentFilters();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Błąd podczas wyszukiwania: $e';
        });
      }
    }
  }

  /// Pobierz przefiltrowaną listę klientów
  List<Client> get _displayedClients {
    if (_showActiveOnly) {
      return _activeClients;
    }

    if (_currentSearchQuery.isNotEmpty) {
      // Jeśli jest wyszukiwanie, zwróć wyniki z _allClients (już przefiltrowane przez serwis)
      return _allClients;
    }

    // Zwróć wszystkich klientów
    return _allClients;
  }

  /// Przełącz widok aktywnych klientów
  void _toggleActiveClients() {
    setState(() {
      _showActiveOnly = !_showActiveOnly;
      _applyCurrentFilters();
    });
  }

  /// Odświeżenie danych
  Future<void> _refreshData() async {
    await _loadInitialData();
    _showSuccessSnackBar('Dane zostały odświeżone');
  }

  /// Pokaż formularz klienta
  void _showClientForm([Client? client]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.backgroundModal,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nagłówek
              Row(
                children: [
                  Icon(
                    client == null ? Icons.person_add : Icons.edit,
                    color: AppTheme.secondaryGold,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    client == null ? 'Nowy Klient' : 'Edytuj Klienta',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Formularz klienta
              Expanded(
                child: ClientForm(
                  client: client,
                  onSave: (savedClient) async {
                    Navigator.of(context).pop();

                    try {
                      if (client == null) {
                        // Nowy klient
                        await _clientService.createClient(savedClient);
                        _showSuccessSnackBar('Klient został dodany');
                      } else {
                        // Aktualizacja klienta
                        await _clientService.updateClient(
                          client.id,
                          savedClient,
                        );
                        _showSuccessSnackBar('Klient został zaktualizowany');
                      }

                      // Odśwież dane po zapisaniu
                      await _refreshData();
                    } catch (e) {
                      _showErrorSnackBar('Błąd podczas zapisywania: $e');
                    }
                  },
                  onCancel: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Column(
          children: [
            _buildHeader(),
            _buildStatsBar(),
            _buildToolbar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.gradientDecoration,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '👥 Klienci',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppTheme.textOnPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Zarządzanie bazą klientów',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textOnPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showClientForm(),
            icon: const Icon(Icons.add),
            label: const Text('Nowy Klient'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryGold,
              foregroundColor: AppTheme.textOnSecondary,
              elevation: 4,
              shadowColor: AppTheme.secondaryGold.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    if (_clientStats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSecondary, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildStatChip(
            icon: Icons.people,
            label: 'Łącznie klientów',
            value: '${_clientStats!.totalClients}',
            color: AppTheme.secondaryGold,
          ),
          const SizedBox(width: 16),
          _buildStatChip(
            icon: Icons.trending_up,
            label: 'Inwestycje',
            value: '${_clientStats!.totalInvestments}',
            color: AppTheme.secondaryGold,
          ),
          const SizedBox(width: 16),
          _buildStatChip(
            icon: Icons.account_balance_wallet,
            label: 'Pozostały kapitał',
            value:
                '${(_clientStats!.totalRemainingCapital / 1000000).toStringAsFixed(1)}M PLN',
            color: AppTheme.successColor,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSecondary, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Pole wyszukiwania
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Szukaj po imieniu, emailu, telefonie...',
                hintStyle: const TextStyle(color: AppTheme.textTertiary),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                        icon: const Icon(
                          Icons.clear,
                          color: AppTheme.textSecondary,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surfaceInteractive,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderSecondary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderSecondary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.secondaryGold,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Przełącznik aktywnych klientów
          FilterChip(
            label: Text(
              'Tylko aktywni (${_activeClients.length})',
              style: TextStyle(
                color: _showActiveOnly ? Colors.white : AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            selected: _showActiveOnly,
            onSelected: (bool selected) => _toggleActiveClients(),
            selectedColor: AppTheme.secondaryGold,
            checkmarkColor: Colors.white,
            backgroundColor: AppTheme.surfaceInteractive,
            side: BorderSide(
              color: _showActiveOnly
                  ? AppTheme.secondaryGold
                  : AppTheme.borderSecondary,
            ),
            tooltip: 'Filtruj aktywnych klientów - szybsze ładowanie',
          ),
          const SizedBox(width: 16),

          // Menu opcji
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  _refreshData();
                  break;
                case 'clear_cache':
                  _clearCache();
                  break;
                case 'export':
                  _showInfoSnackBar('Funkcja eksportu będzie dostępna wkrótce');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: AppTheme.textSecondary),
                    SizedBox(width: 12),
                    Text('Odśwież dane'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_cache',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: AppTheme.textSecondary),
                    SizedBox(width: 12),
                    Text('Wyczyść cache'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, color: AppTheme.textSecondary),
                    SizedBox(width: 12),
                    Text('Eksportuj'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CustomLoadingWidget(
          message: 'Ładowanie klientów z Firebase Functions...',
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (_displayedClients.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Expanded(child: _buildClientsList()),
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildClientsList() {
    return DataTableWidget<Client>(
      items: _displayedClients,
      columns: [
        DataTableColumn<Client>(
          label: 'Imię i nazwisko',
          value: (client) =>
              client.name, // W modelu Client: name zawiera fullName z Firebase
          sortable: true,
          width: 200,
        ),
        DataTableColumn<Client>(
          label: 'PESEL',
          value: (client) => client.pesel ?? '',
          sortable: true,
          width: 130,
        ),
        DataTableColumn<Client>(
          label: 'Email',
          value: (client) => client.email,
          sortable: true,
          width: 220,
        ),
        DataTableColumn<Client>(
          label: 'Telefon',
          value: (client) => client.phone,
          sortable: true,
          width: 140,
        ),
        DataTableColumn<Client>(
          label: 'Firma',
          value: (client) => client.companyName ?? '',
          width: 180,
        ),
        DataTableColumn<Client>(
          label: 'Status',
          value: (client) => client.isActive ? 'Aktywny' : 'Nieaktywny',
          width: 100,
          widget: (client) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: client.isActive
                  ? AppTheme.successColor.withValues(alpha: 0.1)
                  : AppTheme.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              client.isActive ? 'Aktywny' : 'Nieaktywny',
              style: TextStyle(
                color: client.isActive
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        DataTableColumn<Client>(
          label: 'Akcje',
          value: (client) => '',
          width: 120,
          widget: (client) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showClientForm(client),
                icon: const Icon(Icons.edit, size: 18),
                tooltip: 'Edytuj',
              ),
              IconButton(
                onPressed: () => _deleteClient(client),
                icon: const Icon(Icons.delete, size: 18),
                tooltip: 'Usuń',
              ),
            ],
          ),
        ),
      ],
      onRowTap: (client) => _showClientForm(client),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          Text(
            'Wystąpił błąd',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Spróbuj ponownie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.textOnPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Brak klientów',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Nie znaleziono klientów spełniających kryteria wyszukiwania'
                : 'Dodaj pierwszego klienta, aby rozpocząć',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showClientForm(),
            icon: const Icon(Icons.add),
            label: const Text('Dodaj Klienta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryGold,
              foregroundColor: AppTheme.textOnSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    try {
      // Odśwież dane bez czyszczenia cache
      await _refreshData();
      _showSuccessSnackBar('Dane zostały odświeżone');
    } catch (e) {
      _showErrorSnackBar('Błąd podczas odświeżania: $e');
    }
  }

  void _deleteClient(Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundModal,
        title: const Text(
          'Potwierdzenie usunięcia',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Czy na pewno chcesz usunąć klienta ${client.name}?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                // Usuń klienta używając ClientService bezpośrednio
                await ClientService().deleteClient(client.id);
                _showSuccessSnackBar('Klient został usunięty');
                await _refreshData();
              } catch (e) {
                _showErrorSnackBar('Błąd podczas usuwania: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: AppTheme.textOnPrimary,
            ),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.infoColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
