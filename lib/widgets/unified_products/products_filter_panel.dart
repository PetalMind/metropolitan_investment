import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../models/unified_product.dart';
import '../../theme/app_theme.dart';

/// Panel filtrów dla produktów
class ProductsFilterPanel extends StatefulWidget {
  final ProductFilterCriteria criteria;
  final ProductSortField sortField;
  final SortDirection sortDirection;
  final Function(ProductFilterCriteria) onFilterChanged;
  final Function(ProductSortField, SortDirection) onSortChanged;

  const ProductsFilterPanel({
    super.key,
    required this.criteria,
    required this.sortField,
    required this.sortDirection,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  @override
  State<ProductsFilterPanel> createState() => _ProductsFilterPanelState();
}

class _ProductsFilterPanelState extends State<ProductsFilterPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Stan filtrów
  List<UnifiedProductType> _selectedTypes = [];
  List<ProductStatus> _selectedStatuses = [];
  double? _minAmount;
  double? _maxAmount;
  DateTimeRange? _dateRange;
  String _companyName = '';
  RangeValues? _interestRateRange;

  // Kontrolery
  late TextEditingController _companyController;
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Inicjalizuj kontrolery
    _companyController = TextEditingController();
    _minAmountController = TextEditingController();
    _maxAmountController = TextEditingController();
    
    _loadCurrentCriteria();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _companyController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _loadCurrentCriteria() {
    _selectedTypes = widget.criteria.productTypes ?? [];
    _selectedStatuses = widget.criteria.statuses ?? [];
    _minAmount = widget.criteria.minInvestmentAmount;
    _maxAmount = widget.criteria.maxInvestmentAmount;
    _companyName = widget.criteria.companyName ?? '';
    
    _companyController.text = _companyName;
    _minAmountController.text = _minAmount?.toStringAsFixed(2) ?? '';
    _maxAmountController.text = _maxAmount?.toStringAsFixed(2) ?? '';
    
    if (widget.criteria.createdAfter != null || widget.criteria.createdBefore != null) {
      _dateRange = DateTimeRange(
        start: widget.criteria.createdAfter ?? DateTime.now().subtract(const Duration(days: 365)),
        end: widget.criteria.createdBefore ?? DateTime.now(),
      );
    }
    
    if (widget.criteria.minInterestRate != null || widget.criteria.maxInterestRate != null) {
      _interestRateRange = RangeValues(
        widget.criteria.minInterestRate ?? 0.0,
        widget.criteria.maxInterestRate ?? 20.0,
      );
    }
  }

  void _applyFilters() {
    final criteria = ProductFilterCriteria(
      productTypes: _selectedTypes.isNotEmpty ? _selectedTypes : null,
      statuses: _selectedStatuses.isNotEmpty ? _selectedStatuses : null,
      minInvestmentAmount: _minAmount,
      maxInvestmentAmount: _maxAmount,
      createdAfter: _dateRange?.start,
      createdBefore: _dateRange?.end,
      companyName: _companyName.isNotEmpty ? _companyName : null,
      minInterestRate: _interestRateRange?.start,
      maxInterestRate: _interestRateRange?.end,
      searchText: widget.criteria.searchText,
    );
    
    widget.onFilterChanged(criteria);
  }

  void _clearAllFilters() {
    setState(() {
      _selectedTypes.clear();
      _selectedStatuses.clear();
      _minAmount = null;
      _maxAmount = null;
      _dateRange = null;
      _companyName = '';
      _interestRateRange = null;
      
      _companyController.clear();
      _minAmountController.clear();
      _maxAmountController.clear();
    });
    
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.elevatedSurfaceDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            if (isMobile)
              _buildMobileLayout(context)
            else
              _buildDesktopLayout(context),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.tune,
          color: AppTheme.secondaryGold,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Filtry i sortowanie',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        _buildSortingControls(context),
      ],
    );
  }

  Widget _buildSortingControls(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Sortuj:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<ProductSortField>(
          value: widget.sortField,
          isDense: true,
          underline: const SizedBox.shrink(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textPrimary,
          ),
          dropdownColor: AppTheme.backgroundModal,
          items: ProductSortField.values.map((field) {
            return DropdownMenuItem(
              value: field,
              child: Text(field.displayName),
            );
          }).toList(),
          onChanged: (field) {
            if (field != null) {
              widget.onSortChanged(field, widget.sortDirection);
            }
          },
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            final newDirection = widget.sortDirection == SortDirection.ascending
                ? SortDirection.descending
                : SortDirection.ascending;
            widget.onSortChanged(widget.sortField, newDirection);
          },
          icon: Icon(
            widget.sortDirection == SortDirection.ascending
                ? Icons.arrow_upward
                : Icons.arrow_downward,
          ),
          color: AppTheme.secondaryGold,
          iconSize: 20,
          tooltip: widget.sortDirection.displayName,
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildProductTypesFilter(context),
        const SizedBox(height: 16),
        _buildStatusFilter(context),
        const SizedBox(height: 16),
        _buildAmountRangeFilter(context),
        const SizedBox(height: 16),
        _buildCompanyFilter(context),
        const SizedBox(height: 16),
        _buildDateRangeFilter(context),
        const SizedBox(height: 16),
        _buildInterestRateFilter(context),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildProductTypesFilter(context)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatusFilter(context)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildAmountRangeFilter(context)),
            const SizedBox(width: 16),
            Expanded(child: _buildCompanyFilter(context)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDateRangeFilter(context)),
            const SizedBox(width: 16),
            Expanded(child: _buildInterestRateFilter(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildProductTypesFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Typy produktów',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
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
              backgroundColor: AppTheme.surfaceCard,
              selectedColor: AppTheme.getProductTypeColor(type.name).withOpacity(0.2),
              checkmarkColor: AppTheme.getProductTypeColor(type.name),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status produktów',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
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
              backgroundColor: AppTheme.surfaceCard,
              selectedColor: AppTheme.getStatusColor(status.name).withOpacity(0.2),
              checkmarkColor: AppTheme.getStatusColor(status.name),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmountRangeFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kwota inwestycji (PLN)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Od',
                  isDense: true,
                ),
                onChanged: (value) {
                  _minAmount = double.tryParse(value);
                  _applyFilters();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Do',
                  isDense: true,
                ),
                onChanged: (value) {
                  _maxAmount = double.tryParse(value);
                  _applyFilters();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompanyFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nazwa spółki',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _companyController,
          decoration: const InputDecoration(
            hintText: 'Wpisz nazwę spółki...',
            isDense: true,
          ),
          onChanged: (value) {
            _companyName = value;
            _applyFilters();
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data utworzenia',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialDateRange: _dateRange,
            );
            if (range != null) {
              setState(() {
                _dateRange = range;
              });
              _applyFilters();
            }
          },
          icon: const Icon(Icons.date_range),
          label: Text(
            _dateRange != null
                ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                : 'Wybierz zakres dat',
          ),
        ),
        if (_dateRange != null)
          TextButton(
            onPressed: () {
              setState(() {
                _dateRange = null;
              });
              _applyFilters();
            },
            child: const Text('Wyczyść'),
          ),
      ],
    );
  }

  Widget _buildInterestRateFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Oprocentowanie (%)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (_interestRateRange != null) ...[
          RangeSlider(
            values: _interestRateRange!,
            min: 0,
            max: 25,
            divisions: 25,
            labels: RangeLabels(
              '${_interestRateRange!.start.toStringAsFixed(1)}%',
              '${_interestRateRange!.end.toStringAsFixed(1)}%',
            ),
            activeColor: AppTheme.secondaryGold,
            onChanged: (values) {
              setState(() {
                _interestRateRange = values;
              });
              _applyFilters();
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_interestRateRange!.start.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '${_interestRateRange!.end.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ] else
          OutlinedButton(
            onPressed: () {
              setState(() {
                _interestRateRange = const RangeValues(0, 25);
              });
              _applyFilters();
            },
            child: const Text('Ustaw zakres oprocentowania'),
          ),
        if (_interestRateRange != null)
          TextButton(
            onPressed: () {
              setState(() {
                _interestRateRange = null;
              });
              _applyFilters();
            },
            child: const Text('Wyczyść'),
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _clearAllFilters,
          child: const Text('Wyczyść wszystkie'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _applyFilters,
          child: const Text('Zastosuj filtry'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}