import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/client.dart';
import '../models/investor_summary.dart';
import '../services/investor_analytics_service.dart';
import '../widgets/custom_text_field.dart';

class InvestorAnalyticsScreen extends StatefulWidget {
  const InvestorAnalyticsScreen({super.key});

  @override
  State<InvestorAnalyticsScreen> createState() =>
      _InvestorAnalyticsScreenState();
}

class _InvestorAnalyticsScreenState extends State<InvestorAnalyticsScreen> {
  final InvestorAnalyticsService _analyticsService = InvestorAnalyticsService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  final TextEditingController _companyFilterController =
      TextEditingController();

  List<InvestorSummary> _allInvestors = [];
  List<InvestorSummary> _filteredInvestors = [];
  bool _isLoading = true;
  String? _error;

  // Paging
  int _currentPage = 0;
  int _pageSize = 50;
  bool _hasNextPage = false;
  bool _hasPreviousPage = false;

  InvestorRange? _majorityControlPoint;
  double _totalPortfolioValue = 0;

  // Filtry
  VotingStatus? _selectedVotingStatus;
  ClientType? _selectedClientType;
  bool _includeInactive = false;
  bool _showOnlyWithUnviableInvestments = false;

  @override
  void initState() {
    super.initState();
    _loadInvestorData();
    _searchController.addListener(_applyFilters);
    _minAmountController.addListener(_applyFilters);
    _maxAmountController.addListener(_applyFilters);
    _companyFilterController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _companyFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadInvestorData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🚀 [UI] Ładowanie danych inwestorów...');

      // Ładujemy wszystkich inwestorów do analizy i filtrowania
      final allInvestors = await _analyticsService.getAllInvestorsForAnalysis(
        includeInactive: _includeInactive,
      );

      final majorityPoint = _analyticsService.findMajorityControlPoint(
        allInvestors,
      );
      final totalValue = allInvestors.fold<double>(
        0.0,
        (sum, inv) => sum + inv.totalValue,
      );

      setState(() {
        _allInvestors = allInvestors;
        _filteredInvestors = allInvestors;
        _majorityControlPoint = majorityPoint;
        _totalPortfolioValue = totalValue;
        _currentPage = 0; // Reset do pierwszej strony
        _isLoading = false;
      });

      print('✅ [UI] Załadowano ${allInvestors.length} inwestorów');
    } catch (e) {
      print('❌ [UI] Błąd ładowania: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Ładuj konkretną stronę z aktualnie przefiltrowanych danych
  void _loadPage(int page) {
    if (page < 0) return;

    final totalPages = (_filteredInvestors.length / _pageSize).ceil();
    if (page >= totalPages && totalPages > 0) return;

    setState(() {
      _currentPage = page;
      _hasPreviousPage = page > 0;
      _hasNextPage = page < totalPages - 1;
    });
  }

  // Pobierz aktualną stronę danych
  List<InvestorSummary> get _currentPageData {
    final startIndex = _currentPage * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(
      0,
      _filteredInvestors.length,
    );

    if (startIndex >= _filteredInvestors.length) {
      return [];
    }

    return _filteredInvestors.sublist(startIndex, endIndex);
  }

  void _applyFilters() {
    setState(() {
      _filteredInvestors = _allInvestors.where((investor) {
        // Filtr tekstowy
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch =
            searchQuery.isEmpty ||
            investor.client.name.toLowerCase().contains(searchQuery) ||
            (investor.client.companyName?.toLowerCase().contains(searchQuery) ??
                false);

        // Filtr kwoty
        final minAmount = double.tryParse(_minAmountController.text);
        final maxAmount = double.tryParse(_maxAmountController.text);
        final matchesAmount =
            (minAmount == null || investor.totalValue >= minAmount) &&
            (maxAmount == null || investor.totalValue <= maxAmount);

        // Filtr firmy
        final companyQuery = _companyFilterController.text.toLowerCase();
        final matchesCompany =
            companyQuery.isEmpty ||
            investor.investmentsByCompany.keys.any(
              (company) => company.toLowerCase().contains(companyQuery),
            );

        // Filtr statusu głosowania
        final matchesVoting =
            _selectedVotingStatus == null ||
            investor.client.votingStatus == _selectedVotingStatus;

        // Filtr typu klienta
        final matchesType =
            _selectedClientType == null ||
            investor.client.type == _selectedClientType;

        // Filtr niewykonalnych inwestycji
        final matchesUnviable =
            !_showOnlyWithUnviableInvestments ||
            investor.hasUnviableInvestments;

        return matchesSearch &&
            matchesAmount &&
            matchesCompany &&
            matchesVoting &&
            matchesType &&
            matchesUnviable;
      }).toList();

      // Reset do pierwszej strony po filtrowaniu
      _currentPage = 0;
      _loadPage(0);
    });

    print(
      '🔍 [UI] Filtrowanie: ${_allInvestors.length} -> ${_filteredInvestors.length} inwestorów',
    );
  }

  void _showInvestorDetails(InvestorSummary investor) {
    showDialog(
      context: context,
      builder: (context) => _InvestorDetailsDialog(
        investor: investor,
        analyticsService: _analyticsService,
        onUpdate: _loadInvestorData,
      ),
    );
  }

  void _generateEmailList() {
    final selectedIds = _filteredInvestors
        .where((inv) => inv.client.email.isNotEmpty)
        .map((inv) => inv.client.id)
        .toList();

    showDialog(
      context: context,
      builder: (context) => _EmailGeneratorDialog(
        analyticsService: _analyticsService,
        clientIds: selectedIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Analityka Inwestorów'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.textOnPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvestorData,
          ),
          IconButton(
            icon: const Icon(Icons.email),
            onPressed: _generateEmailList,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCards(),
          _buildFiltersSection(),
          Expanded(child: _buildInvestorsList()),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_isLoading) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Łączna wartość portfela',
                    '${_totalPortfolioValue.toStringAsFixed(0)} PLN',
                    Icons.account_balance_wallet,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Liczba inwestorów',
                    '${_allInvestors.length} (${_filteredInvestors.length} po filtrach)',
                    Icons.people,
                    AppTheme.primaryAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_majorityControlPoint != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.successColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified,
                      color: AppTheme.successColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kontrola 51% portfela',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successColor,
                                ),
                          ),
                          Text(
                            '${_majorityControlPoint!.investorCount} inwestorów stanowi ${_majorityControlPoint!.percentage.toStringAsFixed(1)}% portfela',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.successColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Informacje o pagingu
            if (_filteredInvestors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSecondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Strona ${_currentPage + 1} z ${((_filteredInvestors.length / _pageSize).ceil()).clamp(1, double.infinity).toInt()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Pokazano ${_currentPageData.length} z ${_filteredInvestors.length}',
                      style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtry',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _searchController,
                    label: 'Szukaj inwestora',
                    prefixIcon: Icons.search,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _companyFilterController,
                    label: 'Filtruj po firmie',
                    prefixIcon: Icons.business,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _minAmountController,
                    label: 'Min. kwota',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.money,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _maxAmountController,
                    label: 'Max. kwota',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.money,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                FilterChip(
                  label: Text(
                    'Status głosowania: ${_selectedVotingStatus?.displayName ?? 'Wszystkie'}',
                  ),
                  selected: _selectedVotingStatus != null,
                  onSelected: (selected) {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Wybierz status głosowania'),
                        children: [
                          SimpleDialogOption(
                            onPressed: () {
                              setState(() => _selectedVotingStatus = null);
                              Navigator.pop(context);
                              _applyFilters();
                            },
                            child: const Text('Wszystkie'),
                          ),
                          ...VotingStatus.values.map(
                            (status) => SimpleDialogOption(
                              onPressed: () {
                                setState(() => _selectedVotingStatus = status);
                                Navigator.pop(context);
                                _applyFilters();
                              },
                              child: Text(status.displayName),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                FilterChip(
                  label: Text(
                    'Typ: ${_selectedClientType?.displayName ?? 'Wszystkie'}',
                  ),
                  selected: _selectedClientType != null,
                  onSelected: (selected) {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Wybierz typ klienta'),
                        children: [
                          SimpleDialogOption(
                            onPressed: () {
                              setState(() => _selectedClientType = null);
                              Navigator.pop(context);
                              _applyFilters();
                            },
                            child: const Text('Wszystkie'),
                          ),
                          ...ClientType.values.map(
                            (type) => SimpleDialogOption(
                              onPressed: () {
                                setState(() => _selectedClientType = type);
                                Navigator.pop(context);
                                _applyFilters();
                              },
                              child: Text(type.displayName),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                FilterChip(
                  label: const Text('Niewykonalne inwestycje'),
                  selected: _showOnlyWithUnviableInvestments,
                  onSelected: (selected) {
                    setState(() => _showOnlyWithUnviableInvestments = selected);
                    _applyFilters();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestorsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              'Błąd podczas ładowania danych',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadInvestorData,
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    if (_filteredInvestors.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Brak inwestorów spełniających kryteria',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    final currentPageData = _currentPageData;
    final startIndex = _currentPage * _pageSize;

    return Column(
      children: [
        // Kontrolki paginacji na górze
        if (_filteredInvestors.length > _pageSize) _buildPaginationControls(),

        // Lista inwestorów
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: currentPageData.length,
            itemBuilder: (context, index) {
              final investor = currentPageData[index];
              final globalPosition = startIndex + index + 1;
              return _buildInvestorCard(investor, globalPosition);
            },
          ),
        ),

        // Kontrolki paginacji na dole
        if (_filteredInvestors.length > _pageSize) _buildPaginationControls(),
      ],
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = (_filteredInvestors.length / _pageSize)
        .ceil()
        .clamp(1, double.infinity)
        .toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _hasPreviousPage
                    ? () => _loadPage(_currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                'Strona ${_currentPage + 1} z $totalPages',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              IconButton(
                onPressed: _hasNextPage
                    ? () => _loadPage(_currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'Rozmiar strony:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _pageSize,
                items: [25, 50, 100, 200]
                    .map(
                      (size) =>
                          DropdownMenuItem(value: size, child: Text('$size')),
                    )
                    .toList(),
                onChanged: (newSize) {
                  if (newSize != null) {
                    setState(() {
                      _pageSize = newSize;
                      _currentPage = 0; // Reset do pierwszej strony
                      _loadPage(0);
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvestorCard(InvestorSummary investor, int position) {
    final percentage = _totalPortfolioValue > 0
        ? (investor.totalValue / _totalPortfolioValue) * 100
        : 0.0;

    Color cardColor = Colors.white;
    try {
      cardColor = Color(
        int.parse('0xFF${investor.client.colorCode.replaceAll('#', '')}'),
      );
    } catch (e) {
      cardColor = Colors.white;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showInvestorDetails(investor),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        '$position',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investor.client.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (investor.client.companyName?.isNotEmpty ?? false)
                          Text(
                            investor.client.companyName!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${investor.totalValue.toStringAsFixed(0)} PLN',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(2)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    'Inwestycje: ${investor.investmentCount}',
                    Icons.account_balance_wallet,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    'Status: ${investor.client.votingStatus.displayName}',
                    _getVotingStatusIcon(investor.client.votingStatus),
                    _getVotingStatusColor(investor.client.votingStatus),
                  ),
                  const SizedBox(width: 8),
                  if (investor.hasUnviableInvestments)
                    _buildInfoChip(
                      'Niewykonalne',
                      Icons.warning,
                      AppTheme.warningColor,
                    ),
                ],
              ),
              if (investor.client.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    investor.client.notes,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, [Color? color]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color ?? AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getVotingStatusIcon(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return Icons.check_circle;
      case VotingStatus.no:
        return Icons.cancel;
      case VotingStatus.abstain:
        return Icons.remove_circle;
      case VotingStatus.undecided:
        return Icons.help;
    }
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return AppTheme.successColor;
      case VotingStatus.no:
        return AppTheme.errorColor;
      case VotingStatus.abstain:
        return AppTheme.warningColor;
      case VotingStatus.undecided:
        return AppTheme.textSecondary;
    }
  }
}

// Dialog szczegółów inwestora
class _InvestorDetailsDialog extends StatefulWidget {
  final InvestorSummary investor;
  final InvestorAnalyticsService analyticsService;
  final VoidCallback onUpdate;

  const _InvestorDetailsDialog({
    required this.investor,
    required this.analyticsService,
    required this.onUpdate,
  });

  @override
  State<_InvestorDetailsDialog> createState() => _InvestorDetailsDialogState();
}

class _InvestorDetailsDialogState extends State<_InvestorDetailsDialog> {
  late TextEditingController _notesController;
  late VotingStatus _selectedVotingStatus;
  String _selectedColor = '#FFFFFF';
  List<String> _selectedUnviableInvestments = [];

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.investor.client.notes,
    );
    _selectedVotingStatus = widget.investor.client.votingStatus;
    _selectedColor = widget.investor.client.colorCode;
    _selectedUnviableInvestments = List.from(
      widget.investor.client.unviableInvestments,
    );
  }

  Future<void> _saveChanges() async {
    try {
      await widget.analyticsService.updateInvestorNotes(
        widget.investor.client.id,
        _notesController.text,
      );

      await widget.analyticsService.updateVotingStatus(
        widget.investor.client.id,
        _selectedVotingStatus,
      );

      await widget.analyticsService.updateInvestorColor(
        widget.investor.client.id,
        _selectedColor,
      );

      await widget.analyticsService.markInvestmentsAsUnviable(
        widget.investor.client.id,
        _selectedUnviableInvestments,
      );

      Navigator.of(context).pop();
      widget.onUpdate();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Zmiany zostały zapisane')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.investor.client.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Podstawowe informacje
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Podsumowanie inwestycji',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Łączna wartość',
                            '${widget.investor.totalValue.toStringAsFixed(0)} PLN',
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Liczba inwestycji',
                            '${widget.investor.investmentCount}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Kapitał pozostały',
                            '${widget.investor.totalRemainingCapital.toStringAsFixed(0)} PLN',
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Wartość udziałów',
                            '${widget.investor.totalSharesValue.toStringAsFixed(0)} PLN',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Edycja danych
            Text(
              'Edycja danych',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Status głosowania
            DropdownButtonFormField<VotingStatus>(
              value: _selectedVotingStatus,
              decoration: const InputDecoration(labelText: 'Status głosowania'),
              items: VotingStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Icon(
                            _getVotingStatusIcon(status),
                            color: _getVotingStatusColor(status),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(status.displayName),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedVotingStatus = value!);
              },
            ),

            const SizedBox(height: 12),

            // Notatki
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notatki',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // Lista inwestycji z możliwością oznaczania jako niewykonalne
            Text(
              'Inwestycje (${widget.investor.investments.length})',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: widget.investor.investments.length,
                itemBuilder: (context, index) {
                  final investment = widget.investor.investments[index];
                  final isUnviable = _selectedUnviableInvestments.contains(
                    investment.id,
                  );

                  return CheckboxListTile(
                    title: Text(investment.productName),
                    subtitle: Text(
                      '${investment.remainingCapital.toStringAsFixed(0)} PLN - ${investment.creditorCompany}',
                    ),
                    value: isUnviable,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedUnviableInvestments.add(investment.id);
                        } else {
                          _selectedUnviableInvestments.remove(investment.id);
                        }
                      });
                    },
                    secondary: Icon(
                      isUnviable ? Icons.warning : Icons.check_circle,
                      color: isUnviable
                          ? AppTheme.warningColor
                          : AppTheme.successColor,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Przyciski akcji
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Anuluj'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveChanges,
                  child: const Text('Zapisz'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  IconData _getVotingStatusIcon(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return Icons.check_circle;
      case VotingStatus.no:
        return Icons.cancel;
      case VotingStatus.abstain:
        return Icons.remove_circle;
      case VotingStatus.undecided:
        return Icons.help;
    }
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return AppTheme.successColor;
      case VotingStatus.no:
        return AppTheme.errorColor;
      case VotingStatus.abstain:
        return AppTheme.warningColor;
      case VotingStatus.undecided:
        return AppTheme.textSecondary;
    }
  }
}

// Dialog generowania maili
class _EmailGeneratorDialog extends StatefulWidget {
  final InvestorAnalyticsService analyticsService;
  final List<String> clientIds;

  const _EmailGeneratorDialog({
    required this.analyticsService,
    required this.clientIds,
  });

  @override
  State<_EmailGeneratorDialog> createState() => _EmailGeneratorDialogState();
}

class _EmailGeneratorDialogState extends State<_EmailGeneratorDialog> {
  List<InvestorEmailData> _emailData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmailData();
  }

  Future<void> _loadEmailData() async {
    try {
      final data = await widget.analyticsService.generateEmailData(
        widget.clientIds,
      );
      setState(() {
        _emailData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
    }
  }

  void _copyEmailList() {
    final emails = _emailData.map((data) => data.client.email).join('; ');
    Clipboard.setData(ClipboardData(text: emails));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lista maili została skopiowana')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Generator maili (${_emailData.length})',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else ...[
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _copyEmailList,
                    icon: const Icon(Icons.copy),
                    label: const Text('Kopiuj listę maili'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  itemCount: _emailData.length,
                  itemBuilder: (context, index) {
                    final data = _emailData[index];
                    return Card(
                      child: ExpansionTile(
                        title: Text(data.client.name),
                        subtitle: Text(data.client.email),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Inwestycje:',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(data.formattedInvestmentList),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
