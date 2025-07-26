import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/investment.dart';
import '../models/product.dart';
import '../models/client.dart';
import '../models/employee.dart';
import '../services/investment_service.dart';
import '../services/client_service.dart';
import '../services/employee_service.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';

class InvestmentForm extends StatefulWidget {
  final Investment? investment;
  final void Function(Investment investment) onSaved;

  const InvestmentForm({super.key, this.investment, required this.onSaved});

  @override
  State<InvestmentForm> createState() => _InvestmentFormState();
}

class _InvestmentFormState extends State<InvestmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _investmentService = InvestmentService();
  final _clientService = ClientService();
  final _employeeService = EmployeeService();
  final _productService = ProductService();

  // Form controllers
  final _investmentAmountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _realizedCapitalController = TextEditingController();
  final _realizedInterestController = TextEditingController();
  final _transferToOtherProductController = TextEditingController();
  final _remainingCapitalController = TextEditingController();
  final _remainingInterestController = TextEditingController();
  final _plannedTaxController = TextEditingController();
  final _realizedTaxController = TextEditingController();
  final _proposalIdController = TextEditingController();
  final _sharesCountController = TextEditingController();

  // Form values
  String? _selectedClientId;
  String? _selectedEmployeeId;
  String? _selectedProductId;
  InvestmentStatus _selectedStatus = InvestmentStatus.active;
  MarketType _selectedMarketType = MarketType.primary;
  ProductType _selectedProductType = ProductType.bonds;
  bool _isAllocated = false;
  DateTime _signedDate = DateTime.now();
  DateTime? _entryDate;
  DateTime? _exitDate;
  DateTime? _issueDate;
  DateTime? _redemptionDate;
  String _currency = 'PLN';
  double? _exchangeRate;

  // Data lists
  List<Client> _clients = [];
  List<Employee> _employees = [];
  List<Product> _products = [];
  List<Product> _filteredProducts = [];

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeForm();
  }

  @override
  void dispose() {
    _investmentAmountController.dispose();
    _paidAmountController.dispose();
    _realizedCapitalController.dispose();
    _realizedInterestController.dispose();
    _transferToOtherProductController.dispose();
    _remainingCapitalController.dispose();
    _remainingInterestController.dispose();
    _plannedTaxController.dispose();
    _realizedTaxController.dispose();
    _proposalIdController.dispose();
    _sharesCountController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.investment != null) {
      final investment = widget.investment!;
      _selectedClientId = investment.clientId;
      _selectedEmployeeId = investment.employeeId;
      _selectedStatus = investment.status;
      _isAllocated = investment.isAllocated;
      _selectedMarketType = investment.marketType;
      _signedDate = investment.signedDate;
      _entryDate = investment.entryDate;
      _exitDate = investment.exitDate;
      _proposalIdController.text = investment.proposalId;
      _selectedProductType = investment.productType;
      _issueDate = investment.issueDate;
      _redemptionDate = investment.redemptionDate;
      _sharesCountController.text = investment.sharesCount?.toString() ?? '';
      _investmentAmountController.text = investment.investmentAmount.toString();
      _paidAmountController.text = investment.paidAmount.toString();
      _realizedCapitalController.text = investment.realizedCapital.toString();
      _realizedInterestController.text = investment.realizedInterest.toString();
      _transferToOtherProductController.text = investment.transferToOtherProduct
          .toString();
      _remainingCapitalController.text = investment.remainingCapital.toString();
      _remainingInterestController.text = investment.remainingInterest
          .toString();
      _plannedTaxController.text = investment.plannedTax.toString();
      _realizedTaxController.text = investment.realizedTax.toString();
      _currency = investment.currency;
      _exchangeRate = investment.exchangeRate;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final clientsStream = _clientService.getClients();
      final employeesStream = _employeeService.getEmployees();
      final productsStream = _productService.getProducts();

      clientsStream.listen((clients) {
        setState(() => _clients = clients);
      });

      employeesStream.listen((employees) {
        setState(() => _employees = employees);
      });

      productsStream.listen((products) {
        setState(() {
          _products = products;
          _filterProducts();
        });
      });

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Błąd podczas ładowania danych: $e');
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products
          .where((product) => product.type == _selectedProductType)
          .toList();
    });
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime? currentDate,
    Function(DateTime) onDateSelected,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      onDateSelected(date);
    }
  }

  Future<void> _saveInvestment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final selectedClient = _clients.firstWhere(
        (c) => c.id == _selectedClientId,
      );
      final selectedEmployee = _employees.firstWhere(
        (e) => e.id == _selectedEmployeeId,
      );
      final selectedProduct = _products.firstWhere(
        (p) => p.id == _selectedProductId,
      );

      final investment = Investment(
        id: widget.investment?.id ?? '',
        clientId: _selectedClientId!,
        clientName: selectedClient.name,
        employeeId: _selectedEmployeeId!,
        employeeFirstName: selectedEmployee.firstName,
        employeeLastName: selectedEmployee.lastName,
        branchCode: selectedEmployee.branchCode,
        status: _selectedStatus,
        isAllocated: _isAllocated,
        marketType: _selectedMarketType,
        signedDate: _signedDate,
        entryDate: _entryDate,
        exitDate: _exitDate,
        proposalId: _proposalIdController.text,
        productType: _selectedProductType,
        productName: selectedProduct.name,
        creditorCompany: selectedProduct.companyName,
        companyId: selectedProduct.companyId,
        issueDate: _issueDate,
        redemptionDate: _redemptionDate,
        sharesCount: _sharesCountController.text.isNotEmpty
            ? int.parse(_sharesCountController.text)
            : null,
        investmentAmount: double.parse(_investmentAmountController.text),
        paidAmount: double.parse(_paidAmountController.text),
        realizedCapital: double.parse(_realizedCapitalController.text),
        realizedInterest: double.parse(_realizedInterestController.text),
        transferToOtherProduct: double.parse(
          _transferToOtherProductController.text,
        ),
        remainingCapital: double.parse(_remainingCapitalController.text),
        remainingInterest: double.parse(_remainingInterestController.text),
        plannedTax: double.parse(_plannedTaxController.text),
        realizedTax: double.parse(_realizedTaxController.text),
        currency: _currency,
        exchangeRate: _exchangeRate,
        createdAt: widget.investment?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.investment == null) {
        await _investmentService.createInvestment(investment);
      } else {
        // Ustawiam ID dla aktualizacji
        final updatedInvestment = investment.copyWith(
          id: widget.investment!.id,
        );
        await _investmentService.updateInvestment(
          widget.investment!.id,
          updatedInvestment,
        );
      }

      widget.onSaved(investment);
    } catch (e) {
      _showErrorSnackBar('Błąd podczas zapisywania: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.investment == null ? 'Nowa Inwestycja' : 'Edytuj Inwestycję',
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.textOnPrimary,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            child: const Text(
              'Anuluj',
              style: TextStyle(color: AppTheme.textOnPrimary),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveInvestment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surfaceCard,
              foregroundColor: AppTheme.primaryColor,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Zapisz'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildFinancialSection(),
              const SizedBox(height: 24),
              _buildDatesSection(),
              const SizedBox(height: 24),
              _buildAdditionalInfoSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informacje podstawowe',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedClientId,
                  decoration: const InputDecoration(labelText: 'Klient *'),
                  items: _clients
                      .map(
                        (client) => DropdownMenuItem(
                          value: client.id,
                          child: Text(client.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedClientId = value),
                  validator: (value) =>
                      value == null ? 'Wybierz klienta' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedEmployeeId,
                  decoration: const InputDecoration(labelText: 'Doradca *'),
                  items: _employees
                      .map(
                        (employee) => DropdownMenuItem(
                          value: employee.id,
                          child: Text(employee.fullName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedEmployeeId = value),
                  validator: (value) =>
                      value == null ? 'Wybierz doradcę' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ProductType>(
                  value: _selectedProductType,
                  decoration: const InputDecoration(
                    labelText: 'Typ produktu *',
                  ),
                  items: ProductType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProductType = value!;
                      _selectedProductId = null;
                      _filterProducts();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedProductId,
                  decoration: const InputDecoration(labelText: 'Produkt *'),
                  items: _filteredProducts
                      .map(
                        (product) => DropdownMenuItem(
                          value: product.id,
                          child: Text(product.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedProductId = value),
                  validator: (value) =>
                      value == null ? 'Wybierz produkt' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<InvestmentStatus>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: InvestmentStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedStatus = value!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<MarketType>(
                  value: _selectedMarketType,
                  decoration: const InputDecoration(labelText: 'Rynek'),
                  items: MarketType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedMarketType = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _isAllocated,
                onChanged: (value) => setState(() => _isAllocated = value!),
              ),
              const Text('Przydział dokonany'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informacje finansowe',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _investmentAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Kwota inwestycji *',
                    suffixText: 'PLN',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: (value) =>
                      value?.isEmpty == true ? 'Podaj kwotę inwestycji' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _paidAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Kwota wpłacona *',
                    suffixText: 'PLN',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: (value) =>
                      value?.isEmpty == true ? 'Podaj kwotę wpłaconą' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _realizedCapitalController,
                  decoration: const InputDecoration(
                    labelText: 'Kapitał zrealizowany',
                    suffixText: 'PLN',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _realizedInterestController,
                  decoration: const InputDecoration(
                    labelText: 'Odsetki zrealizowane',
                    suffixText: 'PLN',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _remainingCapitalController,
                  decoration: const InputDecoration(
                    labelText: 'Kapitał pozostały',
                    suffixText: 'PLN',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _remainingInterestController,
                  decoration: const InputDecoration(
                    labelText: 'Odsetki pozostałe',
                    suffixText: 'PLN',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _plannedTaxController,
                  decoration: const InputDecoration(
                    labelText: 'Planowany podatek',
                    suffixText: 'PLN',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _realizedTaxController,
                  decoration: const InputDecoration(
                    labelText: 'Zrealizowany podatek',
                    suffixText: 'PLN',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daty', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, _signedDate, (date) {
                    setState(() => _signedDate = date);
                  }),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data podpisania *',
                    ),
                    child: Text(_formatDate(_signedDate)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, _entryDate, (date) {
                    setState(() => _entryDate = date);
                  }),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data wejścia',
                    ),
                    child: Text(
                      _entryDate != null
                          ? _formatDate(_entryDate!)
                          : 'Nie wybrano',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, _exitDate, (date) {
                    setState(() => _exitDate = date);
                  }),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data wyjścia',
                    ),
                    child: Text(
                      _exitDate != null
                          ? _formatDate(_exitDate!)
                          : 'Nie wybrano',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, _redemptionDate, (date) {
                    setState(() => _redemptionDate = date);
                  }),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Data wykupu'),
                    child: Text(
                      _redemptionDate != null
                          ? _formatDate(_redemptionDate!)
                          : 'Nie wybrano',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informacje dodatkowe',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _proposalIdController,
                  decoration: const InputDecoration(labelText: 'ID propozycji'),
                ),
              ),
              const SizedBox(width: 16),
              if (_selectedProductType == ProductType.shares)
                Expanded(
                  child: TextFormField(
                    controller: _sharesCountController,
                    decoration: const InputDecoration(
                      labelText: 'Liczba udziałów',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }
}
