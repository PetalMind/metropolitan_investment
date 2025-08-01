import 'package:flutter/material.dart';
import '../services/firebase_functions_data_service.dart';
import '../models/client.dart';
import '../models/investment.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

/// 🚀 ZARZĄDZANIE DUŻYMI ZBIORAMI DANYCH
/// Demonstracja Firebase Functions dla skalowania
class BigDataManagementScreen extends StatefulWidget {
  const BigDataManagementScreen({super.key});

  @override
  State<BigDataManagementScreen> createState() =>
      _BigDataManagementScreenState();
}

class _BigDataManagementScreenState extends State<BigDataManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = false;
  String? _errorMessage;

  // Clients Tab
  List<Client> _clients = [];
  int _clientsCurrentPage = 1;
  int _clientsTotalCount = 0;
  bool _clientsHasNextPage = false;
  final TextEditingController _clientSearchController = TextEditingController();

  // Investments Tab
  List<Investment> _investments = [];
  int _investmentsCurrentPage = 1;
  int _investmentsTotalCount = 0;
  bool _investmentsHasNextPage = false;
  String? _selectedClientFilter;
  String? _selectedProductTypeFilter;

  // System Stats Tab
  SystemStats? _systemStats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
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
      // Załaduj wszystkie dane równolegle
      await Future.wait([
        _loadClients(),
        _loadInvestments(),
        _loadSystemStats(),
      ]);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zarządzanie Big Data'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Klienci'),
            Tab(icon: Icon(Icons.trending_up), text: 'Inwestycje'),
            Tab(icon: Icon(Icons.analytics), text: 'Statystyki'),
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
}
