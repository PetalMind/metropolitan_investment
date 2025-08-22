import 'package:flutter/material.dart';
import '../../models_and_services.dart';

/// 🎯 Main Investor Views Container
///
/// Manages all three view modes for investor display:
/// - Cards: Visual grid with comprehensive details
/// - List: Expandable cards with detailed financial grids
/// - Table: Professional table with all metrics visible
class InvestorViewsContainer extends StatelessWidget {
  final List<InvestorSummary> investors;
  final List<InvestorSummary> majorityHolders;
  final double totalViableCapital;
  final ViewMode currentViewMode;
  final bool isTablet;
  final bool isLoading;
  final String? error;
  final Function(InvestorSummary) onInvestorTap;
  
  // Multi-selection parameters
  final bool isSelectionMode;
  final Set<String> selectedInvestorIds;
  final Function(String) onInvestorSelectionToggle;

  const InvestorViewsContainer({
    super.key,
    required this.investors,
    required this.majorityHolders,
    required this.totalViableCapital,
    required this.currentViewMode,
    required this.isTablet,
    required this.isLoading,
    this.error,
    required this.onInvestorTap,
    this.isSelectionMode = false,
    this.selectedInvestorIds = const <String>{},
    required this.onInvestorSelectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingSliver();
    }

    if (error != null) {
      return _buildErrorSliver(context);
    }

    // ✅ WSZYSTKIE 3 WIDOKI Z PEŁNYMI METRYKAMI FINANSOWYMI
    switch (currentViewMode) {
      case ViewMode.cards:
        return InvestorCardsWidget(
          investors: investors,
          majorityHolders: majorityHolders,
          totalViableCapital: totalViableCapital,
          isTablet: isTablet,
          onInvestorTap: onInvestorTap,
          isSelectionMode: isSelectionMode,
          selectedInvestorIds: selectedInvestorIds,
          onInvestorSelectionToggle: onInvestorSelectionToggle,
        );

      case ViewMode.list:
        return InvestorListWidget(
          investors: investors,
          majorityHolders: majorityHolders,
          totalViableCapital: totalViableCapital,
          isTablet: isTablet,
          onInvestorTap: onInvestorTap,
          onExportInvestor: (investor) => _exportInvestor(context, investor),
          isSelectionMode: isSelectionMode,
          selectedInvestorIds: selectedInvestorIds,
          onInvestorSelectionToggle: onInvestorSelectionToggle,
        );

      case ViewMode.table:
        return SliverToBoxAdapter(
          child: InvestorTableWidget(
            investors: investors,
            majorityHolders: majorityHolders,
            totalViableCapital: totalViableCapital,
            isTablet: isTablet,
            onInvestorTap: onInvestorTap,
            onExportInvestor: (investor) => _exportInvestor(context, investor),
            isSelectionMode: isSelectionMode,
            selectedInvestorIds: selectedInvestorIds,
            onInvestorSelectionToggle: onInvestorSelectionToggle,
          ),
        );
    }
  }

  Widget _buildLoadingSliver() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppTheme.secondaryGold),
            ),
            const SizedBox(height: 16),
            Text(
              'Ładowanie danych inwestorów...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Przygotowywanie wszystkich metryk finansowych',
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSliver(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Container(
          margin: EdgeInsets.all(isTablet ? 32 : 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.errorPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.errorPrimary.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppTheme.errorPrimary,
              ),
              const SizedBox(height: 16),
              Text(
                'Błąd ładowania danych',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error ?? 'Nieznany błąd podczas ładowania danych inwestorów',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _retryLoading(context),
                icon: Icon(Icons.refresh_rounded),
                label: Text('Spróbuj ponownie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: AppTheme.textOnPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportInvestor(BuildContext context, InvestorSummary investor) {
    InvestorExportHelper.exportToClipboard(context, investor);
  }

  void _retryLoading(BuildContext context) {
    // This would typically call a callback to retry loading
    // For now, we'll just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔄 Odświeżanie danych...'),
        backgroundColor: AppTheme.infoPrimary,
      ),
    );
  }
}

/// 📊 View Mode Enum for different display options
enum ViewMode {
  cards('Karty', Icons.view_agenda_rounded),
  list('Lista', Icons.view_list_rounded),
  table('Tabela', Icons.table_view_rounded);

  const ViewMode(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
}

/// 🎛️ View Mode Selector Widget
///
/// Provides a clean way to switch between different investor view modes
class ViewModeSelector extends StatelessWidget {
  final ViewMode currentMode;
  final Function(ViewMode) onModeChanged;
  final bool isTablet;

  const ViewModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ViewMode>(
      icon: Icon(currentMode.icon, color: AppTheme.textSecondary),
      tooltip: 'Zmień widok (${currentMode.displayName})',
      itemBuilder: (context) => ViewMode.values.map((mode) {
        return PopupMenuItem<ViewMode>(
          value: mode,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  mode.icon,
                  color: mode == currentMode
                      ? AppTheme.secondaryGold
                      : AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.displayName,
                        style: TextStyle(
                          color: mode == currentMode
                              ? AppTheme.secondaryGold
                              : AppTheme.textPrimary,
                          fontWeight: mode == currentMode
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      Text(
                        _getViewModeDescription(mode),
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (mode == currentMode) ...[
                  Icon(
                    Icons.check_rounded,
                    color: AppTheme.secondaryGold,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
      onSelected: onModeChanged,
    );
  }

  String _getViewModeDescription(ViewMode mode) {
    switch (mode) {
      case ViewMode.cards:
        return 'Wizualne karty z metrykami';
      case ViewMode.list:
        return 'Rozwijane szczegóły finansowe';
      case ViewMode.table:
        return 'Pełna tabela z wszystkimi danymi';
    }
  }
}
