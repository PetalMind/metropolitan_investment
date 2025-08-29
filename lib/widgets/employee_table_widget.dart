import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models_and_services.dart';

class EmployeeTableWidget extends StatefulWidget {
  final List<Employee> employees;
  final Function(Employee) onEdit;
  final Function(Employee) onDelete;
  final Function(Employee)? onRowTap;
  final bool canEdit;
  final String sortColumn;
  final bool sortAscending;
  final Function(String, bool) onSort;

  const EmployeeTableWidget({
    super.key,
    required this.employees,
    required this.onEdit,
    required this.onDelete,
    this.onRowTap,
    required this.canEdit,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
  });

  @override
  State<EmployeeTableWidget> createState() => _EmployeeTableWidgetState();
}

class _EmployeeTableWidgetState extends State<EmployeeTableWidget>
    with TickerProviderStateMixin {
  Set<String> selectedEmployees = {};
  bool selectAll = false;
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _toggleSelectAll() {
    setState(() {
      selectAll = !selectAll;
      if (selectAll) {
        selectedEmployees = widget.employees.map((e) => e.id).toSet();
      } else {
        selectedEmployees.clear();
      }
    });
    HapticFeedback.lightImpact();
  }

  void _toggleSelection(String employeeId) {
    setState(() {
      if (selectedEmployees.contains(employeeId)) {
        selectedEmployees.remove(employeeId);
      } else {
        selectedEmployees.add(employeeId);
      }
      selectAll = selectedEmployees.length == widget.employees.length;
    });
    HapticFeedback.selectionClick();
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderPrimary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Checkbox for select all
          SizedBox(
            width: 48,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 200),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Checkbox(
                    value: selectAll,
                    onChanged: widget.canEdit ? (_) => _toggleSelectAll() : null,
                    tristate: true,
                    activeColor: AppTheme.primaryColor,
                  ),
                );
              },
            ),
          ),
          
          // Column headers
          _buildSortableHeader('Imię i Nazwisko', 'lastName', flex: 3),
          _buildSortableHeader('Email', 'email', flex: 3),
          _buildSortableHeader('Telefon', 'phone', flex: 2),
          _buildSortableHeader('Stanowisko', 'position', flex: 3),
          _buildSortableHeader('Filia', 'branchCode', flex: 2),
          _buildSortableHeader('Status', 'isActive', flex: 2),
          _buildSortableHeader('Utworzono', 'createdAt', flex: 2),
          
          // Actions column
          const Expanded(
            flex: 2,
            child: Text(
              'Akcje',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortableHeader(String title, String column, {int flex = 1}) {
    final isActive = widget.sortColumn == column;
    
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => widget.onSort(column, 
            isActive ? !widget.sortAscending : true),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: isActive && !widget.sortAscending ? 0.5 : 0,
                child: Icon(
                  Icons.arrow_upward,
                  size: 16,
                  color: isActive ? AppTheme.primaryColor : AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: Column(
        children: [
          // Bulk actions bar
          if (selectedEmployees.isNotEmpty)
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, -20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Wybrano ${selectedEmployees.length} pracowników',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                selectedEmployees.clear();
                                selectAll = false;
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Wyczyść'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundPrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.borderPrimary.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildTableHeader(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.employees.length,
                      itemBuilder: (context, index) {
                        final employee = widget.employees[index];
                        final isSelected = selectedEmployees.contains(employee.id);
                        
                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 200 + (index * 50)),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: _EmployeeRow(
                                  employee: employee,
                                  isSelected: isSelected,
                                  canEdit: widget.canEdit,
                                  onTap: () {
                                    if (widget.onRowTap != null) {
                                      widget.onRowTap!(employee);
                                    }
                                  },
                                  onSelect: () => _toggleSelection(employee.id),
                                  onEdit: () => widget.onEdit(employee),
                                  onDelete: () => widget.onDelete(employee),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeRow extends StatefulWidget {
  final Employee employee;
  final bool isSelected;
  final bool canEdit;
  final VoidCallback onTap;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmployeeRow({
    required this.employee,
    required this.isSelected,
    required this.canEdit,
    required this.onTap,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_EmployeeRow> createState() => _EmployeeRowState();
}

class _EmployeeRowState extends State<_EmployeeRow>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: AppTheme.primaryColor.withValues(alpha: 0.05),
    ).animate(_hoverController);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) => _onHover(true),
            onExit: (_) => _onHover(false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : _colorAnimation.value,
                  borderRadius: BorderRadius.circular(8),
                  border: widget.isSelected
                      ? Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    // Checkbox
                    SizedBox(
                      width: 48,
                      child: Checkbox(
                        value: widget.isSelected,
                        onChanged: widget.canEdit ? (_) => widget.onSelect() : null,
                        activeColor: AppTheme.primaryColor,
                      ),
                    ),
                    
                    // Employee name with avatar
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            child: Text(
                              '${widget.employee.firstName[0]}${widget.employee.lastName[0]}',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${widget.employee.firstName} ${widget.employee.lastName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_isHovered) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'ID: ${widget.employee.id}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textTertiary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Email
                    Expanded(
                      flex: 3,
                      child: SelectableText(
                        widget.employee.email,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    
                    // Phone
                    Expanded(
                      flex: 2,
                      child: Text(
                        widget.employee.phone.isNotEmpty 
                            ? widget.employee.phone 
                            : '-',
                        style: const TextStyle(color: AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Position
                    Expanded(
                      flex: 3,
                      child: Text(
                        widget.employee.position,
                        style: const TextStyle(color: AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Branch
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.employee.branchCode,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    
                    // Status
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.employee.isActive
                              ? AppTheme.successPrimary.withValues(alpha: 0.1)
                              : AppTheme.errorPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.employee.isActive
                                ? AppTheme.successPrimary
                                : AppTheme.errorPrimary,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.employee.isActive ? 'Aktywny' : 'Nieaktywny',
                          style: TextStyle(
                            color: widget.employee.isActive
                                ? AppTheme.successPrimary
                                : AppTheme.errorPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    
                    // Created date
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${widget.employee.createdAt.day.toString().padLeft(2, '0')}.${widget.employee.createdAt.month.toString().padLeft(2, '0')}.${widget.employee.createdAt.year}',
                        style: const TextStyle(color: AppTheme.textTertiary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Actions
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            scale: _isHovered ? 1.1 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            child: Tooltip(
                              message: widget.canEdit 
                                  ? 'Edytuj pracownika' 
                                  : 'Brak uprawnień',
                              child: IconButton(
                                onPressed: widget.canEdit ? widget.onEdit : null,
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: widget.canEdit 
                                      ? AppTheme.secondaryGold 
                                      : Colors.grey,
                                  size: 20,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: widget.canEdit
                                      ? AppTheme.secondaryGold.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedScale(
                            scale: _isHovered ? 1.1 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            child: Tooltip(
                              message: widget.canEdit 
                                  ? 'Usuń pracownika' 
                                  : 'Brak uprawnień',
                              child: IconButton(
                                onPressed: widget.canEdit ? widget.onDelete : null,
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: widget.canEdit 
                                      ? AppTheme.errorPrimary 
                                      : Colors.grey,
                                  size: 20,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: widget.canEdit
                                      ? AppTheme.errorPrimary.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}