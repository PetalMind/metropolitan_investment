import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../theme/app_theme.dart';
import '../models/investment.dart';
import '../models/product.dart';
import '../services/investment_service.dart';
import '../widgets/investment_card.dart';
import '../widgets/investment_form.dart';
import '../widgets/data_table_widget.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  final InvestmentService _investmentService = InvestmentService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Investment> _investments = [];
  List<Investment> _filteredInvestments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _isGridView = false;
  String? _lastDocumentId;

  // Parametry paginacji
  static const int _pageSize = 20;

  InvestmentStatus? _selectedStatus;
  ProductType? _selectedProductType;
  String? _selectedBranch;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadInitialInvestments();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreInvestments();
    }
  }

  void _onSearchChanged() {
    // Opóźnienie wyszukiwania dla lepszej wydajności
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == _searchController.text) {
        _resetAndReload();
      }
    });
  }

  Future<void> _loadInitialInvestments() async {
    setState(() {
      _isLoading = true;
      _investments.clear();
      _filteredInvestments.clear();
      _lastDocumentId = null;
      _hasMoreData = true;
    });

    try {
      final investments = await _investmentService.getInvestmentsPaginated(
        limit: _pageSize,
      );

      setState(() {
        _investments = investments;
        _filteredInvestments = investments;
        _lastDocumentId = investments.isNotEmpty ? investments.last.id : null;
        _hasMoreData = investments.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Błąd podczas ładowania inwestycji: $e');
    }
  }

  Future<void> _loadMoreInvestments() async {
    if (_isLoadingMore || !_hasMoreData || _lastDocumentId == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final newInvestments = await _investmentService.getInvestmentsPaginated(
        limit: _pageSize,
        lastDocumentId: _lastDocumentId,
      );

      setState(() {
        _investments.addAll(newInvestments);
        _filterInvestments();
        _lastDocumentId = newInvestments.isNotEmpty
            ? newInvestments.last.id
            : null;
        _hasMoreData = newInvestments.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      _showErrorSnackBar('Błąd podczas ładowania kolejnych inwestycji: $e');
    }
  }

  void _resetAndReload() {
    _loadInitialInvestments();
  }

  void _filterInvestments() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredInvestments = _investments.where((investment) {
        // Text search
        final matchesSearch =
            query.isEmpty ||
            investment.clientName.toLowerCase().contains(query) ||
            investment.productName.toLowerCase().contains(query) ||
            investment.employeeFullName.toLowerCase().contains(query);

        // Status filter
        final matchesStatus =
            _selectedStatus == null || investment.status == _selectedStatus;

        // Product type filter
        final matchesProductType =
            _selectedProductType == null ||
            investment.productType == _selectedProductType;

        // Branch filter
        final matchesBranch =
            _selectedBranch == null || investment.branchCode == _selectedBranch;

        // Date range filter
        final matchesDateRange =
            _selectedDateRange == null ||
            (investment.signedDate.isAfter(_selectedDateRange!.start) &&
                investment.signedDate.isBefore(_selectedDateRange!.end));

        return matchesSearch &&
            matchesStatus &&
            matchesProductType &&
            matchesBranch &&
            matchesDateRange;
      }).toList();
    });
  }

  void _showInvestmentForm([Investment? investment]) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.9,
          child: InvestmentForm(
            investment: investment,
            onSaved: (savedInvestment) {
              Navigator.of(context).pop();
              _loadInitialInvestments();
              _showSuccessSnackBar(
                investment == null
                    ? 'Inwestycja została dodana'
                    : 'Inwestycja została zaktualizowana',
              );
            },
          ),
        ),
      ),
    );
  }

  void _deleteInvestment(Investment investment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potwierdzenie usunięcia'),
        content: Text(
          'Czy na pewno chcesz usunąć inwestycję ${investment.clientName} - ${investment.productName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _investmentService.deleteInvestment(investment.id);
                Navigator.of(context).pop();
                _showSuccessSnackBar('Inwestycja została usunięta');
                _loadInitialInvestments();
              } catch (e) {
                _showErrorSnackBar('Błąd podczas usuwania: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtry'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<InvestmentStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Wszystkie')),
                  ...InvestmentStatus.values.map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.displayName),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedStatus = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ProductType>(
                value: _selectedProductType,
                decoration: const InputDecoration(labelText: 'Typ produktu'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Wszystkie')),
                  ...ProductType.values.map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _selectedProductType = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Oddział'),
                onChanged: (value) => setState(
                  () => _selectedBranch = value.isEmpty ? null : value,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final dateRange = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          currentDate: DateTime.now(),
                        );
                        if (dateRange != null) {
                          setState(() => _selectedDateRange = dateRange);
                        }
                      },
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _selectedDateRange == null
                            ? 'Wybierz zakres dat'
                            : '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}',
                      ),
                    ),
                  ),
                  if (_selectedDateRange != null)
                    IconButton(
                      onPressed: () =>
                          setState(() => _selectedDateRange = null),
                      icon: const Icon(Icons.clear),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
                _selectedProductType = null;
                _selectedBranch = null;
                _selectedDateRange = null;
              });
              _filterInvestments();
              Navigator.of(context).pop();
            },
            child: const Text('Wyczyść'),
          ),
          ElevatedButton(
            onPressed: () {
              _filterInvestments();
              Navigator.of(context).pop();
            },
            child: const Text('Zastosuj'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildToolbar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredInvestments.isEmpty
                ? _buildEmptyState()
                : _isGridView
                ? _buildGridView()
                : _buildTableView(),
          ),
        ],
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
                  'Zarządzanie Inwestycjami',
                  style: Theme.of(
                    context,
                  ).textTheme.displayMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_filteredInvestments.length} inwestycji${_hasMoreData ? ' (więcej dostępnych)' : ' (wszystkie)'}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (_hasMoreData && !_isLoadingMore)
            ElevatedButton.icon(
              onPressed: _loadMoreInvestments,
              icon: const Icon(Icons.refresh),
              label: const Text('Załaduj więcej'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.9),
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showInvestmentForm(),
            icon: const Icon(Icons.add),
            label: const Text('Nowa Inwestycja'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Szukaj po kliencie, produkcie lub doradcy...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _filterInvestments();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _showFilterDialog,
            icon: Badge(
              isLabelVisible: _hasActiveFilters(),
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Filtry',
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => setState(() => _isGridView = !_isGridView),
            icon: Icon(_isGridView ? Icons.table_rows : Icons.grid_view),
            tooltip: _isGridView ? 'Widok tabeli' : 'Widok kafelków',
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export_excel':
                  _exportToExcel();
                  break;
                case 'export_pdf':
                  _exportToPdf();
                  break;
                case 'import':
                  _showImportDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_excel',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Eksport do Excel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf),
                    SizedBox(width: 8),
                    Text('Eksport do PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.file_upload),
                    SizedBox(width: 8),
                    Text('Import z Excel'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _filteredInvestments.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredInvestments.length) {
            return const Card(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final investment = _filteredInvestments[index];
          return InvestmentCard(
            investment: investment,
            onTap: () => _showInvestmentForm(investment),
            onEdit: () => _showInvestmentForm(investment),
            onDelete: () => _deleteInvestment(investment),
          );
        },
      ),
    );
  }

  Widget _buildTableView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: DataTableWidget<Investment>(
              items: _filteredInvestments,
              columns: [
                DataTableColumn<Investment>(
                  label: 'Klient',
                  value: (investment) => investment.clientName,
                  sortable: true,
                ),
                DataTableColumn<Investment>(
                  label: 'Produkt',
                  value: (investment) => investment.productName,
                  sortable: true,
                ),
                DataTableColumn<Investment>(
                  label: 'Typ',
                  value: (investment) => investment.productType.displayName,
                  sortable: true,
                  width: 120,
                ),
                DataTableColumn<Investment>(
                  label: 'Kwota',
                  value: (investment) =>
                      _formatCurrency(investment.investmentAmount),
                  sortable: true,
                  numeric: true,
                  width: 140,
                ),
                DataTableColumn<Investment>(
                  label: 'Status',
                  value: (investment) => investment.status.displayName,
                  sortable: true,
                  width: 120,
                  widget: (investment) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.getStatusColor(
                        investment.status.name,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      investment.status.displayName,
                      style: TextStyle(
                        color: AppTheme.getStatusColor(investment.status.name),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                DataTableColumn<Investment>(
                  label: 'Data podpisania',
                  value: (investment) => _formatDate(investment.signedDate),
                  sortable: true,
                  width: 120,
                ),
                DataTableColumn<Investment>(
                  label: 'Doradca',
                  value: (investment) => investment.employeeFullName,
                  sortable: true,
                  width: 150,
                ),
                DataTableColumn<Investment>(
                  label: 'Oddział',
                  value: (investment) => investment.branchCode,
                  sortable: true,
                  width: 80,
                ),
                DataTableColumn<Investment>(
                  label: 'Akcje',
                  value: (investment) => '',
                  width: 120,
                  widget: (investment) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _showInvestmentForm(investment),
                        icon: const Icon(Icons.edit, size: 18),
                        tooltip: 'Edytuj',
                      ),
                      IconButton(
                        onPressed: () => _deleteInvestment(investment),
                        icon: const Icon(Icons.delete, size: 18),
                        tooltip: 'Usuń',
                      ),
                    ],
                  ),
                ),
              ],
              onRowTap: (investment) => _showInvestmentForm(investment),
            ),
          ),
        ),
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(MdiIcons.chartLine, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Brak inwestycji',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Dodaj pierwszą inwestycję, aby rozpocząć',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showInvestmentForm(),
            icon: const Icon(Icons.add),
            label: const Text('Dodaj Inwestycję'),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedStatus != null ||
        _selectedProductType != null ||
        _selectedBranch != null ||
        _selectedDateRange != null;
  }

  void _exportToExcel() {
    // Implement Excel export
    _showInfoSnackBar('Eksport do Excel - w przygotowaniu');
  }

  void _exportToPdf() {
    // Implement PDF export
    _showInfoSnackBar('Eksport do PDF - w przygotowaniu');
  }

  void _showImportDialog() {
    // Implement import dialog
    _showInfoSnackBar('Import z Excel - w przygotowaniu');
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match match) => '${match[1]} ')} PLN';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.successColor),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.infoColor),
    );
  }
}
