import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme_professional.dart';
import '../../models_and_services.dart';
import '../premium_loading_widget.dart';
import '../premium_error_widget.dart';

/// 🚀 METROPOLITAN PRODUCT DASHBOARD
/// Nowoczesny, funkcjonalny dashboard produktów inwestycyjnych
///
/// Funkcje:
/// - Powitanie zalogowanego użytkownika z logo
/// - Górny panel - szybkie podsumowanie (5 kafli)
/// - Sekcja szczegółów produktu
/// - Terminy i oś czasu z kolorowymi ostrzeżeniami
/// - Sekcja ryzyk i statusów finansowych
/// - Płynne animacje i mikrointerakcje
class ProductDashboardWidget extends StatefulWidget {
  final String? selectedProductId;
  final Function(String productId)? onProductSelected;

  const ProductDashboardWidget({
    super.key,
    this.selectedProductId,
    this.onProductSelected,
  });

  @override
  State<ProductDashboardWidget> createState() => _ProductDashboardWidgetState();
}

class _ProductDashboardWidgetState extends State<ProductDashboardWidget>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Services
  final AuthService _authService = AuthService();
  final DeduplicatedProductService _deduplicatedProductService = DeduplicatedProductService();

  // State
  bool _isLoading = true;
  String? _error;
  UserProfile? _userProfile;
  List<Investment> _investments = [];
  List<DeduplicatedProduct> _deduplicatedProducts = [];
  Investment? _selectedInvestment;
  Set<String> _selectedProductIds = {};
  bool _showDeduplicatedView = true; // Domyślnie pokazuj deduplikowane produkty

  // Date formatter
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pl_PL',
    symbol: 'zł',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load user profile
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _userProfile = await _authService.getUserProfile(currentUser.uid);
      }

      // Load investments data and deduplicated products in parallel
      final results = await Future.wait([
        FirebaseFunctionsDataService.getAllInvestments(
          page: 1,
          pageSize: 5000, // Pobierz wszystkie dostępne inwestycje
          forceRefresh: true,
        ),
        _deduplicatedProductService.getAllUniqueProducts(),
      ]);

      final investmentsResult = results[0] as InvestmentsResult;
      final deduplicatedProducts = results[1] as List<DeduplicatedProduct>;

      _investments = investmentsResult.investments;
      _deduplicatedProducts = deduplicatedProducts;

      // Select first investment if none selected
      if (widget.selectedProductId != null) {
        _selectedInvestment = _investments
            .where((inv) => inv.id == widget.selectedProductId)
            .firstOrNull;
      }
      _selectedInvestment ??= _investments.isNotEmpty
          ? _investments.first
          : null;

      setState(() {
        _isLoading = false;
      });

      // Start animations
      _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _slideController.forward();
      await Future.delayed(const Duration(milliseconds: 100));
      _scaleController.forward();
    } catch (e) {
      setState(() {
        _error = 'Błąd podczas ładowania danych: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const PremiumLoadingWidget(
        message: 'Ładowanie danych produktów...',
      );
    }

    if (_error != null) {
      return PremiumErrorWidget(error: _error!, onRetry: _loadData);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppThemePro.backgroundPrimary,
            AppThemePro.backgroundSecondary.withOpacity(0.5),
          ],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with welcome message and logo
            _buildHeader(),
            const SizedBox(height: 20),

            // Deduplication toggle
            _buildDeduplicationToggle(),
            const SizedBox(height: 32),

            // Quick summary tiles - CAŁA BAZA DANYCH
            _buildGlobalSummary(),
            const SizedBox(height: 32),

            // Product selector
            _buildProductSelector(),
            const SizedBox(height: 32),

            // Selected products summary - WYBRANE PRODUKTY
            _buildSelectedProductsSummary(),
            const SizedBox(height: 32),

            // Product details section - SZCZEGÓŁY WYBRANYCH PRODUKTÓW
            _buildSelectedProductsDetails(),
            const SizedBox(height: 32),

            // Timeline section
            _buildTimelineSection(),
            const SizedBox(height: 32),

            // Financial risks section
            _buildFinancialRisksSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppThemePro.premiumCardDecoration,
          child: Row(
            children: [
              // Logo with animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        AppThemePro.accentGold,
                        AppThemePro.accentGoldMuted,
                      ],
                    ),
                  ),
                  child: _buildCustomLogo(60),
                ),
              ),
              const SizedBox(width: 24),

              // Welcome message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Witaj, ',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: AppThemePro.textSecondary),
                        ),
                        Text(
                          _userProfile?.firstName ?? 'Użytkowniku',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppThemePro.accentGold,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _dateFormat.format(DateTime.now()),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppThemePro.textTertiary,
                      ),
                    ),
                    if (_investments.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Zarządzasz ${_investments.length} ${_investments.length == 1
                            ? 'produktem'
                            : _investments.length < 5
                            ? 'produktami'
                            : 'produktami'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppThemePro.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Current time
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppThemePro.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppThemePro.borderSecondary),
                ),
                child: StreamBuilder<DateTime>(
                  stream: Stream.periodic(
                    const Duration(seconds: 1),
                    (_) => DateTime.now(),
                  ),
                  builder: (context, snapshot) {
                    final now = snapshot.data ?? DateTime.now();
                    return Column(
                      children: [
                        Text(
                          DateFormat('HH:mm:ss').format(now),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppThemePro.accentGold,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          DateFormat('dd MMM').format(now),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppThemePro.textTertiary),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeduplicationToggle() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppThemePro.premiumCardDecoration,
        child: Row(
          children: [
            Icon(
              _showDeduplicatedView ? Icons.filter_vintage : Icons.all_inclusive,
              color: AppThemePro.accentGold,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _showDeduplicatedView ? 'Widok: Produkty unikalne' : 'Widok: Wszystkie inwestycje',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppThemePro.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _showDeduplicatedView 
                      ? 'Wyświetlane są deduplikowane produkty (${_deduplicatedProducts.length} unikalnych)'
                      : 'Wyświetlane są wszystkie inwestycje (${_investments.length} pozycji)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: _showDeduplicatedView,
              onChanged: (value) {
                setState(() {
                  _showDeduplicatedView = value;
                  // Wyczyść wybrane produkty przy przełączaniu trybu
                  _selectedProductIds.clear();
                });
              },
              activeColor: AppThemePro.accentGold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalSummary() {
    if (_investments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: AppThemePro.premiumCardDecoration,
        child: Center(
          child: Text(
            'Brak danych w bazie',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppThemePro.textMuted),
          ),
        ),
      );
    }

    // Oblicz statystyki globalnej bazy danych
    double totalInvestmentAmount = 0;
    double totalRemainingCapital = 0;
    double totalCapitalSecured = 0;
    double totalCapitalForRestructuring = 0;

    for (final investment in _investments) {
      totalInvestmentAmount += investment.investmentAmount;
      totalRemainingCapital += investment.remainingCapital;
      totalCapitalSecured += _getCapitalSecuredByRealEstate(investment);
      totalCapitalForRestructuring += _getCapitalForRestructuring(investment);
    }

    final tiles = [
      _SummaryTileData(
        title: 'Łączna kwota inwestycji',
        value: _currencyFormat.format(totalInvestmentAmount),
        icon: Icons.account_balance_wallet,
        color: AppThemePro.accentGold,
        trend: null,
      ),
      _SummaryTileData(
        title: 'Łączny pozostały kapitał',
        value: _currencyFormat.format(totalRemainingCapital),
        icon: Icons.trending_up,
        color: AppThemePro.profitGreen,
        trend: totalRemainingCapital > 0 ? 'positive' : 'negative',
      ),
      _SummaryTileData(
        title: 'Łączny kapitał zabezpieczony',
        value: _currencyFormat.format(totalCapitalSecured),
        icon: Icons.security,
        color: AppThemePro.bondsBlue,
        trend: null,
      ),
      _SummaryTileData(
        title: 'Łączny kapitał w restrukturyzacji',
        value: _currencyFormat.format(totalCapitalForRestructuring),
        icon: Icons.refresh,
        color: AppThemePro.loansOrange,
        trend: totalCapitalForRestructuring > 0 ? 'warning' : null,
      ),
      _SummaryTileData(
        title: 'Liczba produktów (unikalne)',
        value: '${_deduplicatedProducts.length}',
        icon: Icons.inventory,
        color: AppThemePro.neutralGray,
        trend: null,
      ),
    ];

    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Podsumowanie całej bazy danych',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppThemePro.accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppThemePro.accentGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'GLOBALNE • ${_deduplicatedProducts.length} UNIKALNYCH',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppThemePro.accentGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 1200;
              final crossAxisCount = isWide
                  ? 5
                  : (constraints.maxWidth > 800 ? 3 : 2);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: tiles.length,
                itemBuilder: (context, index) =>
                    _buildSummaryTile(tiles[index], index),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelector() {
    // Wybierz odpowiedną listę na podstawie trybu wyświetlania
    final displayList = _showDeduplicatedView ? _deduplicatedProducts : _investments;
    final totalCount = displayList.length;
    
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wybierz produkty do analizy',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppThemePro.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _showDeduplicatedView 
                      ? 'Widok: Produkty unikalne ($totalCount pozycji)'
                      : 'Widok: Wszystkie inwestycje ($totalCount pozycji)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_showDeduplicatedView) {
                          _selectedProductIds = _deduplicatedProducts.map((prod) => prod.id).toSet();
                        } else {
                          _selectedProductIds = _investments.map((inv) => inv.id).toSet();
                        }
                      });
                    },
                    icon: Icon(Icons.select_all, size: 18),
                    label: Text('Zaznacz wszystkie'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppThemePro.accentGold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedProductIds.clear();
                      });
                    },
                    icon: Icon(Icons.clear, size: 18),
                    label: Text('Wyczyść'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppThemePro.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: AppThemePro.premiumCardDecoration,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppThemePro.accentGold.withOpacity(0.05),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppThemePro.accentGold,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Wybrane produkty: ${_selectedProductIds.length}/$totalCount',
                        style: TextStyle(
                          color: AppThemePro.accentGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 400), // Zwiększ wysokość
                  child: _showDeduplicatedView 
                    ? _buildDeduplicatedProductsList()
                    : _buildInvestmentsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeduplicatedProductsList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _deduplicatedProducts.length,
      itemBuilder: (context, index) {
        final product = _deduplicatedProducts[index];
        final isSelected = _selectedProductIds.contains(product.id);
        
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppThemePro.borderPrimary,
                width: 0.5,
              ),
            ),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedProductIds.add(product.id);
                } else {
                  _selectedProductIds.remove(product.id);
                }
              });
            },
            title: Text(
              product.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${product.companyName} • ${product.productType.displayName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.textSecondary,
                  ),
                ),
                Text(
                  '${product.totalInvestments} inwestycji • ${_currencyFormat.format(product.totalRemainingCapital)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.accentGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getUnifiedProductTypeColor(product.productType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getProductTypeIcon(product.productType),
                color: _getUnifiedProductTypeColor(product.productType),
                size: 20,
              ),
            ),
            activeColor: AppThemePro.accentGold,
            checkColor: AppThemePro.backgroundPrimary,
          ),
        );
      },
    );
  }

  Widget _buildInvestmentsList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _investments.length,
      itemBuilder: (context, index) {
        final investment = _investments[index];
        final isSelected = _selectedProductIds.contains(investment.id);
        
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppThemePro.borderPrimary,
                width: 0.5,
              ),
            ),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedProductIds.add(investment.id);
                } else {
                  _selectedProductIds.remove(investment.id);
                }
              });
            },
            title: Text(
              investment.productName.isNotEmpty 
                  ? investment.productName 
                  : 'Produkt ${investment.id.substring(0, 8)}...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${investment.clientName} • ${investment.productType.displayName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.textSecondary,
                  ),
                ),
                Text(
                  _currencyFormat.format(investment.remainingCapital),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.accentGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getStatusColor(investment.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getStatusIcon(investment.status),
                color: _getStatusColor(investment.status),
                size: 20,
              ),
            ),
            activeColor: AppThemePro.accentGold,
            checkColor: AppThemePro.backgroundPrimary,
          ),
        );
      },
    );
  }

  Widget _buildSelectedProductsSummary() {
    // Wybierz odpowiednią listę i oblicz wybrane produkty
    List<dynamic> selectedItems;
    if (_showDeduplicatedView) {
      selectedItems = _deduplicatedProducts
          .where((prod) => _selectedProductIds.contains(prod.id))
          .toList();
    } else {
      selectedItems = _investments
          .where((inv) => _selectedProductIds.contains(inv.id))
          .toList();
    }

    if (selectedItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: AppThemePro.premiumCardDecoration,
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.check_box_outline_blank,
                color: AppThemePro.textMuted,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Nie wybrano żadnych produktów',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppThemePro.textMuted),
              ),
              const SizedBox(height: 8),
              Text(
                'Zaznacz produkty powyżej aby zobaczyć szczegóły',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppThemePro.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    // Oblicz statystyki wybranych produktów
    double totalInvestmentAmount = 0;
    double totalRemainingCapital = 0;
    double totalCapitalSecured = 0;
    double totalCapitalForRestructuring = 0;
    int activeItems = 0;

    if (_showDeduplicatedView) {
      // Oblicz dla deduplikowanych produktów
      for (final product in selectedItems.cast<DeduplicatedProduct>()) {
        totalInvestmentAmount += product.totalValue;
        totalRemainingCapital += product.totalRemainingCapital;
        totalCapitalSecured += 0; // DeduplicatedProduct nie ma tej właściwości
        totalCapitalForRestructuring += 0; // DeduplicatedProduct nie ma tej właściwości
        
        if (product.status == ProductStatus.active) {
          activeItems++;
        }
      }
    } else {
      // Oblicz dla inwestycji
      for (final investment in selectedItems.cast<Investment>()) {
        totalInvestmentAmount += investment.investmentAmount;
        totalRemainingCapital += investment.remainingCapital;
        totalCapitalSecured += _getCapitalSecuredByRealEstate(investment);
        totalCapitalForRestructuring += _getCapitalForRestructuring(investment);
        
        if (investment.status == InvestmentStatus.active) {
          activeItems++;
        }
      }
    }

    final tiles = [
      _SummaryTileData(
        title: 'Kwota wybranych inwestycji',
        value: _currencyFormat.format(totalInvestmentAmount),
        icon: Icons.account_balance_wallet,
        color: AppThemePro.accentGold,
        trend: null,
      ),
      _SummaryTileData(
        title: 'Pozostały kapitał wybranych',
        value: _currencyFormat.format(totalRemainingCapital),
        icon: Icons.trending_up,
        color: AppThemePro.profitGreen,
        trend: totalRemainingCapital > 0 ? 'positive' : 'negative',
      ),
      _SummaryTileData(
        title: 'Zabezpieczony kapitał',
        value: _currencyFormat.format(totalCapitalSecured),
        icon: Icons.security,
        color: AppThemePro.bondsBlue,
        trend: null,
      ),
      _SummaryTileData(
        title: 'W restrukturyzacji',
        value: _currencyFormat.format(totalCapitalForRestructuring),
        icon: Icons.refresh,
        color: AppThemePro.loansOrange,
        trend: totalCapitalForRestructuring > 0 ? 'warning' : null,
      ),
      _SummaryTileData(
        title: 'Aktywne produkty',
        value: '$activeItems/${selectedItems.length}',
        icon: Icons.check_circle,
        color: AppThemePro.statusSuccess,
        trend: null,
      ),
    ];

    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Podsumowanie wybranych produktów',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppThemePro.profitGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppThemePro.profitGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${selectedItems.length} WYBRANYCH',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppThemePro.profitGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 1200;
              final crossAxisCount = isWide
                  ? 5
                  : (constraints.maxWidth > 800 ? 3 : 2);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: tiles.length,
                itemBuilder: (context, index) =>
                    _buildSummaryTile(tiles[index], index),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedProductsDetails() {
    final selectedInvestments = _investments
        .where((inv) => _selectedProductIds.contains(inv.id))
        .toList();

    if (selectedInvestments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: AppThemePro.premiumCardDecoration,
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                color: AppThemePro.textMuted,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Szczegóły produktu',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Wybierz produkty powyżej aby zobaczyć szczegółowe informacje',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppThemePro.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Szczegóły wybranych produktów',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppThemePro.statusInfo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppThemePro.statusInfo.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${selectedInvestments.length} PRODUKTÓW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppThemePro.statusInfo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Jeśli wybrano tylko jeden produkt, pokaż szczegóły jak wcześniej
          if (selectedInvestments.length == 1) ...[
            _buildSingleProductDetails(selectedInvestments.first),
          ] else ...[
            // Jeśli wybrano wiele produktów, pokaż listę
            _buildMultipleProductsList(selectedInvestments),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleProductDetails(Investment investment) {
    return Container(
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        children: [
          _buildDetailRow('Nazwa produktu', investment.productName),
          _buildDetailRow('Typ', investment.productType.displayName),
          _buildDetailRow('Status', investment.status.displayName),
          _buildDetailRow('Emitent / Spółka', investment.creditorCompany),
          _buildDetailRow('Oddział sprzedaży', investment.branchCode),
          _buildDetailRow('Doradca', investment.employeeFullName),
          _buildDetailRow('Klient', investment.clientName),
          _buildDetailRow(
            'Kwota inwestycji',
            _currencyFormat.format(investment.investmentAmount),
          ),
          _buildDetailRow(
            'Pozostały kapitał',
            _currencyFormat.format(investment.remainingCapital),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleProductsList(List<Investment> selectedInvestments) {
    return Container(
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        children: [
          // Header tabeli
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppThemePro.accentGold.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Nazwa produktu',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Klient',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Typ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Pozostały kapitał',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Lista produktów
          ...selectedInvestments.asMap().entries.map((entry) {
            final index = entry.key;
            final investment = entry.value;
            final isLast = index == selectedInvestments.length - 1;
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: isLast ? null : Border(
                  bottom: BorderSide(color: AppThemePro.borderPrimary, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      investment.productName.isNotEmpty 
                          ? investment.productName 
                          : 'Produkt ${investment.id.substring(0, 8)}...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppThemePro.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      investment.clientName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppThemePro.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getProductTypeColor(investment.productType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        investment.productType.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getProductTypeColor(investment.productType),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _currencyFormat.format(investment.remainingCapital),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppThemePro.accentGold,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getStatusColor(investment.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStatusIcon(investment.status),
                        color: _getStatusColor(investment.status),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    if (_selectedInvestment == null) return const SizedBox.shrink();

    final investment = _selectedInvestment!;
    final now = DateTime.now();

    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terminy i oś czasu',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: AppThemePro.premiumCardDecoration,
            child: Column(
              children: [
                _buildTimelineItem(
                  'Data podpisania',
                  investment.signedDate,
                  Icons.edit,
                  AppThemePro.accentGold,
                ),
                _buildTimelineItem(
                  'Data emisji',
                  investment.issueDate,
                  Icons.launch,
                  AppThemePro.bondsBlue,
                ),
                _buildTimelineItem(
                  'Data wprowadzenia',
                  investment.entryDate,
                  Icons.input,
                  AppThemePro.sharesGreen,
                ),
                _buildTimelineItem(
                  'Data wykupu',
                  investment.redemptionDate,
                  Icons.event_available,
                  _getTimelineColor(investment.redemptionDate, now),
                  showWarning: _shouldShowWarning(
                    investment.redemptionDate,
                    now,
                  ),
                ),
                if (investment.additionalInfo['repaymentDate'] != null)
                  _buildTimelineItem(
                    'Data faktycznej spłaty',
                    DateTime.tryParse(
                      investment.additionalInfo['repaymentDate'],
                    ),
                    Icons.payment,
                    AppThemePro.profitGreen,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String label,
    DateTime? date,
    IconData icon,
    Color color, {
    bool showWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppThemePro.borderPrimary, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            children: [
              Text(
                date != null ? _dateFormat.format(date) : '—',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showWarning) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.warning_rounded,
                  color: AppThemePro.statusWarning,
                  size: 16,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRisksSection() {
    if (_selectedInvestment == null) return const SizedBox.shrink();

    final investment = _selectedInvestment!;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sekcja ryzyk i statusów finansowych',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: AppThemePro.premiumCardDecoration,
            child: Column(
              children: [
                _buildRiskRow(
                  'Zrealizowany kapitał',
                  investment.realizedCapital,
                  _getRiskStatus(investment.realizedCapital),
                ),
                _buildRiskRow(
                  'Zrealizowane odsetki',
                  investment.realizedInterest,
                  _getRiskStatus(investment.realizedInterest),
                ),
                _buildRiskRow(
                  'Zrealizowany podatek',
                  investment.realizedTax,
                  investment.realizedTax > 0 ? 'positive' : 'warning',
                ),
                _buildRiskRow(
                  'Przeniesione do innego produktu',
                  investment.transferToOtherProduct,
                  investment.transferToOtherProduct > 0 ? 'neutral' : 'neutral',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskRow(String label, double value, String status) {
    final statusData = _getRiskStatusData(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppThemePro.borderPrimary, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _currencyFormat.format(value),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusData.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusData.color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusData.icon, color: statusData.color, size: 16),
                const SizedBox(width: 6),
                Text(
                  statusData.text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusData.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build custom logo
  Widget _buildCustomLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppThemePro.accentGold, AppThemePro.accentGoldMuted],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: SvgPicture.asset(
          'assets/logos/METROPOLITAN_logo_kontra_RGB.svg',
          width: size * 0.7,
          height: size * 0.7,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }

  Widget _buildSummaryTile(_SummaryTileData data, int index) {
    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  data.color.withOpacity(0.1),
                  data.color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: data.color.withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: data.color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Add haptic feedback
                  // HapticFeedback.lightImpact();
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: data.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(data.icon, color: data.color, size: 24),
                          ),
                          if (data.trend != null) ...[
                            const Spacer(),
                            Icon(
                              data.trend == 'positive'
                                  ? Icons.trending_up
                                  : data.trend == 'negative'
                                  ? Icons.trending_down
                                  : Icons.warning,
                              color: data.trend == 'positive'
                                  ? AppThemePro.profitGreen
                                  : data.trend == 'negative'
                                  ? AppThemePro.lossRed
                                  : AppThemePro.loansOrange,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      const Spacer(),
                      Text(
                        data.value,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppThemePro.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemePro.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppThemePro.borderPrimary, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : '—',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppThemePro.textPrimary),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  double _getCapitalSecuredByRealEstate(Investment investment) {
    final value =
        investment.additionalInfo['realEstateSecuredCapital'] ??
        investment.additionalInfo['capitalSecuredByRealEstate'];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.replaceAll(',', ''));
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  double _getCapitalForRestructuring(Investment investment) {
    final value = investment.additionalInfo['capitalForRestructuring'];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.replaceAll(',', ''));
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  IconData _getStatusIcon(InvestmentStatus status) {
    switch (status) {
      case InvestmentStatus.active:
        return Icons.check_circle;
      case InvestmentStatus.inactive:
        return Icons.pause_circle;
      case InvestmentStatus.earlyRedemption:
        return Icons.fast_forward;
      case InvestmentStatus.completed:
        return Icons.task_alt;
    }
  }

  Color _getStatusColor(InvestmentStatus status) {
    switch (status) {
      case InvestmentStatus.active:
        return AppThemePro.statusSuccess;
      case InvestmentStatus.inactive:
        return AppThemePro.statusWarning;
      case InvestmentStatus.earlyRedemption:
        return AppThemePro.statusInfo;
      case InvestmentStatus.completed:
        return AppThemePro.profitGreen;
    }
  }

  Color _getProductTypeColor(ProductType productType) {
    switch (productType) {
      case ProductType.bonds:
        return AppThemePro.bondsBlue;
      case ProductType.shares:
        return AppThemePro.sharesGreen;
      case ProductType.loans:
        return AppThemePro.loansOrange;
      case ProductType.apartments:
        return AppThemePro.lossRed;
    }
  }

  Color _getUnifiedProductTypeColor(UnifiedProductType productType) {
    switch (productType) {
      case UnifiedProductType.bonds:
        return AppThemePro.bondsBlue;
      case UnifiedProductType.shares:
        return AppThemePro.sharesGreen;
      case UnifiedProductType.loans:
        return AppThemePro.loansOrange;
      case UnifiedProductType.apartments:
        return AppThemePro.lossRed;
      case UnifiedProductType.other:
        return AppThemePro.textSecondary;
    }
  }

  IconData _getProductTypeIcon(UnifiedProductType productType) {
    switch (productType) {
      case UnifiedProductType.bonds:
        return Icons.account_balance;
      case UnifiedProductType.shares:
        return Icons.trending_up;
      case UnifiedProductType.loans:
        return Icons.handshake;
      case UnifiedProductType.apartments:
        return Icons.home;
      case UnifiedProductType.other:
        return Icons.category;
    }
  }

  Color _getTimelineColor(DateTime? date, DateTime now) {
    if (date == null) return AppThemePro.textMuted;

    final daysUntil = date.difference(now).inDays;

    if (daysUntil < 0) return AppThemePro.lossRed; // Past due
    if (daysUntil <= 30) return AppThemePro.statusWarning; // Warning
    return AppThemePro.profitGreen; // Good
  }

  bool _shouldShowWarning(DateTime? date, DateTime now) {
    if (date == null) return false;
    final daysUntil = date.difference(now).inDays;
    return daysUntil <= 30;
  }

  String _getRiskStatus(double value) {
    if (value > 0) return 'positive';
    if (value < 0) return 'negative';
    return 'warning';
  }

  _RiskStatusData _getRiskStatusData(String status) {
    switch (status) {
      case 'positive':
        return _RiskStatusData(
          color: AppThemePro.statusSuccess,
          icon: Icons.check_circle,
          text: 'OK',
        );
      case 'negative':
        return _RiskStatusData(
          color: AppThemePro.lossRed,
          icon: Icons.cancel,
          text: 'Brak spłat',
        );
      case 'warning':
        return _RiskStatusData(
          color: AppThemePro.statusWarning,
          icon: Icons.warning,
          text: 'Niewyliczony',
        );
      default:
        return _RiskStatusData(
          color: AppThemePro.neutralGray,
          icon: Icons.remove,
          text: '—',
        );
    }
  }
}

// Helper classes
class _SummaryTileData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;

  _SummaryTileData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
  });
}

class _RiskStatusData {
  final Color color;
  final IconData icon;
  final String text;

  _RiskStatusData({
    required this.color,
    required this.icon,
    required this.text,
  });
}
