import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/unified_product.dart';
import '../../models/investor_summary.dart';
import '../../models_and_services.dart';
import '../../utils/currency_formatter.dart';

// ⭐ UJEDNOLICONY WZORZEC: Używamy UnifiedDashboardStatisticsService
// zamiast ProductDetailsService + ServerSideStatisticsService

class ProductDetailsHeader extends StatefulWidget {
  final UnifiedProduct product;
  final List<InvestorSummary> investors;
  final bool isLoadingInvestors;
  final VoidCallback onClose;
  final VoidCallback? onShowInvestors;
  final Function(bool)?
  onEditModeChanged; // ⭐ NOWE: Callback dla zmiany trybu edycji
  final Function(int)? onTabChanged; // ⭐ NOWE: Callback dla zmiany tabu

  const ProductDetailsHeader({
    super.key,
    required this.product,
    required this.investors,
    required this.isLoadingInvestors,
    required this.onClose,
    this.onShowInvestors,
    this.onEditModeChanged, // ⭐ NOWE: Callback dla zmiany trybu edycji
    this.onTabChanged, // ⭐ NOWE: Callback dla zmiany tabu
  });
  @override
  State<ProductDetailsHeader> createState() => _ProductDetailsHeaderState();
}

class _ProductDetailsHeaderState extends State<ProductDetailsHeader>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  // ⭐ UJEDNOLICONY SERWIS: Wykorzystujemy zunifikowane statystyki dashboard
  final UnifiedDashboardStatisticsService _statisticsService =
      UnifiedDashboardStatisticsService();

  UnifiedDashboardStatistics? _unifiedStatistics;
  bool _isLoadingStatistics = false;

  // ⭐ NOWE: Stan edycji - przekazywany do product_investors_tab
  bool _isEditModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _loadServerStatistics();
  }

  Future<void> _loadServerStatistics() async {
    if (widget.isLoadingInvestors || widget.investors.isEmpty) return;
    if (widget.product.name.trim().isEmpty) return;

    setState(() => _isLoadingStatistics = true);

    try {
      // ⭐ UJEDNOLICONE OBLICZENIA: Używamy zunifikowanych statystyk z inwestorów
      final stats = await _statisticsService.getStatisticsFromInvestors();

      if (!mounted) return;

      setState(() {
        _unifiedStatistics = stats;
        _isLoadingStatistics = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingStatistics = false);

      // Fallback do lokalnych obliczeń
      debugPrint(
        '⚠️ [ProductDetailsHeader] Fallback do lokalnych statystyk: $error',
      );
    }
  }

  @override
  void didUpdateWidget(covariant ProductDetailsHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.investors != widget.investors ||
        oldWidget.isLoadingInvestors != widget.isLoadingInvestors) {
      _loadServerStatistics();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryLight,
            AppTheme.primaryAccent,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCloseButton(),
            const SizedBox(height: 8),
            _buildMainInfo(),
            const SizedBox(height: 20),
            _buildFinancialMetrics(),
          ],
        ),
      ),
    );
  }

  // --- Metryki (UJEDNOLICONE ŹRÓDŁO DANYCH) ---
  Widget _buildFinancialMetrics() {
    if (_isLoadingStatistics) {
      return Row(
        children: List.generate(
          3,
          (i) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 16 : 0),
              child: _buildMetricLoadingCard(),
            ),
          ),
        ),
      );
    }

    // ⭐ UJEDNOLICONE OBLICZENIA: Używamy zunifikowanych statystyk lub fallback lokalny
    final double totalInvestmentAmount;
    final double totalRemainingCapital;
    final double totalCapitalSecured;

    if (_unifiedStatistics != null) {
      // Zunifikowane statystyki z serwisu
      totalInvestmentAmount = _unifiedStatistics!.totalInvestmentAmount;
      totalRemainingCapital = _unifiedStatistics!.totalRemainingCapital;
      totalCapitalSecured = _unifiedStatistics!.totalCapitalSecured;
    } else {
      // Fallback: Obliczenia lokalne według wzoru z product_details_modal.dart
      totalInvestmentAmount = _computeTotalInvestmentAmount();
      totalRemainingCapital = _computeTotalRemainingCapital();
      totalCapitalSecured = _computeTotalCapitalSecured();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Etykieta źródła danych (dla przejrzystości)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                'Źródło: ${_unifiedStatistics != null ? "Zunifikowane statystyki" : "Obliczenia lokalne"}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 220,
              child: _buildMetricCard(
                title: 'Suma inwestycji',
                value: CurrencyFormatter.formatCurrency(totalInvestmentAmount),
                subtitle: 'PLN',
                icon: Icons.trending_up,
                color: AppTheme.infoPrimary,
              ),
            ),
            SizedBox(
              width: 220,
              child: _buildMetricCard(
                title: 'Kapitał pozostały',
                value: CurrencyFormatter.formatCurrency(totalRemainingCapital),
                subtitle: 'PLN',
                icon: Icons.account_balance_wallet,
                color: AppTheme.successPrimary,
              ),
            ),
            SizedBox(
              width: 220,
              child: _buildMetricCard(
                title: 'Kapitał zabezpieczony',
                value: CurrencyFormatter.formatCurrency(totalCapitalSecured),
                subtitle: 'PLN',
                icon: Icons.security,
                color: AppTheme.warningPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ⭐ POMOCNICZE METODY OBLICZENIOWE (wzór z product_details_modal.dart)
  double _computeTotalInvestmentAmount() {
    double sum = 0.0;
    final processedIds = <String>{};

    for (final investor in widget.investors) {
      for (final investment in investor.investments) {
        if (investment.productName != widget.product.name) continue;
        if (processedIds.contains(investment.id)) continue;
        processedIds.add(investment.id);
        sum += investment.investmentAmount;
      }
    }
    return sum;
  }

  double _computeTotalRemainingCapital() {
    double sum = 0.0;
    final processedIds = <String>{};

    for (final investor in widget.investors) {
      for (final investment in investor.investments) {
        if (investment.productName != widget.product.name) continue;
        if (processedIds.contains(investment.id)) continue;
        processedIds.add(investment.id);
        sum += investment.remainingCapital;
      }
    }
    return sum;
  }

  double _computeTotalCapitalSecured() {
    final totalRemaining = _computeTotalRemainingCapital();
    final totalForRestructuring = _computeTotalCapitalForRestructuring();
    // Wzór: capitalSecured = max(remainingCapital - capitalForRestructuring, 0)
    return (totalRemaining - totalForRestructuring).clamp(0.0, double.infinity);
  }

  double _computeTotalCapitalForRestructuring() {
    double sum = 0.0;
    final processedIds = <String>{};

    for (final investor in widget.investors) {
      for (final investment in investor.investments) {
        if (investment.productName != widget.product.name) continue;
        if (processedIds.contains(investment.id)) continue;
        processedIds.add(investment.id);
        sum += investment.capitalForRestructuring;
      }
    }
    return sum;
  }

  Widget _buildCloseButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Przycisk edycji
        Container(
          decoration: BoxDecoration(
            color: AppTheme.secondaryGold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.secondaryGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () => _editProduct(),
            icon: const Icon(
              Icons.edit,
              color: AppTheme.secondaryGold,
              size: 20,
            ),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
            tooltip: 'Edytuj produkt',
          ),
        ),
        const SizedBox(width: 12),
        // Przycisk zamknięcia
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
            tooltip: 'Zamknij',
          ),
        ),
      ],
    );
  }

  void _editProduct() async {
    setState(() {
      _isEditModeEnabled = !_isEditModeEnabled;
    });

    // ⭐ NOWE: Powiadom parent o zmianie trybu edycji
    widget.onEditModeChanged?.call(_isEditModeEnabled);

    if (_isEditModeEnabled) {
      // ⭐ NOWE: Automatycznie przełącz na tab "Inwestorzy" (index 1)
      widget.onTabChanged?.call(1);
      
      _showSnackBar(
        'Tryb edycji włączony - kliknij na inwestora aby edytować',
        isError: false,
        icon: Icons.edit,
      );
    } else {
      _showSnackBar(
        'Tryb edycji wyłączony',
        isError: false,
        icon: Icons.visibility,
      );
    }
  }

  void _showSnackBar(String message, {required bool isError, IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon ?? (isError ? Icons.error : Icons.check_circle),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError
            ? AppTheme.errorPrimary
            : AppTheme.successPrimary,
        duration: Duration(seconds: isError ? 5 : 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildMainInfo() {
    return Row(
      children: [
        // Ikona produktu z animacją
        TweenAnimationBuilder(
          duration: const Duration(milliseconds: 800),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.getProductTypeColor(
                        widget.product.productType.collectionName,
                      ).withOpacity(0.8),
                      AppTheme.getProductTypeColor(
                        widget.product.productType.collectionName,
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.getProductTypeColor(
                        widget.product.productType.collectionName,
                      ).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _getProductIcon(widget.product.productType),
                  color: Colors.white,
                  size: 32,
                ),
              ),
            );
          },
        ),

        const SizedBox(width: 20),

        // Informacje o produkcie
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.product.productType.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Status badge
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final color = AppTheme.getStatusColor(widget.product.status.displayName);

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.8), color],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.product.status.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Widget loading state dla metryk podczas ładowania z serwera
  Widget _buildMetricLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 60,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 80,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 30,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 1000),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ⭐ POMOCNICZA METODA: Ikona produktu (wzór z product_details_modal.dart)
  IconData _getProductIcon(UnifiedProductType productType) {
    switch (productType) {
      case UnifiedProductType.bonds:
        return Icons.account_balance;
      case UnifiedProductType.shares:
        return Icons.trending_up;
      case UnifiedProductType.loans:
        return Icons.monetization_on;
      case UnifiedProductType.apartments:
        return Icons.home;
      case UnifiedProductType.other:
        return Icons.inventory;
    }
  }
}
