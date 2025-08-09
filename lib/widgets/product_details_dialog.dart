import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/unified_product.dart';
import '../models/investor_summary.dart';
import '../services/product_investors_service.dart';
import 'premium_loading_widget.dart';
import 'premium_error_widget.dart';
/// Enhanced widget do wyświetlania szczegółów produktu w modal dialog
class EnhancedProductDetailsDialog extends StatefulWidget {
  final UnifiedProduct product;

  const EnhancedProductDetailsDialog({super.key, required this.product});

  @override
  State<EnhancedProductDetailsDialog> createState() =>
      _EnhancedProductDetailsDialogState();
}

class _EnhancedProductDetailsDialogState
    extends State<EnhancedProductDetailsDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ProductInvestorsService _investorsService = ProductInvestorsService();

  List<InvestorSummary> _investors = [];
  bool _isLoadingInvestors = true;
  String? _investorsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Rozpocznij ładowanie inwestorów natychmiast
    _loadInvestors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInvestors() async {
    try {
      setState(() {
        _isLoadingInvestors = true;
        _investorsError = null;
      });

      print('🔍 [ProductDetailsDialog] Ładowanie inwestorów dla produktu:');
      print('  - Nazwa: "${widget.product.name}"');
      print('  - Typ: ${widget.product.productType.displayName}');

      // Używamy ulepszonej metody getInvestorsForProduct z zaawansowanymi strategiami
      final investors = await _investorsService.getInvestorsForProduct(
        widget.product,
      );

      if (mounted) {
        setState(() {
          _investors = investors;
          _isLoadingInvestors = false;
        });

        print(
          '✅ [ProductDetailsDialog] Załadowano ${investors.length} inwestorów',
        );
      }
    } catch (e) {
      print('❌ [ProductDetailsDialog] Błąd podczas ładowania inwestorów: $e');
      if (mounted) {
        setState(() {
          _investorsError = 'Błąd podczas ładowania inwestorów: $e';
          _isLoadingInvestors = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsywne wymiary dialogu
    final dialogWidth = screenWidth > 800
        ? screenWidth * 0.6
        : screenWidth * 0.92;
    final dialogHeight = screenHeight * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
        decoration: BoxDecoration(
          color: AppTheme.backgroundModal,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.borderPrimary.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header z gradientem i przyciskiem zamknięcia
            _buildDialogHeader(),

            // Tab Bar
            _buildTabBar(),

            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildInvestorsTab(),
                  _buildAnalyticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Przycisk zamknięcia
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
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
              _buildAnimatedStatusBadge(),
            ],
          ),

          const SizedBox(height: 20),

          // Metryki finansowe
          _buildFinancialMetrics(),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatusBadge() {
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
                colors: [
                  color.withOpacity(0.8),
                  color,
                ],
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
    final profitLoss =
        widget.product.totalValue - widget.product.investmentAmount;
    final profitLossPercentage = widget.product.investmentAmount > 0
        ? (profitLoss / widget.product.investmentAmount) * 100
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Inwestycja',
            value: _formatCurrency(widget.product.investmentAmount),
            subtitle: 'PLN',
            icon: Icons.input,
            color: AppTheme.infoPrimary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Wartość',
            value: _formatCurrency(widget.product.totalValue),
            subtitle: 'PLN',
            icon: Icons.account_balance_wallet,
            color: AppTheme.secondaryGold,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: profitLoss >= 0 ? 'Zysk' : 'Strata',
            value: _formatCurrency(profitLoss.abs()),
            subtitle: '${profitLossPercentage.toStringAsFixed(1)}%',
            icon: profitLoss >= 0 ? Icons.trending_up : Icons.trending_down,
            color: profitLoss >= 0
                ? AppTheme.gainPrimary
                : AppTheme.lossPrimary,
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

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundModal,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderPrimary, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                const Text('Szczegóły'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_outline, size: 18),
                const SizedBox(width: 8),
                _isLoadingInvestors
                    ? const Row(
                        children: [
                          Text('Inwestorzy '),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                AppTheme.secondaryGold,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Text('Inwestorzy (${_investors.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.analytics_outlined, size: 18),
                const SizedBox(width: 8),
                const Text('Analiza'),
              ],
            ),
          ),
        ],
        labelColor: AppTheme.secondaryGold,
        unselectedLabelColor: AppTheme.textTertiary,
        indicatorColor: AppTheme.secondaryGold,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.2,
        ),
        indicator: BoxDecoration(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(3),
            bottomRight: Radius.circular(3),
          ),
          gradient: LinearGradient(
            colors: [
              AppTheme.secondaryGold.withOpacity(0.6),
              AppTheme.secondaryGold,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondaryGold.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getProductIcon(UnifiedProductType type) {
    switch (type) {
      case UnifiedProductType.bonds:
        return Icons.account_balance;
      case UnifiedProductType.shares:
        return Icons.trending_up;
      case UnifiedProductType.loans:
        return Icons.attach_money;
      case UnifiedProductType.apartments:
        return Icons.apartment;
      case UnifiedProductType.other:
        return Icons.inventory;
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M zł';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K zł';
    } else {
      return '${amount.toStringAsFixed(2)} zł';
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Szczegółowe informacje specyficzne dla typu produktu
          _buildProductSpecificDetails(),

          const SizedBox(height: 24),

          // Podstawowe informacje
          _buildBasicInformation(),

          const SizedBox(height: 24),

          // Opis produktu
          if (widget.product.description.isNotEmpty) ...[
            _buildDescriptionSection(),
            const SizedBox(height: 24),
          ],

          // Dodatkowe informacje
          if (widget.product.additionalInfo.isNotEmpty) ...[
            _buildAdditionalInfoSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildInvestorsTab() {
    if (_isLoadingInvestors) {
      return const Center(
        child: PremiumLoadingWidget(message: 'Ładowanie inwestorów...'),
      );
    }

    if (_investorsError != null) {
      return PremiumErrorWidget(
        error: _investorsError!,
        onRetry: _loadInvestors,
      );
    }

    if (_investors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Brak inwestorów',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nie znaleziono inwestorów dla tego produktu.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Pokaż informacje debuggowe
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Informacje o wyszukiwaniu:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nazwa: "${widget.product.name}"',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      'Typ: ${widget.product.productType.displayName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      'Kolekcja: ${widget.product.productType.collectionName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadInvestors,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Spróbuj ponownie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.textOnPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _investors.length,
      itemBuilder: (context, index) {
        final investor = _investors[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(Icons.person, color: AppTheme.primaryColor),
            ),
            title: Text(
              investor.client.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (investor.client.email.isNotEmpty)
                  Text(
                    investor.client.email,
                    style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.8),
                    ),
                  ),
                if (investor.client.phone.isNotEmpty)
                  Text(
                    investor.client.phone,
                    style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.8),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Inwestycje: ${investor.investmentCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryGold,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.secondaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatCurrency(investor.viableRemainingCapital),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryGold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statystyki inwestorów
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statystyki Inwestorów',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Liczba Inwestorów',
                        _investors.length.toString(),
                        Icons.people,
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Łączny Kapitał',
                        _formatCurrency(
                          _investors.fold(
                            0.0,
                            (sum, investor) =>
                                sum + investor.viableRemainingCapital,
                          ),
                        ),
                        Icons.attach_money,
                        AppTheme.secondaryGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Średnia Inwestycja',
                        _investors.isNotEmpty
                            ? _formatCurrency(
                                _investors.fold(
                                      0.0,
                                      (sum, investor) =>
                                          sum + investor.viableRemainingCapital,
                                    ) /
                                    _investors.length,
                              )
                            : '0 zł',
                        Icons.trending_up,
                        AppTheme.successPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Łączne Inwestycje',
                        _investors
                            .fold(
                              0,
                              (sum, investor) => sum + investor.investmentCount,
                            )
                            .toString(),
                        Icons.account_balance,
                        AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Ranking inwestorów
          if (_investors.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Inwestorzy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._investors.take(5).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final investor = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundPrimary.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: index == 0
                              ? AppTheme.secondaryGold.withOpacity(0.3)
                              : AppTheme.primaryColor.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? AppTheme.secondaryGold
                                  : AppTheme.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: index == 0
                                      ? AppTheme.backgroundPrimary
                                      : AppTheme.primaryColor,
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
                                  investor.client.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${investor.investmentCount} inwestycji',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary.withOpacity(
                                      0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatCurrency(investor.viableRemainingCapital),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: index == 0
                                  ? AppTheme.secondaryGold
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textTertiary,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Buduje szczegóły specyficzne dla typu produktu
  Widget _buildProductSpecificDetails() {
    switch (widget.product.productType) {
      case UnifiedProductType.bonds:
        return _buildBondsDetails();
      case UnifiedProductType.shares:
        return _buildSharesDetails();
      case UnifiedProductType.loans:
        return _buildLoansDetails();
      case UnifiedProductType.apartments:
        return _buildApartmentsDetails();
      case UnifiedProductType.other:
        return _buildOtherProductDetails();
    }
  }

  /// Szczegóły dla obligacji
  Widget _buildBondsDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.bondsColor.withOpacity(0.1),
            AppTheme.bondsBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.bondsColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.bondsColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bondsColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance,
                  color: AppTheme.bondsColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Szczegóły Obligacji',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.bondsColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Informacje o instrumencie dłużnym',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.product.realizedCapital != null)
            _buildDetailRow(
              'Zrealizowany kapitał',
              _formatCurrency(widget.product.realizedCapital!),
            ),
          if (widget.product.remainingCapital != null)
            _buildDetailRow(
              'Pozostały kapitał',
              _formatCurrency(widget.product.remainingCapital!),
            ),
          if (widget.product.realizedInterest != null)
            _buildDetailRow(
              'Zrealizowane odsetki',
              _formatCurrency(widget.product.realizedInterest!),
            ),
          if (widget.product.remainingInterest != null)
            _buildDetailRow(
              'Pozostałe odsetki',
              _formatCurrency(widget.product.remainingInterest!),
            ),
          if (widget.product.interestRate != null)
            _buildDetailRow(
              'Oprocentowanie',
              '${widget.product.interestRate!.toStringAsFixed(2)}%',
            ),
          if (widget.product.maturityDate != null)
            _buildDetailRow(
              'Data zapadalności',
              _formatDate(widget.product.maturityDate!),
            ),
          if (widget.product.companyName != null)
            _buildDetailRow('Emitent', widget.product.companyName!),
        ],
      ),
    );
  }

  /// Szczegóły dla udziałów
  Widget _buildSharesDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.sharesColor.withOpacity(0.1),
            AppTheme.sharesBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.sharesColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.sharesColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.sharesColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: AppTheme.sharesColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Szczegóły Udziałów',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.sharesColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Informacje o udziałach w spółce',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.product.sharesCount != null)
            _buildDetailRow(
              'Liczba udziałów',
              widget.product.sharesCount.toString(),
            ),
          if (widget.product.pricePerShare != null)
            _buildDetailRow(
              'Cena za udział',
              _formatCurrency(widget.product.pricePerShare!),
            ),
          if (widget.product.companyName != null)
            _buildDetailRow('Nazwa spółki', widget.product.companyName!),
          _buildDetailRow(
            'Wartość całkowita',
            _formatCurrency(widget.product.totalValue),
          ),
        ],
      ),
    );
  }

  /// Szczegóły dla pożyczek
  Widget _buildLoansDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.loansColor.withOpacity(0.1),
            AppTheme.loansBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.loansColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.loansColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.loansColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.attach_money,
                  color: AppTheme.loansColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Szczegóły Pożyczki',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.loansColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Informacje o produkcie pożyczkowym',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.product.additionalInfo['borrower'] != null)
            _buildDetailRow(
              'Pożyczkobiorca',
              widget.product.additionalInfo['borrower'].toString(),
            ),
          if (widget.product.additionalInfo['creditorCompany'] != null)
            _buildDetailRow(
              'Spółka wierzyciel',
              widget.product.additionalInfo['creditorCompany'].toString(),
            ),
          if (widget.product.interestRate != null)
            _buildDetailRow(
              'Oprocentowanie',
              '${widget.product.interestRate!.toStringAsFixed(2)}%',
            ),
          if (widget.product.maturityDate != null)
            _buildDetailRow(
              'Termin spłaty',
              _formatDate(widget.product.maturityDate!),
            ),
          if (widget.product.additionalInfo['collateral'] != null)
            _buildDetailRow(
              'Zabezpieczenie',
              widget.product.additionalInfo['collateral'].toString(),
            ),
          if (widget.product.additionalInfo['status'] != null)
            _buildDetailRow(
              'Status pożyczki',
              widget.product.additionalInfo['status'].toString(),
            ),
        ],
      ),
    );
  }

  /// Szczegóły dla apartamentów
  Widget _buildApartmentsDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.apartmentsColor.withOpacity(0.1),
            AppTheme.apartmentsBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.apartmentsColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.apartmentsColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.apartmentsColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.apartment,
                  color: AppTheme.apartmentsColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Szczegóły Apartamentu',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.apartmentsColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Informacje o nieruchomości',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.product.additionalInfo['apartmentNumber'] != null)
            _buildDetailRow(
              'Numer apartamentu',
              widget.product.additionalInfo['apartmentNumber'].toString(),
            ),
          if (widget.product.additionalInfo['building'] != null)
            _buildDetailRow(
              'Budynek',
              widget.product.additionalInfo['building'].toString(),
            ),
          if (widget.product.additionalInfo['area'] != null)
            _buildDetailRow(
              'Powierzchnia',
              '${widget.product.additionalInfo['area']} m²',
            ),
          if (widget.product.additionalInfo['roomCount'] != null)
            _buildDetailRow(
              'Liczba pokoi',
              widget.product.additionalInfo['roomCount'].toString(),
            ),
          if (widget.product.additionalInfo['floor'] != null)
            _buildDetailRow(
              'Piętro',
              widget.product.additionalInfo['floor'].toString(),
            ),
          if (widget.product.additionalInfo['apartmentType'] != null)
            _buildDetailRow(
              'Typ apartamentu',
              widget.product.additionalInfo['apartmentType'].toString(),
            ),
          if (widget.product.additionalInfo['pricePerSquareMeter'] != null)
            _buildDetailRow(
              'Cena za m²',
              '${widget.product.additionalInfo['pricePerSquareMeter']} PLN/m²',
            ),
          if (widget.product.additionalInfo['address'] != null)
            _buildDetailRow(
              'Adres',
              widget.product.additionalInfo['address'].toString(),
            ),
          // Dodatkowe amenity
          Row(
            children: [
              if (widget.product.additionalInfo['hasBalcony'] == true)
                _buildAmenityChip('Balkon', Icons.balcony),
              if (widget.product.additionalInfo['hasParkingSpace'] == true) ...[
                const SizedBox(width: 8),
                _buildAmenityChip('Parking', Icons.local_parking),
              ],
              if (widget.product.additionalInfo['hasStorage'] == true) ...[
                const SizedBox(width: 8),
                _buildAmenityChip('Komórka', Icons.storage),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Szczegóły dla innych produktów
  Widget _buildOtherProductDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.backgroundTertiary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Szczegóły Produktu',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Informacje o produkcie inwestycyjnym',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            'Wartość całkowita',
            _formatCurrency(widget.product.totalValue),
          ),
          if (widget.product.companyName != null)
            _buildDetailRow('Firma', widget.product.companyName!),
          if (widget.product.currency != null)
            _buildDetailRow('Waluta', widget.product.currency!),
        ],
      ),
    );
  }

  /// Buduje podstawowe informacje o produkcie
  Widget _buildBasicInformation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceElevated.withOpacity(0.6),
            AppTheme.surfaceCard,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderPrimary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: AppTheme.secondaryGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Podstawowe Informacje',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.secondaryGold,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow('ID Produktu', widget.product.id),
          _buildDetailRow(
            'Typ produktu',
            widget.product.productType.displayName,
          ),
          _buildDetailRow(
            'Status',
            widget.product.isActive ? 'Aktywny' : 'Nieaktywny',
          ),
          _buildDetailRow(
            'Kwota inwestycji',
            _formatCurrency(widget.product.investmentAmount),
          ),
          _buildDetailRow(
            'Data utworzenia',
            _formatDate(widget.product.createdAt),
          ),
          _buildDetailRow(
            'Ostatnia aktualizacja',
            _formatDate(widget.product.uploadedAt),
          ),
          _buildDetailRow('Źródło danych', widget.product.sourceFile),
          _buildDetailRow('Waluta', widget.product.currency ?? 'PLN'),
        ],
      ),
    );
  }

  /// Buduje sekcję opisu
  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.infoPrimary.withOpacity(0.05),
            AppTheme.infoBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.infoPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.infoPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: AppTheme.infoPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Opis Produktu',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.infoPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.borderSecondary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              widget.product.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textPrimary,
                height: 1.6,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Buduje sekcję dodatkowych informacji
  Widget _buildAdditionalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.neutralPrimary.withOpacity(0.05),
            AppTheme.neutralBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.neutralPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.neutralPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.more_horiz,
                  color: AppTheme.neutralPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Dodatkowe Informacje',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.neutralPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...widget.product.additionalInfo.entries
              .where((entry) => !_isSpecialField(entry.key))
              .map(
            (entry) => _buildDetailRow(
              _formatFieldName(entry.key),
              entry.value.toString(),
            ),
          ),
        ],
      ),
    );
  }

  /// Buduje chip z amenity dla apartamentów
  Widget _buildAmenityChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.successPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.successPrimary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.successPrimary, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.successPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Sprawdza czy pole jest specjalne (już wyświetlone w sekcji specyficznej)
  bool _isSpecialField(String fieldName) {
    const specialFields = [
      'borrower',
      'creditorCompany',
      'collateral',
      'status',
      'apartmentNumber',
      'building',
      'area',
      'roomCount',
      'floor',
      'apartmentType',
      'pricePerSquareMeter',
      'address',
      'hasBalcony',
      'hasParkingSpace',
      'hasStorage',
    ];
    return specialFields.contains(fieldName);
  }

  /// Formatuje nazwę pola dla wyświetlenia
  String _formatFieldName(String fieldName) {
    // Mapa tłumaczeń dla polskich nazw pól
    const translations = {
      'nazwa_produktu': 'Nazwa produktu',
      'typ_produktu': 'Typ produktu',
      'kwota_inwestycji': 'Kwota inwestycji',
      'data_utworzenia': 'Data utworzenia',
      'ostatnia_aktualizacja': 'Ostatnia aktualizacja',
      'oprocentowanie': 'Oprocentowanie',
      'data_zapadalnosci': 'Data zapadalności',
      'liczba_udzialow': 'Liczba udziałów',
      'cena_za_udzial': 'Cena za udział',
      'nazwa_firmy': 'Nazwa firmy',
      'waluta': 'Waluta',
      'projekt_nazwa': 'Nazwa projektu',
      'numer_apartamentu': 'Numer apartamentu',
      'powierzchnia': 'Powierzchnia',
      'liczba_pokoi': 'Liczba pokoi',
      'pietro': 'Piętro',
      'typ_apartamentu': 'Typ apartamentu',
      'cena_za_m2': 'Cena za m²',
      'balkon': 'Balkon',
      'miejsce_parkingowe': 'Miejsce parkingowe',
      'komorka': 'Komórka',
      'adres': 'Adres',
      'pozyczkobiorca': 'Pożyczkobiorca',
      'wierzyciel_spolka': 'Wierzyciel spółka',
      'zabezpieczenie': 'Zabezpieczenie',
      'status_pozyczki': 'Status pożyczki',
    };

    return translations[fieldName] ?? 
           fieldName.replaceAll('_', ' ').toUpperCase()[0] + 
           fieldName.replaceAll('_', ' ').substring(1);
  }

  /// Formatuje datę
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
