import 'package:flutter/material.dart';
import '../../models_and_services.dart';
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
  final bool isEditModeEnabled; // ⭐ NOWE: Stan edycji

  const ProductDetailsTabs({
    super.key,
    required this.product,
    required this.tabController,
    required this.investors,
    required this.isLoadingInvestors,
    required this.investorsError,
    required this.onRefreshInvestors,
    this.isEditModeEnabled = false, // ⭐ NOWE: Stan edycji (domyślnie false)
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        _buildTabBar(context),

        // Tab Bar View
        Expanded(
          child: TabBarView(
            controller: tabController,
            physics: isEditModeEnabled 
                ? const NeverScrollableScrollPhysics() // ⭐ NOWE: Zablokuj przesuwanie w trybie edycji
                : null, // Domyślne zachowanie gdy tryb edycji wyłączony
            children: [
              ProductOverviewTab(product: product),
              ProductInvestorsTab(
                product: product,
                investors: investors,
                isLoading: isLoadingInvestors,
                error: investorsError,
                onRefresh: onRefreshInvestors,
                isEditModeEnabled:
                    isEditModeEnabled, // ⭐ NOWE: Przekazanie stanu edycji
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

  Widget _buildTabBar(BuildContext context) {
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
        // ⭐ NOWE: Wyłącz interakcję z zabami w trybie edycji (tylko tab "Inwestorzy" dostępny)
        onTap: isEditModeEnabled ? (index) {
          if (index != 1) { // Tab "Inwestorzy" ma index 1
            // Pokaż komunikat i wróć do tab "Inwestorzy"
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('W trybie edycji dostępna jest tylko zakładka "Inwestorzy"'),
                  ],
                ),
                backgroundColor: AppTheme.warningPrimary,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
            // Wróć do tab "Inwestorzy"
            tabController.animateTo(1);
          }
        } : null,
        tabs: [
          // ⭐ Tab "Szczegóły" - zablokowany w trybie edycji
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline, 
                  size: 18,
                  color: isEditModeEnabled 
                      ? AppTheme.textTertiary.withOpacity(0.5) 
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Szczegóły',
                  style: isEditModeEnabled 
                      ? TextStyle(
                          color: AppTheme.textTertiary.withOpacity(0.5),
                          decoration: TextDecoration.lineThrough,
                        )
                      : null,
                ),
                if (isEditModeEnabled) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.lock_outline, 
                    size: 14,
                    color: AppTheme.textTertiary.withOpacity(0.5),
                  ),
                ],
              ],
            ),
          ),
          
          // ⭐ Tab "Inwestorzy" - zawsze dostępny, podświetlony w trybie edycji
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_outline, 
                  size: 18,
                  color: isEditModeEnabled ? AppTheme.warningPrimary : null,
                ),
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
                    : Text(
                        'Inwestorzy (${investors.length})',
                        style: isEditModeEnabled 
                            ? TextStyle(
                                color: AppTheme.warningPrimary,
                                fontWeight: FontWeight.bold,
                              )
                            : null,
                      ),
                if (isEditModeEnabled) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit, 
                    size: 14,
                    color: AppTheme.warningPrimary,
                  ),
                ],
              ],
            ),
          ),
          
          // ⭐ Tab "Analiza" - zablokowany w trybie edycji
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.analytics_outlined, 
                  size: 18,
                  color: isEditModeEnabled 
                      ? AppTheme.textTertiary.withOpacity(0.5) 
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Analiza',
                  style: isEditModeEnabled 
                      ? TextStyle(
                          color: AppTheme.textTertiary.withOpacity(0.5),
                          decoration: TextDecoration.lineThrough,
                        )
                      : null,
                ),
                if (isEditModeEnabled) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.lock_outline, 
                    size: 14,
                    color: AppTheme.textTertiary.withOpacity(0.5),
                  ),
                ],
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
