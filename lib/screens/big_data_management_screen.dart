import 'package:flutter/material.dart';
import '../services/firebase_functions_data_service.dart';
import '../models/client.dart';
import '../models/investment.dart';
import '../models/product.dart';
import '../models/bond.dart';
import '../models/share.dart';
import '../models/loan.dart';
import '../models/apartment.dart';
import '../theme/app_theme.dart';

/// 🚀 ZARZĄDZANIE DUŻYMI ZBIORAMI DANYCH
/// Demonstracja Firebase Functions dla skalowania z nowymi funkcjami
class BigDataManagementScreen extends StatefulWidget {
  const BigDataManagementScreen({super.key});

  @override
  State<BigDataManagementScreen> createState() =>
      _BigDataManagementScreenState();
}

class _BigDataManagementScreenState extends State<BigDataManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFunctionsDataService _dataService =
      FirebaseFunctionsDataService();

  bool _isLoading = false;
  String? _errorMessage;

  // Legacy tabs
  List<Client> _clients = [];
  int _clientsCurrentPage = 1;
  int _clientsTotalCount = 0;
  bool _clientsHasNextPage = false;
  final TextEditingController _clientSearchController = TextEditingController();

  List<Investment> _investments = [];
  int _investmentsCurrentPage = 1;
  int _investmentsTotalCount = 0;
  bool _investmentsHasNextPage = false;
  String? _selectedClientFilter;
  String? _selectedProductTypeFilter;

  SystemStats? _systemStats;

  // New product tabs
  List<Bond> _bonds = [];
  int _bondsCurrentPage = 1;
  BondsResult? _bondsResult;

  List<Share> _shares = [];
  int _sharesCurrentPage = 1;
  SharesResult? _sharesResult;

  List<Loan> _loans = [];
  int _loansCurrentPage = 1;
  LoansResult? _loansResult;

  List<Apartment> _apartments = [];
  int _apartmentsCurrentPage = 1;
  ApartmentsResult? _apartmentsResult;

  ProductTypeStatistics? _productStats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 8,
      vsync: this,
    ); // Zwiększono liczbę zakładek
    _tabController.addListener(_onTabChanged);
    _loadInitialData();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadInitialData(); // Załaduj dane dla nowej zakładki
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clientSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Załaduj dane z aktualnej zakładki
      final currentIndex = _tabController.index;
      switch (currentIndex) {
        case 0:
          await _loadClients();
          break;
        case 1:
          await _loadInvestments();
          break;
        case 2:
          await _loadSystemStats();
          break;
        case 3:
          await _loadBonds();
          break;
        case 4:
          await _loadShares();
          break;
        case 5:
          await _loadLoans();
          break;
        case 6:
          await _loadApartments();
          break;
        case 7:
          await _loadProductStats();
          break;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Błąd ładowania danych: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadClients({int page = 1, bool append = false}) async {
    try {
      final result = await FirebaseFunctionsDataService.getAllClients(
        page: page,
        pageSize: 100,
        searchQuery: _clientSearchController.text.isNotEmpty
            ? _clientSearchController.text
            : null,
      );

      setState(() {
        if (append) {
          _clients.addAll(result.clients);
        } else {
          _clients = result.clients;
        }
        _clientsCurrentPage = result.currentPage;
        _clientsTotalCount = result.totalCount;
        _clientsHasNextPage = result.hasNextPage;
      });

      print(
        '📱 [BigData] Załadowano ${result.clients.length} klientów z ${result.source}',
      );
    } catch (e) {
      throw Exception('Błąd ładowania klientów: $e');
    }
  }

  Future<void> _loadInvestments({int page = 1, bool append = false}) async {
    try {
      final result = await FirebaseFunctionsDataService.getAllInvestments(
        page: page,
        pageSize: 100,
        clientFilter: _selectedClientFilter,
        productTypeFilter: _selectedProductTypeFilter,
      );

      setState(() {
        if (append) {
          _investments.addAll(result.investments);
        } else {
          _investments = result.investments;
        }
        _investmentsCurrentPage = result.currentPage;
        _investmentsTotalCount = result.totalCount;
        _investmentsHasNextPage = result.hasNextPage;
      });

      print(
        '📱 [BigData] Załadowano ${result.investments.length} inwestycji z ${result.source}',
      );
    } catch (e) {
      throw Exception('Błąd ładowania inwestycji: $e');
    }
  }

  Future<void> _loadSystemStats() async {
    try {
      final stats = await FirebaseFunctionsDataService.getSystemStats();

      setState(() {
        _systemStats = stats;
      });

      print('📱 [BigData] Załadowano statystyki z ${stats.source}');
    } catch (e) {
      throw Exception('Błąd ładowania statystyk: $e');
    }
  }

  // =============================================
  // NEW PRODUCT DATA LOADING METHODS
  // =============================================

  Future<void> _loadBonds({int page = 1, bool append = false}) async {
    try {
      final result = await _dataService.getBonds(page: page, pageSize: 50);

      setState(() {
        if (append) {
          _bonds.addAll(result.bonds);
        } else {
          _bonds = result.bonds;
        }
        _bondsCurrentPage = result.page;
        _bondsResult = result;
      });

      print('📱 [BigData] Załadowano ${result.bonds.length} obligacji');
    } catch (e) {
      throw Exception('Błąd ładowania obligacji: $e');
    }
  }

  Future<void> _loadShares({int page = 1, bool append = false}) async {
    try {
      final result = await _dataService.getShares(page: page, pageSize: 50);

      setState(() {
        if (append) {
          _shares.addAll(result.shares);
        } else {
          _shares = result.shares;
        }
        _sharesCurrentPage = result.page;
        _sharesResult = result;
      });

      print('📱 [BigData] Załadowano ${result.shares.length} udziałów');
    } catch (e) {
      throw Exception('Błąd ładowania udziałów: $e');
    }
  }

  Future<void> _loadLoans({int page = 1, bool append = false}) async {
    try {
      final result = await _dataService.getLoans(page: page, pageSize: 50);

      setState(() {
        if (append) {
          _loans.addAll(result.loans);
        } else {
          _loans = result.loans;
        }
        _loansCurrentPage = result.page;
        _loansResult = result;
      });

      print('📱 [BigData] Załadowano ${result.loans.length} pożyczek');
    } catch (e) {
      throw Exception('Błąd ładowania pożyczek: $e');
    }
  }

  Future<void> _loadApartments({int page = 1, bool append = false}) async {
    try {
      final result = await _dataService.getApartments(page: page, pageSize: 50);

      setState(() {
        if (append) {
          _apartments.addAll(result.apartments);
        } else {
          _apartments = result.apartments;
        }
        _apartmentsCurrentPage = result.page;
        _apartmentsResult = result;
      });

      print('📱 [BigData] Załadowano ${result.apartments.length} apartamentów');
    } catch (e) {
      throw Exception('Błąd ładowania apartamentów: $e');
    }
  }

  Future<void> _loadProductStats() async {
    try {
      final stats = await _dataService.getProductTypeStatistics();

      setState(() {
        _productStats = stats;
      });

      print('📱 [BigData] Załadowano statystyki produktów');
    } catch (e) {
      throw Exception('Błąd ładowania statystyk produktów: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zarządzanie Big Data'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Klienci'),
            Tab(icon: Icon(Icons.trending_up), text: 'Inwestycje'),
            Tab(icon: Icon(Icons.analytics), text: 'Statystyki'),
            Tab(icon: Icon(Icons.description), text: 'Obligacje'),
            Tab(icon: Icon(Icons.share), text: 'Udziały'),
            Tab(icon: Icon(Icons.account_balance), text: 'Pożyczki'),
            Tab(icon: Icon(Icons.apartment), text: 'Apartamenty'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Stats Produktów'),
          ],
        ),
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadInitialData,
                    child: Text('Ponów próbę'),
                  ),
                ],
              ),
            )
          else
            TabBarView(
              controller: _tabController,
              children: [
                _buildClientsTab(),
                _buildInvestmentsTab(),
                _buildStatsTab(),
                _buildBondsTab(),
                _buildSharesTab(),
                _buildLoansTab(),
                _buildApartmentsTab(),
                _buildProductStatsTab(),
              ],
            ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildClientsTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _clientSearchController,
            decoration: InputDecoration(
              labelText: 'Szukaj klientów',
              hintText: 'Imię, nazwisko, email, telefon...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _clientSearchController.clear();
                  _loadClients();
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onSubmitted: (_) => _loadClients(),
          ),
        ),

        // Stats Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Znaleziono: $_clientsTotalCount klientów',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Strona: $_clientsCurrentPage',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),

        // Clients List
        Expanded(
          child: ListView.builder(
            itemCount: _clients.length + (_clientsHasNextPage ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _clients.length) {
                // Load More Button
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => _loadClients(
                      page: _clientsCurrentPage + 1,
                      append: true,
                    ),
                    child: const Text('Załaduj więcej'),
                  ),
                );
              }

              final client = _clients[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: client.type == ClientType.company
                        ? Colors.blue
                        : Colors.green,
                    child: Icon(
                      client.type == ClientType.company
                          ? Icons.business
                          : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(client.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (client.email.isNotEmpty) Text('📧 ${client.email}'),
                      if (client.phone.isNotEmpty) Text('📱 ${client.phone}'),
                      Text(
                        '📅 ${client.createdAt.day}/${client.createdAt.month}/${client.createdAt.year}',
                      ),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(client.type.displayName),
                    backgroundColor: client.isActive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentsTab() {
    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedClientFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filtruj po kliencie',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Wszyscy')),
                    ..._clients.map(
                      (client) => DropdownMenuItem(
                        value: client.name,
                        child: Text(client.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedClientFilter = value;
                    });
                    _loadInvestments();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedProductTypeFilter,
                  decoration: const InputDecoration(
                    labelText: 'Typ produktu',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Wszystkie')),
                    DropdownMenuItem(
                      value: 'Obligacje',
                      child: Text('Obligacje'),
                    ),
                    DropdownMenuItem(value: 'Udziały', child: Text('Udziały')),
                    DropdownMenuItem(
                      value: 'Pożyczki',
                      child: Text('Pożyczki'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedProductTypeFilter = value;
                    });
                    _loadInvestments();
                  },
                ),
              ),
            ],
          ),
        ),

        // Stats Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Znaleziono: $_investmentsTotalCount inwestycji',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Strona: $_investmentsCurrentPage',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),

        // Investments List
        Expanded(
          child: ListView.builder(
            itemCount: _investments.length + (_investmentsHasNextPage ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _investments.length) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => _loadInvestments(
                      page: _investmentsCurrentPage + 1,
                      append: true,
                    ),
                    child: const Text('Załaduj więcej'),
                  ),
                );
              }

              final investment = _investments[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: investment.productType == ProductType.bonds
                        ? Colors.blue
                        : investment.productType == ProductType.shares
                        ? Colors.green
                        : Colors.orange,
                    child: Text(
                      investment.productType == ProductType.bonds
                          ? 'O'
                          : investment.productType == ProductType.shares
                          ? 'U'
                          : 'P',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(investment.clientName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💼 ${investment.productType.displayName}'),
                      Text(
                        '💰 ${investment.investmentAmount.toStringAsFixed(2)} PLN',
                      ),
                      Text(
                        '📅 ${investment.signedDate.day}/${investment.signedDate.month}/${investment.signedDate.year}',
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Chip(
                        label: Text(investment.status.displayName),
                        backgroundColor:
                            investment.status == InvestmentStatus.active
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                      ),
                      Text(
                        '${investment.remainingCapital.toStringAsFixed(0)} PLN',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    if (_systemStats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _systemStats!;

    return RefreshIndicator(
      onRefresh: _loadSystemStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Performance Badge
            Card(
              color: Colors.green.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.rocket_launch,
                      color: Colors.green,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🚀 Firebase Functions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('Źródło: ${stats.source}'),
                          Text(
                            'Ostatnia aktualizacja: ${stats.lastUpdated.hour}:${stats.lastUpdated.minute.toString().padLeft(2, '0')}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Overall Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Klienci',
                    stats.totalClients.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Inwestycje',
                    stats.totalInvestments.toString(),
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Capital Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Kapitał zainwestowany',
                    '${(stats.totalInvestedCapital / 1000000).toStringAsFixed(1)}M PLN',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Kapitał pozostały',
                    '${(stats.totalRemainingCapital / 1000000).toStringAsFixed(1)}M PLN',
                    Icons.account_balance_wallet,
                    Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildStatCard(
              'Średnia na klienta',
              '${stats.averageInvestmentPerClient.toStringAsFixed(0)} PLN',
              Icons.person_add,
              Colors.teal,
            ),

            const SizedBox(height: 24),

            // Product Type Breakdown
            Text(
              'Rozkład według typów produktów',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 16),

            ...stats.productTypeBreakdown.map(
              (breakdown) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: breakdown.productType.contains('Obligacje')
                        ? Colors.blue
                        : breakdown.productType.contains('Udziały')
                        ? Colors.green
                        : Colors.orange,
                    child: Text(
                      breakdown.productType[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(breakdown.productType),
                  subtitle: Text('${breakdown.count} inwestycji'),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(breakdown.totalCapital / 1000000).toStringAsFixed(1)}M PLN',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Śr: ${breakdown.averagePerInvestment.toStringAsFixed(0)} PLN',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================
  // NEW TAB BUILDERS FOR PRODUCTS
  // =============================================

  Widget _buildBondsTab() {
    return RefreshIndicator(
      onRefresh: () => _loadBonds(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.description, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Obligacje (${_bondsResult?.total ?? 0})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (_bondsResult != null)
                  Text(
                    'Strona ${_bondsResult!.page}/${_bondsResult!.totalPages}',
                  ),
              ],
            ),
          ),
          Expanded(
            child: _bonds.isEmpty
                ? const Center(child: Text('Brak obligacji'))
                : ListView.builder(
                    itemCount: _bonds.length,
                    itemBuilder: (context, index) {
                      final bond = _bonds[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(
                              Icons.description,
                              color: Colors.blue,
                            ),
                          ),
                          title: Text(bond.productType),
                          subtitle: Text('ID: ${bond.id}'),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${bond.remainingCapital.toStringAsFixed(2)} PLN',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Inwestycja: ${bond.investmentAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_bondsResult?.hasNextPage == true)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () =>
                    _loadBonds(page: _bondsCurrentPage + 1, append: true),
                child: const Text('Załaduj więcej'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSharesTab() {
    return RefreshIndicator(
      onRefresh: () => _loadShares(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.share, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Udziały (${_sharesResult?.total ?? 0})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (_sharesResult != null)
                  Text(
                    'Strona ${_sharesResult!.page}/${_sharesResult!.totalPages}',
                  ),
              ],
            ),
          ),
          Expanded(
            child: _shares.isEmpty
                ? const Center(child: Text('Brak udziałów'))
                : ListView.builder(
                    itemCount: _shares.length,
                    itemBuilder: (context, index) {
                      final share = _shares[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: const Icon(Icons.share, color: Colors.green),
                          ),
                          title: Text(share.productType),
                          subtitle: Text('Udziałów: ${share.sharesCount}'),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${share.remainingCapital.toStringAsFixed(2)} PLN',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Cena/udział: ${share.pricePerShare.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_sharesResult?.hasNextPage == true)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () =>
                    _loadShares(page: _sharesCurrentPage + 1, append: true),
                child: const Text('Załaduj więcej'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoansTab() {
    return RefreshIndicator(
      onRefresh: () => _loadLoans(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.account_balance, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Pożyczki (${_loansResult?.total ?? 0})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (_loansResult != null)
                  Text(
                    'Strona ${_loansResult!.page}/${_loansResult!.totalPages}',
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loans.isEmpty
                ? const Center(child: Text('Brak pożyczek'))
                : ListView.builder(
                    itemCount: _loans.length,
                    itemBuilder: (context, index) {
                      final loan = _loans[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: const Icon(
                              Icons.account_balance,
                              color: Colors.orange,
                            ),
                          ),
                          title: Text(
                            loan.loanNumber ??
                                'Pożyczka ${loan.id.substring(0, 8)}',
                          ),
                          subtitle: Text(
                            'Pożyczkobiorca: ${loan.borrower ?? 'N/A'}',
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${loan.remainingCapital.toStringAsFixed(2)} PLN',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Status: ${loan.status ?? 'N/A'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_loansResult?.hasNextPage == true)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () =>
                    _loadLoans(page: _loansCurrentPage + 1, append: true),
                child: const Text('Załaduj więcej'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildApartmentsTab() {
    return RefreshIndicator(
      onRefresh: () => _loadApartments(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.apartment, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Apartamenty (${_apartmentsResult?.total ?? 0})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (_apartmentsResult != null)
                  Text(
                    'Strona ${_apartmentsResult!.page}/${_apartmentsResult!.totalPages}',
                  ),
              ],
            ),
          ),
          Expanded(
            child: _apartments.isEmpty
                ? const Center(child: Text('Brak apartamentów'))
                : ListView.builder(
                    itemCount: _apartments.length,
                    itemBuilder: (context, index) {
                      final apartment = _apartments[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.shade100,
                            child: const Icon(
                              Icons.apartment,
                              color: Colors.purple,
                            ),
                          ),
                          title: Text(
                            apartment.apartmentNumber.isNotEmpty
                                ? 'Apartament ${apartment.apartmentNumber}'
                                : 'Apartament ${apartment.id.substring(0, 8)}',
                          ),
                          subtitle: Text(
                            '${apartment.area}m² | ${apartment.roomCount} pokoje | ${apartment.status.displayName}',
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${apartment.investmentAmount.toStringAsFixed(2)} PLN',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${apartment.pricePerSquareMeter.toStringAsFixed(0)} PLN/m²',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_apartmentsResult?.hasNextPage == true)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => _loadApartments(
                  page: _apartmentsCurrentPage + 1,
                  append: true,
                ),
                child: const Text('Załaduj więcej'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductStatsTab() {
    return RefreshIndicator(
      onRefresh: () => _loadProductStats(),
      child: _productStats == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Podsumowanie ogólne
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.pie_chart, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'Podsumowanie Systemu',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Łączna liczba',
                                  '${_productStats!.summary.totalCount}',
                                  Icons.inventory,
                                  Colors.blue,
                                ),
                              ),
                              Expanded(
                                child: _buildStatCard(
                                  'Łączna wartość',
                                  '${(_productStats!.summary.totalValue / 1000000).toStringAsFixed(1)}M PLN',
                                  Icons.monetization_on,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Statystyki poszczególnych typów
                  _buildProductTypeCard(
                    'Obligacje',
                    _productStats!.bonds,
                    Icons.description,
                    Colors.blue,
                  ),
                  _buildProductTypeCard(
                    'Udziały',
                    _productStats!.shares,
                    Icons.share,
                    Colors.green,
                  ),
                  _buildProductTypeCard(
                    'Pożyczki',
                    _productStats!.loans,
                    Icons.account_balance,
                    Colors.orange,
                  ),
                  _buildProductTypeCardWithArea(
                    'Apartamenty',
                    _productStats!.apartments,
                    Icons.apartment,
                    Colors.purple,
                  ),
                  _buildProductTypeCard(
                    'Inwestycje',
                    _productStats!.investments,
                    Icons.trending_up,
                    Colors.red,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProductTypeCard(
    String title,
    ProductStats stats,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Liczba: ${stats.count}'),
                      Text(
                        'Łączna wartość: ${(stats.totalValue / 1000).toStringAsFixed(1)}K PLN',
                      ),
                      Text(
                        'Średnia: ${stats.averageValue.toStringAsFixed(0)} PLN',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTypeCardWithArea(
    String title,
    ProductStats stats,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Liczba: ${stats.count}'),
                      Text(
                        'Łączna wartość: ${(stats.totalValue / 1000).toStringAsFixed(1)}K PLN',
                      ),
                      Text(
                        'Średnia: ${stats.averageValue.toStringAsFixed(0)} PLN',
                      ),
                      if (stats.totalArea != null)
                        Text(
                          'Łączna powierzchnia: ${stats.totalArea!.toStringAsFixed(0)} m²',
                        ),
                      if (stats.averageArea != null)
                        Text(
                          'Średnia powierzchnia: ${stats.averageArea!.toStringAsFixed(1)} m²',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
