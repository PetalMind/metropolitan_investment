import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// 🎯 ENHANCED FLOATING ACTION BUTTON
/// Zaawansowany FAB z animacjami i interaktywnością
class EnhancedFloatingActionButton extends StatelessWidget {
  final Animation<double> scaleAnimation;
  final bool isFilterVisible;
  final VoidCallback onToggleFilters;

  const EnhancedFloatingActionButton({
    super.key,
    required this.scaleAnimation,
    required this.isFilterVisible,
    required this.onToggleFilters,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: scaleAnimation,
      child: FloatingActionButton.extended(
        onPressed: onToggleFilters,
        backgroundColor: AppTheme.secondaryGold,
        foregroundColor: AppTheme.backgroundPrimary,
        icon: AnimatedRotation(
          turns: isFilterVisible ? 0.5 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: const Icon(Icons.tune),
        ),
        label: Text(isFilterVisible ? 'Ukryj filtry' : 'Filtry'),
      ),
    );
  }
}

/// 📱 LOADING VIEW
/// Elegant loading state z animacjami
class EnhancedLoadingView extends StatelessWidget {
  final Animation<double> opacityAnimation;

  const EnhancedLoadingView({super.key, required this.opacityAnimation});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.secondaryGold),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: opacityAnimation,
            child: const Text(
              'Ładowanie zaawansowanej analityki...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// ❌ ERROR VIEW
/// Comprehensive error handling z fallback options
class EnhancedErrorView extends StatelessWidget {
  final String? error;
  final bool usePremiumMode;
  final VoidCallback onRefresh;
  final VoidCallback onToggleMode;

  const EnhancedErrorView({
    super.key,
    required this.error,
    required this.usePremiumMode,
    required this.onRefresh,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Wystąpił błąd',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error ?? 'Nieznany błąd',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Spróbuj ponownie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryGold,
                    foregroundColor: AppTheme.backgroundPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: onToggleMode,
                  icon: Icon(usePremiumMode ? Icons.cloud_off : Icons.cloud),
                  label: Text(usePremiumMode ? 'Tryb lokalny' : 'Tryb premium'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.secondaryGold,
                    side: const BorderSide(color: AppTheme.secondaryGold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔄 LOAD MORE BUTTON
/// Elegant load more functionality
class LoadMoreButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onLoadMore;

  const LoadMoreButton({
    super.key,
    required this.isLoading,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onLoadMore,
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.expand_more),
          label: Text(isLoading ? 'Ładowanie...' : 'Załaduj więcej'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.surfaceCard,
            foregroundColor: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
