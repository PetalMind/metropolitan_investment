import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/investment.dart';
import '../models/investor_summary.dart';
import '../models/product.dart';
import '../services/investor_analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/investor_details_modal.dart';

class InvestorModalDemoScreen extends StatefulWidget {
  const InvestorModalDemoScreen({super.key});

  @override
  State<InvestorModalDemoScreen> createState() =>
      _InvestorModalDemoScreenState();
}

class _InvestorModalDemoScreenState extends State<InvestorModalDemoScreen> {
  late InvestorSummary _demoInvestor;
  final InvestorAnalyticsService _analyticsService = InvestorAnalyticsService();

  @override
  void initState() {
    super.initState();
    _createDemoInvestor();
  }

  void _createDemoInvestor() {
    // Stwórz demo klienta
    final demoClient = Client(
      id: 'demo-client-12345',
      name: 'Anna Kowalska',
      email: 'anna.kowalska@example.com',
      phone: '+48 123 456 789',
      address: 'ul. Przykładowa 123, 00-001 Warszawa',
      pesel: '85051234567',
      companyName: null,
      type: ClientType.individual,
      notes:
          'Klient o wysokim potencjale inwestycyjnym. Preferuje konserwatywne instrumenty finansowe.',
      votingStatus: VotingStatus.yes,
      colorCode: '#4CAF50',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      isActive: true,
    );

    // Stwórz przykładowe inwestycje
    final demoInvestments = [
      Investment(
        id: 'inv-001',
        clientId: demoClient.id,
        clientName: demoClient.name,
        employeeId: 'emp-001',
        employeeFirstName: 'Jan',
        employeeLastName: 'Nowak',
        branchCode: 'WAW01',
        status: InvestmentStatus.active,
        isAllocated: true,
        marketType: MarketType.primary,
        signedDate: DateTime.now().subtract(const Duration(days: 180)),
        entryDate: DateTime.now().subtract(const Duration(days: 175)),
        proposalId: 'proposal-001',
        productType: ProductType.bonds,
        productName: 'Obligacje Korporacyjne A',
        creditorCompany: 'Metropolitan Investments Sp. z o.o.',
        companyId: 'MI-001',
        issueDate: DateTime.now().subtract(const Duration(days: 200)),
        redemptionDate: DateTime.now().add(const Duration(days: 365)),
        investmentAmount: 50000.0,
        paidAmount: 50000.0,
        realizedCapital: 5000.0,
        realizedInterest: 1200.0,
        remainingCapital: 45000.0,
        remainingInterest: 2800.0,
        currency: 'PLN',
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Investment(
        id: 'inv-002',
        clientId: demoClient.id,
        clientName: demoClient.name,
        employeeId: 'emp-002',
        employeeFirstName: 'Maria',
        employeeLastName: 'Wiśniewska',
        branchCode: 'KRK01',
        status: InvestmentStatus.active,
        isAllocated: true,
        marketType: MarketType.primary,
        signedDate: DateTime.now().subtract(const Duration(days: 90)),
        entryDate: DateTime.now().subtract(const Duration(days: 85)),
        proposalId: 'proposal-002',
        productType: ProductType.shares,
        productName: 'Akcje Spółki XYZ',
        creditorCompany: 'XYZ Spółka Akcyjna',
        companyId: 'XYZ-001',
        issueDate: DateTime.now().subtract(const Duration(days: 100)),
        sharesCount: 100,
        investmentAmount: 25000.0,
        paidAmount: 25000.0,
        realizedCapital: 0.0,
        realizedInterest: 0.0,
        remainingCapital: 28500.0,
        remainingInterest: 0.0,
        currency: 'PLN',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Investment(
        id: 'inv-003',
        clientId: demoClient.id,
        clientName: demoClient.name,
        employeeId: 'emp-001',
        employeeFirstName: 'Jan',
        employeeLastName: 'Nowak',
        branchCode: 'WAW01',
        status: InvestmentStatus.completed,
        isAllocated: false,
        marketType: MarketType.secondary,
        signedDate: DateTime.now().subtract(const Duration(days: 730)),
        entryDate: DateTime.now().subtract(const Duration(days: 725)),
        exitDate: DateTime.now().subtract(const Duration(days: 30)),
        proposalId: 'proposal-003',
        productType: ProductType.loans,
        productName: 'Pożyczka Nieruchomościowa B',
        creditorCompany: 'Metropolitan Loans Sp. z o.o.',
        companyId: 'ML-001',
        investmentAmount: 100000.0,
        paidAmount: 100000.0,
        realizedCapital: 100000.0,
        realizedInterest: 12000.0,
        remainingCapital: 0.0,
        remainingInterest: 0.0,
        currency: 'PLN',
        createdAt: DateTime.now().subtract(const Duration(days: 730)),
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];

    // Stwórz InvestorSummary
    _demoInvestor = InvestorSummary.fromInvestments(
      demoClient,
      demoInvestments,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Demo - Rozszerzone funkcjonalności modalu'),
        backgroundColor: AppTheme.backgroundSecondary,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nagłówek z opisem
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.secondaryGold.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.secondaryGold.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryGold.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.new_releases,
                          color: AppTheme.secondaryGold,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Nowe Funkcjonalności',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Modal detali inwestora został wzbogacony o:',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.note,
                    'System notatek klientów',
                    'Zaawansowane notatki z kategoriami, priorytetami i tagami',
                  ),
                  _buildFeatureItem(
                    Icons.edit,
                    'Edycja inline',
                    'Możliwość edycji danych klienta bezpośrednio z modalu',
                  ),
                  _buildFeatureItem(
                    Icons.account_balance_wallet,
                    'Lista inwestycji',
                    'Podgląd wszystkich inwestycji klienta w modalę',
                  ),
                  _buildFeatureItem(
                    Icons.contact_page,
                    'Zaawansowany kontakt',
                    'Kopiowanie emaila, telefonu i adresu do schowka',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Informacje o demo kliencie
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSecondary, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(
                              '0xFF${_demoInvestor.client.colorCode.replaceAll('#', '')}',
                            ),
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(_demoInvestor.client.name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _demoInvestor.client.name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_demoInvestor.investments.length} inwestycji • ${_formatCurrency(_demoInvestor.totalValue)}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStat('Email', _demoInvestor.client.email),
                      const SizedBox(width: 16),
                      _buildStat('Telefon', _demoInvestor.client.phone),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildStat('Adres', _demoInvestor.client.address),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Przycisk do otworzenia modalu
            Center(
              child: Column(
                children: [
                  const Text(
                    'Kliknij przycisk poniżej, aby zobaczyć rozszerzone funkcjonalności modalu:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showDemoModal,
                    icon: const Icon(Icons.visibility, size: 24),
                    label: const Text('Otwórz Modal z Nowymi Funkcjami'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Instrukcje użytkowania
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSecondary, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: AppTheme.infoColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Jak testować nowe funkcjonalności',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInstruction(
                    '1',
                    'Zakładka "Notatki"',
                    'Dodaj nową notatkę, przetestuj kategorie i priorytety',
                  ),
                  _buildInstruction(
                    '2',
                    'Zakładka "Inwestycje"',
                    'Przejrzyj listę inwestycji klienta z szczegółami',
                  ),
                  _buildInstruction(
                    '3',
                    'Zakładka "Kontakt"',
                    'Kliknij na email, telefon lub adres aby skopiować do schowka',
                  ),
                  _buildInstruction(
                    '4',
                    'Przycisk "Edytuj"',
                    'Otwórz formularz edycji klienta bezpośrednio z modalu',
                  ),
                  _buildInstruction(
                    '5',
                    'Edycja statusu głosowania',
                    'Zmień status głosowania w zakładce "Info" i zapisz zmiany',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.secondaryGold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.infoColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
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
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDemoModal() {
    InvestorDetailsModalHelper.show(
      context: context,
      investor: _demoInvestor,
      analyticsService: _analyticsService,
      onEditInvestor: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Edycja klienta - funkcja demonstracyjna'),
            backgroundColor: AppTheme.infoColor,
          ),
        );
      },
      onViewInvestments: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Przegląd inwestycji - funkcja demonstracyjna'),
            backgroundColor: AppTheme.infoColor,
          ),
        );
      },
      onUpdateInvestor: (updatedInvestor) {
        setState(() {
          _demoInvestor = updatedInvestor;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dane klienta zostały zaktualizowane'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return '?';
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2).replaceAll('.', ',')} zł';
  }
}
