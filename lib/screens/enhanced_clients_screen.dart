import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models_and_services.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme_professional.dart';
import '../widgets/enhanced_clients/collapsible_search_header_fixed.dart'
    as CollapsibleHeader;
import '../widgets/enhanced_clients/spectacular_clients_grid.dart';
import '../widgets/enhanced_clients/enhanced_clients_header.dart';
import '../widgets/enhanced_clients/clients_legend_widget.dart';
import '../screens/wow_email_editor_screen.dart';
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
  // Services - UŻYWAMY JUŻ ISTNIEJĄCYCH SERWISÓW
  final IntegratedClientService _integratedClientService =
      IntegratedClientService();

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
  List<Client> _originalClients =
      []; // 🚀 NOWE: Przechowuje wszystkich klientów dla zachowania zaznaczenia
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

  // 🚀 NOWE: Stan ładowania danych inwestycji
  bool _isInvestmentDataLoaded = false;

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
  
  // 🎯 NOWE: Stan legendy
  bool _isLegendExpanded = false;

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

  /// 🚀 NOWA METODA: Załaduj WSZYSTKICH klientów bezpośrednio z Firebase Functions
  Future<void> _loadInitialData() async {
    if (!mounted) return; // 🛡️ SPRAWDZENIE: czy widget jest aktywny
    
    setState(() {
      _isLoading = true;
      _isInvestmentDataLoaded = false; // Reset stanu danych inwestycji
      _errorMessage = '';
    });

    try {
      print(
        '🔄 [EnhancedClientsScreen] Rozpoczynam ładowanie WSZYSTKICH klientów z Firebase Functions...',
      );

      // 🚀 KROK 1: Pobierz WSZYSTKICH klientów przez Firebase Functions
      print(
        '🎯 [EnhancedClientsScreen] Pobieranie WSZYSTKICH klientów przez Firebase Functions...',
      );

      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final clientsResult = await functions
          .httpsCallable('getAllActiveClientsFunction')
          .call({
            'options': {'limit': 10000, 'includeInactive': true},
          });

      if (clientsResult.data?['success'] == true) {
        final clientsData = clientsResult.data?['clients'] as List<dynamic>?;

        if (clientsData == null) {
          throw Exception('Brak danych klientów w odpowiedzi z serwera');
        }
        
        final clients = clientsData
            .where(
              (clientData) => clientData != null,
            ) // 🚀 Filtruj null elementy
            .map((clientData) {
              try {
                return Client.fromServerMap(clientData);
              } catch (e) {
                print('⚠️ [ClientData] Błąd parsowania klienta: $e');
                return null;
              }
            })
            .where(
              (client) => client != null,
            ) // 🚀 Filtruj niepoprawnie sparsowane
            .cast<Client>() // 🚀 Rzutuj na prawidłowy typ
            .toList();

        print(
          '✅ [KROK 1] Firebase Functions SUCCESS - pobrano ${clients.length} WSZYSTKICH klientów',
        );

        // Utwórz statystyki klientów
        final statistics = clientsResult.data?['statistics'];
        ClientStats? clientStats;
        if (statistics != null) {
          clientStats = ClientStats(
            totalClients: clients.length,
            totalInvestments: statistics['totalClients'] ?? 0,
            totalRemainingCapital:
                0.0, // Będzie zaktualizowane po załadowaniu inwestycji
            averageCapitalPerClient: 0.0,
            lastUpdated: DateTime.now().toIso8601String(),
            source: 'Firebase Functions - Enhanced Clients Service',
          );
        }

        if (mounted) {
          setState(() {
            _allClients = clients;
            _originalClients =
                clients; // 🚀 NOWE: Zachowaj kopię wszystkich klientów
            _activeClients = clients.where((c) => c.isActive != false).toList();
            _clientStats = clientStats;
            _isLoading =
                false; // 🚀 POPRAWKA: Reset loading po udanym załadowaniu klientów
          });
        }

        print('✅ [SUCCESS] Dane klientów załadowane z Firebase Functions:');
        print('    - ${clients.length} klientów WSZYSTKICH');
        print(
          '    - ${clients.where((c) => c.isActive != false).length} aktywnych',
        );
        print('    - Źródło: Firebase Functions - getAllActiveClientsFunction');

        // 🚀 KROK 2: Pobierz dane inwestycji przez Firebase Functions
        await _loadInvestmentDataFromFirebase();
      } else {
        throw Exception(
          clientsResult.data?['error'] ??
              'Nieznany błąd podczas pobierania klientów',
        );
      }
    } catch (e) {
      print('❌ [EnhancedClientsScreen] Krytyczny błąd ładowania: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInvestmentDataLoaded = false;
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
      if (mounted && context.mounted) {
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
      if (mounted && context.mounted) {
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

        // 🚀 NOWE: W trybie selekcji dodaj zaznaczone klientów jeśli nie są w wynikach
        List<Client> finalResults = results;
        if (_isSelectionMode && _originalClients.isNotEmpty) {
          final selectedClients = _originalClients
              .where((client) => _selectedClientIds.contains(client.id))
              .toList();
          for (final selectedClient in selectedClients) {
            if (!finalResults.any((client) => client.id == selectedClient.id)) {
              finalResults.add(selectedClient);
            }
          }
        }

        if (mounted) {
          setState(() {
            _allClients = finalResults;
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
      final filtered = _allClients.where((client) {
        final clientName = client.name.toLowerCase();
        final companyName = client.companyName?.toLowerCase() ?? '';
        final email = client.email.toLowerCase();

        return clientName.contains(query) ||
            companyName.contains(query) ||
            email.contains(query);
      }).toList();

      // 🚀 NOWE: W trybie selekcji dodaj zaznaczone klientów jeśli nie są w wynikach filtrowania
      if (_isSelectionMode && _originalClients.isNotEmpty) {
        final selectedClients = _originalClients
            .where((client) => _selectedClientIds.contains(client.id))
            .toList();
        for (final selectedClient in selectedClients) {
          if (!filtered.any((client) => client.id == selectedClient.id)) {
            filtered.add(selectedClient);
          }
        }
      }

      return filtered;
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

  /// 🎯 NOWE: Przełączanie widoczności legendy
  void _toggleLegend() {
    setState(() {
      _isLegendExpanded = !_isLegendExpanded;
    });
    HapticFeedback.lightImpact();
  }

  /// Odświeżenie danych
  Future<void> _refreshData() async {
    if (!mounted) return; // 🛡️ SPRAWDZENIE: czy widget jest jeszcze aktywny
    
    print(
      '🔄 [EnhancedClientsScreen] _refreshData() - rozpoczynanie odświeżania...',
    );
    print(
      '🔄 [Debug] Stan przed odświeżaniem: _isLoading=$_isLoading, _isInvestmentDataLoaded=$_isInvestmentDataLoaded, _allClients.length=${_allClients.length}',
    );
    
    await _loadInitialData();
    print(
      '🔄 [Debug] Stan po _loadInitialData: _isLoading=$_isLoading, _allClients.length=${_allClients.length}',
    );
    
    // 🚀 ZAWSZE odśwież dane inwestycji po odświeżeniu klientów
    await _loadInvestmentDataFromFirebase();
    print(
      '🔄 [Debug] Stan po _loadInvestmentDataFromFirebase: _isLoading=$_isLoading, _isInvestmentDataLoaded=$_isInvestmentDataLoaded',
    );

    if (mounted) {
      // 🛡️ SPRAWDZENIE: przed pokazaniem SnackBar
      _showSuccessSnackBar('Dane zostały odświeżone');
      print('✅ [RefreshData] Odświeżanie zakończone pomyślnie');
    }
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
            if (mounted) {
              _showSuccessSnackBar('Klient został dodany');
            }
          } else {
            // Aktualizacja klienta
            await _integratedClientService.updateClient(client.id, savedClient);
            if (mounted) {
              _showSuccessSnackBar('Klient został zaktualizowany');
            }
          }

          // 🚀 POPRAWKA: Zostaw zamykanie dialogu do EnhancedClientDialog
          // Dialog sam się zamknie po udanym zapisie
          // NIE używamy Navigator.of(context).pop() tutaj!

          // Odśwież dane w tle po zapisie - z opóźnieniem
          if (mounted) {
            // Użyj Future.delayed aby dać czas na zamknięcie dialogu
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _refreshData();
              }
            });
          }
        } catch (e) {
          if (mounted) {
            _showErrorSnackBar('Błąd podczas zapisywania: $e');
          }
        }
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted || !context.mounted)
      return; // 🛡️ SPRAWDZENIE: czy widget i kontekst są aktywne
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppThemePro.statusSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted || !context.mounted)
      return; // 🛡️ SPRAWDZENIE: czy widget i kontekst są aktywne
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
      child: Column(
        children: [
   
          // Statystyki
          Row(
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
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ Najpierw wybierz odbiorców maili\n💡 Użyj trybu email aby wybrać klientów',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      
      if (!_isEmailMode && !_isSelectionMode) {
        _toggleEmailMode();
      }
      return;
    }

    // 🚀 SPRAWDZENIE: Czy dane inwestycji są załadowane
    if (_investorSummaries.isEmpty) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⏳ Dane inwestycji się ładują - spróbuj ponownie za chwilę',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
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
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ Wybrani klienci nie mają prawidłowych adresów email',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
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

      if (!mounted || !context.mounted) return;

      // 🚀 NOWE: Używamy WowEmailEditorScreen zamiast dialogu
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WowEmailEditorScreen(
            selectedInvestors: investorsData,
            initialSubject: 'Informacje o klientach - Metropolitan Investment',
          ),
        ),
      );

      // Sprawdź czy emaile zostały wysłane pomyślnie
      if (result == true && mounted) {
        _toggleEmailMode(); // Wyłącz tryb email po wysłaniu
        
        // 🚀 NOWE: Wyczyść wyszukiwanie i odśwież listę klientów do pełnej
        _searchController.clear();
        _currentSearchQuery = '';
        _lastServerSearchQuery = '';
        await _loadInitialData(); // Odśwież do pełnej listy klientów
        
        _showSuccessSnackBar(
          '✅ Emaile zostały wysłane do ${clientsWithEmail.length} odbiorców',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Błąd podczas przygotowywania danych: $e');
    }
  }

  /// Eksportuje wybranych klientów do różnych formatów (wzorowane na premium_investor_analytics_screen)
  Future<void> _exportSelectedClients() async {
    if (_selectedClients.isEmpty) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Najpierw wybierz klientów do eksportu'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // 🚀 SPRAWDZENIE: Czy dane inwestycji są załadowane
    if (_investorSummaries.isEmpty) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⏳ Dane inwestycji się ładują - spróbuj ponownie za chwilę',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
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
        onExportComplete: () async {
          if (mounted && context.mounted) {
            // Dialog already handles its own closure, so we don't call Navigator.of(context).pop() here
            _toggleExportMode(); // Wyłącz tryb eksportu
            
            // 🚀 NOWE: Wyczyść wyszukiwanie i odśwież listę klientów do pełnej
            _searchController.clear();
            _currentSearchQuery = '';
            _lastServerSearchQuery = '';
            await _loadInitialData(); // Odśwież do pełnej listy klientów
            
            _showSuccessSnackBar('✅ Eksport zakończony pomyślnie');
          }
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
            AppThemePro.bondsBlue.withOpacity(0.8),
            AppThemePro.accentGold.withOpacity(0.6),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.bondsBlue.withOpacity(0.3),
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
      body: SingleChildScrollView( // 🎯 DODANE: Zabezpieczenie przed overflow
        child: Column(
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
              onToggleLegend: _toggleLegend, // 🎯 NOWY CALLBACK
            ),

            // 🚀 NOWY: Export Mode Banner (wzorowane na premium analytics)
            if (_isExportMode) _buildExportModeBanner(),
            
            // 🚀 NOWY: Email Mode Banner
            if (_isEmailMode) _buildEmailModeBanner(),
            
            // 🚀 NOWY: Edit Mode Banner
            // edit mode removed

            // 🎯 NOWA LEGENDA - wyjaśnienia oznaczeń
            ClientsLegendWidget(
              isExpanded: _isLegendExpanded,
              onToggle: _toggleLegend,
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

            // 🎨 SPECTACULAR CLIENTS GRID - OKREŚLONA WYSOKOŚĆ
            SizedBox(
              height: MediaQuery.of(context).size.height - 300, // 🎯 OKREŚLONA WYSOKOŚĆ
              child: _buildContent(),
            ),
          ],
        ),
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

    // 🚀 POPRAWKA: Dokładniejsze sprawdzanie stanów ładowania
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PremiumShimmerLoadingWidget.fullScreen(),
            const SizedBox(height: 16),
            Text(
              'Ładowanie klientów...',
              style: TextStyle(color: AppThemePro.textSecondary),
            ),
          ],
        ),
      );
    }

    // 🚀 POPRAWKA: Sprawdź dane inwestycji tylko jeśli klienci są już załadowani
    if (_allClients.isNotEmpty && !_isInvestmentDataLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PremiumShimmerLoadingWidget.fullScreen(),
            const SizedBox(height: 16),
            Text(
              'Ładowanie danych inwestycji...',
              style: TextStyle(color: AppThemePro.textSecondary),
            ),
          ],
        ),
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

        // 🚀 NOWE: Przekaż tryby specjalne dla różnych kolorów zaznaczania
        isEmailMode: _isEmailMode,
        isExportMode: _isExportMode,
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

  /// 🚀 NOWA METODA: Ładowanie danych inwestycji przez Firebase Functions
  Future<void> _loadInvestmentDataFromFirebase() async {
    if (!mounted) return; // 🛡️ SPRAWDZENIE: czy widget jest aktywny
    
  

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final analyticsResult = await functions
          .httpsCallable('getPremiumInvestorAnalytics')
          .call({
            'page': 1,
            'pageSize': 10000,
            'sortBy': 'viableRemainingCapital',
            'sortAscending': false,
            'includeInactive': true,
            'forceRefresh': true,
          });

      if (analyticsResult.data?['success'] == true) {
        final dataMap = analyticsResult.data?['data'] as Map<String, dynamic>?;
        final investorsData = dataMap?['investors'] as List<dynamic>?;

        if (investorsData == null) {
          throw Exception('Brak danych inwestorów w odpowiedzi z serwera');
        }
        
        final investors = investorsData
            .where(
              (investorData) => investorData != null,
            ) // 🚀 Filtruj null elementy
            .map((investorData) {
              try {
                return InvestorSummary.fromMap(investorData);
              } catch (e) {
                print('⚠️ [InvestmentData] Błąd parsowania inwestora: $e');
                return null;
              }
            })
            .where(
              (investor) => investor != null,
            ) // 🚀 Filtruj niepoprawnie sparsowane
            .cast<InvestorSummary>() // 🚀 Rzutuj na prawidłowy typ
            .toList();

        print(
          '✅ [InvestmentData] Pobrano ${investors.length} podsumowań inwestorów przez Firebase Functions',
        );

        // Utwórz mapę clientId -> InvestorSummary
        final Map<String, InvestorSummary> summariesMap = {};
        final Map<String, List<Investment>> investmentsMap = {};

        for (final summary in investors) {
          // 🚀 ZABEZPIECZENIE: Sprawdź czy client.id nie jest pusty
          if (summary.client.id.isNotEmpty) {
            summariesMap[summary.client.id] = summary;
            investmentsMap[summary.client.id] = summary.investments;

      
          } else {
            print('⚠️ [InvestmentData] Pomiń inwestora z pustym client.id');
          }
        }

        // Zaktualizuj statystyki klientów z danymi inwestycji
        if (_clientStats != null && mounted) {
          final totalCapital = investors.fold<double>(
            0.0,
            (sum, investor) => sum + investor.totalRemainingCapital,
          );
          final updatedStats = ClientStats(
            totalClients: _clientStats!.totalClients,
            totalInvestments: investors.fold<int>(
              0,
              (sum, investor) => sum + investor.investmentCount,
            ),
            totalRemainingCapital: totalCapital,
            averageCapitalPerClient: _clientStats!.totalClients > 0
                ? totalCapital / _clientStats!.totalClients
                : 0.0,
            lastUpdated: DateTime.now().toIso8601String(),
            source: 'Firebase Functions - Premium Analytics',
          );

          setState(() {
            _clientStats = updatedStats;
          });
        }

        if (mounted) {
          setState(() {
            _investorSummaries = summariesMap;
            _clientInvestments = investmentsMap;
            _isInvestmentDataLoaded =
                true; // 🚀 Ustaw flagę że dane są załadowane
            _isLoading = false; // Zakończ ładowanie
          });
        }

        print(
          '✅ [InvestmentData] Zaktualizowano dane inwestycji dla ${summariesMap.length} klientów',
        );
        print(
          '🎯 [InvestmentData] Dane inwestycji przekazane do SpectacularClientsGrid - karty klientów będą widoczne!',
        );
      } else {
        throw Exception(
          analyticsResult.data?['error'] ??
              'Nieznany błąd podczas pobierania danych inwestycji',
        );
      }
    } catch (e) {
      print(
        '⚠️ [InvestmentData] Błąd ładowania danych inwestycji przez Firebase Functions: $e',
      );
      // Nie przerywamy ładowania - ustaw flagę że dane są załadowane (nawet jeśli puste)
      if (mounted) {
        setState(() {
          _isInvestmentDataLoaded = true;
          _isLoading = false;
        });
      }
    }
  }
}
