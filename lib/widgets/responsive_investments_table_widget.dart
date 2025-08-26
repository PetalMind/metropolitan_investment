import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models_and_services.dart';
import '../theme/app_theme_professional.dart';

/// Responsive investments table widget showing investment details
/// with columns: nazwa, Kapitał pozostały, Kapitał zabezpieczony, 
/// Łączny kapitał do restrukturyzacji, Kwota inwestycji
class ResponsiveInvestmentsTableWidget extends ConsumerStatefulWidget {
  final List<Investment> investments;
  final bool showHeader;
  final bool allowSorting;
  final Function(Investment)? onInvestmentTap;
  final EdgeInsets padding;

  const ResponsiveInvestmentsTableWidget({
    super.key,
    required this.investments,
    this.showHeader = true,
    this.allowSorting = true,
    this.onInvestmentTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  ConsumerState<ResponsiveInvestmentsTableWidget> createState() =>
      _ResponsiveInvestmentsTableWidgetState();
}

class _ResponsiveInvestmentsTableWidgetState
    extends ConsumerState<ResponsiveInvestmentsTableWidget> {
  String _sortColumn = 'name';
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    if (widget.investments.isEmpty) {
      return _buildEmptyState();
    }

    final sortedInvestments = _getSortedInvestments();

    return Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) _buildHeader(),
          if (widget.showHeader) const SizedBox(height: 16),
          if (isMobile)
            _buildMobileLayout(sortedInvestments)
          else if (isTablet)
            _buildTabletLayout(sortedInvestments)
          else
            _buildDesktopLayout(sortedInvestments),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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

  List<Investment> _getSortedInvestments() {
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

  Widget _buildMobileLayout(List<Investment> investments) {
    return Column(
      children: investments.map((investment) => _buildMobileCard(investment)).toList(),
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
              ],
            ),
            const SizedBox(height: 12),
            
            // Metryki
            _buildMobileMetric(
              'Kwota inwestycji',
              _formatCurrency(investment.investmentAmount ?? 0),
              AppThemePro.statusInfo,
            ),
            _buildMobileMetric(
              'Kapitał pozostały',
              _formatCurrency(investment.remainingCapital ?? 0),
              AppThemePro.statusWarning,
            ),
            _buildMobileMetric(
              'Kapitał zabezpieczony',
              _formatCurrency(investment.capitalSecured ?? 0),
              AppThemePro.statusSuccess,
            ),
            _buildMobileMetric(
              'Łączny kapitał do restrukturyzacji',
              _formatCurrency(_calculateTotalRestructuringCapital(investment)),
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

  Widget _buildTabletLayout(List<Investment> investments) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 32,
        ),
        child: _buildDataTable(investments, isCompact: true),
      ),
    );
  }

  Widget _buildDesktopLayout(List<Investment> investments) {
    return _buildDataTable(investments, isCompact: false);
  }

  Widget _buildDataTable(List<Investment> investments, {required bool isCompact}) {
    return DataTable(
      sortColumnIndex: _getSortColumnIndex(),
      sortAscending: _sortAscending,
      columns: _buildColumns(isCompact),
      rows: investments.map((investment) => _buildDataRow(investment, isCompact)).toList(),
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
    );
  }

  int _getSortColumnIndex() {
    switch (_sortColumn) {
      case 'name': return 0;
      case 'investmentAmount': return 4;
      case 'remainingCapital': return 1;
      case 'capitalSecured': return 2;
      case 'totalRestructuringCapital': return 3;
      default: return 0;
    }
  }

  List<DataColumn> _buildColumns(bool isCompact) {
    return [
      DataColumn(
        label: Text(
          'Nazwa',
          style: _getHeaderStyle(isCompact),
        ),
        onSort: widget.allowSorting ? (columnIndex, ascending) => _sort('name', ascending) : null,
      ),
      DataColumn(
        label: Text(
          isCompact ? 'Kap. poz.' : 'Kapitał pozostały',
          style: _getHeaderStyle(isCompact),
        ),
        numeric: true,
        onSort: widget.allowSorting ? (columnIndex, ascending) => _sort('remainingCapital', ascending) : null,
      ),
      DataColumn(
        label: Text(
          isCompact ? 'Kap. zab.' : 'Kapitał zabezpieczony',
          style: _getHeaderStyle(isCompact),
        ),
        numeric: true,
        onSort: widget.allowSorting ? (columnIndex, ascending) => _sort('capitalSecured', ascending) : null,
      ),
      DataColumn(
        label: Text(
          isCompact ? 'Łącz. restr.' : 'Łączny kapitał\ndo restrukturyzacji',
          style: _getHeaderStyle(isCompact),
          textAlign: TextAlign.center,
        ),
        numeric: true,
        onSort: widget.allowSorting ? (columnIndex, ascending) => _sort('totalRestructuringCapital', ascending) : null,
      ),
      DataColumn(
        label: Text(
          isCompact ? 'Kw. inw.' : 'Kwota inwestycji',
          style: _getHeaderStyle(isCompact),
        ),
        numeric: true,
        onSort: widget.allowSorting ? (columnIndex, ascending) => _sort('investmentAmount', ascending) : null,
      ),
    ];
  }

  TextStyle _getHeaderStyle(bool isCompact) {
    return AppThemePro.textStyleBody.copyWith(
      color: AppThemePro.textPrimary,
      fontWeight: FontWeight.bold,
      fontSize: isCompact ? 12 : 14,
    );
  }

  DataRow _buildDataRow(Investment investment, bool isCompact) {
    return DataRow(
      onSelectChanged: widget.onInvestmentTap != null 
          ? (_) => widget.onInvestmentTap!(investment)
          : null,
      cells: [
        DataCell(
          Container(
            constraints: BoxConstraints(maxWidth: isCompact ? 120 : 200),
            child: Text(
              investment.productName ?? 'Nieznany produkt',
              style: AppThemePro.textStyleBody.copyWith(
                color: AppThemePro.textPrimary,
                fontSize: isCompact ? 12 : 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Text(
            _formatCurrency(investment.remainingCapital ?? 0),
            style: AppThemePro.textStyleBody.copyWith(
              color: AppThemePro.statusWarning,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 12 : 14,
            ),
          ),
        ),
        DataCell(
          Text(
            _formatCurrency(investment.capitalSecured ?? 0),
            style: AppThemePro.textStyleBody.copyWith(
              color: AppThemePro.statusSuccess,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 12 : 14,
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
              _formatCurrency(_calculateTotalRestructuringCapital(investment)),
              style: AppThemePro.textStyleBody.copyWith(
                color: AppThemePro.accentGold,
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 12 : 14,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            _formatCurrency(investment.investmentAmount ?? 0),
            style: AppThemePro.textStyleBody.copyWith(
              color: AppThemePro.statusInfo,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 12 : 14,
            ),
          ),
        ),
      ],
    );
  }

  void _sort(String column, bool ascending) {
    if (widget.allowSorting) {
      setState(() {
        _sortColumn = column;
        _sortAscending = ascending;
      });
    }
  }

  String _formatCurrency(double amount) {
    if (amount == 0) return '0,00 zł';
    
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final wholePart = parts[0];
    final decimalPart = parts[1];

    // Add thousands separators
    final buffer = StringBuffer();
    for (int i = 0; i < wholePart.length; i++) {
      if (i > 0 && (wholePart.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(wholePart[i]);
    }

    return '${buffer.toString()},$decimalPart zł';
  }
}

/// Summary widget showing aggregated totals for the investments table
class InvestmentsTableSummaryWidget extends StatelessWidget {
  final List<Investment> investments;

  const InvestmentsTableSummaryWidget({
    super.key,
    required this.investments,
  });

  @override
  Widget build(BuildContext context) {
    final totals = _calculateTotals();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize,
                color: AppThemePro.accentGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Podsumowanie Inwestycji',
                style: AppThemePro.textStyleHeading3.copyWith(
                  color: AppThemePro.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryGrid(totals),
        ],
      ),
    );
  }

  Map<String, double> _calculateTotals() {
    double totalInvestment = 0;
    double totalRemaining = 0;
    double totalSecured = 0;
    
    for (final investment in investments) {
      totalInvestment += investment.investmentAmount ?? 0;
      totalRemaining += investment.remainingCapital ?? 0;
      totalSecured += investment.capitalSecured ?? 0;
    }
    
    return {
      'totalInvestment': totalInvestment,
      'totalRemaining': totalRemaining,
      'totalSecured': totalSecured,
      'totalRestructuring': totalRemaining + totalSecured,
    };
  }

  Widget _buildSummaryGrid(Map<String, double> totals) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final crossAxisCount = isWide ? 4 : 2;
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: isWide ? 2.5 : 2.0,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildSummaryCard(
              'Łączna kwota inwestycji',
              totals['totalInvestment']!,
              Icons.account_balance_wallet,
              AppThemePro.statusInfo,
            ),
            _buildSummaryCard(
              'Kapitał pozostały',
              totals['totalRemaining']!,
              Icons.trending_down,
              AppThemePro.statusWarning,
            ),
            _buildSummaryCard(
              'Kapitał zabezpieczony',
              totals['totalSecured']!,
              Icons.security,
              AppThemePro.statusSuccess,
            ),
            _buildSummaryCard(
              'Łączny kapitał do restrukturyzacji',
              totals['totalRestructuring']!,
              Icons.transform,
              AppThemePro.accentGold,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppThemePro.textStyleCaption.copyWith(
                    color: AppThemePro.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(value),
            style: AppThemePro.textStyleHeading4.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount == 0) return '0,00 zł';
    
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final wholePart = parts[0];
    final decimalPart = parts[1];

    // Add thousands separators
    final buffer = StringBuffer();
    for (int i = 0; i < wholePart.length; i++) {
      if (i > 0 && (wholePart.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(wholePart[i]);
    }

    return '${buffer.toString()},$decimalPart zł';
  }
}