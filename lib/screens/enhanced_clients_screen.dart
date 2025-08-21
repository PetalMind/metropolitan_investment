import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models_and_services.dart';
import '../providers/auth_provider.dart';
import '../widgets/enhanced_clients/collapsible_search_header_fixed.dart'
    as CollapsibleHeader;
import '../widgets/enhanced_clients/spectacular_clients_grid.dart';
import '../widgets/enhanced_clients/enhanced_clients_header.dart';

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
  // Services - UŻYWAMY JUŻ ISTNIEJĄCYCH SERWISÓW
  final IntegratedClientService _integratedClientService =
      IntegratedClientService();
  final UnifiedDashboardStatisticsService _dashboardStatsService =
      UnifiedDashboardStatisticsService();

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
  bool _isEmailMode = false; // 🚀 NOWY: Tryb email
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

  // Responsywność
  bool get _isTablet => MediaQuery.of(context).size.width > 768;

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

      // Równoległe ładowanie danych używając istniejących serwisów
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
        // Pobierz statystyki klientów - główny serwis
        _integratedClientService.getClientStats(),
        // Pobierz zunifikowane statystyki dashboard jako backup
        _dashboardStatsService.getStatisticsFromInvestments(),
      ]);

      if (mounted) {
        final allClients = futures[0] as List<Client>;
        final activeClients = futures[1] as List<Client>;
        final clientStats = futures[2] as ClientStats;
        final dashboardStats = futures[3] as UnifiedDashboardStatistics;

        print('📊 [EnhancedClientsScreen] Wyniki ładowania:');
        print('   - Wszyscy klienci (getAllClients): ${allClients.length}');
        print(
          '   - Aktywni klienci (getActiveClients): ${activeClients.length}',
        );

        // 🔍 SZCZEGÓŁOWE DEBUGGING STATYSTYK
        print('   - Statystyki otrzymane: $clientStats');
        print('   - Statystyki - łącznie: ${clientStats.totalClients}');
        print('   - Statystyki - inwestycje: ${clientStats.totalInvestments}');
        print(
          '   - Statystyki - kapitał: ${clientStats.totalRemainingCapital}',
        );
        print(
          '   - Statystyki - średnia na klienta: ${clientStats.averageCapitalPerClient}',
        );
        print('   - Statystyki - źródło: ${clientStats.source}');
        print(
          '   - Statystyki - ostatnia aktualizacja: ${clientStats.lastUpdated}',
        );

        setState(() {
          _allClients = allClients;
          _activeClients = activeClients;
          _clientStats = clientStats;
          _isLoading = false;
        });

        // 🎉 SUCCESS: Statystyki załadowane
        print('✅ [SUCCESS] Statystyki załadowane pomyślnie:');
        print('   - ${clientStats.totalClients} klientów');
        print('   - ${clientStats.totalInvestments} inwestycji');
        print(
          '   - ${clientStats.totalRemainingCapital.toStringAsFixed(2)} PLN kapitału',
        );
        print('   - Źródło: ${clientStats.source}');

        // 🚨 TYLKO JEŚLI WSZYSTKIE POLA SĄ 0 - użyj inteligentnego fallback z dashboardStats
        if (clientStats.totalClients == 0 &&
            clientStats.totalInvestments == 0 &&
            clientStats.totalRemainingCapital == 0.0) {
          print(
            '⚠️ [EMERGENCY] Wszystkie statystyki są 0 - używam dashboardStats jako backup...',
          );

          // Użyj dashboardStats które już mamy załadowane
          final smartStats = ClientStats(
            totalClients: _allClients.length, // Prawdziwa liczba klientów
            totalInvestments: dashboardStats.totalInvestments,
            totalRemainingCapital: dashboardStats.totalRemainingCapital,
            averageCapitalPerClient: _allClients.length > 0
                ? dashboardStats.totalRemainingCapital / _allClients.length
                : 0.0,
            lastUpdated: DateTime.now().toIso8601String(),
            source: 'dashboard-stats-smart-backup',
          );

          setState(() {
            _clientStats = smartStats;
          });

          print('🎯 [EMERGENCY] Użyto inteligentnego backup:');
          print('   - ${_allClients.length} klientów (rzeczywista liczba)');
          print(
            '   - ${dashboardStats.totalInvestments} inwestycji (z dashboard)',
          );
          print(
            '   - ${dashboardStats.totalRemainingCapital.toStringAsFixed(2)} PLN kapitału (z dashboard)',
          );
          print('   - Źródło: dashboard-stats-smart-backup');
        }

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
    _searchTimer = Timer(const Duration(milliseconds: 1000), () {
      _performSearch();
    });
  }

  // 🚀 NOWE: Funkcje obsługi email
  void _toggleEmailMode() {
    setState(() {
      _isEmailMode = !_isEmailMode;
      if (_isEmailMode) {
        _isSelectionMode = true;
        _selectedClientIds.clear();
      } else {
        _isSelectionMode = false;
        _selectedClientIds.clear();
      }
    });

    if (_isEmailMode) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Tryb email aktywny - wybierz odbiorców wiadomości',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppTheme.secondaryGold,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Anuluj',
            textColor: AppTheme.backgroundPrimary,
            onPressed: _toggleEmailMode,
          ),
        ),
      );
    }
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedClientIds.clear();
    });
    _selectionController.forward();
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _isEmailMode = false;
      _selectedClientIds.clear();
    });
    _selectionController.reverse();
  }

  void _selectAllClients() {
    setState(() {
      _selectedClientIds = _displayedClients.map((client) => client.id).toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedClientIds.clear();
    });
  }

  /// Wykonaj wyszukiwanie i filtrowanie
  Future<void> _performSearch() async {
    if (!mounted) return;

    final query = _searchController.text.trim();

    // Dla krótkich zapytań (1-2 znaki) używaj lokalnego filtrowania
    if (query.length <= 2) {
      setState(() {
        _currentSearchQuery = query;
      });
      return;
    }

    // Dla dłuższych zapytań używaj serwera z debouncing
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

    // Dla krótkich zapytań (1-2 znaki) używaj lokalnego filtrowania
    if (_currentSearchQuery.isNotEmpty && _currentSearchQuery.length <= 2) {
      final query = _currentSearchQuery.toLowerCase();
      return _allClients.where((client) {
        final clientName = client.name.toLowerCase();
        final companyName = client.companyName?.toLowerCase() ?? '';
        final email = client.email.toLowerCase();

        return clientName.contains(query) ||
            companyName.contains(query) ||
            email.contains(query);
      }).toList();
    }

    if (_currentSearchQuery.isNotEmpty && _currentSearchQuery.length > 2) {
      // Jeśli jest długie wyszukiwanie, zwróć wyniki z _allClients (już przefiltrowane przez serwis)
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
            await _integratedClientService.createClient(savedClient);
            _showSuccessSnackBar('Klient został dodany');
          } else {
            // Aktualizacja klienta
            await _integratedClientService.updateClient(client.id, savedClient);
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

  Widget _buildStatsWidget(ClientStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Klienci',
              stats.totalClients.toString(),
              Icons.people,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Inwestycje',
              stats.totalInvestments.toString(),
              Icons.trending_up,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Kapitał',
              '${(stats.totalRemainingCapital / 1000000).toStringAsFixed(1)}M PLN',
              Icons.attach_money,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.secondaryGold.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.secondaryGold, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _showEmailDialog() async {
    if (_selectedClients.isEmpty) {
      _showErrorSnackBar('Nie wybrano żadnych klientów');
      return;
    }

    // Filtruj klientów z prawidłowymi emailami
    final clientsWithEmail = _selectedClients
        .where(
          (client) =>
              client.email.isNotEmpty &&
              RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(client.email),
        )
        .toList();

    if (clientsWithEmail.isEmpty) {
      _showErrorSnackBar('Wybrani klienci nie mają prawidłowych adresów email');
      return;
    }

    try {
      // Konwertuj klientów na InvestorSummary (z pustymi inwestycjami)
      final investorsData = clientsWithEmail
          .map((client) => InvestorSummary.fromInvestments(client, []))
          .toList();

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => EnhancedEmailEditorDialog(
          selectedInvestors: investorsData,
          onEmailSent: () {
            _exitSelectionMode();
            _showSuccessSnackBar('Email został wysłany pomyślnie');
          },
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Błąd podczas przygotowywania danych: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        body: const Center(child: PremiumShimmerLoadingWidget.fullScreen()),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Column(
        children: [
          // 🚀 NOWY: Enhanced responsywny header z animacjami
          EnhancedClientsHeader(
            isTablet: _isTablet,
            canEdit: canEdit,
            totalCount: _allClients.length,
            isLoading: _isLoading,
            isRefreshing: _isLoading, // używamy tego samego stanu
            isSelectionMode: _isSelectionMode,
            isEmailMode: _isEmailMode,
            selectedClientIds: _selectedClientIds,
            displayedClients: _displayedClients,
            onRefresh: _refreshData,
            onAddClient: () => _showClientForm(),
            onToggleEmail: _toggleEmailMode,
            onEmailClients:
                _showEmailDialog, // 🚀 NOWY: Callback do wysyłania email
            onClearCache: _clearCache,
            onSelectAll: _selectAllClients,
            onClearSelection: _clearSelection,
          ),

          // 🎨 LEGACY COLLAPSIBLE SEARCH HEADER - TYLKO DLA WYSZUKIWANIA I FILTRÓW
          CollapsibleHeader.CollapsibleSearchHeader(
            searchController: _searchController,
            isCollapsed:
                _isHeaderCollapsed, // 🚀 KONTROLUJE UKRYWANIE STATYSTYK
            onSearchChanged: (query) {
              _currentSearchQuery = query;
              _performSearch();
            },
            statsWidget: _clientStats != null
                ? _buildStatsWidget(_clientStats!)
                : null,
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
            additionalActions:
                null, // 🚀 USUNIĘTE: actions są teraz w nowym headerze
          ),

          // 🎨 SPECTACULAR CLIENTS GRID - POZOSTAŁA PRZESTRZEŃ
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: PremiumShimmerLoadingWidget.fullScreen());
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
}
