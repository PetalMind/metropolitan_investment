import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models_and_services.dart';

class EmployeeActionsWidget extends StatefulWidget {
  final bool canEdit;
  final VoidCallback onAddEmployee;
  final Function(String) onSortChanged;
  final Function() onToggleSortOrder;
  final String currentSort;
  final bool sortAscending;
  final Function()? onRefresh;
  final Function()? onExport;
  final Function()? onBulkActions;
  final int totalEmployees;
  final int filteredEmployees;

  const EmployeeActionsWidget({
    super.key,
    required this.canEdit,
    required this.onAddEmployee,
    required this.onSortChanged,
    required this.onToggleSortOrder,
    required this.currentSort,
    required this.sortAscending,
    this.onRefresh,
    this.onExport,
    this.onBulkActions,
    required this.totalEmployees,
    required this.filteredEmployees,
  });

  @override
  State<EmployeeActionsWidget> createState() => _EmployeeActionsWidgetState();
}

class _EmployeeActionsWidgetState extends State<EmployeeActionsWidget>
    with TickerProviderStateMixin {
  late AnimationController _fabController;
  late AnimationController _countersController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _countersSlideAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _countersController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fabScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));
    
    _countersSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _countersController,
      curve: Curves.easeOutBack,
    ));
    
    _countersController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _countersController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    HapticFeedback.lightImpact();
  }

  String _getSortDisplayName(String sortKey) {
    switch (sortKey) {
      case 'firstName':
        return 'Imię';
      case 'lastName':
        return 'Nazwisko';
      case 'email':
        return 'Email';
      case 'position':
        return 'Stanowisko';
      case 'branchCode':
        return 'Filia';
      case 'createdAt':
        return 'Data utworzenia';
      default:
        return 'Nazwisko';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Statistics row
          AnimatedBuilder(
            animation: _countersSlideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - _countersSlideAnimation.value)),
                child: Opacity(
                  opacity: _countersSlideAnimation.value,
                  child: Row(
                    children: [
                      // Total employees counter
                      _StatisticCard(
                        icon: Icons.people,
                        label: 'Łącznie pracowników',
                        value: widget.totalEmployees.toString(),
                        color: AppTheme.primaryColor,
                        delay: 0,
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Filtered employees counter
                      _StatisticCard(
                        icon: Icons.filter_list,
                        label: 'Wyświetlane',
                        value: widget.filteredEmployees.toString(),
                        color: AppTheme.successPrimary,
                        delay: 100,
                      ),
                      
                      const Spacer(),
                      
                      // Sort controls
                      _SortControls(
                        currentSort: widget.currentSort,
                        sortAscending: widget.sortAscending,
                        onSortChanged: widget.onSortChanged,
                        onToggleSortOrder: widget.onToggleSortOrder,
                        getSortDisplayName: _getSortDisplayName,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Actions row
          Row(
            children: [
              // Add button
              AnimatedBuilder(
                animation: _fabScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _fabScaleAnimation.value,
                    child: Tooltip(
                      message: widget.canEdit 
                          ? 'Dodaj nowego pracownika' 
                          : 'Brak uprawnień – rola user',
                      child: FloatingActionButton.extended(
                        onPressed: widget.canEdit 
                            ? () {
                                _fabController.forward().then((_) {
                                  _fabController.reverse();
                                });
                                HapticFeedback.mediumImpact();
                                widget.onAddEmployee();
                              }
                            : null,
                        icon: Icon(
                          Icons.add,
                          color: widget.canEdit ? Colors.white : Colors.grey,
                        ),
                        label: Text(
                          'Dodaj pracownika',
                          style: TextStyle(
                            color: widget.canEdit ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: widget.canEdit 
                            ? AppTheme.primaryColor 
                            : Colors.grey.withValues(alpha: 0.3),
                        elevation: widget.canEdit ? 6 : 2,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(width: 16),
              
              // Secondary actions
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Refresh button
                    if (widget.onRefresh != null)
                      _ActionButton(
                        icon: Icons.refresh,
                        tooltip: 'Odśwież dane',
                        onPressed: widget.onRefresh!,
                        color: AppTheme.textSecondary,
                      ),
                    
                    const SizedBox(width: 8),
                    
                    // Export button
                    if (widget.onExport != null)
                      _ActionButton(
                        icon: Icons.download,
                        tooltip: 'Eksportuj dane',
                        onPressed: widget.onExport!,
                        color: AppTheme.secondaryGold,
                      ),
                    
                    const SizedBox(width: 8),
                    
                    // More actions button
                    _ActionButton(
                      icon: _isExpanded ? Icons.expand_less : Icons.more_vert,
                      tooltip: 'Więcej opcji',
                      onPressed: _toggleExpansion,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Expanded actions
          if (_isExpanded)
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return SizeTransition(
                  sizeFactor: AlwaysStoppedAnimation(value),
                  axisAlignment: -1.0,
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundPrimary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.borderPrimary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dodatkowe opcje',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _ExpandedActionButton(
                                  icon: Icons.groups,
                                  label: 'Akcje grupowe',
                                  onPressed: widget.onBulkActions,
                                  enabled: widget.canEdit,
                                ),
                                _ExpandedActionButton(
                                  icon: Icons.analytics,
                                  label: 'Statystyki',
                                  onPressed: () => _showStatistics(context),
                                  enabled: true,
                                ),
                                _ExpandedActionButton(
                                  icon: Icons.settings,
                                  label: 'Ustawienia',
                                  onPressed: () => _showSettings(context),
                                  enabled: widget.canEdit,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showStatistics(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _StatisticsDialog(
        totalEmployees: widget.totalEmployees,
        filteredEmployees: widget.filteredEmployees,
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _SettingsDialog(),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final int delay;

  const _StatisticCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animValue),
          child: Opacity(
            opacity: animValue,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: color.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SortControls extends StatefulWidget {
  final String currentSort;
  final bool sortAscending;
  final Function(String) onSortChanged;
  final Function() onToggleSortOrder;
  final String Function(String) getSortDisplayName;

  const _SortControls({
    required this.currentSort,
    required this.sortAscending,
    required this.onSortChanged,
    required this.onToggleSortOrder,
    required this.getSortDisplayName,
  });

  @override
  State<_SortControls> createState() => _SortControlsState();
}

class _SortControlsState extends State<_SortControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Sortuj: ',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        DropdownButton<String>(
          value: widget.currentSort,
          onChanged: (value) {
            if (value != null) {
              widget.onSortChanged(value);
              HapticFeedback.lightImpact();
            }
          },
          underline: const SizedBox(),
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
          items: [
            'lastName',
            'firstName',
            'email',
            'position',
            'branchCode',
            'createdAt',
          ].map((sort) {
            return DropdownMenuItem<String>(
              value: sort,
              child: Text(widget.getSortDisplayName(sort)),
            );
          }).toList(),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            widget.onToggleSortOrder();
            _rotationController.forward().then((_) {
              _rotationController.reverse();
            });
            HapticFeedback.lightImpact();
          },
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 3.14159,
                child: Icon(
                  widget.sortAscending 
                      ? Icons.arrow_upward 
                      : Icons.arrow_downward,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(_scaleController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Tooltip(
            message: widget.tooltip,
            child: IconButton(
              onPressed: () {
                _scaleController.forward().then((_) {
                  _scaleController.reverse();
                });
                HapticFeedback.lightImpact();
                widget.onPressed();
              },
              icon: Icon(
                widget.icon,
                color: widget.color,
              ),
              style: IconButton.styleFrom(
                backgroundColor: widget.color.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ExpandedActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  const _ExpandedActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(
        icon,
        size: 16,
        color: enabled ? AppTheme.primaryColor : Colors.grey,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? AppTheme.primaryColor : Colors.grey,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: enabled 
              ? AppTheme.primaryColor.withValues(alpha: 0.3) 
              : Colors.grey.withValues(alpha: 0.3),
        ),
        backgroundColor: enabled
            ? AppTheme.primaryColor.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _StatisticsDialog extends StatelessWidget {
  final int totalEmployees;
  final int filteredEmployees;

  const _StatisticsDialog({
    required this.totalEmployees,
    required this.filteredEmployees,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Statystyki pracowników'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Łączna liczba pracowników'),
            trailing: Text(
              totalEmployees.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.filter_list),
            title: const Text('Aktualnie wyświetlane'),
            trailing: Text(
              filteredEmployees.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Zamknij'),
        ),
      ],
    );
  }
}

class _SettingsDialog extends StatelessWidget {
  const _SettingsDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ustawienia'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Funkcje w przygotowaniu...'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Zamknij'),
        ),
      ],
    );
  }
}