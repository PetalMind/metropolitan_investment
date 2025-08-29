import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models_and_services.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme_professional.dart';
import '../widgets/enhanced_clients/collapsible_search_header_fixed.dart'
    as CollapsibleHeader;
import '../widgets/enhanced_clients/spectacular_clients_grid.dart';
import '../widgets/enhanced_clients/enhanced_clients_header.dart';
import '../widgets/dialogs/enhanced_email_editor_dialog 2.dart';
import '../widgets/enhanced_client_dialog/enhanced_client_dialog.dart';

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
  // Services - UŻYWAMY JUŻ ISTNIEJĄCYCH SERWISÓW + DODATKOWY FALLBACK + OPTIMIZED SERVICE
  final IntegratedClientService _integratedClientService =
      IntegratedClientService();
  final OptimizedProductService _optimizedProductService =
      OptimizedProductService(); // 🚀 GŁÓWNY SERWIS jak w Premium Analytics
  final EnhancedClientService _enhancedClientService =
      EnhancedClientService(); // 🚀 NOWY: Server-side optimized service
  final InvestorAnalyticsService _investorAnalyticsService =
      InvestorAnalyticsService(); // 🚀 NOWY: Pobieranie danych inwestycji

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // Debounce timer for search
  Timer? _searchDebounce;

  // Animation Controllers
  late AnimationController _headerController;
  late AnimationController _gridController;
  late AnimationController _selectionController;

  // Data
  List<Client> _allClients = [];
  List<Client> _activeClients = [];
  ClientStats? _clientStats;
  
  // 🚀 NOWE: Dane inwestycji i kapitału
  Map<String, InvestorSummary> _investorSummaries = {}; // clientId -> InvestorSummary
  Map<String, List<Investment>> _clientInvestments = {}; // clientId -> List<Investment>

  // State
  bool _isLoading = true;
  bool _isSearching = false; // 🚀 NOWE: Stan ładowania tylko dla wyszukiwania
  bool _isLoadingMore = false;
  bool _showActiveOnly = false;
  String _errorMessage = '';

  // Filtering & sorting
  final String _sortBy = 'fullName';
  String _currentSearchQuery = '';
  String _lastServerSearchQuery =
      ''; // 🚀 NOWE: Śledzenie ostatniego zapytania do serwera

  // Multi-selection
  bool _isSelectionMode = false;
  bool _isEmailMode = false; // 🚀 NOWY: Tryb email
  bool _isExportMode =
      false; // 🚀 NOWY: Tryb eksportu (podobnie jak w premium analytics)
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
    // cancel debounce timer if active
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _headerController.dispose();
    _gridController.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  /// Handler for search controller changes with debounce
  void _onSearchChanged() {
    // update local query immediately for UI responsiveness
    _currentSearchQuery = _searchController.text;

    // debounce server searches
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        _performSearch();
      }
    });
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

  /// 🚀 NOWA METODA: Załaduj WSZYSTKICH klientów bezpośrednio z bazy
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print(
        '🔄 [EnhancedClientsScreen] Rozpoczynam ładowanie WSZYSTKICH klientów...',
      );

      // 🚀 KROK 1: Pobierz WSZYSTKICH klientów bezpośrednio z bazy
      print(
        '🎯 [EnhancedClientsScreen] Pobieranie WSZYSTKICH klientów z bazy...',
      );

      final enhancedResult = await _enhancedClientService.getAllActiveClients(
        limit: 10000,
        includeInactive: true, // Pobierz wszystkich, łącznie z nieaktywnymi
        forceRefresh: true,
      );

      if (!enhancedResult.hasError && enhancedResult.clients.isNotEmpty) {
        print(
          '✅ [KROK 1] EnhancedClientService SUCCESS - pobrano ${enhancedResult.clients.length} WSZYSTKICH klientów',
        );

        // 🚀 KROK 2: Opcjonalnie wzbogać o dane inwestycyjne
        try {
          final optimizedResult = await _optimizedProductService
              .getAllProductsOptimized(
                forceRefresh: true,
                includeStatistics: true,
                maxProducts: 10000,
              );

          print(
            '✅ [KROK 2] OptimizedProductService SUCCESS - ${optimizedResult.products.length} produktów',
          );

          // Utwórz statystyki kombinowane
          ClientStats? clientStats;
          if (optimizedResult.statistics != null &&
              enhancedResult.statistics != null) {
            clientStats = ClientStats(
              totalClients: enhancedResult.clients.length,
              totalInvestments: optimizedResult.statistics!.totalInvestors,
              totalRemainingCapital:
                  optimizedResult.statistics!.totalRemainingCapital,
              averageCapitalPerClient: enhancedResult.clients.isNotEmpty
                  ? optimizedResult.statistics!.totalRemainingCapital /
                        enhancedResult.clients.length
                  : 0.0,
              lastUpdated: DateTime.now().toIso8601String(),
              source: 'EnhancedClientService+OptimizedProductService',
            );
          }

          setState(() {
            _allClients = enhancedResult.clients;
            _activeClients = enhancedResult.clients
                .where((c) => c.isActive != false)
                .toList();
            _clientStats = clientStats;
            _isLoading = false;
          });

          print(
            '✅ [SUCCESS] Dane załadowane z EnhancedClientService+OptimizedProductService:',
          );
          print('    - ${enhancedResult.clients.length} klientów WSZYSTKICH');
          print(
            '    - ${enhancedResult.statistics?.activeClients ?? 0} aktywnych',
          );
          print('    - ${optimizedResult.products.length} produktów');
          print(
            '    - ${optimizedResult.statistics?.totalRemainingCapital.toStringAsFixed(2) ?? '0'} PLN kapitału',
          );
          print('    - Źródło: EnhancedClientService+OptimizedProductService');

          // 🚀 NOWE: Pobierz dane inwestycji i kapitału
          await _loadInvestmentData();
        } catch (productError) {
          print('⚠️ [KROK 2] OptimizedProductService failed: $productError');

          // Kontynuuj tylko z klientami bez danych inwestycyjnych
          setState(() {
            _allClients = enhancedResult.clients;
            _activeClients = enhancedResult.clients
                .where((c) => c.isActive != false)
                .toList();
            _clientStats = enhancedResult.statistics?.toClientStats();
            _isLoading = false;
          });

          print(
            '✅ [SUCCESS] Dane załadowane tylko z EnhancedClientService (bez inwestycji)',
          );
          print('    - ${enhancedResult.clients.length} klientów WSZYSTKICH');
          print(
            '    - ${enhancedResult.statistics?.activeClients ?? 0} aktywnych',
          );

          // 🚀 NOWE: Pobierz dane inwestycji i kapitału
          await _loadInvestmentData();
        }
      } else {
        print(
          '⚠️ [KROK 1] EnhancedClientService failed: ${enhancedResult.error}',
        );

        // FALLBACK: Stara metoda przez OptimizedProductService
        await _loadDataViaProducts();
      }

      // 🚀 ZAWSZE ładowane dane inwestycji po załadowaniu klientów
      await _loadInvestmentData();
    } catch (e) {
      print('❌ [EnhancedClientsScreen] Krytyczny błąd ładowania: $e');
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
    // Uwaga: nie zmieniamy trybów tutaj — tylko wymuszamy re-render aby filtry się zastosowały
    if (mounted) {
      setState(() {});
    }
  }

  // 🚀 NOWE: Funkcje obsługi email i eksportu (wzorowane na premium_investor_analytics_screen)
  void _toggleEmailMode() {
    setState(() {
      _isEmailMode = !_isEmailMode;
      if (_isEmailMode) {
        _isSelectionMode = true;
        _isExportMode = false; // Wyłącz tryb eksportu
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
            '📧 Tryb email aktywny - wybierz odbiorców wiadomości',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppThemePro.accentGold,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Anuluj',
            textColor: AppThemePro.backgroundPrimary,
            onPressed: _toggleEmailMode,
          ),
        ),
      );
    }
  }

  void _toggleExportMode() {
    setState(() {
      _isExportMode = !_isExportMode;
      if (_isExportMode) {
        _isSelectionMode = true;
        _isEmailMode = false; // Wyłącz tryb email
        // edit mode removed
        _selectedClientIds.clear();
      } else {
        _isSelectionMode = false;
        _selectedClientIds.clear();
      }
    });
    // edit mode removed
    if (_isExportMode) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '📊 Tryb eksportu aktywny - wybierz klientów do wyeksportowania',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppThemePro.statusInfo,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Anuluj',
            textColor: Colors.white,
            onPressed: _toggleExportMode,
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
      _isExportMode = false;
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

    // Dla krótkich zapytań (1-2 znaki) używaj lokalnego filtrowania - BEZ ładowania
    if (query.length <= 2) {
      setState(() {
        _currentSearchQuery = query;
        _isSearching = false; // Nie szukamy już
      });
      return;
    }

    // Sprawdź czy to jest to samo zapytanie co ostatnio
    if (query == _lastServerSearchQuery) {
      print('🔄 [Search] To samo zapytanie, pomijam: "$query"');
      return;
    }

    // Dla dłuższych zapytań używaj serwera z debouncing
    setState(() {
      _currentSearchQuery = query;
      _isSearching = true; // 🚀 Ustaw stan wyszukiwania
      _lastServerSearchQuery = query; // Zapisz ostatnie zapytanie
    });

    try {
      if (query.isNotEmpty) {
        print('🔍 [Search] Wyszukiwanie na serwerze: "$query"');

        // Użyj Firebase Functions/Integrated Service do wyszukiwania
        final results = await _integratedClientService.getAllClients(
          page: 1,
          pageSize: 5000,
          searchQuery: query,
          sortBy: _sortBy,
          forceRefresh: false,
        );

        if (mounted) {
          setState(() {
            _allClients = results;
            _isSearching = false; // 🚀 Zakończ wyszukiwanie
          });
        }

        print('✅ [Search] Znaleziono ${results.length} klientów dla: "$query"');
      } else {
        // Jeśli brak zapytania, przeładuj wszystkich klientów
        print('🔄 [Search] Brak zapytania - przeładowanie wszystkich klientów');
        await _loadInitialData();
      }

      // Zastosuj filtry po wczytaniu
      _applyCurrentFilters();
    } catch (e) {
      print('❌ [Search] Błąd podczas wyszukiwania: $e');
      if (mounted) {
        setState(() {
          _isSearching = false; // 🚀 Zakończ wyszukiwanie nawet przy błędzie
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
    print(
      '🔄 [EnhancedClientsScreen] _refreshData() - rozpoczynanie odświeżania...',
    );
    await _loadInitialData();
    // 🚀 ZAWSZE odśwież dane inwestycji po odświeżeniu klientów
    await _loadInvestmentData();
    _showSuccessSnackBar('Dane zostały odświeżone');
  }

  /// Pokaż formularz klienta
  void _showClientForm([Client? client]) {
    // 🚀 NOWY: Użyj Enhanced Client Dialog zamiast starszego ClientDialog
    EnhancedClientDialog.show(
      context: context,
      client: client,
      additionalData: {
        'investorSummaries': _investorSummaries,
        'clientInvestments': _clientInvestments,
        'clientStats': _clientStats,
      },
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppThemePro.statusSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppThemePro.statusError,
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
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.accentGold.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppThemePro.accentGold, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppThemePro.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: AppThemePro.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Wysyła email do wybranych klientów (wzorowane na premium_investor_analytics_screen)
  Future<void> _sendEmailToSelectedClients() async {
    if (_selectedClients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Najpierw wybierz odbiorców maili\n💡 Użyj trybu email aby wybrać klientów'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      
      if (!_isEmailMode && !_isSelectionMode) {
        _toggleEmailMode();
      }
      return;
    }

    // 🚀 SPRAWDZENIE: Czy dane inwestycji są załadowane
    if (_investorSummaries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ Dane inwestycji się ładują - spróbuj ponownie za chwilę'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Wybrani klienci nie mają prawidłowych adresów email'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    try {
      // 🚀 POPRAWKA: Użyj prawdziwych danych inwestycji zamiast pustych list
      final investorsData = clientsWithEmail.map((client) {
        // Sprawdź czy mamy dane inwestora w cache
        final cachedSummary = _investorSummaries[client.id];
        if (cachedSummary != null) {
          return cachedSummary; // Użyj prawdziwych danych z cache
        } else {
          // Fallback: utwórz z pustymi danymi (ale z ostrzeżeniem)
          print('⚠️ [Email] Brak danych inwestora dla ${client.name} - używam pustych danych');
          return InvestorSummary.fromInvestments(client, []);
        }
      }).toList();

      if (!mounted) return;

      // 🚀 WZOROWANE NA PREMIUM ANALYTICS: Używamy EnhancedEmailEditorDialog
      showDialog(
        context: context,
        builder: (context) => EnhancedEmailEditorDialog(
          selectedInvestors: investorsData,
          onEmailSent: () {
            Navigator.of(context).pop();
            _toggleEmailMode(); // Wyłącz tryb email po wysłaniu
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Emaile zostały wysłane do ${clientsWithEmail.length} odbiorców'),
                backgroundColor: AppThemePro.statusSuccess,
              ),
            );
          },
          initialSubject: 'Informacje o klientach - Metropolitan Investment',
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Błąd podczas przygotowywania danych: $e');
    }
  }

  /// Eksportuje wybranych klientów do różnych formatów (wzorowane na premium_investor_analytics_screen)
  Future<void> _exportSelectedClients() async {
    if (_selectedClients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Najpierw wybierz klientów do eksportu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 🚀 SPRAWDZENIE: Czy dane inwestycji są załadowane
    if (_investorSummaries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ Dane inwestycji się ładują - spróbuj ponownie za chwilę'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // 🚀 POPRAWKA: Użyj prawdziwych danych inwestycji zamiast pustych list
    final investorsData = _selectedClients.map((client) {
      // Sprawdź czy mamy dane inwestora w cache
      final cachedSummary = _investorSummaries[client.id];
      if (cachedSummary != null) {
        return cachedSummary; // Użyj prawdziwych danych z cache
      } else {
        // Fallback: utwórz z pustymi danymi (ale z ostrzeżeniem)
        print('⚠️ [Export] Brak danych inwestora dla ${client.name} - używam pustych danych');
        return InvestorSummary.fromInvestments(client, []);
      }
    }).toList();

    showDialog(
      context: context,
      builder: (context) => InvestorExportDialog(
        selectedInvestors: investorsData,
        onExportComplete: () {
          Navigator.of(context).pop();
          _toggleExportMode(); // Wyłącz tryb eksportu
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Eksport zakończony pomyślnie'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }



  /// Banner dla trybu eksportu (wzorowane na premium analytics)
  Widget _buildExportModeBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.statusInfo.withOpacity(0.8),
            AppThemePro.statusInfo.withOpacity(0.6),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.statusInfo.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.file_download,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📊 Tryb eksportu aktywny',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _selectedClientIds.isEmpty
                      ? 'Wybierz klientów do wyeksportowania'
                      : '${_selectedClientIds.length} klientów wybranych',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedClientIds.isNotEmpty)
            TextButton.icon(
              onPressed: _exportSelectedClients,
              icon: const Icon(Icons.download, color: Colors.white, size: 18),
              label: const Text(
                'Eksportuj',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _toggleExportMode,
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Zamknij tryb eksportu',
          ),
        ],
      ),
    );
  }

  // Edit mode banner removed.

  /// Banner dla trybu email (wzorowane na premium analytics)
  Widget _buildEmailModeBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.accentGold.withOpacity(0.8),
            AppThemePro.accentGold.withOpacity(0.6),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.email,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📧 Tryb email aktywny',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _selectedClientIds.isEmpty
                      ? 'Wybierz odbiorców wiadomości'
                      : '${_selectedClientIds.length} odbiorców wybranych',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedClientIds.isNotEmpty)
            TextButton.icon(
              onPressed: _sendEmailToSelectedClients,
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              label: const Text(
                'Wyślij',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _toggleEmailMode,
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Zamknij tryb email',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppThemePro.backgroundPrimary,
        body: const Center(child: PremiumShimmerLoadingWidget.fullScreen()),
      );
    }
    return Scaffold(
      backgroundColor: AppThemePro.backgroundPrimary,
      body: Column(
        children: [
          // 🚀 NOWY: Enhanced responsywny header z animacjami (wzorowany na premium analytics)
          EnhancedClientsHeader(
            isTablet: _isTablet,
            canEdit: canEdit,
            totalCount: _allClients.length,
            isLoading: _isLoading,
            isSelectionMode: _isSelectionMode,
            isEmailMode: _isEmailMode,
            isExportMode: _isExportMode,
            selectedClientIds: _selectedClientIds,
            displayedClients: _displayedClients,
            onAddClient: () => _showClientForm(),
            onToggleEmail: _toggleEmailMode,
            onToggleExport: _toggleExportMode,
            onSelectAll: _selectAllClients,
            onClearSelection: _clearSelection,
          ),

          // 🚀 NOWY: Export Mode Banner (wzorowane na premium analytics)
          if (_isExportMode) _buildExportModeBanner(),
          
          // 🚀 NOWY: Email Mode Banner
          if (_isEmailMode) _buildEmailModeBanner(),
          
          // 🚀 NOWY: Edit Mode Banner
          // edit mode removed

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
    // 🚀 Pokaż loading tylko podczas wyszukiwania, nie podczas ładowania początkowego
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Wyszukiwanie klientów...',
              style: TextStyle(color: AppThemePro.textSecondary),
            ),
          ],
        ),
      );
    }

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
        isLoading:
            _isLoading || _isSearching, // 🚀 Uwzględnij stan wyszukiwania
        isSelectionMode: _isSelectionMode || _isExportMode || _isEmailMode,
        selectedClientIds: _selectedClientIds,
        scrollController: _scrollController,
        onClientTap: (_isSelectionMode || _isExportMode || _isEmailMode)
            ? null
            : (client) => _showClientForm(client),
        onSelectionChanged: (selectedIds) {
          setState(() {
            _selectedClientIds = selectedIds;
          });
        },
        onLoadMore: _hasMoreData ? _loadMoreClients : null,
        hasMoreData: _hasMoreData,
        
        // 🚀 NOWE: Przekaż dane inwestycji
        investorSummaries: _investorSummaries,
        clientInvestments: _clientInvestments,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: AppThemePro.statusError),
          const SizedBox(height: 16),
          Text(
            'Wystąpił błąd',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(
              color: AppThemePro.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppThemePro.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Spróbuj ponownie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemePro.accentGold,
              foregroundColor: AppThemePro.textPrimary,
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
          Icon(Icons.people_outline, size: 80, color: AppThemePro.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Brak klientów',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(
              color: AppThemePro.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Nie znaleziono klientów spełniających kryteria wyszukiwania'
                : 'Dodaj pierwszego klienta, aby rozpocząć',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppThemePro.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (canEdit)
            ElevatedButton.icon(
              onPressed: () => _showClientForm(),
              icon: const Icon(Icons.add),
              label: const Text('Dodaj Klienta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemePro.accentGold,
                foregroundColor: AppThemePro.textPrimary,
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

  /// 🚀 NOWA METODA: Ładowanie danych inwestycji i kapitału dla wszystkich klientów
  Future<void> _loadInvestmentData() async {
    print('💰 [InvestmentData] Ładowanie danych inwestycji dla ${_allClients.length} klientów...');
    
    try {
      // Użyj InvestorAnalyticsService do pobierania wszystkich danych inwestorów
      final allInvestorSummaries = await _investorAnalyticsService.getAllInvestorsForAnalysis(
        includeInactive: true, // Pobierz wszystkich klientów
      );
      
      print('✅ [InvestmentData] Pobrano ${allInvestorSummaries.length} podsumowań inwestorów');
      
      // Utwórz mapę clientId -> InvestorSummary
      final Map<String, InvestorSummary> summariesMap = {};
      final Map<String, List<Investment>> investmentsMap = {};
      
      for (final summary in allInvestorSummaries) {
        summariesMap[summary.client.id] = summary;
        investmentsMap[summary.client.id] = summary.investments;
        
        print('💰 ${summary.client.name}: ${summary.totalRemainingCapital.toStringAsFixed(2)} PLN (${summary.investmentCount} inwestycji)');
      }
      
      setState(() {
        _investorSummaries = summariesMap;
        _clientInvestments = investmentsMap;
      });
      
      print('✅ [InvestmentData] Zaktualizowano dane inwestycji dla ${summariesMap.length} klientów');
      print(
        '🎯 [InvestmentData] Dane inwestycji przekazane do SpectacularClientsGrid - premium animacje powinny działać!',
      );
    } catch (e) {
      print('⚠️ [InvestmentData] Błąd ładowania danych inwestycji: $e');
      // Nie przerywamy ładowania - klienci mogą być wyświetleni bez danych inwestycji
    }
  }

  /// Fallback method - ładowanie przez produkty (stara metoda)
  Future<void> _loadDataViaProducts() async {
    print('🔄 [FALLBACK] Ładowanie przez OptimizedProductService...');

    try {
      final optimizedResult = await _optimizedProductService
          .getAllProductsOptimized(
            forceRefresh: true,
            includeStatistics: true,
            maxProducts: 10000,
          );

      print('✅ [FALLBACK] OptimizedProductService SUCCESS');
      print('   - Produkty: ${optimizedResult.products.length}');

      // Wyciągnij unikalnych klientów z produktów (tylko IDs)
      final Set<String> uniqueClientIds = {};
      for (final product in optimizedResult.products) {
        for (final investor in product.topInvestors) {
          uniqueClientIds.add(investor.clientId);
        }
      }

      print(
        '📋 [FALLBACK] Znaleziono ${uniqueClientIds.length} unikalnych ID klientów',
      );

      // Pobierz pełne dane klientów
      final enhancedResult = await _enhancedClientService.getClientsByIds(
        uniqueClientIds.toList(),
        includeStatistics: true,
        maxClients: 1000,
      );

      if (!enhancedResult.hasError && enhancedResult.clients.isNotEmpty) {
        print(
          '✅ [FALLBACK] EnhancedClientService SUCCESS - pobrano ${enhancedResult.clients.length} klientów',
        );

        // Utwórz mapę inwestycji per klient
        final Map<String, dynamic> clientInvestments = {};
        for (final product in optimizedResult.products) {
          for (final investor in product.topInvestors) {
            clientInvestments.putIfAbsent(investor.clientId, () => []);
            clientInvestments[investor.clientId]!.add(product);
          }
        }

        ClientStats? clientStats;
        if (optimizedResult.statistics != null &&
            enhancedResult.statistics != null) {
          clientStats = ClientStats(
            totalClients: enhancedResult.clients.length,
            totalInvestments: optimizedResult.statistics!.totalInvestors,
            totalRemainingCapital:
                optimizedResult.statistics!.totalRemainingCapital,
            averageCapitalPerClient: enhancedResult.clients.isNotEmpty
                ? optimizedResult.statistics!.totalRemainingCapital /
                      enhancedResult.clients.length
                : 0.0,
            lastUpdated: DateTime.now().toIso8601String(),
            source: 'OptimizedProductService+EnhancedClientService (FALLBACK)',
          );
        }

        setState(() {
          _allClients = enhancedResult.clients;
          _activeClients = enhancedResult.clients
              .where((c) => c.isActive != false)
              .toList();
          _clientStats = clientStats;
          _isLoading = false;
        });

        print(
          '✅ [FALLBACK SUCCESS] ${enhancedResult.clients.length} klientów załadowanych przez produkty',
        );
      } else {
        throw Exception(
          'EnhancedClientService failed: ${enhancedResult.error}',
        );
      }
    } catch (e) {
      print('❌ [FALLBACK] Błąd: $e');
      setState(() {
        _errorMessage = 'Błąd ładowania danych: $e';
        _isLoading = false;
      });
    }

    // Zawsze załaduj dane inwestycji na końcu
    await _loadInvestmentData();
  }
}
