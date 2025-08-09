import 'package:flutter/material.dart';
import '../../models/unified_product.dart';
import '../../models/investor_summary.dart';
import '../../theme/app_theme.dart';
import 'product_overview_tab.dart';
import 'product_investors_tab.dart';
import 'product_analytics_tab.dart';

/// Widget zawierający tab bar i zawartość zakładek
class ProductDetailsTabs extends StatelessWidget {
  final UnifiedProduct product;
  final TabController tabController;
  final List<InvestorSummary> investors;
  final bool isLoadingInvestors;
  final String? investorsError;
  final VoidCallback onRefreshInvestors;

  const ProductDetailsTabs({
    super.key,
    required this.product,
    required this.tabController,
    required this.investors,
    required this.isLoadingInvestors,
    required this.investorsError,
    required this.onRefreshInvestors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        _buildTabBar(),

        // Tab Bar View
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              ProductOverviewTab(product: product),
              ProductInvestorsTab(
                product: product,
                investors: investors,
                isLoading: isLoadingInvestors,
                error: investorsError,
                onRefresh: onRefreshInvestors,
              ),
              ProductAnalyticsTab(
                product: product,
                investors: investors,
                isLoading: isLoadingInvestors,
                error: investorsError,
                onRefresh: onRefreshInvestors,
              ),
            ],
          ),
        ),
      ],
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
        controller: tabController,
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
                isLoadingInvestors
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
                    : Text('Inwestorzy (${investors.length})'),
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
        labelColor: AppTheme.apartmentsBackground,
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
}
