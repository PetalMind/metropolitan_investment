import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models_and_services.dart'; // Centralized import
import '../premium_loading_widget.dart';
import '../premium_error_widget.dart';
import 'product_details_service.dart';

/// Zakładka z inwestorami produktu
class ProductInvestorsTab extends StatefulWidget {
  final UnifiedProduct product;
  final List<InvestorSummary> investors;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;

  const ProductInvestorsTab({
    super.key,
    required this.product,
    required this.investors,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
  });

  @override
  State<ProductInvestorsTab> createState() => _ProductInvestorsTabState();
}

class _ProductInvestorsTabState extends State<ProductInvestorsTab>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final ProductDetailsService _service = ProductDetailsService();
  String _sortBy = 'capital'; // 'capital', 'name', 'investments'
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    if (!widget.isLoading) {
      _fadeController.forward();
    }
  }

  @override
  void didUpdateWidget(ProductInvestorsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLoading && oldWidget.isLoading) {
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: PremiumLoadingWidget(message: 'Ładowanie inwestorów...'),
      );
    }

    if (widget.error != null) {
      return PremiumErrorWidget(
        error: widget.error!,
        onRetry: widget.onRefresh,
      );
    }

    if (widget.investors.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          // Header z podsumowaniem i kontrolkami sortowania
          SliverToBoxAdapter(child: _buildHeader()),

          // Lista inwestorów jako sliver
          _buildInvestorsSliver(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.05),
            AppTheme.backgroundSecondary.withOpacity(0.3),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderPrimary.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Podsumowanie
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.people, color: AppTheme.bondsColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inwestorzy Produktu',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.secondaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.investors.length} ${_getInvestorText(widget.investors.length)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Przycisk odświeżania
              IconButton(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  foregroundColor: AppTheme.bondsColor,
                ),
                tooltip: 'Odśwież listę',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Statystyki
          _buildStatistics(),

          const SizedBox(height: 16),

          // Kontrolki sortowania
          _buildSortingControls(),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    // 📊 STATYSTYKI INWESTORÓW - bardziej odpowiednie dla tej zakładki

    // Suma wszystkich inwestycji (nie wartość, ale liczba)
    final totalInvestmentCount = widget.investors.fold(
      0,
      (sum, investor) => sum + _getProductInvestmentCount(investor),
    );

    // Liczba aktywnych inwestorów (mających inwestycje w tym produkcie)
    final activeInvestorsCount = widget.investors
        .where((investor) => _getProductInvestmentCount(investor) > 0)
        .length;

    // Średnia liczba inwestycji na inwestora
    final averageInvestmentsPerInvestor = activeInvestorsCount > 0
        ? (totalInvestmentCount / activeInvestorsCount).toStringAsFixed(1)
        : '0.0';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Suma inwestycji',
            totalInvestmentCount.toString(),
            Icons.trending_up,
            AppTheme.infoPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Aktywni inwestorzy',
            activeInvestorsCount.toString(),
            Icons.people,
            AppTheme.successPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Śr. inwes./osobę',
            averageInvestmentsPerInvestor,
            Icons.analytics,
            AppTheme.warningPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSortingControls() {
    return Row(
      children: [
        Text(
          'Sortuj według:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        _buildSortChip('Kapitału', 'capital'),
        const SizedBox(width: 8),
        _buildSortChip('Nazwy', 'name'),
        const SizedBox(width: 8),
        _buildSortChip('Inwestycji', 'investments'),
        const Spacer(),
        IconButton(
          onPressed: () {
            setState(() {
              _sortAscending = !_sortAscending;
            });
          },
          icon: Icon(
            _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
            size: 20,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.secondaryGold.withOpacity(0.1),
            foregroundColor: AppTheme.secondaryGold,
            padding: const EdgeInsets.all(8),
            minimumSize: const Size(32, 32),
          ),
          tooltip: _sortAscending ? 'Rosnąco' : 'Malejąco',
        ),
      ],
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.secondaryGold.withOpacity(0.15)
              : AppTheme.surfaceElevated.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.secondaryGold.withOpacity(0.5)
                : AppTheme.borderPrimary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected ? AppTheme.secondaryGold : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildInvestorsSliver() {
    final sortedInvestors = _getSortedInvestors();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return TweenAnimationBuilder(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  margin: const EdgeInsets.only(
                    bottom: 12,
                    left: 16,
                    right: 16,
                  ),
                  child: _buildInvestorCard(sortedInvestors[index], index),
                ),
              ),
            );
          },
        );
      }, childCount: sortedInvestors.length),
    );
  }

  Widget _buildInvestorCard(InvestorSummary investor, int index) {
    final isTopInvestor = index < 3;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isTopInvestor
              ? [
                  AppTheme.secondaryGold.withOpacity(0.05),
                  AppTheme.backgroundSecondary.withOpacity(0.8),
                ]
              : [
                  AppTheme.backgroundSecondary.withOpacity(0.6),
                  AppTheme.surfaceCard,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTopInvestor
              ? AppTheme.secondaryGold.withOpacity(0.3)
              : AppTheme.borderPrimary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          if (isTopInvestor)
            BoxShadow(
              color: AppTheme.secondaryGold.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildInvestorAvatar(investor, index),
        title: _buildInvestorTitle(investor),
        subtitle: _buildInvestorSubtitle(investor),
        trailing: _buildInvestorTrailing(investor),
        onTap: () => _showInvestorDetails(investor),
      ),
    );
  }

  Widget _buildInvestorAvatar(InvestorSummary investor, int index) {
    final isTopInvestor = index < 3;

    return Stack(
      children: [
        CircleAvatar(
          backgroundColor: isTopInvestor
              ? AppTheme.secondaryGold.withOpacity(0.2)
              : AppTheme.primaryColor.withOpacity(0.15),
          radius: 24,
          child: Icon(
            Icons.person,
            color: isTopInvestor
                ? AppTheme.secondaryGold
                : AppTheme.primaryColor,
            size: 24,
          ),
        ),
        if (isTopInvestor)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppTheme.secondaryGold,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInvestorTitle(InvestorSummary investor) {
    return Row(
      children: [
        Expanded(
          child: Text(
            investor.client.name.isNotEmpty
                ? investor.client.name
                : 'Brak nazwy',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (investor.client.votingStatus != VotingStatus.undecided)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getVotingStatusColor(
                investor.client.votingStatus,
              ).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getVotingStatusColor(
                  investor.client.votingStatus,
                ).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              _getVotingStatusText(investor.client.votingStatus),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _getVotingStatusColor(investor.client.votingStatus),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInvestorSubtitle(InvestorSummary investor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        if (investor.client.email.isNotEmpty)
          Row(
            children: [
              Icon(
                Icons.email_outlined,
                size: 14,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  investor.client.email,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        if (investor.client.phone.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                size: 14,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                investor.client.phone,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
              ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.infoPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_getProductInvestmentCount(investor)} ${_getInvestmentText(_getProductInvestmentCount(investor))}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.infoPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvestorTrailing(InvestorSummary investor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.gainPrimary.withOpacity(0.8),
                AppTheme.gainPrimary,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gainPrimary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _service.formatCurrency(_getProductCapital(investor)),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Icon(
          Icons.arrow_forward_ios,
          size: 12,
          color: AppTheme.textTertiary.withOpacity(0.6),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.backgroundSecondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.people_outline,
                  size: 60,
                  color: AppTheme.textTertiary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Brak inwestorów',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Nie znaleziono inwestorów dla tego produktu.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildDebugInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.infoPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppTheme.infoPrimary),
              const SizedBox(width: 8),
              Text(
                'Informacje debugowe:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.infoPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDebugRow('Nazwa', widget.product.name),
          _buildDebugRow('Typ', widget.product.productType.displayName),
          _buildDebugRow('Kolekcja', widget.product.productType.collectionName),
        ],
      ),
    );
  }

  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        '$label: "$value"',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.textTertiary,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  List<InvestorSummary> _getSortedInvestors() {
    final investors = List<InvestorSummary>.from(widget.investors);

    investors.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'name':
          comparison = a.client.name.compareTo(b.client.name);
          break;
        case 'investments':
          comparison = a.investmentCount.compareTo(b.investmentCount);
          break;
        case 'capital':
        default:
          comparison = a.viableRemainingCapital.compareTo(
            b.viableRemainingCapital,
          );
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });

    return investors;
  }

  void _showInvestorDetails(InvestorSummary investor) {
    // Zamknij dialog produktu i przejdź do analityki inwestorów
    Navigator.of(context).pop(); // Zamknij dialog produktu

    // Przejdź do analityki inwestorów z wyszukiwaniem imienia inwestora
    context.go(
      '/investor-analytics?search=${Uri.encodeComponent(investor.client.name)}',
    );
  }

  String _getInvestorText(int count) {
    if (count == 1) return 'inwestor';
    if (count >= 2 && count <= 4) return 'inwestorów';
    return 'inwestorów';
  }

  String _getInvestmentText(int count) {
    if (count == 1) return 'inwestycja';
    if (count >= 2 && count <= 4) return 'inwestycje';
    return 'inwestycji';
  }

  /// Zwraca liczbę inwestycji klienta w tym konkretnym produkcie
  int _getProductInvestmentCount(InvestorSummary investor) {
    print(
      '🔍 [_getProductInvestmentCount] Sprawdzam dla inwestora: ${investor.client.name}',
    );
    print(
      '🔍 [_getProductInvestmentCount] - Szukany produkt: "${widget.product.name}"',
    );
    print(
      '🔍 [_getProductInvestmentCount] - Szukane ID: "${widget.product.id}"',
    );
    print(
      '🔍 [_getProductInvestmentCount] - Inwestycje klienta (${investor.investments.length}):',
    );

    // Grupa inwestycje po ID żeby wyeliminować duplikaty
    final uniqueInvestments = <String, Investment>{};

    for (final investment in investor.investments) {
      final key = investment.id.isNotEmpty
          ? investment.id
          : '${investment.productName}_${investment.investmentAmount}_${investment.clientId}';
      uniqueInvestments[key] = investment;
    }

    final uniqueInvestmentsList = uniqueInvestments.values.toList();

    print(
      '🔍 [_getProductInvestmentCount] - Unikalne inwestycje (${uniqueInvestmentsList.length}):',
    );

    for (int i = 0; i < uniqueInvestmentsList.length; i++) {
      final inv = uniqueInvestmentsList[i];
      print(
        '  $i: productName="${inv.productName}", productId="${inv.productId}", amount=${inv.investmentAmount}',
      );
    }

    // Sprawdź po ID produktu (uwaga na "null" jako string!)
    if (widget.product.id.isNotEmpty) {
      final countById = uniqueInvestmentsList
          .where(
            (investment) =>
                investment.productId != null &&
                investment.productId!.isNotEmpty &&
                investment.productId != "null" && // Wyklucz "null" jako string
                investment.productId == widget.product.id,
          )
          .length;

      print('🔍 [_getProductInvestmentCount] - Znaleziono po ID: $countById');

      if (countById > 0) {
        return countById;
      }
    }

    // Fallback: sprawdź po nazwie produktu (na unikalnych inwestycjach)
    final countByName = uniqueInvestmentsList
        .where(
          (investment) =>
              investment.productName.trim().toLowerCase() ==
              widget.product.name.trim().toLowerCase(),
        )
        .length;

    print(
      '🔍 [_getProductInvestmentCount] - Znaleziono po nazwie: $countByName',
    );

    return countByName;
  }

  /// Zwraca kapitał pozostały klienta w tym konkretnym produkcie
  double _getProductCapital(InvestorSummary investor) {
    // Grupa inwestycje po ID żeby wyeliminować duplikaty (podobnie jak w _getProductInvestmentCount)
    final uniqueInvestments = <String, Investment>{};

    for (final investment in investor.investments) {
      final key = investment.id.isNotEmpty
          ? investment.id
          : '${investment.productName}_${investment.investmentAmount}_${investment.clientId}';
      uniqueInvestments[key] = investment;
    }

    final uniqueInvestmentsList = uniqueInvestments.values.toList();

    // Sprawdź po ID produktu (jeśli dostępne)
    if (widget.product.id.isNotEmpty) {
      final matchingInvestments = uniqueInvestmentsList.where(
        (investment) =>
            investment.productId != null &&
            investment.productId!.isNotEmpty &&
            investment.productId != "null" && // Wyklucz "null" jako string
            investment.productId == widget.product.id,
      );

      if (matchingInvestments.isNotEmpty) {
        return matchingInvestments.fold(
          0.0,
          (sum, investment) => sum + investment.remainingCapital,
        );
      }
    }

    // Fallback: sprawdź po nazwie produktu
    return uniqueInvestmentsList
        .where(
          (investment) =>
              investment.productName.trim().toLowerCase() ==
              widget.product.name.trim().toLowerCase(),
        )
        .fold(0.0, (sum, investment) => sum + investment.remainingCapital);
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return AppTheme.successPrimary;
      case VotingStatus.abstain:
        return AppTheme.warningPrimary;
      case VotingStatus.no:
        return AppTheme.errorPrimary;
      case VotingStatus.undecided:
        return AppTheme.neutralPrimary;
    }
  }

  String _getVotingStatusText(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return 'TAK';
      case VotingStatus.abstain:
        return 'WSTRZYMUJE';
      case VotingStatus.no:
        return 'NIE';
      case VotingStatus.undecided:
        return 'NIEZDECYD.';
    }
  }
}
