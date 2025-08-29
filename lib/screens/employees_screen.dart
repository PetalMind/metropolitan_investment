import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models_and_services.dart';
import '../providers/auth_provider.dart';
import '../widgets/employee_form.dart';
import '../widgets/animated_button.dart';
import '../widgets/employee_table_widget.dart';
import '../widgets/employee_cards_widget.dart';
import '../widgets/employee_search_filters_widget.dart';
import '../theme/app_theme_professional.dart';

// RBAC: wspólny tooltip dla braku uprawnień
const String kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen>
    with TickerProviderStateMixin {
  final EmployeeService _employeeService = EmployeeService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortColumn = 'lastName';
  bool _sortAscending = true;
  String? _selectedBranch;
  String? _selectedStatus;
  String? _selectedPosition;
  List<String> _branches = [];
  List<String> _positions = [
    'Manager',
    'Analityk',
    'Konsultant',
    'Dyrektor',
    'Asystent',
    'Specjalista',
  ];
  bool _isTableView = false;

  // Debouncing timer for search
  Timer? _searchTimer;

  // Animation controllers
  late AnimationController _viewSwitchController;

  // RBAC getter
  bool get canEdit => Provider.of<AuthProvider>(context, listen: false).isAdmin;

  @override
  void initState() {
    super.initState();
    _loadBranches();
    _loadPositions();

    _viewSwitchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
    _viewSwitchController.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await _employeeService.getUniqueBranches();
      if (!mounted) return;
      setState(() {
        _branches = branches;
      });
    } catch (e) {
      debugPrint('Error loading branches: $e');
    }
  }

  Future<void> _loadPositions() async {
    // Using static positions for now
    // In a real app, you would fetch from the service
    setState(() {
      _positions = [
        'Manager',
        'Analityk',
        'Konsultant',
        'Dyrektor',
        'Asystent',
        'Specjalista',
      ];
    });
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 800), () {
      setState(() {
        _searchQuery = value;
      });
    });
  }

  void _onSort(String column, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;
    });
  }

  void _onBranchFilterChanged(String? branch) {
    setState(() {
      _selectedBranch = branch;
    });
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatus = status;
    });
  }

  void _onPositionFilterChanged(String? position) {
    setState(() {
      _selectedPosition = position;
    });
  }

  void _toggleView() {
    setState(() {
      _isTableView = !_isTableView;
    });

    if (_isTableView) {
      _viewSwitchController.reverse();
    } else {
      _viewSwitchController.forward();
    }
  }

  void _showEmployeeForm({Employee? employee}) {
    showDialog(
      context: context,
      builder: (context) => EmployeeForm(
        employee: employee,
        onDelete: employee != null ? _deleteEmployee : null,
      ),
    ).then((_) {
      _loadBranches();
      _loadPositions();
    });
  }

  void _deleteEmployee(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń pracownika'),
        content: Text(
          'Czy na pewno chcesz usunąć pracownika "${employee.fullName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await _employeeService.deleteEmployee(employee.id);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pracownik został usunięty'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Błąd podczas usuwania: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  List<Employee> _filterAndSortEmployees(List<Employee> employees) {
    // Filter by branch
    List<Employee> filtered = employees;
    if (_selectedBranch != null) {
      filtered = employees
          .where((employee) => employee.branchCode == _selectedBranch)
          .toList();
    }

    // Filter by status
    if (_selectedStatus != null) {
      final isActive = _selectedStatus == 'Aktywny';
      filtered = filtered
          .where((employee) => employee.isActive == isActive)
          .toList();
    }

    // Filter by position
    if (_selectedPosition != null) {
      filtered = filtered
          .where((employee) => employee.position == _selectedPosition)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((employee) {
        return employee.firstName.toLowerCase().contains(query) ||
            employee.lastName.toLowerCase().contains(query) ||
            employee.email.toLowerCase().contains(query) ||
            employee.position.toLowerCase().contains(query) ||
            employee.branchName.toLowerCase().contains(query);
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortColumn) {
        case 'firstName':
          comparison = a.firstName.compareTo(b.firstName);
          break;
        case 'lastName':
          comparison = a.lastName.compareTo(b.lastName);
          break;
        case 'email':
          comparison = a.email.compareTo(b.email);
          break;
        case 'position':
          comparison = a.position.compareTo(b.position);
          break;
        case 'branchCode':
          comparison = a.branchCode.compareTo(b.branchCode);
          break;
        case 'createdAt':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'isActive':
          comparison = a.isActive == b.isActive ? 0 : (a.isActive ? -1 : 1);
          break;
        default:
          comparison = a.lastName.compareTo(b.lastName);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Widget _buildStatisticsBar(int totalEmployees, int filteredEmployees) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        border: Border(
          bottom: BorderSide(color: AppThemePro.borderPrimary, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Total employees stat
          Expanded(
            child: _buildStatCard(
              icon: Icons.people,
              title: 'Łącznie pracowników',
              value: totalEmployees.toString(),
              color: AppThemePro.accentGold,
              subtitle: 'w systemie',
            ),
          ),
          
          const SizedBox(width: 16),

          // Filtered employees stat
          Expanded(
            child: _buildStatCard(
              icon: Icons.filter_list,
              title: 'Wyświetlane',
              value: filteredEmployees.toString(),
              color: AppThemePro.statusInfo,
              subtitle: 'po filtrach',
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Active employees percentage
          Expanded(
            child: _buildStatCard(
              icon: Icons.verified_user,
              title: 'Aktywni',
              value: totalEmployees > 0
                  ? '${((filteredEmployees / totalEmployees) * 100).round()}%'
                  : '0%',
              color: AppThemePro.statusSuccess,
              subtitle: 'z całości',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppThemePro.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final shouldShowTableView = screenWidth > 900 && _isTableView;

    return Scaffold(
      backgroundColor: AppThemePro.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Zarządzanie pracownikami'),
        backgroundColor: AppThemePro.backgroundSecondary,
        actions: [
          // View toggle for larger screens
          if (screenWidth > 900) ...[
            Tooltip(
              message: _isTableView
                  ? 'Przełącz na karty'
                  : 'Przełącz na tabelę',
              child: IconButton(
                onPressed: _toggleView,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _isTableView ? Icons.grid_view : Icons.table_rows,
                    key: ValueKey(_isTableView),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Add employee button for smaller screens
          if (screenWidth <= 900)
            Tooltip(
              message: canEdit ? 'Dodaj pracownika' : kRbacNoPermissionTooltip,
              child: AnimatedButton(
                onPressed: canEdit ? () => _showEmployeeForm() : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      color: canEdit ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dodaj',
                      style: TextStyle(
                        color: canEdit ? Colors.white : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<List<Employee>>(
        stream: _employeeService.getEmployees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: PremiumShimmerLoadingWidget.fullScreen(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppThemePro.statusError,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Błąd podczas wczytywania danych',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Błąd: ${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppThemePro.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Spróbuj ponownie'),
                  ),
                ],
              ),
            );
          }

          final allEmployees = snapshot.data ?? [];
          final filteredEmployees = _filterAndSortEmployees(allEmployees);

          return Column(
            children: [
              // Statistics bar at the top
              _buildStatisticsBar(
                allEmployees.length,
                filteredEmployees.length,
              ),

              // Search and filters
              EmployeeSearchAndFiltersWidget(
                onSearchChanged: _onSearchChanged,
                onBranchFilterChanged: _onBranchFilterChanged,
                onStatusFilterChanged: _onStatusFilterChanged,
                onPositionFilterChanged: _onPositionFilterChanged,
                branches: _branches,
                positions: _positions,
                currentSearchQuery: _searchQuery,
                selectedBranch: _selectedBranch,
                selectedStatus: _selectedStatus,
                selectedPosition: _selectedPosition,
              ),

              // Main content
              Expanded(
                child: shouldShowTableView
                    ? EmployeeTableWidget(
                        employees: filteredEmployees,
                        onEdit: (employee) =>
                            _showEmployeeForm(employee: employee),
                        onDelete: _deleteEmployee,
                        onRowTap: (employee) =>
                            _showEmployeeForm(employee: employee),
                        canEdit: canEdit,
                        sortColumn: _sortColumn,
                        sortAscending: _sortAscending,
                        onSort: _onSort,
                      )
                    : EmployeeCardsWidget(
                        employees: filteredEmployees,
                        onEdit: (employee) =>
                            _showEmployeeForm(employee: employee),
                        onDelete: _deleteEmployee,
                        onTap: (employee) =>
                            _showEmployeeForm(employee: employee),
                        canEdit: canEdit,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
