import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/unified_product.dart';
import '../../models/investor_summary.dart';
import '../../models_and_services.dart'; // Import wszystkich serwisów
import 'product_details_service.dart';

/// Header dialogu szczegółów produktu z animacjami i gradientem
class ProductDetailsHeader extends StatefulWidget {
  final UnifiedProduct product;
  final List<InvestorSummary> investors;
  final bool isLoadingInvestors;
  final VoidCallback onClose;
  final VoidCallback? onShowInvestors;

  const ProductDetailsHeader({
    super.key,
    required this.product,
    required this.investors,
    required this.isLoadingInvestors,
    required this.onClose,
    this.onShowInvestors,
  });

  @override
  State<ProductDetailsHeader> createState() => _ProductDetailsHeaderState();
}

class _ProductDetailsHeaderState extends State<ProductDetailsHeader>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final ProductDetailsService _service = ProductDetailsService();
  final UnifiedStatisticsService _statisticsService =
      UnifiedStatisticsService();
  // ignore: unused_field
  final EnhancedUnifiedProductService _productService =
      EnhancedUnifiedProductService();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
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
            // Przycisk zamknięcia
            _buildCloseButton(),
            const SizedBox(height: 8),

            // Główne informacje o produkcie
            _buildMainInfo(),
            const SizedBox(height: 20),

            // Metryki finansowe
            _buildFinancialMetrics(),
          ],
        ),
      ),
    );
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
    try {
      // Zamykamy obecny dialog
      widget.onClose();

      // Pokazujemy dialog ładowania
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Tutaj będzie logika otwierania formularza edycji
      // Na razie symulujemy proces
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop(); // Zamknij dialog ładowania

        // Pokazuj informację o dostępności funkcji
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Funkcja edycji produktu',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Formularz edycji dla ${widget.product.name} zostanie wkrótce dodany',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.warningPrimary,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }

      print(
        '🔧 [ProductDetailsHeader] Edycja produktu: ${widget.product.name}',
      );
      print('  - ID: ${widget.product.id}');
      print('  - Typ: ${widget.product.productType.displayName}');
      print(
        '  - Kolekcja docelowa: ${widget.product.productType.collectionName}',
      );
      print('  - Serwis dostępny: TAK');

      // Potencjalna logika dla przyszłego formularza edycji:
      // await _productService.updateUnifiedProduct(modifiedProduct);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Zamknij dialog ładowania jeśli błąd

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas przygotowania edycji: $e'),
            backgroundColor: AppTheme.errorPrimary,
          ),
        );
      }

      print('❌ [ProductDetailsHeader] Błąd podczas edycji produktu: $e');
    }
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
                  _service.getProductIcon(widget.product.productType),
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

  Widget _buildFinancialMetrics() {
    // ⭐ ZUNIFIKOWANE STATYSTYKI - używamy UnifiedStatisticsService
    // Obliczamy statystyki zgodnie z STATISTICS_UNIFICATION_GUIDE.md

    final statistics = _statisticsService.calculateProductStatistics(
      widget.product,
      widget.investors,
    );

    // 🐛 DEBUG - Śledzenie wartości statystyk
    print('🔍 [ProductDetailsHeader] Zunifikowane statystyki finansowe:');
    print('  - isLoadingInvestors: ${widget.isLoadingInvestors}');
    print('  - investorsCount: ${widget.investors.length}');
    print('  - productType: ${widget.product.productType.displayName}');
    print('  - source: ${statistics.source.displayName}');
    print('  - product.totalValue (raw): ${widget.product.totalValue}');
    print('  - product.remainingCapital: ${widget.product.remainingCapital}');
    print('  - product.remainingInterest: ${widget.product.remainingInterest}');
    print('  - product.investmentAmount: ${widget.product.investmentAmount}');
    print(
      '  - ⭐ ZUNIFIKOWANE totalInvestmentAmount: ${statistics.totalInvestmentAmount}',
    );
    print(
      '  - ⭐ ZUNIFIKOWANE totalRemainingCapital: ${statistics.totalRemainingCapital}',
    );
    print(
      '  - ⭐ ZUNIFIKOWANE totalCapitalSecuredByRealEstate: ${statistics.totalCapitalSecuredByRealEstate}',
    );

    // 🐛 DEBUG - Szczegółowe dane inwestorów (pierwsze 3)
    if (widget.investors.isNotEmpty) {
      print('📊 [ProductDetailsHeader] Próbka danych inwestorów:');
      for (int i = 0; i < widget.investors.length.clamp(0, 3); i++) {
        final investor = widget.investors[i];
        print('  Inwestor $i:');
        print('    - totalInvestmentAmount: ${investor.totalInvestmentAmount}');
        print('    - totalRemainingCapital: ${investor.totalRemainingCapital}');
        print(
          '    - capitalSecuredByRealEstate: ${investor.capitalSecuredByRealEstate}',
        );
        print('    - investmentCount: ${investor.investmentCount}');

        // Sprawdź pierwsze inwestycje
        if (investor.investments.isNotEmpty) {
          final investment = investor.investments.first;
          print(
            '    - pierwsza inwestycja.remainingCapital: ${investment.remainingCapital}',
          );
          print(
            '    - pierwsza inwestycja.investmentAmount: ${investment.investmentAmount}',
          );
          print(
            '    - pierwsza inwestycja.remainingInterest: ${investment.remainingInterest}',
          );
          print(
            '    - pierwsza inwestycja.productName: "${investment.productName}"',
          );
        }
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Suma inwestycji',
            value: _service.formatCurrency(statistics.totalInvestmentAmount),
            subtitle: 'PLN',
            icon: Icons.trending_down,
            color: AppTheme.infoPrimary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Kapitał pozostały',
            value: _service.formatCurrency(statistics.totalRemainingCapital),
            subtitle: 'PLN',
            icon: Icons.account_balance_wallet,
            color: AppTheme.successPrimary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Zabezpiecz. nieru.',
            value: _service.formatCurrency(
              statistics.totalCapitalSecuredByRealEstate,
            ),
            subtitle: 'PLN',
            icon: Icons.home,
            color: AppTheme.warningPrimary,
          ),
        ),
      ],
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
}
