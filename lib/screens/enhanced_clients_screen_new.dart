import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../models_and_services.dart';
import '../providers/auth_provider.dart';
import '../widgets/dialogs/enhanced_investor_email_dialog.dart';
import '../widgets/metropolitan_loading_system.dart';
import '../widgets/enhanced_clients/collapsible_search_header.dart';
import '../widgets/enhanced_clients/spectacular_clients_grid.dart';
import '../widgets/enhanced_clients/enhanced_client_stats_display.dart';

/// 🎨 SPEKTAKULARNY EKRAN KLIENTÓW Z EFEKTEM WOW
///
/// Funkcje:
/// - Zwijany nagłówek z animacjami podczas przewijania
/// - Spektakularny grid zamiast tradycyjnej tabeli
/// - Multi-selection z email functionality
/// - Responsywny design z particle effects
/// - Staggered animations i hero transitions
/// - Smart search z morphing field
class EnhancedClientsScreen extends StatefulWidget {
  const EnhancedClientsScreen({super.key});

  @override
  State<EnhancedClientsScreen> createState() => _EnhancedClientsScreenState();
}

class _EnhancedClientsScreenState extends State<EnhancedClientsScreen>
    with TickerProviderStateMixin {
  // Services
  final IntegratedClientService _integratedClientService =
      IntegratedClientService();
  final ClientService _clientService = ClientService();

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Animation Controllers
  late AnimationController _headerController;
  late AnimationController _gridController;
  late AnimationController _selectionController;

  // Data
  List<Client> _allClients = [];
  List<Client> _activeClients = [];
  ClientStats? _clientStats;

  // State
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _showActiveOnly = false;
  String _errorMessage = '';

  // Filtering & sorting
  String _sortBy = 'fullName';
  String _currentSearchQuery = '';

  // Multi-selection
  bool _isSelectionMode = false;
  Set<String> _selectedClientIds = <String>{};

  // Header collapse state
  bool _isHeaderCollapsed = false;

  // Pagination state
  bool _hasMoreData = false;

  List<Client> get _selectedClients => _displayedClients
      .where((client) => _selectedClientIds.contains(client.id))
      .toList();

  // RBAC getter
  bool get canEdit => Provider.of<AuthProvider>(context, listen: false).isAdmin;

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        _refreshData();
        break;
      case 'clear_cache':
        _clearCache();
        break;
    }
  }

  void _loadMoreClients() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Load more clients implementation
      // For now, we'll just set hasMoreData to false
      setState(() {
        _hasMoreData = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _headerController.dispose();
    _gridController.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _gridController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final isCollapsed = _scrollController.offset > 100;
      if (isCollapsed != _isHeaderCollapsed) {
        setState(() {
          _isHeaderCollapsed = isCollapsed;
        });

        if (isCollapsed) {
          _headerController.forward();
        } else {
          _headerController.reverse();
        }
      }
    });
  }

  /// Załaduj dane początkowe wykorzystując IntegratedClientService
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🔄 [EnhancedClientsScreen] Rozpoczynam ładowanie danych...');

      // Równoległe ładowanie danych z progress tracking
      final futures = await Future.wait([
        // Pobierz wszystkich klientów bez ograniczeń
        _integratedClientService.getAllClients(
          page: 1,
          pageSize: 50000, // Bardzo duży limit aby pobrać wszystkich
          sortBy: _sortBy,
          forceRefresh: false,
        ),
        // Pobierz aktywnych klientów
        _integratedClientService.getActiveClients(),
        // Pobierz statystyki
        _integratedClientService.getClientStats(),
      ]);

      if (mounted) {
        final allClients = futures[0] as List<Client>;
        final activeClients = futures[1] as List<Client>;
        final clientStats = futures[2] as ClientStats;

        print('📊 [EnhancedClientsScreen] Wyniki ładowania:');
        print('   - Wszyscy klienci (getAllClients): ${allClients.length}');
        print(
          '   - Aktywni klienci (getActiveClients): ${activeClients.length}',
        );
        print('   - Statystyki - łącznie: ${clientStats.totalClients}');
        print('   - Statystyki - inwestycje: ${clientStats.totalInvestments}');
        print(
          '   - Statystyki - kapitał: ${clientStats.totalRemainingCapital}',
        );

        setState(() {
          _allClients = allClients;
          _activeClients = activeClients;
          _clientStats = clientStats;
          _isLoading = false;
        });

        // Zastosuj filtrowanie jeśli potrzeba
        _applyCurrentFilters();
      }
    } catch (e) {
      print('❌ [EnhancedClientsScreen] Błąd ładowania: $e');
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
        final results = await _integratedClientService.getAllClients(
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
    ClientDialog.show(
      context: context,
      client: client,
      onSave: (savedClient) async {
        try {
          if (client == null) {
            // Nowy klient
            await _clientService.createClient(savedClient);
            _showSuccessSnackBar('Klient został dodany');
          } else {
            // Aktualizacja klienta
            await _clientService.updateClient(client.id, savedClient);
            _showSuccessSnackBar('Klient został zaktualizowany');
          }

          // Odśwież dane po zapisaniu
          await _refreshData();
        } catch (e) {
          _showErrorSnackBar('Błąd podczas zapisywania: $e');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: _isLoading
          ? const Center(
              child: MetropolitanLoadingWidget.clients(showProgress: true),
            )
          : Column(
              children: [
                // 🎨 COLLAPSIBLE SEARCH HEADER
                CollapsibleSearchHeader(
                  searchController: _searchController,
                  onSearchChanged: (query) {
                    _currentSearchQuery = query;
                    _performSearch();
                  },
                  statsWidget: EnhancedClientStatsDisplay(
                    clientStats: _clientStats,
                    isLoading: _isLoading && _clientStats == null,
                    isCompact: _isHeaderCollapsed,
                    showTrends: true,
                    showSourceInfo: true,
                  ),
                  showActiveOnly: _showActiveOnly,
                  onToggleActiveOnly: _toggleActiveClients,
                  activeClientsCount: _activeClients.length,
                  isSelectionMode: _isSelectionMode,
                  onSelectionModeToggle: () {
                    if (_isSelectionMode) {
                      _exitSelectionMode();
                    } else {
                      _enterSelectionMode();
                    }
                  },
                  additionalActions: _buildHeaderActions(),
                ),

                // 🎨 SPECTACULAR CLIENTS GRID
                Expanded(child: _buildContent()),
              ],
            ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isSelectionMode && _selectedClientIds.isNotEmpty) ...[
          ElevatedButton.icon(
            onPressed: _showEmailDialog,
            icon: const Icon(Icons.email),
            label: Text('Email (${_selectedClientIds.length})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryGold,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
        ],

        if (canEdit && !_isSelectionMode) ...[
          ElevatedButton.icon(
            onPressed: () => _showClientForm(),
            icon: const Icon(Icons.add),
            label: const Text('Dodaj Klienta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryGold,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
        ],

        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 12),
                  Text('Odśwież'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear_cache',
              child: Row(
                children: [
                  Icon(Icons.clear_all),
                  SizedBox(width: 12),
                  Text('Wyczyść cache'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: MetropolitanLoadingWidget.clients(showProgress: true),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (_displayedClients.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SpectacularClientsGrid(
        clients: _displayedClients,
        isLoading: _isLoading,
        isSelectionMode: _isSelectionMode,
        selectedClientIds: _selectedClientIds,
        scrollController: _scrollController,
        onClientTap: _isSelectionMode
            ? null
            : (client) => _showClientForm(client),
        onSelectionChanged: (selectedIds) {
          setState(() {
            _selectedClientIds = selectedIds;
          });
        },
        onLoadMore: _hasMoreData ? _loadMoreClients : null,
        hasMoreData: _hasMoreData,
      ),
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
          if (canEdit)
            ElevatedButton.icon(
              onPressed: () => _showClientForm(),
              icon: const Icon(Icons.add),
              label: const Text('Dodaj Klienta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryGold,
                foregroundColor: AppTheme.textOnSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
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
      // Użyj IntegratedClientService do czyszczenia cache
      _integratedClientService.clearAllCache();
      await _refreshData();
      _showSuccessSnackBar('Cache został wyczyszczony i dane odświeżone');
    } catch (e) {
      _showErrorSnackBar('Błąd podczas czyszczenia cache: $e');
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
                await _clientService.deleteClient(client.id);
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

  // 🚀 NOWE: Funkcje multi-selection dla email
  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedClientIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedClientIds.clear();
    });
  }

  Future<void> _showEmailDialog() async {
    if (_selectedClients.isEmpty) {
      _showErrorSnackBar('Nie wybrano żadnych klientów');
      return;
    }

    // Konwertuj klientów na InvestorSummary (potrzebne dane inwestycji)
    final investorAnalyticsService = InvestorAnalyticsService();

    try {
      // Pobierz dane inwestycji dla wybranych klientów
      final investorsData = await investorAnalyticsService
          .getInvestorsByClientIds(_selectedClients.map((c) => c.id).toList());

      if (!mounted) return;

      if (investorsData.isEmpty) {
        _showErrorSnackBar('Wybrani klienci nie mają żadnych inwestycji');
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => EnhancedInvestorEmailDialog(
          selectedInvestors: investorsData,
          onEmailSent: () {
            _exitSelectionMode();
            _showSuccessSnackBar('Email został wysłany pomyślnie');
          },
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Błąd podczas pobierania danych inwestycji: $e');
    }
  }
}
