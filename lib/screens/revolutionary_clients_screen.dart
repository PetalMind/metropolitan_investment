import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../models_and_services.dart';
import '../providers/auth_provider.dart';
import '../widgets/dialogs/enhanced_investor_email_dialog.dart';
import '../widgets/metropolitan_loading_system.dart';
import '../widgets/revolutionary_clients/clients_hero_section.dart';
import '../widgets/revolutionary_clients/clients_discovery_panel.dart';
import '../widgets/revolutionary_clients/clients_grid_view.dart';
import '../widgets/revolutionary_clients/clients_action_center.dart';
import '../widgets/revolutionary_clients/clients_intelligence_dashboard.dart';
import '../widgets/revolutionary_clients/clients_types.dart';
import '../widgets/revolutionary_clients/clients_intelligence_dashboard.dart';

/// 🚀 REVOLUTIONARY CLIENTS SCREEN
/// 
/// Kompletnie przeprojektowane doświadczenie zarządzania klientami:
/// - Hero Section z wizualną hierarchią i smart badges
/// - Discovery Panel z AI-powered search i advanced filters
/// - Grid View z card-based layout i micro-interactions
/// - Action Center z contextual actions i bulk operations
/// - Intelligence Dashboard z real-time analytics
class RevolutionaryClientsScreen extends StatefulWidget {
  const RevolutionaryClientsScreen({super.key});

  @override
  State<RevolutionaryClientsScreen> createState() => _RevolutionaryClientsScreenState();
}

class _RevolutionaryClientsScreenState extends State<RevolutionaryClientsScreen>
    with TickerProviderStateMixin {
  
  // 🎭 Animation Controllers
  late AnimationController _heroController;
  late AnimationController _cardController;
  late AnimationController _filterController;
  late AnimationController _actionController;
  
  late Animation<double> _heroAnimation;
  late Animation<double> _cardStaggerAnimation;
  late Animation<Offset> _filterSlideAnimation;
  late Animation<double> _actionScaleAnimation;

  // 🧠 Services & Data
  final IntegratedClientService _integratedClientService = IntegratedClientService();
  final ClientService _clientService = ClientService();
  final InvestorAnalyticsService _analyticsService = InvestorAnalyticsService();
  
  // 📊 State Management
  List<Client> _allClients = [];
  List<Client> _displayedClients = [];
  ClientStats? _clientStats;
  Map<String, dynamic> _intelligenceData = {};
  
  // 🎯 UI State
  bool _isLoading = true;
  bool _isInitialLoad = true;
  String _errorMessage = '';
  ClientViewMode _viewMode = ClientViewMode.grid;
  ClientSortMode _sortMode = ClientSortMode.nameAsc;
  
  // 🔍 Discovery State
  String _searchQuery = '';
  Set<ClientFilter> _activeFilters = {};
  Set<String> _selectedClientIds = {};
  bool _isSelectionMode = false;
  
  // 🎪 View Modes & Display
  double _cardAnimationProgress = 0.0;
  bool _showIntelligenceDashboard = true;
  bool _isCompactMode = false;
  
  // 🚀 Smart Features
  List<ClientInsight> _clientInsights = [];
  Map<String, ClientMetrics> _clientMetrics = {};
  Timer? _searchDebouncer;
  Timer? _metricsUpdater;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startInitialLoad();
    _startMetricsUpdater();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _cardController.dispose();
    _filterController.dispose();
    _actionController.dispose();
    _searchDebouncer?.cancel();
    _metricsUpdater?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _filterController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _actionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _heroAnimation = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutCubic,
    );
    
    _cardStaggerAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutQuart,
    );
    
    _filterSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _filterController,
      curve: Curves.easeOutBack,
    ));
    
    _actionScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _actionController,
      curve: Curves.elasticOut,
    ));
  }

  Future<void> _startInitialLoad() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // 🚀 Phase 1: Hero Animation
      _heroController.forward();
      await Future.delayed(const Duration(milliseconds: 300));

      // 🚀 Phase 2: Load Core Data
      final futures = await Future.wait([
        _integratedClientService.getAllClients(
          page: 1,
          pageSize: 10000,
          forceRefresh: true,
          onProgress: _updateLoadingProgress,
        ),
        _integratedClientService.getClientStats(),
        _loadIntelligenceData(),
      ]);

      if (mounted) {
        setState(() {
          _allClients = futures[0] as List<Client>;
          _clientStats = futures[1] as ClientStats;
          _intelligenceData = futures[2] as Map<String, dynamic>;
          _isLoading = false;
          _isInitialLoad = false;
        });

        // 🚀 Phase 3: Staggered Animations
        _filterController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        _cardController.forward();
        await Future.delayed(const Duration(milliseconds: 100));
        _actionController.forward();

        // 🚀 Phase 4: Apply Initial Filters & Generate Insights
        _applyFiltersAndSorting();
        _generateClientInsights();
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Błąd podczas ładowania: $e';
        });
      }
    }
  }

  void _updateLoadingProgress(String progress, String stage) {
    print('🔄 Loading: $stage - $progress');
    // Update loading UI if needed
  }

  Future<Map<String, dynamic>> _loadIntelligenceData() async {
    // Simulate AI-powered insights loading
    await Future.delayed(const Duration(milliseconds: 800));
    
    return {
      'total_investment_value': 15420000.0,
      'avg_client_value': 89500.0,
      'growth_rate': 12.5,
      'risk_score': 0.85,
      'active_ratio': 0.78,
      'top_client_segments': ['Premium', 'Corporate', 'Retail'],
      'trends': {
        'new_clients_this_month': 23,
        'reactivated_clients': 8,
        'churned_clients': 3,
      }
    };
  }

  void _startMetricsUpdater() {
    _metricsUpdater = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isLoading) {
        _updateRealtimeMetrics();
      }
    });
  }

  void _updateRealtimeMetrics() async {
    try {
      final newStats = await _integratedClientService.getClientStats();
      if (mounted && newStats != null) {
        setState(() {
          _clientStats = newStats;
        });
        _generateClientInsights();
      }
    } catch (e) {
      print('Warning: Failed to update metrics: $e');
    }
  }

  void _generateClientInsights() {
    final insights = <ClientInsight>[];
    
    if (_clientStats != null) {
      // 🧠 AI-powered insights
      final avgInvestment = _clientStats!.totalInvestments > 0 
          ? _clientStats!.totalRemainingCapital / _clientStats!.totalInvestments
          : 0.0;
      
      if (avgInvestment > 100000) {
        insights.add(ClientInsight(
          type: InsightType.opportunity,
          title: 'Wysoka wartość portfela',
          description: 'Średnia inwestycja przekracza 100k zł',
          priority: InsightPriority.high,
          actionable: true,
        ));
      }
      
      final activeRatio = _allClients.isNotEmpty 
          ? _allClients.where((c) => c.isActive).length / _allClients.length
          : 0.0;
      
      if (activeRatio < 0.8) {
        insights.add(ClientInsight(
          type: InsightType.warning,
          title: 'Niska aktywność klientów',
          description: '${(activeRatio * 100).toStringAsFixed(1)}% aktywnych klientów',
          priority: InsightPriority.medium,
          actionable: true,
        ));
      }
    }
    
    setState(() {
      _clientInsights = insights;
    });
  }

  void _applyFiltersAndSorting() {
    List<Client> filtered = List.from(_allClients);
    
    // 🔍 Search Filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((client) {
        return client.name.toLowerCase().contains(query) ||
               client.email.toLowerCase().contains(query) ||
               (client.phone.toLowerCase().contains(query)) ||
               (client.companyName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    // 🎯 Active Filters
    for (final filter in _activeFilters) {
      filtered = filter.apply(filtered);
    }
    
    // 📈 Sorting
    filtered = _sortMode.apply(filtered);
    
    setState(() {
      _displayedClients = filtered;
    });
  }

  void _onSearchChanged(String query) {
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
      });
      _applyFiltersAndSorting();
    });
  }

  void _onFilterChanged(Set<ClientFilter> filters) {
    setState(() {
      _activeFilters = filters;
    });
    _applyFiltersAndSorting();
  }

  void _onSortChanged(ClientSortMode sortMode) {
    setState(() {
      _sortMode = sortMode;
    });
    _applyFiltersAndSorting();
  }

  void _onViewModeChanged(ClientViewMode viewMode) {
    setState(() {
      _viewMode = viewMode;
    });
    
    // Animate transition
    _cardController.reset();
    _cardController.forward();
  }

  void _onSelectionChanged(Set<String> selectedIds) {
    setState(() {
      _selectedClientIds = selectedIds;
      _isSelectionMode = selectedIds.isNotEmpty;
    });
    
    if (selectedIds.isNotEmpty) {
      _actionController.forward();
    } else {
      _actionController.reverse();
    }
  }

  void _toggleCompactMode() {
    setState(() {
      _isCompactMode = !_isCompactMode;
    });
  }

  void _toggleIntelligenceDashboard() {
    setState(() {
      _showIntelligenceDashboard = !_showIntelligenceDashboard;
    });
  }

  Future<void> _refreshData() async {
    await _startInitialLoad();
    _showSuccessMessage('Dane zostały odświeżone');
  }

  Future<void> _handleBulkEmail() async {
    if (_selectedClientIds.isEmpty) return;
    
    final selectedClients = _displayedClients
        .where((client) => _selectedClientIds.contains(client.id))
        .toList();
    
    try {
      final investorsData = await _analyticsService
          .getInvestorsByClientIds(_selectedClientIds.toList());
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => EnhancedInvestorEmailDialog(
          selectedInvestors: investorsData,
          onEmailSent: () {
            _onSelectionChanged({});
            _showSuccessMessage('Email został wysłany pomyślnie');
          },
        ),
      );
    } catch (e) {
      _showErrorMessage('Błąd podczas wysyłania email: $e');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  bool get canEdit => Provider.of<AuthProvider>(context, listen: false).isAdmin;

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _isInitialLoad) {
      return const Scaffold(
        body: Center(
          child: MetropolitanLoadingWidget.clients(showProgress: true),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            // 🦸‍♂️ Hero Section
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _heroAnimation,
                child: ClientsHeroSection(
                  clientStats: _clientStats,
                  intelligenceData: _intelligenceData,
                  insights: _clientInsights,
                  isSelectionMode: _isSelectionMode,
                  selectedCount: _selectedClientIds.length,
                  onExitSelection: () => _onSelectionChanged({}),
                  onBulkEmail: _handleBulkEmail,
                  onToggleIntelligence: _toggleIntelligenceDashboard,
                  canEdit: canEdit,
                ),
              ),
            ),

            // 🔍 Discovery Panel
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _filterSlideAnimation,
                child: ClientsDiscoveryPanel(
                  searchQuery: _searchQuery,
                  activeFilters: _activeFilters,
                  sortMode: _sortMode,
                  viewMode: _viewMode,
                  isCompactMode: _isCompactMode,
                  onSearchChanged: _onSearchChanged,
                  onFiltersChanged: _onFilterChanged,
                  onSortChanged: _onSortChanged,
                  onViewModeChanged: _onViewModeChanged,
                  onToggleCompact: _toggleCompactMode,
                  totalClients: _allClients.length,
                  filteredClients: _displayedClients.length,
                ),
              ),
            ),

            // 🧠 Intelligence Dashboard (Optional)
            if (_showIntelligenceDashboard)
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _heroAnimation,
                  child: ClientsIntelligenceDashboard(
                    intelligenceData: _intelligenceData,
                    insights: _clientInsights,
                    clientMetrics: _clientMetrics,
                    isCompact: _isCompactMode,
                  ),
                ),
              ),

            // 🎨 Main Content Grid
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _cardStaggerAnimation,
                builder: (context, child) {
                  return ClientsGridView(
                    clients: _displayedClients,
                    viewMode: _viewMode,
                    isCompactMode: _isCompactMode,
                    selectedClientIds: _selectedClientIds,
                    isSelectionMode: _isSelectionMode,
                    animationProgress: _cardStaggerAnimation.value,
                    onSelectionChanged: _onSelectionChanged,
                    onClientTap: (client) {
                      // Handle client details
                    },
                    canEdit: canEdit,
                  );
                },
              ),
            ),

            // 🎭 Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),

      // 🎪 Floating Action Center
      floatingActionButton: ScaleTransition(
        scale: _actionScaleAnimation,
        child: ClientsActionCenter(
          isSelectionMode: _isSelectionMode,
          selectedCount: _selectedClientIds.length,
          onBulkEmail: _handleBulkEmail,
          onExportSelected: () {
            // TODO: Implement export
          },
          onCreateClient: canEdit ? () {
            // TODO: Show client form
          } : null,
        ),
      ),
      
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// 🎯 Enums & Models
enum ClientViewMode { grid, list, cards, timeline }
enum ClientSortMode { nameAsc, nameDesc, dateAsc, dateDesc, valueAsc, valueDesc }
enum InsightType { opportunity, warning, info, success }
enum InsightPriority { low, medium, high, critical }

class ClientInsight {
  final InsightType type;
  final String title;
  final String description;
  final InsightPriority priority;
  final bool actionable;
  
  ClientInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    this.actionable = false,
  });
}

class ClientMetrics {
  final double totalValue;
  final int investmentCount;
  final double averageInvestment;
  final DateTime lastActivity;
  final double riskScore;
  
  ClientMetrics({
    required this.totalValue,
    required this.investmentCount,
    required this.averageInvestment,
    required this.lastActivity,
    required this.riskScore,
  });
}

// 🔍 Filter System
abstract class ClientFilter {
  String get displayName;
  List<Client> apply(List<Client> clients);
}

class ActiveClientsFilter extends ClientFilter {
  @override
  String get displayName => 'Aktywni';
  
  @override
  List<Client> apply(List<Client> clients) {
    return clients.where((client) => client.isActive).toList();
  }
}

class PremiumClientsFilter extends ClientFilter {
  @override
  String get displayName => 'Premium';
  
  @override
  List<Client> apply(List<Client> clients) {
    // TODO: Implement premium logic based on investment value
    return clients;
  }
}

// 📈 Sort System
extension ClientSortModeExtension on ClientSortMode {
  String get displayName {
    switch (this) {
      case ClientSortMode.nameAsc:
        return 'Nazwa A-Z';
      case ClientSortMode.nameDesc:
        return 'Nazwa Z-A';
      case ClientSortMode.dateAsc:
        return 'Data rosnąco';
      case ClientSortMode.dateDesc:
        return 'Data malejąco';
      case ClientSortMode.valueAsc:
        return 'Wartość rosnąco';
      case ClientSortMode.valueDesc:
        return 'Wartość malejąco';
    }
  }
  
  List<Client> apply(List<Client> clients) {
    switch (this) {
      case ClientSortMode.nameAsc:
        return clients..sort((a, b) => a.name.compareTo(b.name));
      case ClientSortMode.nameDesc:
        return clients..sort((a, b) => b.name.compareTo(a.name));
      case ClientSortMode.dateAsc:
        return clients..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case ClientSortMode.dateDesc:
        return clients..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ClientSortMode.valueAsc:
        // TODO: Sort by investment value
        return clients;
      case ClientSortMode.valueDesc:
        // TODO: Sort by investment value
        return clients;
    }
  }
}
