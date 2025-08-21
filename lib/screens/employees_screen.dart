import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models_and_services.dart';
import '../providers/auth_provider.dart';
import '../widgets/employee_form.dart';
import '../widgets/animated_button.dart';

// RBAC: wspólny tooltip dla braku uprawnień
const String kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final EmployeeService _employeeService = EmployeeService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortColumn = 'lastName';
  bool _sortAscending = true;
  String? _selectedBranch;
  List<String> _branches = [];

  // Debouncing timer for search
  Timer? _searchTimer;

  // RBAC getter
  bool get canEdit => Provider.of<AuthProvider>(context, listen: false).isAdmin;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
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

  void _showEmployeeForm({Employee? employee}) {
    showDialog(
      context: context,
      builder: (context) => EmployeeForm(employee: employee),
    ).then((_) => _loadBranches()); // Refresh branches after form closes
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
        default:
          comparison = a.lastName.compareTo(b.lastName);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Zarządzanie pracownikami'),
        backgroundColor: AppTheme.backgroundSecondary,
        actions: [
          Tooltip(
            message: canEdit ? 'Dodaj pracownika' : kRbacNoPermissionTooltip,
            child: AnimatedButton(
              onPressed: canEdit ? () => _showEmployeeForm() : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: canEdit ? Colors.white : Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Dodaj pracownika',
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
      body: Column(
        children: [
          // Search and filters
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.backgroundSecondary,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: const InputDecoration(
                          labelText: 'Szukaj pracowników',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          hintText: 'Wpisz imię, nazwisko, email...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedBranch,
                        decoration: const InputDecoration(
                          labelText: 'Filia',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Wszystkie filie'),
                          ),
                          ..._branches.map((branch) {
                            return DropdownMenuItem<String>(
                              value: branch,
                              child: Text(branch),
                            );
                          }).toList(),
                        ],
                        onChanged: _onBranchFilterChanged,
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _sortColumn,
                      onChanged: (value) {
                        if (value != null) {
                          _onSort(value, _sortAscending);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'lastName',
                          child: Text('Nazwisko'),
                        ),
                        DropdownMenuItem(
                          value: 'firstName',
                          child: Text('Imię'),
                        ),
                        DropdownMenuItem(value: 'email', child: Text('Email')),
                        DropdownMenuItem(
                          value: 'position',
                          child: Text('Stanowisko'),
                        ),
                        DropdownMenuItem(
                          value: 'branchCode',
                          child: Text('Filia'),
                        ),
                        DropdownMenuItem(
                          value: 'createdAt',
                          child: Text('Data utworzenia'),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => _onSort(_sortColumn, !_sortAscending),
                      icon: Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Employees table
          Expanded(
            child: StreamBuilder<List<Employee>>(
              stream: _searchQuery.isEmpty && _selectedBranch == null
                  ? _employeeService.getEmployees()
                  : _selectedBranch != null && _searchQuery.isEmpty
                  ? _employeeService.getEmployeesByBranch(_selectedBranch!)
                  : _employeeService.searchEmployees(_searchQuery),
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
                          color: AppTheme.errorPrimary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Błąd podczas wczytywania danych',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Błąd: ${snapshot.error}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
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

                final employees = snapshot.data ?? [];
                final filteredEmployees = _filterAndSortEmployees(employees);

                if (filteredEmployees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outlined,
                          size: 64,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty && _selectedBranch == null
                              ? 'Brak pracowników w systemie'
                              : 'Nie znaleziono pracowników',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty && _selectedBranch == null
                              ? 'Dodaj pierwszego pracownika, aby rozpocząć'
                              : 'Spróbuj zmienić kryteria wyszukiwania',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        if (_searchQuery.isEmpty &&
                            _selectedBranch == null) ...[
                          const SizedBox(height: 24),
                          Tooltip(
                            message: canEdit
                                ? 'Dodaj pierwszego pracownika'
                                : kRbacNoPermissionTooltip,
                            child: AnimatedButton(
                              onPressed: canEdit
                                  ? () => _showEmployeeForm()
                                  : null,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: canEdit ? Colors.white : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Dodaj pierwszego pracownika',
                                    style: TextStyle(
                                      color: canEdit
                                          ? Colors.white
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return DataTableWidget<Employee>(
                  items: filteredEmployees,
                  columns: [
                    DataTableColumn<Employee>(
                      label: 'Imię',
                      value: (employee) => employee.firstName,
                      sortable: true,
                      width: 120,
                      widget: (employee) => Text(
                        employee.firstName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    DataTableColumn<Employee>(
                      label: 'Nazwisko',
                      value: (employee) => employee.lastName,
                      sortable: true,
                      width: 130,
                      widget: (employee) => Text(
                        employee.lastName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    DataTableColumn<Employee>(
                      label: 'Email',
                      value: (employee) => employee.email,
                      sortable: true,
                      width: 200,
                      widget: (employee) => Text(
                        employee.email,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    DataTableColumn<Employee>(
                      label: 'Telefon',
                      value: (employee) => employee.phone,
                      width: 130,
                      widget: (employee) => Text(
                        employee.phone.isNotEmpty ? employee.phone : '-',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    DataTableColumn<Employee>(
                      label: 'Stanowisko',
                      value: (employee) => employee.position,
                      sortable: true,
                      width: 160,
                      widget: (employee) => Text(
                        employee.position,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    DataTableColumn<Employee>(
                      label: 'Filia',
                      value: (employee) => employee.branchCode,
                      sortable: true,
                      width: 80,
                      widget: (employee) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          employee.branchCode,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    DataTableColumn<Employee>(
                      label: 'Status',
                      value: (employee) =>
                          employee.isActive ? 'Aktywny' : 'Nieaktywny',
                      width: 100,
                      widget: (employee) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: employee.isActive
                              ? AppTheme.successPrimary.withValues(alpha: 0.1)
                              : AppTheme.errorPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: employee.isActive
                                ? AppTheme.successPrimary
                                : AppTheme.errorPrimary,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          employee.isActive ? 'Aktywny' : 'Nieaktywny',
                          style: TextStyle(
                            color: employee.isActive
                                ? AppTheme.successPrimary
                                : AppTheme.errorPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    DataTableColumn<Employee>(
                      label: 'Data utworzenia',
                      value: (employee) =>
                          '${employee.createdAt.day.toString().padLeft(2, '0')}.${employee.createdAt.month.toString().padLeft(2, '0')}.${employee.createdAt.year}',
                      sortable: true,
                      width: 120,
                      widget: (employee) => Text(
                        '${employee.createdAt.day.toString().padLeft(2, '0')}.${employee.createdAt.month.toString().padLeft(2, '0')}.${employee.createdAt.year}',
                        style: const TextStyle(color: AppTheme.textTertiary),
                      ),
                    ),
                    DataTableColumn<Employee>(
                      label: 'Akcje',
                      value: (employee) => '',
                      width: 120,
                      widget: (employee) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: canEdit
                                ? 'Edytuj'
                                : kRbacNoPermissionTooltip,
                            child: IconButton(
                              onPressed: canEdit
                                  ? () => _showEmployeeForm(employee: employee)
                                  : null,
                              icon: Icon(
                                Icons.edit,
                                color: canEdit
                                    ? AppTheme.secondaryGold
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          Tooltip(
                            message: canEdit
                                ? 'Usuń'
                                : kRbacNoPermissionTooltip,
                            child: IconButton(
                              onPressed: canEdit
                                  ? () => _deleteEmployee(employee)
                                  : null,
                              icon: Icon(
                                Icons.delete,
                                color: canEdit
                                    ? AppTheme.errorPrimary
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onRowTap: (employee) => _showEmployeeForm(employee: employee),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
