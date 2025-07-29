import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../theme/app_theme.dart';
import '../models/investment.dart';
import '../models/product.dart';
import '../services/investment_service.dart';
import '../widgets/investment_card.dart';
import '../widgets/investment_form.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/custom_loading_widget.dart';
import '../utils/currency_formatter.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  final InvestmentService _investmentService = InvestmentService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Investment> _allInvestments = [];
  List<Investment> _investments = [];
  List<Investment> _filteredInvestments = [];
  bool _isInitialLoading = true;
  bool _isGridView = false;
  double _loadingProgress = 0.0;
  String _loadingStage = 'Inicjalizacja...';

  InvestmentStatus? _selectedStatus;
  ProductType? _selectedProductType;
  String? _selectedBranch;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadAllInvestments();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Opóźnienie wyszukiwania dla lepszej wydajności
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchController.text == _searchController.text) {
        _filterInvestments();
      }
    });
  }

  Future<void> _loadAllInvestments() async {
    try {
      setState(() {
        _isInitialLoading = true;
        _loadingProgress = 0.0;
        _loadingStage = 'Inicjalizacja...';
      });

      final investments = await _investmentService
          .loadAllInvestmentsWithProgress(
            onProgress: (progress, stage) {
              if (mounted) {
                setState(() {
                  _loadingProgress = progress;
                  _loadingStage = stage;
                });
              }
            },
          );

      setState(() {
        _allInvestments = investments;
        _investments = investments;
        _filteredInvestments = investments;
        _isInitialLoading = false;
      });
    } catch (e) {
      setState(() => _isInitialLoading = false);
      _showErrorSnackBar('Błąd podczas ładowania inwestycji: $e');
    }
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
              _loadAllInvestments();
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
                _loadAllInvestments();
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
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkTheme ? AppTheme.backgroundPrimary : null,
      body: Column(
        children: [
          _buildHeader(),
          if (!_isInitialLoading) _buildToolbar(),
          Expanded(
            child: _isInitialLoading
                ? _buildCustomLoading()
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

  Widget _buildCustomLoading() {
    return Center(
      child: ProgressLoadingWidget(
        progress: _loadingProgress,
        message: _loadingStage,
        details: _loadingProgress > 0.3
            ? 'Może to potrwać kilka sekund...'
            : null,
      ),
    );
  }

  Widget _buildHeader() {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isDarkTheme
            ? AppTheme.primaryGradient
            : AppTheme.goldGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        MdiIcons.chartLine,
                        color: AppTheme.textOnPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zarządzanie Inwestycjami',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  color: AppTheme.textOnPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_filteredInvestments.length} inwestycji (wszystkie załadowane)',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppTheme.textOnPrimary.withOpacity(
                                    0.85,
                                  ),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: _loadAllInvestments,
                  icon: const Icon(Icons.refresh),
                  color: AppTheme.textOnPrimary,
                  tooltip: 'Odśwież dane',
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showInvestmentForm(),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Nowa Inwestycja',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: isDarkTheme
                      ? AppTheme.primaryColor
                      : AppTheme.secondaryGold,
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      color: isDarkTheme ? AppTheme.backgroundSecondary : Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDarkTheme ? AppTheme.surfaceInteractive : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkTheme
                      ? AppTheme.borderSecondary
                      : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkTheme ? 0.2 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: isDarkTheme ? AppTheme.textPrimary : Colors.black87,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Szukaj po kliencie, produkcie lub doradcy...',
                  hintStyle: TextStyle(
                    color: isDarkTheme
                        ? AppTheme.textTertiary
                        : Colors.grey[600],
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDarkTheme
                        ? AppTheme.textSecondary
                        : Colors.grey[600],
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _filterInvestments();
                          },
                          icon: Icon(
                            Icons.clear,
                            color: isDarkTheme
                                ? AppTheme.textSecondary
                                : Colors.grey[600],
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildToolbarButton(
            onPressed: _showFilterDialog,
            icon: Icons.filter_list,
            tooltip: 'Filtry',
            color: AppTheme.primaryColor,
            hasNotification: _hasActiveFilters(),
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            onPressed: () => setState(() => _isGridView = !_isGridView),
            icon: _isGridView ? Icons.table_rows : Icons.grid_view,
            tooltip: _isGridView ? 'Widok tabeli' : 'Widok kafelków',
            color: AppTheme.infoColor,
          ),
          const SizedBox(width: 8),
          _buildToolbarPopupMenu(),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String tooltip,
    required Color color,
    bool hasNotification = false,
  }) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkTheme ? color.withOpacity(0.15) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkTheme ? color.withOpacity(0.3) : color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: hasNotification
            ? Badge(child: Icon(icon, color: color))
            : Icon(icon, color: color),
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildToolbarPopupMenu() {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkTheme
            ? AppTheme.warningColor.withOpacity(0.15)
            : AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkTheme
              ? AppTheme.warningColor.withOpacity(0.3)
              : AppTheme.warningColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: PopupMenuButton<String>(
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(Icons.more_vert, color: AppTheme.warningColor),
        ),
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
        itemCount: _filteredInvestments.length,
        itemBuilder: (context, index) {
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
    return Container(
      padding: const EdgeInsets.all(16),
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
            label: 'Kapitał pozostały',
            value: (investment) => _formatCurrency(investment.remainingCapital),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }

  Widget _buildEmptyState() {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkTheme
                    ? AppTheme.surfaceElevated
                    : Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkTheme
                      ? AppTheme.borderPrimary
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Icon(
                MdiIcons.chartLine,
                size: 64,
                color: isDarkTheme ? AppTheme.textTertiary : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Brak inwestycji',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: isDarkTheme ? AppTheme.textSecondary : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Nie znaleziono inwestycji spełniających kryteria wyszukiwania.\nSpróbuj zmienić filtry lub dodać pierwszą inwestycję.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDarkTheme ? AppTheme.textTertiary : Colors.grey[500],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_hasActiveFilters()) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedStatus = null;
                        _selectedProductType = null;
                        _selectedBranch = null;
                        _selectedDateRange = null;
                        _searchController.clear();
                      });
                      _filterInvestments();
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Wyczyść filtry'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDarkTheme
                            ? AppTheme.borderPrimary
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                ElevatedButton.icon(
                  onPressed: () => _showInvestmentForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj Inwestycję'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkTheme
                        ? AppTheme.secondaryGold
                        : AppTheme.primaryColor,
                    foregroundColor: isDarkTheme
                        ? AppTheme.textOnSecondary
                        : AppTheme.textOnPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
    return CurrencyFormatter.formatCurrency(amount);
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
