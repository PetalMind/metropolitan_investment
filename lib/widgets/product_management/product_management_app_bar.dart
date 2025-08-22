import 'package:flutter/material.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme.dart';

/// AppBar dla zarządzania produktami z funkcjonalnością email i selekcji
class ProductManagementAppBar extends StatelessWidget {
  final AnimationController fadeController;
  final Animation<double> fadeAnimation;
  final bool isSelectionMode;
  final int selectedProductsCount;
  final bool useOptimizedMode;
  final bool showDeduplicatedView;
  final bool showStatistics;
  final bool isRefreshing;
  final ViewMode viewMode;
  final int filteredDeduplicatedProductsCount;
  final int deduplicatedProductsCount;
  final int filteredProductsCount;
  final int allProductsCount;

  final VoidCallback onEmailPressed;
  final VoidCallback onCancelSelection;
  final VoidCallback onStartSelection;
  final VoidCallback onToggleOptimizedMode;
  final VoidCallback onToggleDeduplicatedView;
  final VoidCallback onToggleStatistics;
  final VoidCallback onToggleViewMode;
  final VoidCallback? onRefreshData;

  const ProductManagementAppBar({
    super.key,
    required this.fadeController,
    required this.fadeAnimation,
    required this.isSelectionMode,
    required this.selectedProductsCount,
    required this.useOptimizedMode,
    required this.showDeduplicatedView,
    required this.showStatistics,
    required this.isRefreshing,
    required this.viewMode,
    required this.filteredDeduplicatedProductsCount,
    required this.deduplicatedProductsCount,
    required this.filteredProductsCount,
    required this.allProductsCount,
    required this.onEmailPressed,
    required this.onCancelSelection,
    required this.onStartSelection,
    required this.onToggleOptimizedMode,
    required this.onToggleDeduplicatedView,
    required this.onToggleStatistics,
    required this.onToggleViewMode,
    this.onRefreshData,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.backgroundPrimary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FadeTransition(
                    opacity: fadeAnimation,
                    child: Text(
                      isSelectionMode
                          ? 'Wybrano produktów: $selectedProductsCount'
                          : 'Zarządzanie Produktami',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppTheme.textOnPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FadeTransition(
                    opacity: fadeAnimation,
                    child: Text(
                      showDeduplicatedView
                          ? '$filteredDeduplicatedProductsCount z $deduplicatedProductsCount unikalnych produktów'
                          : '$filteredProductsCount z $allProductsCount produktów',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textOnPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: _buildActions(),
    );
  }

  List<Widget> _buildActions() {
    return [
      // Email functionality w trybie selekcji
      if (isSelectionMode) ...[
        IconButton(
          icon: Icon(
            Icons.email,
            color: selectedProductsCount > 0
                ? AppTheme.secondaryGold
                : AppTheme.textSecondary,
          ),
          onPressed: selectedProductsCount > 0 ? onEmailPressed : null,
          tooltip: 'Wyślij email do wybranych ($selectedProductsCount)',
        ),
        IconButton(
          icon: const Icon(Icons.close, color: AppTheme.secondaryGold),
          onPressed: onCancelSelection,
          tooltip: 'Anuluj selekcję',
        ),
      ] else ...[
        // Przycisk rozpoczęcia selekcji email
        IconButton(
          icon: const Icon(Icons.email, color: AppTheme.secondaryGold),
          onPressed: onStartSelection,
          tooltip: 'Wybierz produkty do email',
        ),
      ],

      // 🚀 Przełącznik trybu optymalizacji
      IconButton(
        icon: Icon(
          useOptimizedMode ? Icons.rocket_launch : Icons.speed,
          color: AppTheme.secondaryGold,
        ),
        onPressed: onToggleOptimizedMode,
        tooltip: useOptimizedMode
            ? 'Przełącz na tryb legacy'
            : 'Przełącz na tryb zoptymalizowany',
      ),

      // Przełącznik deduplikacji
      IconButton(
        icon: Icon(
          showDeduplicatedView ? Icons.filter_vintage : Icons.all_inclusive,
          color: AppTheme.secondaryGold,
        ),
        onPressed: onToggleDeduplicatedView,
        tooltip: showDeduplicatedView
            ? 'Pokaż wszystkie inwestycje'
            : 'Pokaż produkty unikalne',
      ),

      // Przełącznik statystyk
      IconButton(
        icon: Icon(
          showStatistics ? Icons.analytics_outlined : Icons.analytics,
          color: AppTheme.secondaryGold,
        ),
        onPressed: onToggleStatistics,
        tooltip: showStatistics ? 'Ukryj statystyki' : 'Pokaż statystyki',
      ),

      // Przełącznik widoku
      IconButton(
        icon: Icon(
          viewMode == ViewMode.grid ? Icons.view_list : Icons.grid_view,
          color: AppTheme.secondaryGold,
        ),
        onPressed: onToggleViewMode,
        tooltip: 'Zmień widok',
      ),

      // Odśwież dane
      IconButton(
        icon: Icon(
          isRefreshing ? Icons.hourglass_empty : Icons.refresh,
          color: AppTheme.secondaryGold,
        ),
        onPressed: isRefreshing ? null : onRefreshData,
        tooltip: 'Odśwież dane',
      ),
    ];
  }
}

enum ViewMode { grid, list }
