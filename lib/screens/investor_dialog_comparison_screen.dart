import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models_and_services.dart';
import '../theme/app_theme_professional.dart';
import '../widgets/investor_analytics/dialogs/investor_details_dialog.dart';
import '../widgets/investor_analytics/dialogs/enhanced_investor_details_dialog.dart';

/// 🎯 DEMO SCREEN - PORÓWNANIE DIALOGÓW INWESTORA
/// 
/// Ekran demonstracyjny pokazujący różnice między:
/// 1. Starym dialogiem (InvestorDetailsDialog)
/// 2. Nowym, ulepszonym dialogiem (EnhancedInvestorDetailsDialog)
/// 
/// Funkcje demo:
/// - Porównanie UI/UX obu dialogów
/// - Przykładowe dane inwestora do testów
/// - Przełączanie między dialogami
/// - Podgląd najważniejszych funkcji
class InvestorDialogComparisonScreen extends StatefulWidget {
  const InvestorDialogComparisonScreen({super.key});

  @override
  State<InvestorDialogComparisonScreen> createState() =>
      _InvestorDialogComparisonScreenState();
}

class _InvestorDialogComparisonScreenState
    extends State<InvestorDialogComparisonScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  // Sample investor data for demo
  late InvestorSummary _demoInvestor;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _createDemoInvestor();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimationController.forward();
  }

  void _createDemoInvestor() {
    // Create sample client
    final demoClient = Client(
      id: 'demo-client-001',
      excelId: 'EXCEL-001',
      name: 'Kowalski Development Sp. z o.o.',
      email: 'kontakt@kowalski-dev.com',
      phone: '+48 123 456 789',
      address: 'ul. Warszawska 12, 00-001 Warszawa',
      companyName: 'Kowalski Development Sp. z o.o.',
      type: ClientType.company,
      votingStatus: VotingStatus.yes,
      notes: 'Długoletni partner biznesowy. Wysoka jakość współpracy. Preferuje inwestycje w sektorze nieruchomości komercyjnych. Szczególne zainteresowanie projektami biurowymi w większych miastach.',
      colorCode: '#4CAF50',
      isActive: true,
      unviableInvestments: ['demo-investment-003'],
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    );

    // Create sample investments
    final demoInvestments = [
      Investment(
        id: 'demo-investment-001',
        clientId: 'demo-client-001',
        productId: 'bond-product-001',
        productName: 'Obligacje Metropolitalne 2024',
        productType: ProductType.bonds,
        creditorCompany: 'Metropolitan Investment',
        clientName: 'Kowalski Development Sp. z o.o.',
        employeeId: 'emp-001',
        employeeFirstName: 'Jan',
        employeeLastName: 'Nowak',
        signedDate: DateTime.now().subtract(const Duration(days: 320)),
        proposalId: 'proposal-001',
        companyId: 'company-001',
        investmentAmount: 500000.0,
        paidAmount: 500000.0,
        remainingCapital: 420000.0,
        realizedCapital: 80000.0,
        realizedInterest: 45000.0,
        remainingInterest: 35000.0,
        transferToOtherProduct: 0.0,
        capitalForRestructuring: 0.0,
        capitalSecuredByRealEstate: 420000.0,
        plannedTax: 8000.0,
        realizedTax: 3500.0,
        status: InvestmentStatus.active,
        marketType: MarketType.primary,
        branchCode: 'WAR-001',
        createdAt: DateTime.now().subtract(const Duration(days: 300)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Investment(
        id: 'demo-investment-002',
        clientId: 'demo-client-001',
        productId: 'share-product-002',
        productName: 'Udziały w Funduszu Nieruchomości',
        productType: ProductType.shares,
        creditorCompany: 'Metropolitan Investment',
        clientName: 'Kowalski Development Sp. z o.o.',
        employeeId: 'emp-002',
        employeeFirstName: 'Anna',
        employeeLastName: 'Kowalska',
        signedDate: DateTime.now().subtract(const Duration(days: 170)),
        proposalId: 'proposal-002',
        companyId: 'company-001',
        investmentAmount: 750000.0,
        paidAmount: 750000.0,
        remainingCapital: 680000.0,
        realizedCapital: 70000.0,
        realizedInterest: 0.0,
        remainingInterest: 0.0,
        transferToOtherProduct: 0.0,
        capitalForRestructuring: 25000.0,
        capitalSecuredByRealEstate: 655000.0,
        plannedTax: 0.0,
        realizedTax: 0.0,
        status: InvestmentStatus.active,
        marketType: MarketType.secondary,
        branchCode: 'WAR-001',
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Investment(
        id: 'demo-investment-003',
        clientId: 'demo-client-001',
        productId: 'loan-product-003',
        productName: 'Pożyczka Hipoteczna Premium',
        productType: ProductType.loans,
        creditorCompany: 'Metropolitan Investment',
        clientName: 'Kowalski Development Sp. z o.o.',
        employeeId: 'emp-003',
        employeeFirstName: 'Piotr',
        employeeLastName: 'Zieliński',
        signedDate: DateTime.now().subtract(const Duration(days: 85)),
        proposalId: 'proposal-003',
        companyId: 'company-002',
        investmentAmount: 300000.0,
        paidAmount: 300000.0,
        remainingCapital: 285000.0,
        realizedCapital: 15000.0,
        realizedInterest: 22000.0,
        remainingInterest: 45000.0,
        transferToOtherProduct: 50000.0,
        capitalForRestructuring: 100000.0,
        capitalSecuredByRealEstate: 185000.0,
        plannedTax: 5000.0,
        realizedTax: 1200.0,
        status: InvestmentStatus.inactive,
        marketType: MarketType.primary,
        branchCode: 'KRK-002',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Investment(
        id: 'demo-investment-004',
        clientId: 'demo-client-001',
        productId: 'apartment-product-004',
        productName: 'Apartamenty Marina Plaza',
        productType: ProductType.apartments,
        creditorCompany: 'Metropolitan Investment',
        clientName: 'Kowalski Development Sp. z o.o.',
        employeeId: 'emp-004',
        employeeFirstName: 'Maria',
        employeeLastName: 'Wiśniewska',
        signedDate: DateTime.now().subtract(const Duration(days: 40)),
        proposalId: 'proposal-004',
        companyId: 'company-003',
        investmentAmount: 1200000.0,
        paidAmount: 1200000.0,
        remainingCapital: 1150000.0,
        realizedCapital: 50000.0,
        realizedInterest: 0.0,
        remainingInterest: 0.0,
        transferToOtherProduct: 0.0,
        capitalForRestructuring: 0.0,
        capitalSecuredByRealEstate: 1150000.0,
        plannedTax: 0.0,
        realizedTax: 0.0,
        status: InvestmentStatus.active,
        marketType: MarketType.primary,
        branchCode: 'GDA-003',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];

    // Create investor summary
    _demoInvestor = InvestorSummary(
      client: demoClient,
      investments: demoInvestments,
      totalInvestmentAmount: 2750000.0,
      totalRemainingCapital: 2535000.0,
      totalRealizedCapital: 215000.0,
      totalSharesValue: 680000.0,
      totalValue: 2750000.0,
      capitalSecuredByRealEstate: 2410000.0,
      capitalForRestructuring: 125000.0,
      investmentCount: 4,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePro.backgroundPrimary,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppThemePro.backgroundPrimary,
      elevation: 0,
      title: Text(
        'Dialog Inwestora - Porównanie',
        style: TextStyle(
          color: AppThemePro.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppThemePro.textSecondary),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildComparisonSection(),
          const SizedBox(height: 32),
          _buildDemoDataSection(),
          const SizedBox(height: 32),
          _buildDialogButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.accentGold.withOpacity(0.1),
            AppThemePro.bondsBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.accentGold.withOpacity(0.2),
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
                  color: AppThemePro.accentGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.compare,
                  color: AppThemePro.accentGold,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Porównanie Dialogów Inwestora',
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Demonstracja starszej vs nowej wersji z zaawansowanymi funkcjami',
                      style: TextStyle(
                        color: AppThemePro.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFeatureComparisonGrid(),
        ],
      ),
    );
  }

  Widget _buildFeatureComparisonGrid() {
    final features = [
      _FeatureComparison(
        'Responsywny design',
        hasOld: false,
        hasNew: true,
        description: 'Automatyczne dostosowanie do rozmiaru ekranu',
      ),
      _FeatureComparison(
        'Tab navigation',
        hasOld: false,
        hasNew: true,
        description: '5 zakładek z różnymi funkcjami',
      ),
      _FeatureComparison(
        'Historia inwestycji',
        hasOld: false,
        hasNew: true,
        description: 'Pełna historia zmian z filtrowaniem',
      ),
      _FeatureComparison(
        'Historia głosowania',
        hasOld: false,
        hasNew: true,
        description: 'Timeline wszystkich zmian statusu',
      ),
      _FeatureComparison(
        'Smooth animations',
        hasOld: false,
        hasNew: true,
        description: 'Płynne przejścia i microinteractions',
      ),
      _FeatureComparison(
        'Zaawansowane filtry',
        hasOld: false,
        hasNew: true,
        description: 'Wyszukiwanie i filtrowanie inwestycji',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 8,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppThemePro.surfaceCard.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppThemePro.borderSecondary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      feature.name,
                      style: TextStyle(
                        color: AppThemePro.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (feature.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        feature.description,
                        style: TextStyle(
                          color: AppThemePro.textMuted,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Icon(
                    feature.hasOld ? Icons.check : Icons.close,
                    color: feature.hasOld ? AppThemePro.profitGreen : AppThemePro.lossRed,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    feature.hasNew ? Icons.check : Icons.close,
                    color: feature.hasNew ? AppThemePro.profitGreen : AppThemePro.lossRed,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComparisonSection() {
    return Row(
      children: [
        Expanded(child: _buildDialogInfo(isOld: true)),
        const SizedBox(width: 24),
        Expanded(child: _buildDialogInfo(isOld: false)),
      ],
    );
  }

  Widget _buildDialogInfo({required bool isOld}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isOld
              ? [
                  AppThemePro.neutralGray.withOpacity(0.1),
                  AppThemePro.surfaceCard.withOpacity(0.5),
                ]
              : [
                  AppThemePro.accentGold.withOpacity(0.1),
                  AppThemePro.profitGreen.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOld
              ? AppThemePro.neutralGray.withOpacity(0.3)
              : AppThemePro.accentGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isOld
                      ? AppThemePro.neutralGray.withOpacity(0.2)
                      : AppThemePro.accentGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isOld ? Icons.history : Icons.auto_awesome,
                  color: isOld ? AppThemePro.neutralGray : AppThemePro.accentGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isOld ? 'Obecny Dialog' : 'Nowy Enhanced Dialog',
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(!isOld
              ? [
                  _buildFeatureItem(
                    'Tab-based navigation',
                    'Przegląd, Inwestycje, Historia, Głosowania, Ustawienia',
                  ),
                  _buildFeatureItem(
                    'Responsywny design',
                    'Automatyczne dostosowanie do mobile/tablet/desktop',
                  ),
                  _buildFeatureItem(
                    'Historia zmian',
                    'Pełna historia z InvestmentChangeHistoryService',
                  ),
                  _buildFeatureItem(
                    'Historia głosowania',
                    'Timeline z VotingStatusChangeService',
                  ),
                  _buildFeatureItem(
                    'Zaawansowane filtry',
                    'Wyszukiwanie, filtrowanie po typie, statusie',
                  ),
                  _buildFeatureItem(
                    'Professional animations',
                    'Smooth transitions i microinteractions',
                  ),
                ]
              : [
                  _buildFeatureItem(
                    'Podstawowa edycja',
                    'Status głosowania, notatki, kolor',
                  ),
                  _buildFeatureItem(
                    'Lista inwestycji',
                    'Prosta lista z deduplikacją',
                  ),
                  _buildFeatureItem(
                    'Statystyki',
                    'Podstawowe podsumowanie finansowe',
                  ),
                ]),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppThemePro.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(
              color: AppThemePro.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoDataSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.data_usage,
                color: AppThemePro.accentGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Dane demonstracyjne',
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDemoInvestorInfo(),
        ],
      ),
    );
  }

  Widget _buildDemoInvestorInfo() {
    return Column(
      children: [
        _buildDemoInfoRow('Klient', _demoInvestor.client.name),
        _buildDemoInfoRow('Email', _demoInvestor.client.email),
        _buildDemoInfoRow('Typ', _demoInvestor.client.type.displayName),
        _buildDemoInfoRow('Status głosowania', _demoInvestor.client.votingStatus.displayName),
        _buildDemoInfoRow('Liczba inwestycji', '${_demoInvestor.investmentCount}'),
        _buildDemoInfoRow('Łączna wartość', '${(_demoInvestor.totalValue / 1000000).toStringAsFixed(1)}M PLN'),
        _buildDemoInfoRow('Kapitał pozostały', '${(_demoInvestor.totalRemainingCapital / 1000000).toStringAsFixed(1)}M PLN'),
        const SizedBox(height: 12),
        Text(
          'Inwestycje obejmują: Obligacje Metropolitalne, Udziały w Funduszu Nieruchomości, Pożyczkę Hipoteczną (oznaczoną jako nieopłacalną), oraz Apartamenty Marina Plaza.',
          style: TextStyle(
            color: AppThemePro.textMuted,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildDemoInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: AppThemePro.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppThemePro.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildDialogButton(
            title: 'Obecny Dialog',
            subtitle: 'InvestorDetailsDialog',
            icon: Icons.article_outlined,
            color: AppThemePro.neutralGray,
            onPressed: () => _showOldDialog(),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildDialogButton(
            title: 'Nowy Enhanced Dialog',
            subtitle: 'EnhancedInvestorDetailsDialog',
            icon: Icons.auto_awesome,
            color: AppThemePro.accentGold,
            onPressed: () => _showNewDialog(),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppThemePro.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Otwórz dialog',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOldDialog() {
    showDialog(
      context: context,
      builder: (context) => InvestorDetailsDialog(
        investor: _demoInvestor,
        onUpdate: () {
          // Handle update callback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Aktualizacja z obecnego dialoga'),
              backgroundColor: AppThemePro.neutralGray,
            ),
          );
        },
        onInvestorUpdated: (updatedInvestor) {
          // Handle investor update callback
          setState(() {
            _demoInvestor = updatedInvestor;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Inwestor zaktualizowany (obecny dialog)'),
              backgroundColor: AppThemePro.profitGreen,
            ),
          );
        },
      ),
    );
  }

  void _showNewDialog() {
    showDialog(
      context: context,
      builder: (context) => EnhancedInvestorDetailsDialog(
        investor: _demoInvestor,
        onUpdate: () {
          // Handle update callback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Aktualizacja z nowego dialoga'),
              backgroundColor: AppThemePro.accentGold,
            ),
          );
        },
        onInvestorUpdated: (updatedInvestor) {
          // Handle investor update callback
          setState(() {
            _demoInvestor = updatedInvestor;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Inwestor zaktualizowany (nowy dialog)'),
              backgroundColor: AppThemePro.profitGreen,
            ),
          );
        },
      ),
    );
  }
}

// === HELPER CLASSES ===

class _FeatureComparison {
  final String name;
  final bool hasOld;
  final bool hasNew;
  final String description;

  const _FeatureComparison(
    this.name, {
    required this.hasOld,
    required this.hasNew,
    this.description = '',
  });
}