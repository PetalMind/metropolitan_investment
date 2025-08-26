import 'package:flutter/material.dart';
import '../../widgets/investments/responsive_investments_table.dart';
import '../../widgets/responsive_investments_table_widget.dart';
import '../../models/investment.dart';
import '../../theme/app_theme_professional.dart';

/// Demo screen showcasing the ResponsiveInvestmentsTable widget
class InvestmentsTableDemoScreen extends StatefulWidget {
  const InvestmentsTableDemoScreen({super.key});

  @override
  State<InvestmentsTableDemoScreen> createState() => _InvestmentsTableDemoScreenState();
}

class _InvestmentsTableDemoScreenState extends State<InvestmentsTableDemoScreen> {
  List<Investment> _mockInvestments = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  void _loadMockData() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate loading delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
        _mockInvestments = _generateMockInvestments();
      });
    });
  }

  List<Investment> _generateMockInvestments() {
    return [
      Investment(
        id: '1',
        clientId: 'client_1',
        clientName: 'Jan Kowalski',
        employeeId: 'emp_1',
        employeeFirstName: 'Anna',
        employeeLastName: 'Nowak',
        branchCode: 'WAR01',
        productName: 'Pożyczka Metropolitan Alpha',
        productType: InvestmentType.bonds,
        status: InvestmentStatus.active,
        creditorCompany: 'Metropolitan Investment Sp. z o.o.',
        companyId: 'MI001',
        investmentAmount: 150000.0,
        remainingCapital: 125000.0,
        capitalSecuredByRealEstate: 100000.0,
        capitalForRestructuring: 25000.0,
        paidAmount: 150000.0,
        realizedCapital: 25000.0,
        realizedInterest: 5000.0,
        transferToOtherProduct: 0.0,
        remainingInterest: 8000.0,
        plannedTax: 1000.0,
        realizedTax: 500.0,
        currency: 'PLN',
        exchangeRate: 1.0,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now(),
        votingStatus: VotingStatus.support,
        additionalInfo: {},
      ),
      Investment(
        id: '2',
        clientId: 'client_2',
        clientName: 'Maria Wiśniewska',
        employeeId: 'emp_2',
        employeeFirstName: 'Piotr',
        employeeLastName: 'Zieliński',
        branchCode: 'KRA01',
        productName: 'Obligacje Metropolitan Beta',
        productType: InvestmentType.bonds,
        status: InvestmentStatus.active,
        creditorCompany: 'Metropolitan Capital S.A.',
        companyId: 'MC001',
        investmentAmount: 250000.0,
        remainingCapital: 230000.0,
        capitalSecuredByRealEstate: 180000.0,
        capitalForRestructuring: 50000.0,
        paidAmount: 250000.0,
        realizedCapital: 20000.0,
        realizedInterest: 12000.0,
        transferToOtherProduct: 0.0,
        remainingInterest: 15000.0,
        plannedTax: 2000.0,
        realizedTax: 1200.0,
        currency: 'PLN',
        exchangeRate: 1.0,
        createdAt: DateTime.now().subtract(const Duration(days: 300)),
        updatedAt: DateTime.now(),
        votingStatus: VotingStatus.support,
        additionalInfo: {},
      ),
      Investment(
        id: '3',
        clientId: 'client_3',
        clientName: 'Andrzej Nowak',
        employeeId: 'emp_3',
        employeeFirstName: 'Katarzyna',
        employeeLastName: 'Krawczyk',
        branchCode: 'GDA01',
        productName: 'Udziały Metropolitan Gamma',
        productType: InvestmentType.shares,
        status: InvestmentStatus.active,
        creditorCompany: 'Metropolitan Holdings Sp. z o.o.',
        companyId: 'MH001',
        investmentAmount: 75000.0,
        remainingCapital: 70000.0,
        capitalSecuredByRealEstate: 60000.0,
        capitalForRestructuring: 10000.0,
        paidAmount: 75000.0,
        realizedCapital: 5000.0,
        realizedInterest: 2500.0,
        transferToOtherProduct: 0.0,
        remainingInterest: 4000.0,
        plannedTax: 500.0,
        realizedTax: 250.0,
        currency: 'PLN',
        exchangeRate: 1.0,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        updatedAt: DateTime.now(),
        votingStatus: VotingStatus.abstain,
        additionalInfo: {},
      ),
      Investment(
        id: '4',
        clientId: 'client_4',
        clientName: 'Barbara Kozłowska',
        employeeId: 'emp_1',
        employeeFirstName: 'Anna',
        employeeLastName: 'Nowak',
        branchCode: 'WRO01',
        productName: 'Pożyczka Metropolitan Delta',
        productType: InvestmentType.loans,
        status: InvestmentStatus.active,
        creditorCompany: 'Metropolitan Loan Services Sp. z o.o.',
        companyId: 'MLS001',
        investmentAmount: 300000.0,
        remainingCapital: 280000.0,
        capitalSecuredByRealEstate: 250000.0,
        capitalForRestructuring: 30000.0,
        paidAmount: 300000.0,
        realizedCapital: 20000.0,
        realizedInterest: 18000.0,
        transferToOtherProduct: 0.0,
        remainingInterest: 20000.0,
        plannedTax: 3000.0,
        realizedTax: 1800.0,
        currency: 'PLN',
        exchangeRate: 1.0,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now(),
        votingStatus: VotingStatus.support,
        additionalInfo: {},
      ),
      Investment(
        id: '5',
        clientId: 'client_5',
        clientName: 'Tomasz Wójcik',
        employeeId: 'emp_4',
        employeeFirstName: 'Michał',
        employeeLastName: 'Lewandowski',
        branchCode: 'POZ01',
        productName: 'Certyfikaty Metropolitan Epsilon',
        productType: InvestmentType.bonds,
        status: InvestmentStatus.terminated,
        creditorCompany: 'Metropolitan Certificates S.A.',
        companyId: 'MCE001',
        investmentAmount: 500000.0,
        remainingCapital: 450000.0,
        capitalSecuredByRealEstate: 400000.0,
        capitalForRestructuring: 50000.0,
        paidAmount: 500000.0,
        realizedCapital: 50000.0,
        realizedInterest: 25000.0,
        transferToOtherProduct: 0.0,
        remainingInterest: 30000.0,
        plannedTax: 5000.0,
        realizedTax: 2500.0,
        currency: 'PLN',
        exchangeRate: 1.0,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now(),
        votingStatus: VotingStatus.opposition,
        additionalInfo: {},
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePro.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Tabela Inwestycji - Demo'),
        backgroundColor: AppThemePro.backgroundSecondary,
        foregroundColor: AppThemePro.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMockData,
            tooltip: 'Odśwież dane',
          ),
          IconButton(
            icon: const Icon(Icons.error),
            onPressed: _simulateError,
            tooltip: 'Symuluj błąd',
          ),
        ],
      ),
      body: Column(
        children: [
          // Demo info header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemePro.statusInfo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppThemePro.statusInfo.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppThemePro.statusInfo,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Responsive Investments Table Demo',
                      style: TextStyle(
                        color: AppThemePro.statusInfo,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ta tabela automatycznie dostosowuje się do rozmiaru ekranu:\n'
                  '• Desktop: Pełna tabela ze wszystkimi kolumnami\n'
                  '• Tablet: Kompaktowa tabela z skróconymi nazwami\n'
                  '• Mobile: Karty z metrykami w siatce',
                  style: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // The responsive table
          Expanded(
            child: ResponsiveInvestmentsTable(
              investments: _mockInvestments,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
              onInvestmentTap: _onInvestmentTap,
              onInvestmentEdit: _onInvestmentEdit,
              onInvestmentDelete: _onInvestmentDelete,
              showActions: true,
            ),
          ),
        ],
      ),
    );
  }

  void _simulateError() {
    setState(() {
      _errorMessage = 'Błąd połączenia z serwerem';
      _mockInvestments.clear();
    });
  }

  void _onInvestmentTap(Investment investment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Wybrano inwestycję: ${investment.productName}'),
        backgroundColor: AppThemePro.statusInfo,
      ),
    );
  }

  void _onInvestmentEdit(Investment investment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edytuj inwestycję: ${investment.productName}'),
        backgroundColor: AppThemePro.statusWarning,
      ),
    );
  }

  void _onInvestmentDelete(Investment investment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń inwestycję'),
        content: Text('Czy na pewno chcesz usunąć inwestycję "${investment.productName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _mockInvestments.removeWhere((inv) => inv.id == investment.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Usunięto inwestycję: ${investment.productName}'),
                  backgroundColor: AppThemePro.statusSuccess,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemePro.statusError,
            ),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }
}