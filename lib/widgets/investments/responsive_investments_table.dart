import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../models/investment.dart';
import '../../theme/app_theme_professional.dart';
import '../../utils/currency_formatter.dart';

/// 📊 Responsive Investments Table Widget
/// 
/// Displays individual investments in a responsive table format with columns:
/// - nazwa (Name)
/// - Kapitał pozostały (Remaining Capital)
/// - Kapitał zabezpieczony (Secured Capital)
/// - Łączny kapitał do restrukturyzacji (Total Capital for Restructuring)  
/// - Kwota inwestycji (Investment Amount)
class ResponsiveInvestmentsTable extends StatefulWidget {
  final List<Investment> investments;
  final bool isLoading;
  final String? errorMessage;
  final Function(Investment)? onInvestmentTap;
  final Function(Investment)? onInvestmentEdit;
  final Function(Investment)? onInvestmentDelete;
  final bool showActions;
  final bool allowSorting;
  final bool showHeader;

  const ResponsiveInvestmentsTable({
    super.key,
    required this.investments,
    this.isLoading = false,
    this.errorMessage,
    this.onInvestmentTap,
    this.onInvestmentEdit,
    this.onInvestmentDelete,
    this.showActions = true,
    this.allowSorting = true,
    this.showHeader = true,
  });

  @override
  State<ResponsiveInvestmentsTable> createState() => _ResponsiveInvestmentsTableState();
}

class _ResponsiveInvestmentsTableState extends State<ResponsiveInvestmentsTable> {
  String _sortColumn = 'name';
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.errorMessage != null) {
      return _buildErrorState();
    }

    if (widget.investments.isEmpty) {
      return _buildEmptyState();
    }

    final sortedInvestments = _getSortedInvestments();

    return Container(
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) _buildHeader(),
          if (widget.showHeader) Divider(color: AppThemePro.borderPrimary),
          if (isDesktop)
            _buildDesktopTable(sortedInvestments)
          else if (isTablet)
            _buildTabletTable(sortedInvestments)
          else
            _buildMobileCards(sortedInvestments),
        ],
      ),
    );
  }

  List<Investment> _getSortedInvestments() {
    if (!widget.allowSorting) return widget.investments;
    
    final investments = List<Investment>.from(widget.investments);
    
    investments.sort((a, b) {
      dynamic aValue, bValue;
      
      switch (_sortColumn) {
        case 'name':
          aValue = a.productName?.toLowerCase() ?? '';
          bValue = b.productName?.toLowerCase() ?? '';
          break;
        case 'investmentAmount':
          aValue = a.investmentAmount ?? 0;
          bValue = b.investmentAmount ?? 0;
          break;
        case 'remainingCapital':
          aValue = a.remainingCapital ?? 0;
          bValue = b.remainingCapital ?? 0;
          break;
        case 'capitalSecured':
          aValue = a.capitalSecured ?? 0;
          bValue = b.capitalSecured ?? 0;
          break;
        case 'totalRestructuringCapital':
          aValue = _calculateTotalRestructuringCapital(a);
          bValue = _calculateTotalRestructuringCapital(b);
          break;
        default:
          return 0;
      }
      
      final result = aValue.compareTo(bValue);
      return _sortAscending ? result : -result;
    });
    
    return investments;
  }

  double _calculateTotalRestructuringCapital(Investment investment) {
    final remaining = investment.remainingCapital ?? 0;
    final secured = investment.capitalSecured ?? 0;
    return remaining + secured;
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.account_balance,
            color: AppThemePro.accentGold,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Tabela Inwestycji',
            style: AppThemePro.textStyleHeading2.copyWith(
              color: AppThemePro.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            '${widget.investments.length} inwestycji',
            style: AppThemePro.textStyleBody.copyWith(
              color: AppThemePro.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<Investment> investments) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DataTable(
        sortColumnIndex: _getSortColumnIndex(),
        sortAscending: _sortAscending,
        columns: _buildDesktopColumns(),
        rows: investments.map((investment) => _buildDesktopDataRow(investment)).toList(),
        headingRowColor: WidgetStateProperty.all(AppThemePro.backgroundTertiary),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppThemePro.backgroundTertiary.withValues(alpha: 0.5);
          }
          return AppThemePro.backgroundPrimary;
        }),
        border: TableBorder.all(
          color: AppThemePro.borderSecondary,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildTabletTable(List<Investment> investments) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 800),
        child: DataTable(
          sortColumnIndex: _getSortColumnIndex(),
          sortAscending: _sortAscending,
          columns: _buildTabletColumns(),
          rows: investments.map((investment) => _buildTabletDataRow(investment)).toList(),
          headingRowColor: WidgetStateProperty.all(AppThemePro.backgroundTertiary),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppThemePro.backgroundTertiary.withValues(alpha: 0.5);
            }
            return AppThemePro.backgroundPrimary;
          }),
          border: TableBorder.all(
            color: AppThemePro.borderSecondary,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCards(List<Investment> investments) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: investments.map((investment) => _buildMobileCard(investment)).toList(),
      ),
    );
  }

  List<DataColumn> _buildDesktopColumns() {
    return [
      DataColumn(
        label: Text(
          'Nazwa',
          style: AppThemePro.textStyleBody.copyWith(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        onSort: widget.allowSorting ? (columnIndex, ascending) => _sort('name', ascending) : null,
      ),
      DataColumn(
        label: Text(
          'Kapitał pozostały',
          style: AppThemePro.textStyleBody.copyWith(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        numeric: true,
        onSort: widget.allowSorting ? (columnIndex, ascending) => _sort('remainingCapital', ascending) : null,
      ),
      DataColumn(
        label: Text(
          'Kapitał zabezpieczony',
          style: AppThemePro.textStyleBody.copyWith(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        numeric: true,
        onSort: widget.allowSorting ? (columnIndex, ascending) => _sort('capitalSecured', ascending) : null,
      ),
      DataColumn(
        label: Text(
          'Łączny kapitał\ndo restrukturyzacji',
          style: AppThemePro.textStyleBody.copyWith(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        numeric: true,
        onSort: widget.allowSorting ? (columnIndex, ascending) => _sort('totalRestructuringCapital', ascending) : null,
      ),
      DataColumn(
        label: Text(
          'Kwota inwestycji',
          style: AppThemePro.textStyleBody.copyWith(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        numeric: true,
        onSort: widget.allowSorting ? (columnIndex, ascending) => _sort('investmentAmount', ascending) : null,
      ),
      if (widget.showActions)
        DataColumn(
          label: Text(
            'Akcje',
            style: AppThemePro.textStyleBody.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
    ];
  }

  List<DataColumn> _buildTabletColumns() {
    return [
      DataColumn(
        label: Text(
          'Nazwa',
          style: AppThemePro.textStyleBody.copyWith(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        onSort: widget.allowSorting ? (columnIndex, ascending) => _sort('name', ascending) : null,
      ),
      DataColumn(
        label: Text(
          'Kap. poz.',
          style: AppThemePro.textStyleBody.copyWith(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        numeric: true,
        onSort: widget.allowSorting ? (columnIndex, ascending) => _sort('remainingCapital', ascending) : null,
      ),
      DataColumn(
        label: Text(
          'Kap. zab.',
          style: AppThemePro.textStyleBody.copyWith(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        numeric: true,
        onSort: widget.allowSorting ? (columnIndex, ascending) => _sort('capitalSecured', ascending) : null,
      ),
      DataColumn(
        label: Text(
          'Łącz. restr.',
          style: AppThemePro.textStyleBody.copyWith(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        numeric: true,
        onSort: widget.allowSorting ? (columnIndex, ascending) => _sort('totalRestructuringCapital', ascending) : null,
      ),
      DataColumn(
        label: Text(
          'Kw. inw.',
          style: AppThemePro.textStyleBody.copyWith(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        numeric: true,
        onSort: widget.allowSorting ? (columnIndex, ascending) => _sort('investmentAmount', ascending) : null,
      ),
      if (widget.showActions)
        DataColumn(
          label: Text(
            'Akcje',
            style: AppThemePro.textStyleBody.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
    ];
  }

  DataRow _buildDesktopDataRow(Investment investment) {
    return DataRow(
      onSelectChanged: widget.onInvestmentTap != null 
          ? (_) => widget.onInvestmentTap!(investment)
          : null,
      cells: [
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              investment.productName ?? 'Nieznany produkt',
              style: AppThemePro.textStyleBody.copyWith(
                color: AppThemePro.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Text(
            CurrencyFormatter.formatAmount(investment.remainingCapital ?? 0),
            style: AppThemePro.textStyleBody.copyWith(
              color: AppThemePro.statusWarning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DataCell(
          Text(
            CurrencyFormatter.formatAmount(investment.capitalSecured ?? 0),
            style: AppThemePro.textStyleBody.copyWith(
              color: AppThemePro.statusSuccess,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppThemePro.accentGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppThemePro.accentGold.withValues(alpha: 0.3)),
            ),
            child: Text(
              CurrencyFormatter.formatAmount(_calculateTotalRestructuringCapital(investment)),
              style: AppThemePro.textStyleBody.copyWith(
                color: AppThemePro.accentGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            CurrencyFormatter.formatAmount(investment.investmentAmount ?? 0),
            style: AppThemePro.textStyleBody.copyWith(
              color: AppThemePro.statusInfo,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (widget.showActions)
          DataCell(_buildActionButtons(investment)),
      ],
    );
  }

  DataRow _buildTabletDataRow(Investment investment) {
    return DataRow(
      onSelectChanged: widget.onInvestmentTap != null 
          ? (_) => widget.onInvestmentTap!(investment)
          : null,
      cells: [
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              investment.productName ?? 'Nieznany produkt',
              style: AppThemePro.textStyleBody.copyWith(
                color: AppThemePro.textPrimary,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Text(
            CurrencyFormatter.formatAmount(investment.remainingCapital ?? 0),
            style: AppThemePro.textStyleBody.copyWith(
              color: AppThemePro.statusWarning,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        DataCell(
          Text(
            CurrencyFormatter.formatAmount(investment.capitalSecured ?? 0),
            style: AppThemePro.textStyleBody.copyWith(
              color: AppThemePro.statusSuccess,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppThemePro.accentGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              CurrencyFormatter.formatAmount(_calculateTotalRestructuringCapital(investment)),
              style: AppThemePro.textStyleBody.copyWith(
                color: AppThemePro.accentGold,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            CurrencyFormatter.formatAmount(investment.investmentAmount ?? 0),
            style: AppThemePro.textStyleBody.copyWith(
              color: AppThemePro.statusInfo,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        if (widget.showActions)
          DataCell(_buildActionButtons(investment)),
      ],
    );
  }

  Widget _buildMobileCard(Investment investment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.borderSecondary),
      ),
      child: InkWell(
        onTap: widget.onInvestmentTap != null 
            ? () => widget.onInvestmentTap!(investment)
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nazwa produktu
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: AppThemePro.accentGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    investment.productName ?? 'Nieznany produkt',
                    style: AppThemePro.textStyleHeading4.copyWith(
                      color: AppThemePro.textPrimary,
                    ),
                  ),
                ),
                if (widget.showActions) _buildActionButtons(investment),
              ],
            ),
            const SizedBox(height: 12),
            
            // Metryki
            _buildMobileMetric(
              'Kwota inwestycji',
              CurrencyFormatter.formatAmount(investment.investmentAmount ?? 0),
              AppThemePro.statusInfo,
            ),
            _buildMobileMetric(
              'Kapitał pozostały',
              CurrencyFormatter.formatAmount(investment.remainingCapital ?? 0),
              AppThemePro.statusWarning,
            ),
            _buildMobileMetric(
              'Kapitał zabezpieczony',
              CurrencyFormatter.formatAmount(investment.capitalSecured ?? 0),
              AppThemePro.statusSuccess,
            ),
            _buildMobileMetric(
              'Łączny kapitał do restrukturyzacji',
              CurrencyFormatter.formatAmount(_calculateTotalRestructuringCapital(investment)),
              AppThemePro.accentGold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMetric(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppThemePro.textStyleBody.copyWith(
              color: AppThemePro.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppThemePro.textStyleBody.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Investment investment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onInvestmentEdit != null)
          IconButton(
            icon: Icon(
              Icons.edit,
              color: AppThemePro.accentGold,
              size: 18,
            ),
            onPressed: () => widget.onInvestmentEdit!(investment),
            tooltip: 'Edytuj',
          ),
        if (widget.onInvestmentDelete != null)
          IconButton(
            icon: Icon(
              Icons.delete,
              color: AppThemePro.statusError,
              size: 18,
            ),
            onPressed: () => widget.onInvestmentDelete!(investment),
            tooltip: 'Usuń',
          ),
      ],
    );
  }

  int _getSortColumnIndex() {
    switch (_sortColumn) {
      case 'name': return 0;
      case 'remainingCapital': return 1;
      case 'capitalSecured': return 2;
      case 'totalRestructuringCapital': return 3;
      case 'investmentAmount': return 4;
      default: return 0;
    }
  }

  void _sort(String column, bool ascending) {
    if (widget.allowSorting) {
      setState(() {
        _sortColumn = column;
        _sortAscending = ascending;
      });
    }
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppThemePro.accentGold),
            ),
            const SizedBox(height: 16),
            Text(
              'Ładowanie inwestycji...',
              style: AppThemePro.textStyleBody.copyWith(
                color: AppThemePro.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppThemePro.statusError,
            ),
            const SizedBox(height: 16),
            Text(
              'Błąd ładowania',
              style: AppThemePro.textStyleHeading3.copyWith(
                color: AppThemePro.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.errorMessage ?? 'Nieznany błąd',
              style: AppThemePro.textStyleBody.copyWith(
                color: AppThemePro.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppThemePro.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Brak inwestycji do wyświetlenia',
              style: AppThemePro.textStyleHeading3.copyWith(
                color: AppThemePro.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Inwestycje pojawią się tutaj po ich dodaniu',
              style: AppThemePro.textStyleBody.copyWith(
                color: AppThemePro.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: AppTheme.premiumCardDecoration,
      child: Column(
        children: [
          _buildTableHeader(isDesktop: true),
          ...investments.asMap().entries.map(
            (entry) => _buildDesktopTableRow(entry.value, entry.key),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletTable() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: AppTheme.premiumCardDecoration,
      child: Column(
        children: [
          _buildTableHeader(isDesktop: false),
          ...investments.asMap().entries.map(
            (entry) => _buildTabletTableRow(entry.value, entry.key),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCards() {
    return Column(
      children: investments.asMap().entries.map(
        (entry) => _buildMobileCard(entry.value, entry.key),
      ).toList(),
    );
  }

  Widget _buildTableHeader({required bool isDesktop}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('#', style: _getTableHeaderStyle())),
          Expanded(
            flex: isDesktop ? 4 : 3,
            child: Text('Nazwa', style: _getTableHeaderStyle()),
          ),
          Expanded(
            flex: 3,
            child: Text('Kapitał pozostały', style: _getTableHeaderStyle()),
          ),
          if (isDesktop) ...[
            Expanded(
              flex: 3,
              child: Text('Kapitał zabezpieczony', style: _getTableHeaderStyle()),
            ),
            Expanded(
              flex: 3,
              child: Text('Łączny kapitał do restrukturyzacji', style: _getTableHeaderStyle()),
            ),
            Expanded(
              flex: 3,
              child: Text('Kwota inwestycji', style: _getTableHeaderStyle()),
            ),
          ] else ...[
            Expanded(
              flex: 2,
              child: Text('Zabezp.', style: _getTableHeaderStyle()),
            ),
            Expanded(
              flex: 2,
              child: Text('Restruk.', style: _getTableHeaderStyle()),
            ),
            Expanded(
              flex: 2,
              child: Text('Kwota', style: _getTableHeaderStyle()),
            ),
          ],
          if (showActions)
            SizedBox(
              width: isDesktop ? 80 : 48,
              child: Text('Akcje', style: _getTableHeaderStyle()),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopTableRow(Investment investment, int index) {
    return InkWell(
      onTap: () => onInvestmentTap?.call(investment),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.borderSecondary.withOpacity(0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    investment.productName,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (investment.creditorCompany.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      investment.creditorCompany,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                CurrencyFormatter.formatCurrency(investment.remainingCapital),
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                CurrencyFormatter.formatCurrency(investment.capitalSecuredByRealEstate),
                style: TextStyle(
                  color: AppTheme.successPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                CurrencyFormatter.formatCurrency(investment.capitalForRestructuring),
                style: TextStyle(
                  color: AppTheme.warningPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                CurrencyFormatter.formatCurrency(investment.investmentAmount),
                style: TextStyle(
                  color: AppTheme.infoPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            if (showActions)
              SizedBox(
                width: 80,
                child: _buildActionsMenu(investment),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletTableRow(Investment investment, int index) {
    return InkWell(
      onTap: () => onInvestmentTap?.call(investment),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.borderSecondary.withOpacity(0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    investment.productName,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (investment.creditorCompany.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      investment.creditorCompany,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                CurrencyFormatter.formatCurrencyShort(investment.remainingCapital),
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                CurrencyFormatter.formatCurrencyShort(investment.capitalSecuredByRealEstate),
                style: TextStyle(
                  color: AppTheme.successPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                CurrencyFormatter.formatCurrencyShort(investment.capitalForRestructuring),
                style: TextStyle(
                  color: AppTheme.warningPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                CurrencyFormatter.formatCurrencyShort(investment.investmentAmount),
                style: TextStyle(
                  color: AppTheme.infoPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ),
            if (showActions)
              SizedBox(
                width: 48,
                child: _buildActionsMenu(investment),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCard(Investment investment, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: AppTheme.premiumCardDecoration,
      child: InkWell(
        onTap: () => onInvestmentTap?.call(investment),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and index
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investment.productName,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (investment.creditorCompany.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            investment.creditorCompany,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showActions) _buildActionsMenu(investment),
                ],
              ),

              const SizedBox(height: 16),

              // Financial metrics grid
              _buildMobileMetricsGrid(investment),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileMetricsGrid(Investment investment) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMobileMetricItem(
                'Kapitał pozostały',
                CurrencyFormatter.formatCurrency(investment.remainingCapital),
                AppTheme.primaryColor,
                Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMobileMetricItem(
                'Kwota inwestycji',
                CurrencyFormatter.formatCurrency(investment.investmentAmount),
                AppTheme.infoPrimary,
                Icons.trending_up,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMobileMetricItem(
                'Zabezpieczony',
                CurrencyFormatter.formatCurrency(investment.capitalSecuredByRealEstate),
                AppTheme.successPrimary,
                Icons.security,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMobileMetricItem(
                'Do restrukturyzacji',
                CurrencyFormatter.formatCurrency(investment.capitalForRestructuring),
                AppTheme.warningPrimary,
                Icons.construction,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileMetricItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionsMenu(Investment investment) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 16,
        color: AppTheme.textSecondary,
      ),
      color: AppTheme.backgroundModal,
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 16, color: AppTheme.infoPrimary),
              const SizedBox(width: 8),
              const Text('Podgląd'),
            ],
          ),
        ),
        if (onInvestmentEdit != null)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 16, color: AppTheme.warningPrimary),
                const SizedBox(width: 8),
                const Text('Edytuj'),
              ],
            ),
          ),
        if (onInvestmentDelete != null)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 16, color: AppTheme.errorColor),
                const SizedBox(width: 8),
                const Text('Usuń'),
              ],
            ),
          ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'view':
            onInvestmentTap?.call(investment);
            break;
          case 'edit':
            onInvestmentEdit?.call(investment);
            break;
          case 'delete':
            onInvestmentDelete?.call(investment);
            break;
        }
      },
    );
  }

  TextStyle _getTableHeaderStyle() {
    return TextStyle(
      color: AppTheme.textSecondary,
      fontWeight: FontWeight.w700,
      fontSize: 11,
      letterSpacing: 0.5,
    );
  }
}