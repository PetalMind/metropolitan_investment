import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Widget kontroli paginacji dla list inwestorów
class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final int pageSize;
  final int totalItems;
  final Function(int) onPageChanged;
  final Function(int) onPageSizeChanged;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.pageSize,
    required this.totalItems,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 768;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: isTablet ? _buildTabletPagination() : _buildMobilePagination(),
    );
  }

  Widget _buildTabletPagination() {
    return Row(
      children: [
        // Informacje o stronie
        Expanded(
          child: Text(
            'Strona ${currentPage + 1} z $totalPages • Łącznie $totalItems elementów',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ),

        // Nawigacja stron
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: hasPreviousPage ? () => onPageChanged(0) : null,
              icon: const Icon(Icons.first_page),
              tooltip: 'Pierwsza strona',
              style: IconButton.styleFrom(
                foregroundColor: AppTheme.secondaryGold,
                disabledForegroundColor: AppTheme.textTertiary,
              ),
            ),
            IconButton(
              onPressed: hasPreviousPage
                  ? () => onPageChanged(currentPage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Poprzednia strona',
              style: IconButton.styleFrom(
                foregroundColor: AppTheme.secondaryGold,
                disabledForegroundColor: AppTheme.textTertiary,
              ),
            ),

            // Selector stron (dla małej liczby stron)
            if (totalPages <= 7) _buildPageNumbers(),

            IconButton(
              onPressed: hasNextPage
                  ? () => onPageChanged(currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Następna strona',
              style: IconButton.styleFrom(
                foregroundColor: AppTheme.secondaryGold,
                disabledForegroundColor: AppTheme.textTertiary,
              ),
            ),
            IconButton(
              onPressed: hasNextPage
                  ? () => onPageChanged(totalPages - 1)
                  : null,
              icon: const Icon(Icons.last_page),
              tooltip: 'Ostatnia strona',
              style: IconButton.styleFrom(
                foregroundColor: AppTheme.secondaryGold,
                disabledForegroundColor: AppTheme.textTertiary,
              ),
            ),
          ],
        ),

        const SizedBox(width: 16),

        // Selektor rozmiaru strony
        Row(
          children: [
            const Text(
              'Rozmiar:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderSecondary, width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: pageSize,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  dropdownColor: AppTheme.surfaceCard,
                  items: [20, 50, 100, 250]
                      .map(
                        (size) =>
                            DropdownMenuItem(value: size, child: Text('$size')),
                      )
                      .toList(),
                  onChanged: (newSize) {
                    if (newSize != null) {
                      onPageSizeChanged(newSize);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobilePagination() {
    return Column(
      children: [
        // Informacje o stronie
        Text(
          'Strona ${currentPage + 1} z $totalPages',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Łącznie $totalItems elementów',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),

        // Nawigacja
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: hasPreviousPage
                  ? () => onPageChanged(currentPage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Poprzednia strona',
              style: IconButton.styleFrom(
                foregroundColor: AppTheme.secondaryGold,
                disabledForegroundColor: AppTheme.textTertiary,
                backgroundColor: AppTheme.backgroundSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Bezpośredni dostęp do stron (kompaktowy)
            if (totalPages <= 5)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(totalPages, (index) {
                  final isSelected = index == currentPage;
                  return GestureDetector(
                    onTap: () => onPageChanged(index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.secondaryGold
                            : AppTheme.backgroundSecondary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.secondaryGold
                              : AppTheme.borderSecondary,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSecondary, width: 1),
                ),
                child: Text(
                  '${currentPage + 1}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(width: 16),
            IconButton(
              onPressed: hasNextPage
                  ? () => onPageChanged(currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Następna strona',
              style: IconButton.styleFrom(
                foregroundColor: AppTheme.secondaryGold,
                disabledForegroundColor: AppTheme.textTertiary,
                backgroundColor: AppTheme.backgroundSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Selektor rozmiaru strony (mobile)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Elementy na stronę:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSecondary, width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: pageSize,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                  ),
                  dropdownColor: AppTheme.surfaceCard,
                  items: [20, 50, 100, 250]
                      .map(
                        (size) =>
                            DropdownMenuItem(value: size, child: Text('$size')),
                      )
                      .toList(),
                  onChanged: (newSize) {
                    if (newSize != null) {
                      onPageSizeChanged(newSize);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPageNumbers() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalPages, (index) {
        final isSelected = index == currentPage;
        return GestureDetector(
          onTap: () => onPageChanged(index),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.secondaryGold
                  : AppTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? AppTheme.secondaryGold
                    : AppTheme.borderSecondary,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
