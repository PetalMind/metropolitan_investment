import 'package:flutter/material.dart';
import '../../../models_and_services.dart';
import '../../../theme/app_theme.dart';

/// Panel filtrów dla analityki inwestorów
class InvestorFilterPanel extends StatelessWidget {
  final TextEditingController searchController;
  final TextEditingController minAmountController;
  final TextEditingController maxAmountController;
  final TextEditingController companyFilterController;
  final VotingStatus? selectedVotingStatus;
  final ClientType? selectedClientType;
  final bool includeInactive;
  final bool showOnlyWithUnviableInvestments;
  final String sortBy;
  final bool sortAscending;
  final bool isTablet;
  final Function(VotingStatus?) onVotingStatusChanged;
  final Function(ClientType?) onClientTypeChanged;
  final Function(bool) onIncludeInactiveChanged;
  final Function(bool) onShowUnviableChanged;
  final Function(String) onSortChanged;
  final VoidCallback onResetFilters;

  const InvestorFilterPanel({
    super.key,
    required this.searchController,
    required this.minAmountController,
    required this.maxAmountController,
    required this.companyFilterController,
    required this.selectedVotingStatus,
    required this.selectedClientType,
    required this.includeInactive,
    required this.showOnlyWithUnviableInvestments,
    required this.sortBy,
    required this.sortAscending,
    required this.isTablet,
    required this.onVotingStatusChanged,
    required this.onClientTypeChanged,
    required this.onIncludeInactiveChanged,
    required this.onShowUnviableChanged,
    required this.onSortChanged,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceCard,
            AppTheme.backgroundSecondary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryGold.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppTheme.secondaryGold.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header filtrów
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.filter_list_rounded,
                  color: AppTheme.secondaryGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Filtry i sortowanie',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onResetFilters,
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text('Resetuj'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filtry - responsive layout
          if (isTablet) _buildTabletFilters() else _buildMobileFilters(),
        ],
      ),
    );
  }

  Widget _buildTabletFilters() {
    return Column(
      children: [
        // Pierwsze rzędy - pola tekstowe
        Row(
          children: [
            Expanded(child: _buildSearchField()),
            const SizedBox(width: 12),
            Expanded(child: _buildCompanyField()),
          ],
        ),
        const SizedBox(height: 12),

        // Drugi rząd - kwoty i sortowanie
        Row(
          children: [
            Expanded(child: _buildMinAmountField()),
            const SizedBox(width: 12),
            Expanded(child: _buildMaxAmountField()),
            const SizedBox(width: 12),
            Expanded(child: _buildSortDropdown()),
          ],
        ),
        const SizedBox(height: 16),

        // Trzeci rząd - dropdown filters
        Row(
          children: [
            Expanded(child: _buildVotingStatusDropdown()),
            const SizedBox(width: 12),
            Expanded(child: _buildClientTypeDropdown()),
            const SizedBox(width: 12),
            Expanded(
              child: Container(), // Placeholder for alignment
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Ostatni rząd - chips
        _buildFilterChips(),
      ],
    );
  }

  Widget _buildMobileFilters() {
    return Column(
      children: [
        _buildSearchField(),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: _buildMinAmountField()),
            const SizedBox(width: 12),
            Expanded(child: _buildMaxAmountField()),
          ],
        ),
        const SizedBox(height: 12),

        _buildCompanyField(),
        const SizedBox(height: 12),

        _buildSortDropdown(),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: _buildVotingStatusDropdown()),
            const SizedBox(width: 12),
            Expanded(child: _buildClientTypeDropdown()),
          ],
        ),
        const SizedBox(height: 16),

        _buildFilterChips(),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      controller: searchController,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: 'Szukaj inwestora',
        hintText: 'Nazwa, email, firma...',
        prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textSecondary),
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        hintStyle: const TextStyle(color: AppTheme.textTertiary),
        filled: true,
        fillColor: AppTheme.backgroundSecondary.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.secondaryGold, width: 2),
        ),
      ),
    );
  }

  Widget _buildCompanyField() {
    return TextFormField(
      controller: companyFilterController,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: 'Firma/Produkt',
        hintText: 'Nazwa firmy...',
        prefixIcon: Icon(Icons.business_rounded, color: AppTheme.textSecondary),
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        hintStyle: const TextStyle(color: AppTheme.textTertiary),
        filled: true,
        fillColor: AppTheme.backgroundSecondary.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.secondaryGold, width: 2),
        ),
      ),
    );
  }

  Widget _buildMinAmountField() {
    return TextFormField(
      controller: minAmountController,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: 'Min. kwota',
        hintText: '0',
        prefixIcon: Icon(
          Icons.currency_exchange_rounded,
          color: AppTheme.textSecondary,
        ),
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        hintStyle: const TextStyle(color: AppTheme.textTertiary),
        filled: true,
        fillColor: AppTheme.backgroundSecondary.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.secondaryGold, width: 2),
        ),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildMaxAmountField() {
    return TextFormField(
      controller: maxAmountController,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: 'Max. kwota',
        hintText: '∞',
        prefixIcon: Icon(
          Icons.currency_exchange_rounded,
          color: AppTheme.textSecondary,
        ),
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        hintStyle: const TextStyle(color: AppTheme.textTertiary),
        filled: true,
        fillColor: AppTheme.backgroundSecondary.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.secondaryGold, width: 2),
        ),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButtonFormField<String>(
      value: sortBy,
      style: const TextStyle(color: AppTheme.textPrimary),
      dropdownColor: AppTheme.surfaceCard,
      decoration: InputDecoration(
        labelText: 'Sortuj według',
        prefixIcon: Icon(Icons.sort_rounded, color: AppTheme.textSecondary),
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.backgroundSecondary.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.secondaryGold, width: 2),
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: 'totalValue',
          child: Text(
            'Wartość portfela',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
        ),
        DropdownMenuItem(
          value: 'name',
          child: Text(
            'Nazwa klienta',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
        ),
        DropdownMenuItem(
          value: 'investmentCount',
          child: Text(
            'Liczba inwestycji',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
        ),
      ],
      onChanged: (value) {
        if (value != null) onSortChanged(value);
      },
    );
  }

  Widget _buildVotingStatusDropdown() {
    return DropdownButtonFormField<VotingStatus?>(
      value: selectedVotingStatus,
      style: const TextStyle(color: AppTheme.textPrimary),
      dropdownColor: AppTheme.surfaceCard,
      decoration: InputDecoration(
        labelText: 'Status głosowania',
        prefixIcon: Icon(
          Icons.how_to_vote_rounded,
          color: AppTheme.textSecondary,
        ),
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.backgroundSecondary.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.secondaryGold, width: 2),
        ),
      ),
      items: [
        const DropdownMenuItem<VotingStatus?>(
          value: null,
          child: Text(
            'Wszystkie',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
        ),
        ...VotingStatus.values.map(
          (status) => DropdownMenuItem(
            value: status,
            child: Row(
              children: [
                Icon(
                  _getVotingStatusIcon(status),
                  color: _getVotingStatusColor(status),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  status.displayName,
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
      onChanged: onVotingStatusChanged,
    );
  }

  Widget _buildClientTypeDropdown() {
    return DropdownButtonFormField<ClientType?>(
      value: selectedClientType,
      style: const TextStyle(color: AppTheme.textPrimary),
      dropdownColor: AppTheme.surfaceCard,
      decoration: InputDecoration(
        labelText: 'Typ klienta',
        prefixIcon: Icon(
          Icons.person_outline_rounded,
          color: AppTheme.textSecondary,
        ),
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.backgroundSecondary.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.secondaryGold, width: 2),
        ),
      ),
      items: [
        const DropdownMenuItem<ClientType?>(
          value: null,
          child: Text(
            'Wszystkie',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
        ),
        ...ClientType.values.map(
          (type) => DropdownMenuItem(
            value: type,
            child: Text(
              type.displayName,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ),
      ],
      onChanged: onClientTypeChanged,
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          'Nieaktywni',
          includeInactive,
          Icons.visibility_off_rounded,
          onIncludeInactiveChanged,
        ),
        _buildFilterChip(
          'Niewykonalne',
          showOnlyWithUnviableInvestments,
          Icons.warning_rounded,
          onShowUnviableChanged,
        ),
        _buildFilterChip(
          sortAscending ? 'Rosnąco' : 'Malejąco',
          true,
          sortAscending
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded,
          (_) => onSortChanged(sortBy), // Trigger re-sort with same field
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    bool selected,
    IconData icon,
    Function(bool) onChanged,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? AppTheme.textOnSecondary
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppTheme.textOnSecondary
                    : AppTheme.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
        selected: selected,
        onSelected: onChanged,
        selectedColor: AppTheme.secondaryGold.withOpacity(0.2),
        backgroundColor: AppTheme.surfaceElevated,
        checkmarkColor: AppTheme.secondaryGold,
        side: BorderSide(
          color: selected ? AppTheme.secondaryGold : AppTheme.borderSecondary,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: selected ? 4 : 0,
        shadowColor: AppTheme.secondaryGold.withOpacity(0.3),
      ),
    );
  }

  IconData _getVotingStatusIcon(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return Icons.check_circle_rounded;
      case VotingStatus.no:
        return Icons.cancel_rounded;
      case VotingStatus.abstain:
        return Icons.remove_circle_rounded;
      case VotingStatus.undecided:
        return Icons.help_rounded;
    }
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return AppTheme.successColor;
      case VotingStatus.no:
        return AppTheme.errorColor;
      case VotingStatus.abstain:
        return AppTheme.warningColor;
      case VotingStatus.undecided:
        return AppTheme.textSecondary;
    }
  }
}
