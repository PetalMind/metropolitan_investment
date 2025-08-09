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
          color: AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
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
        gradient: AppTheme.getPerformanceCardDecoration(
          widget.product.totalValue - widget.product.investmentAmount,
        ).gradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Przycisk zamknięcia
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: AppTheme.textOnPrimary,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.textOnPrimary.withOpacity(0.1),
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
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
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.getProductTypeColor(
                          widget.product.productType.collectionName,
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.getProductTypeColor(
                            widget.product.productType.collectionName,
                          ).withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.getProductTypeColor(
                              widget.product.productType.collectionName,
                            ).withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getProductIcon(widget.product.productType),
                        color: AppTheme.getProductTypeColor(
                          widget.product.productType.collectionName,
                        ),
                        size: 28,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 16),

              // Informacje o produkcie
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.product.productType.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryGold,
                          fontWeight: FontWeight.w600,
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

          const SizedBox(height: 16),

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.product.status.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
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
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Wartość',
            value: _formatCurrency(widget.product.totalValue),
            subtitle: 'PLN',
            icon: Icons.account_balance_wallet,
            color: AppTheme.secondaryGold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Zysk/Strata',
            value: _formatCurrency(profitLoss),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundPrimary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
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
        color: AppTheme.backgroundSecondary,
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 6),
                const Text('Szczegóły'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_outline, size: 18),
                const SizedBox(width: 6),
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
                const SizedBox(width: 6),
                const Text('Analiza'),
              ],
            ),
          ),
        ],
        labelColor: AppTheme.secondaryGold,
        unselectedLabelColor: AppTheme.textTertiary,
        indicatorColor: AppTheme.secondaryGold,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
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
          // Szczegółowe informacje
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
                  'Szczegóły Produktu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Typ', widget.product.productType.displayName),
                _buildDetailRow(
                  'Status',
                  widget.product.isActive ? 'Aktywny' : 'Nieaktywny',
                ),
                _buildDetailRow('Waluta', widget.product.currency ?? 'PLN'),
                if (widget.product.interestRate != null)
                  _buildDetailRow(
                    'Oprocentowanie',
                    '${widget.product.interestRate!}%',
                  ),
                if (widget.product.maturityDate != null)
                  _buildDetailRow(
                    'Data zapadalności',
                    widget.product.maturityDate!.toString().substring(0, 10),
                  ),
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
                  _buildDetailRow('Firma', widget.product.companyName!),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Opis produktu
          if (widget.product.description.isNotEmpty) ...[
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
                    'Opis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.product.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Dodatkowe informacje
          if (widget.product.additionalInfo.isNotEmpty) ...[
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
                    'Dodatkowe Informacje',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.product.additionalInfo.entries.map(
                    (entry) =>
                        _buildDetailRow(entry.key, entry.value.toString()),
                  ),
                ],
              ),
            ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
