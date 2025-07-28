import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DataTableColumn<T> {
  final String label;
  final String Function(T item) value;
  final Widget Function(T item)? widget;
  final bool sortable;
  final bool numeric;
  final double? width;

  const DataTableColumn({
    required this.label,
    required this.value,
    this.widget,
    this.sortable = false,
    this.numeric = false,
    this.width,
  });
}

class DataTableWidget<T> extends StatefulWidget {
  final List<T> items;
  final List<DataTableColumn<T>> columns;
  final void Function(T item)? onRowTap;
  final bool showCheckboxColumn;
  final void Function(List<T> selected)? onSelectionChanged;

  const DataTableWidget({
    super.key,
    required this.items,
    required this.columns,
    this.onRowTap,
    this.showCheckboxColumn = false,
    this.onSelectionChanged,
  });

  @override
  State<DataTableWidget<T>> createState() => _DataTableWidgetState<T>();
}

class _DataTableWidgetState<T> extends State<DataTableWidget<T>> {
  int? _sortColumnIndex;
  bool _sortAscending = true;
  List<T> _sortedItems = [];
  final Set<T> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _sortedItems = List.from(widget.items);
  }

  @override
  void didUpdateWidget(DataTableWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _sortedItems = List.from(widget.items);
      _selectedItems.clear();
      if (_sortColumnIndex != null) {
        _sortItems(_sortColumnIndex!, _sortAscending);
      }
    }
  }

  void _sortItems(int columnIndex, bool ascending) {
    final column = widget.columns[columnIndex];
    if (!column.sortable) return;

    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      _sortedItems.sort((a, b) {
        final aValue = column.value(a);
        final bValue = column.value(b);

        int comparison;
        if (column.numeric) {
          final aNum =
              double.tryParse(aValue.replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0;
          final bNum =
              double.tryParse(bValue.replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0;
          comparison = aNum.compareTo(bNum);
        } else {
          comparison = aValue.compareTo(bValue);
        }

        return ascending ? comparison : -comparison;
      });
    });
  }

  void _onSelectAll(bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedItems.addAll(_sortedItems);
      } else {
        _selectedItems.clear();
      }
    });
    widget.onSelectionChanged?.call(_selectedItems.toList());
  }

  void _onSelectItem(T item, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedItems.add(item);
      } else {
        _selectedItems.remove(item);
      }
    });
    widget.onSelectionChanged?.call(_selectedItems.toList());
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkTheme ? AppTheme.surfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkTheme ? AppTheme.borderSecondary : Colors.grey.shade300,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkTheme ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 32,
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dataTableTheme: DataTableThemeData(
                  headingRowColor: MaterialStateProperty.all(
                    isDarkTheme 
                        ? AppTheme.surfaceElevated
                        : AppTheme.primaryColor.withOpacity(0.05),
                  ),
                  dataRowMinHeight: 60,
                  dataRowMaxHeight: 60,
                  headingRowHeight: 56,
                  horizontalMargin: 16,
                  columnSpacing: 24,
                  headingTextStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkTheme ? AppTheme.secondaryGold : AppTheme.primaryColor,
                    letterSpacing: 0.2,
                  ),
                  dataTextStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: isDarkTheme ? AppTheme.textPrimary : Colors.black87,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              child: DataTable(
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                showCheckboxColumn: widget.showCheckboxColumn,
                columns: widget.columns.map((column) {
                  return DataColumn(
                    label: SizedBox(
                      width: column.width,
                      child: Text(
                        column.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkTheme ? AppTheme.secondaryGold : AppTheme.primaryColor,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onSort: column.sortable
                        ? (columnIndex, ascending) {
                            _sortItems(columnIndex, ascending);
                          }
                        : null,
                    numeric: column.numeric,
                  );
                }).toList(),
                rows: _sortedItems.map((item) {
                  final index = _sortedItems.indexOf(item);
                  final isSelected = _selectedItems.contains(item);

                  return DataRow(
                    selected: isSelected,
                    onSelectChanged: widget.showCheckboxColumn
                        ? (selected) => _onSelectItem(item, selected)
                        : null,
                    cells: widget.columns.map((column) {
                      return DataCell(
                        SizedBox(
                          width: column.width,
                          child: column.widget != null
                              ? column.widget!(item)
                              : Text(
                                  column.value(item),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: isDarkTheme ? AppTheme.textPrimary : Colors.black87,
                                    letterSpacing: 0.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        onTap: widget.onRowTap != null
                            ? () => widget.onRowTap!(item)
                            : null,
                      );
                    }).toList(),
                    color: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.hovered)) {
                        return isDarkTheme 
                            ? AppTheme.secondaryGold.withOpacity(0.08)
                            : AppTheme.primaryColor.withOpacity(0.08);
                      }
                      if (states.contains(MaterialState.selected)) {
                        return isDarkTheme 
                            ? AppTheme.secondaryGold.withOpacity(0.15)
                            : AppTheme.primaryColor.withOpacity(0.12);
                      }
                      // Naprzemienne kolorowanie wierszy dla ciemnego motywu
                      if (isDarkTheme) {
                        return index.isEven
                            ? AppTheme.surfaceContainer.withOpacity(0.5)
                            : Colors.transparent;
                      } else {
                        return index.isEven
                            ? Colors.grey[50]?.withOpacity(0.3)
                            : Colors.transparent;
                      }
                    }),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
