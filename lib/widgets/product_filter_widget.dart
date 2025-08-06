import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/unified_product.dart';

/// Widget do filtrowania i sortowania produktów zgodny z motywem aplikacji
class ProductFilterWidget extends StatefulWidget {
  final ProductFilterCriteria initialCriteria;
  final ProductSortField initialSortField;
  final SortDirection initialSortDirection;
  final Function(ProductFilterCriteria) onFilterChanged;
  final Function(ProductSortField, SortDirection) onSortChanged;

  const ProductFilterWidget({
    super.key,
    required this.initialCriteria,
    required this.initialSortField,
    required this.initialSortDirection,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  @override
  State<ProductFilterWidget> createState() => _ProductFilterWidgetState();
}

class _ProductFilterWidgetState extends State<ProductFilterWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ProductSortField _currentSortField;
  late SortDirection _currentSortDirection;

  // Kontrolery dla filtrów
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  final TextEditingController _minInterestController = TextEditingController();
  final TextEditingController _maxInterestController = TextEditingController();

  // Wybrane filtry
  Set<UnifiedProductType> _selectedTypes = {};
  Set<ProductStatus> _selectedStatuses = {};
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentSortField = widget.initialSortField;
    _currentSortDirection = widget.initialSortDirection;

    _initializeFromCriteria();
  }

  void _initializeFromCriteria() {
    _selectedTypes = Set.from(widget.initialCriteria.productTypes ?? []);
    _selectedStatuses = Set.from(widget.initialCriteria.statuses ?? []);

    if (widget.initialCriteria.companyName != null) {
      _companyController.text = widget.initialCriteria.companyName!;
    }

    if (widget.initialCriteria.minInvestmentAmount != null) {
      _minAmountController.text = widget.initialCriteria.minInvestmentAmount
          .toString();
    }

    if (widget.initialCriteria.maxInvestmentAmount != null) {
      _maxAmountController.text = widget.initialCriteria.maxInvestmentAmount
          .toString();
    }

    if (widget.initialCriteria.minInterestRate != null) {
      _minInterestController.text = widget.initialCriteria.minInterestRate
          .toString();
    }

    if (widget.initialCriteria.maxInterestRate != null) {
      _maxInterestController.text = widget.initialCriteria.maxInterestRate
          .toString();
    }

    if (widget.initialCriteria.createdAfter != null &&
        widget.initialCriteria.createdBefore != null) {
      _dateRange = DateTimeRange(
        start: widget.initialCriteria.createdAfter!,
        end: widget.initialCriteria.createdBefore!,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _companyController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _minInterestController.dispose();
    _maxInterestController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final criteria = ProductFilterCriteria(
      productTypes: _selectedTypes.isNotEmpty ? _selectedTypes.toList() : null,
      statuses: _selectedStatuses.isNotEmpty
          ? _selectedStatuses.toList()
          : null,
      companyName: _companyController.text.isNotEmpty
          ? _companyController.text
          : null,
      minInvestmentAmount: _minAmountController.text.isNotEmpty
          ? double.tryParse(_minAmountController.text)
          : null,
      maxInvestmentAmount: _maxAmountController.text.isNotEmpty
          ? double.tryParse(_maxAmountController.text)
          : null,
      minInterestRate: _minInterestController.text.isNotEmpty
          ? double.tryParse(_minInterestController.text)
          : null,
      maxInterestRate: _maxInterestController.text.isNotEmpty
          ? double.tryParse(_maxInterestController.text)
          : null,
      createdAfter: _dateRange?.start,
      createdBefore: _dateRange?.end,
    );

    widget.onFilterChanged(criteria);
  }

  void _clearFilters() {
    setState(() {
      _selectedTypes.clear();
      _selectedStatuses.clear();
      _companyController.clear();
      _minAmountController.clear();
      _maxAmountController.clear();
      _minInterestController.clear();
      _maxInterestController.clear();
      _dateRange = null;
    });

    _applyFilters();
  }

  void _applySorting() {
    widget.onSortChanged(_currentSortField, _currentSortDirection);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.premiumCardDecoration,
      child: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.filter_list), text: 'Filtry'),
                Tab(icon: Icon(Icons.sort), text: 'Sortowanie'),
              ],
              labelColor: AppTheme.secondaryGold,
              unselectedLabelColor: AppTheme.textTertiary,
              indicatorColor: AppTheme.secondaryGold,
              indicatorWeight: 3,
            ),
          ),

          // Tab Bar View
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabController,
              children: [_buildFiltersTab(), _buildSortingTab()],
            ),
          ),

          // Przyciski akcji
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildFiltersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Typy produktów
          _buildSectionTitle('Typy produktów'),
          const SizedBox(height: 8),
          _buildProductTypeChips(),

          const SizedBox(height: 16),

          // Statusy
          _buildSectionTitle('Statusy'),
          const SizedBox(height: 8),
          _buildStatusChips(),

          const SizedBox(height: 16),

          // Kwoty inwestycji
          _buildSectionTitle('Kwota inwestycji (PLN)'),
          const SizedBox(height: 8),
          _buildAmountInputs(),

          const SizedBox(height: 16),

          // Oprocentowanie
          _buildSectionTitle('Oprocentowanie (%)'),
          const SizedBox(height: 8),
          _buildInterestInputs(),

          const SizedBox(height: 16),

          // Nazwa spółki
          _buildSectionTitle('Nazwa spółki'),
          const SizedBox(height: 8),
          _buildCompanyInput(),

          const SizedBox(height: 16),

          // Zakres dat
          _buildSectionTitle('Data utworzenia'),
          const SizedBox(height: 8),
          _buildDateRangePicker(),
        ],
      ),
    );
  }

  Widget _buildSortingTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Sortuj według'),
          const SizedBox(height: 12),

          ...ProductSortField.values.map((field) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (_currentSortField == field) {
                      _currentSortDirection =
                          _currentSortDirection == SortDirection.ascending
                          ? SortDirection.descending
                          : SortDirection.ascending;
                    } else {
                      _currentSortField = field;
                      _currentSortDirection = SortDirection.ascending;
                    }
                  });
                  _applySorting();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _currentSortField == field
                        ? AppTheme.secondaryGold.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _currentSortField == field
                          ? AppTheme.secondaryGold.withOpacity(0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getSortFieldIcon(field),
                        size: 20,
                        color: _currentSortField == field
                            ? AppTheme.secondaryGold
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          field.displayName,
                          style: TextStyle(
                            color: _currentSortField == field
                                ? AppTheme.secondaryGold
                                : AppTheme.textSecondary,
                            fontWeight: _currentSortField == field
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (_currentSortField == field)
                        Icon(
                          _currentSortDirection == SortDirection.ascending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 16,
                          color: AppTheme.secondaryGold,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildProductTypeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: UnifiedProductType.values.map((type) {
        final isSelected = _selectedTypes.contains(type);
        return FilterChip(
          label: Text(type.displayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedTypes.add(type);
              } else {
                _selectedTypes.remove(type);
              }
            });
            _applyFilters();
          },
          labelStyle: TextStyle(
            color: isSelected
                ? AppTheme.textOnSecondary
                : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          backgroundColor: isSelected
              ? AppTheme.getProductTypeColor(type.collectionName)
              : AppTheme.surfaceInteractive,
          selectedColor: AppTheme.getProductTypeColor(type.collectionName),
          checkmarkColor: AppTheme.textOnSecondary,
          side: BorderSide(
            color: isSelected
                ? AppTheme.getProductTypeColor(type.collectionName)
                : AppTheme.borderSecondary,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ProductStatus.values.map((status) {
        final isSelected = _selectedStatuses.contains(status);
        return FilterChip(
          label: Text(status.displayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedStatuses.add(status);
              } else {
                _selectedStatuses.remove(status);
              }
            });
            _applyFilters();
          },
          labelStyle: TextStyle(
            color: isSelected
                ? AppTheme.textOnSecondary
                : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          backgroundColor: isSelected
              ? AppTheme.getStatusColor(status.displayName)
              : AppTheme.surfaceInteractive,
          selectedColor: AppTheme.getStatusColor(status.displayName),
          checkmarkColor: AppTheme.textOnSecondary,
          side: BorderSide(
            color: isSelected
                ? AppTheme.getStatusColor(status.displayName)
                : AppTheme.borderSecondary,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmountInputs() {
    return Row(
      children: [
        Expanded(
          child: _buildNumberInput(
            controller: _minAmountController,
            hintText: 'Min',
            onChanged: _applyFilters,
          ),
        ),
        const SizedBox(width: 12),
        const Text('—', style: TextStyle(color: AppTheme.textTertiary)),
        const SizedBox(width: 12),
        Expanded(
          child: _buildNumberInput(
            controller: _maxAmountController,
            hintText: 'Max',
            onChanged: _applyFilters,
          ),
        ),
      ],
    );
  }

  Widget _buildInterestInputs() {
    return Row(
      children: [
        Expanded(
          child: _buildNumberInput(
            controller: _minInterestController,
            hintText: 'Min %',
            onChanged: _applyFilters,
          ),
        ),
        const SizedBox(width: 12),
        const Text('—', style: TextStyle(color: AppTheme.textTertiary)),
        const SizedBox(width: 12),
        Expanded(
          child: _buildNumberInput(
            controller: _maxInterestController,
            hintText: 'Max %',
            onChanged: _applyFilters,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInput({
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppTheme.textTertiary),
        filled: true,
        fillColor: AppTheme.surfaceInteractive,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: (_) => onChanged(),
    );
  }

  Widget _buildCompanyInput() {
    return TextField(
      controller: _companyController,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: 'Wprowadź nazwę spółki',
        hintStyle: const TextStyle(color: AppTheme.textTertiary),
        filled: true,
        fillColor: AppTheme.surfaceInteractive,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: (_) => _applyFilters(),
    );
  }

  Widget _buildDateRangePicker() {
    return InkWell(
      onTap: () async {
        final result = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: _dateRange,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppTheme.secondaryGold,
                  onPrimary: AppTheme.textOnSecondary,
                  surface: AppTheme.backgroundSecondary,
                  onSurface: AppTheme.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );

        if (result != null) {
          setState(() {
            _dateRange = result;
          });
          _applyFilters();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceInteractive,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.date_range,
              color: AppTheme.secondaryGold,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _dateRange != null
                    ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                    : 'Wybierz zakres dat',
                style: TextStyle(
                  color: _dateRange != null
                      ? AppTheme.textPrimary
                      : AppTheme.textTertiary,
                ),
              ),
            ),
            if (_dateRange != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _dateRange = null;
                  });
                  _applyFilters();
                },
                child: const Icon(
                  Icons.clear,
                  color: AppTheme.textTertiary,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Wyczyść'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: const BorderSide(color: AppTheme.borderSecondary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _applyFilters,
              icon: const Icon(Icons.check),
              label: const Text('Zastosuj'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryGold,
                foregroundColor: AppTheme.textOnSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSortFieldIcon(ProductSortField field) {
    switch (field) {
      case ProductSortField.name:
        return Icons.sort_by_alpha;
      case ProductSortField.type:
        return Icons.category;
      case ProductSortField.investmentAmount:
      case ProductSortField.totalValue:
        return Icons.attach_money;
      case ProductSortField.createdAt:
      case ProductSortField.uploadedAt:
        return Icons.schedule;
      case ProductSortField.status:
        return Icons.flag;
      case ProductSortField.companyName:
        return Icons.business;
      case ProductSortField.interestRate:
        return Icons.percent;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
